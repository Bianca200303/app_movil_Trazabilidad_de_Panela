import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/services/production_batch_service.dart';

/// Sync service for Production Batches
///
/// Handles uploading pending production batches and related data to Supabase.
/// Validates dependencies (producers and plots must be synced first).
/// Provides detailed logging for debugging synchronization operations.
class ProductionSyncService {
  final AppDatabase _db;
  final ProductionBatchService _batchService;

  ProductionSyncService(this._db)
      : _batchService = ProductionBatchService(db: _db);

  /// Synchronize all pending production batches
  ///
  /// For each pending batch:
  /// 1. Validate dependencies (producer and plot must be synced)
  /// 2. Get related data (certs, temps, pH control)
  /// 3. Build request with remote IDs
  /// 4. Upload batch to Supabase using ProductionBatchService
  /// 5. Mark all as synced
  ///
  /// Yields after each batch is successfully synced.
  /// Skips batches with unsynced dependencies.
  Stream<void> sync() async* {
    DebugLogger.info('ProductionSyncService', 'sync',
        'Iniciando sincronización de lotes de producción');

    final pending = await _db.productionBatchesDao.getPending();

    DebugLogger.info('ProductionSyncService', 'sync',
        'Lotes de producción pendientes: ${pending.length}');

    if (pending.isEmpty) {
      DebugLogger.info('ProductionSyncService', 'sync',
          'No hay lotes pendientes de sync');
      return;
    }

    for (final batch in pending) {
      bool synced = false;

      try {
        DebugLogger.info(
            'ProductionSyncService',
            'sync',
            'Syncing batch: localId=${batch.id}, '
            'batchCode=${batch.batchCode}, '
            'producerLocalId=${batch.producerLocalId}');

        // 1. Validate producer dependency
        final producer = await _db.producersDao.getById(batch.producerLocalId);
        if (producer == null) {
          DebugLogger.error('ProductionSyncService', 'sync',
              'Producer not found for batch ${batch.id}. Skipping batch.');
          continue;
        }

        if (producer.remoteId == null) {
          DebugLogger.warning(
              'ProductionSyncService',
              'sync',
              'Producer ${producer.id} (${producer.firstName} ${producer.lastName}) '
              'not synced yet for batch ${batch.id}. Skipping batch.');
          continue;
        }

        DebugLogger.debug('ProductionSyncService', 'sync',
            'Producer validated: remoteId=${producer.remoteId}');

        // 2. Validate plot dependency (if applicable)
        String? plotRemoteId;
        if (batch.plotLocalId != null) {
          final plot = await _db.plotsDao.getById(batch.plotLocalId!);
          if (plot == null) {
            DebugLogger.error('ProductionSyncService', 'sync',
                'Plot not found for batch ${batch.id}. Skipping batch.');
            continue;
          }

          if (plot.remoteId == null) {
            DebugLogger.warning(
                'ProductionSyncService',
                'sync',
                'Plot ${plot.id} (${plot.name}) not synced yet for batch ${batch.id}. '
                'Skipping batch.');
            continue;
          }

          plotRemoteId = plot.remoteId;
          DebugLogger.debug('ProductionSyncService', 'sync',
              'Plot validated: remoteId=$plotRemoteId');
        }

        // 3. Get related local data
        final certs =
            await _db.productionBatchCertsDao.getByBatchLocalId(batch.id);
        final temps = await _db.batchTemperaturesDao.getByBatchLocalId(batch.id);
        final phControl =
            await _db.batchPhControlsDao.getByBatchLocalId(batch.id);

        DebugLogger.debug(
            'ProductionSyncService',
            'sync',
            'Related data: certs=${certs.length}, '
            'temps=${temps.length}, '
            'phControl=${phControl != null}');

        // 4. Build request with remote IDs
        final request = CreateProductionBatchRequest(
          producerId: producer.remoteId!,
          plotId: plotRemoteId,
          harvestDate: batch.harvestDate,
          processDate: batch.processDate,
          juiceLiters: batch.juiceLiters,
          panelaKg: batch.panelaKg,
          confitilloKg: batch.confitilloKg,
          extractionPercentage: batch.porcentajeExtraccion ?? 62.5,
          cachazaPercentage: batch.cachazaPercentage ?? 2.5,
          selectedCertificateIds: certs.map((c) => c.batchCertId).toList(),
          temperatures: temps.map((t) => t.temperature).toList(),
          phInitial: phControl?.phInitial ?? 0.0,
          phFinal: phControl?.phFinal ?? 0.0,
          regulatorType: phControl?.regulatorType ?? 'cal',
          regulatorQuantityValue: phControl?.regulatorQuantityValue,
          regulatorQuantityUnit: phControl?.regulatorQuantityUnit,
          brix: phControl?.brix,
          correctiveAction: phControl?.correctiveAction,
        );

        DebugLogger.debug('ProductionSyncService', 'sync',
            'Request built: producerId=${request.producerId}, plotId=${request.plotId}');

        // 5. Upload to Supabase using ProductionBatchService
        DebugLogger.debug('ProductionSyncService', 'sync',
            'Uploading batch ${batch.id} to Supabase');

        final remoteBatch = await _batchService.createOnline(request);

        DebugLogger.info('ProductionSyncService', 'sync',
            'Batch uploaded to Supabase: remoteId=${remoteBatch.id}');

        // 6. Mark batch as synced
        await _db.productionBatchesDao.markAsSynced(
          localId: batch.id,
          remoteId: remoteBatch.id,
        );

        DebugLogger.debug('ProductionSyncService', 'sync',
            'Batch marked as synced in local DB');

        // 7. Mark related tables as synced
        await _markRelatedAsSynced(batch.id);

        DebugLogger.info(
            'ProductionSyncService',
            'sync',
            'Batch synced successfully: localId=${batch.id}, '
            'remoteId=${remoteBatch.id}, '
            'batchCode=${remoteBatch.batchCode}');

        synced = true;
      } catch (e, st) {
        // Handle duplicate batch code (23505 = unique constraint violation)
        if (e is PostgrestException && e.code == '23505') {
          DebugLogger.warning(
              'ProductionSyncService',
              'sync',
              'Batch ${batch.id} (${batch.batchCode}) already exists in Supabase. '
              'Marking as synced with placeholder remote ID.');

          // Mark as synced anyway to avoid retrying
          await _db.productionBatchesDao.markAsSynced(
            localId: batch.id,
            remoteId: 'DUPLICATE_${batch.id}',
          );

          await _markRelatedAsSynced(batch.id);

          synced = true;
        } else if (e is PostgrestException &&
            e.message.contains('foreign key')) {
          // Foreign key constraint violation - dependency not found
          DebugLogger.error(
              'ProductionSyncService',
              'sync',
              'Foreign key constraint violation for batch ${batch.id}. '
              'Producer or plot may have been deleted. Skipping batch.',
              stackTrace: st);
          // Skip this batch and continue with next one
          synced = false;
        } else {
          // Other errors - rethrow to stop sync
          DebugLogger.error('ProductionSyncService', 'sync',
              'Error syncing batch ${batch.id}: $e',
              stackTrace: st);
          rethrow;
        }
      }

      if (synced) {
        yield null; // Signal progress
      }
    }

    DebugLogger.info('ProductionSyncService', 'sync',
        'Sincronización de lotes de producción completada');
  }

  /// Mark related tables as synced (simplified - no individual remote IDs)
  ///
  /// We use placeholder remote IDs since related tables cascade delete
  /// with the batch and we don't need to track individual IDs.
  Future<void> _markRelatedAsSynced(int batchLocalId) async {
    DebugLogger.debug('ProductionSyncService', '_markRelatedAsSynced',
        'Marking related tables for batch $batchLocalId');

    try {
      // Get all related records
      final certs =
          await _db.productionBatchCertsDao.getByBatchLocalId(batchLocalId);
      final temps =
          await _db.batchTemperaturesDao.getByBatchLocalId(batchLocalId);
      final phControl =
          await _db.batchPhControlsDao.getByBatchLocalId(batchLocalId);

      // Mark certs as synced (use placeholder remote IDs)
      if (certs.isNotEmpty) {
        await _db.productionBatchCertsDao.markBatchAsSynced(
          batchLocalId,
          certs.map((c) => 'SYNCED_${c.id}').toList(),
        );
        DebugLogger.debug('ProductionSyncService', '_markRelatedAsSynced',
            'Marked ${certs.length} certificates as synced');
      }

      // Mark temps as synced
      if (temps.isNotEmpty) {
        await _db.batchTemperaturesDao.markBatchAsSynced(
          batchLocalId,
          temps.map((t) => 'SYNCED_${t.id}').toList(),
        );
        DebugLogger.debug('ProductionSyncService', '_markRelatedAsSynced',
            'Marked ${temps.length} temperatures as synced');
      }

      // Mark pH control as synced
      if (phControl != null) {
        await _db.batchPhControlsDao.markAsSynced(
          localId: phControl.id,
          remoteId: 'SYNCED_${phControl.id}',
        );
        DebugLogger.debug('ProductionSyncService', '_markRelatedAsSynced',
            'Marked pH control as synced');
      }
    } catch (e, st) {
      DebugLogger.error('ProductionSyncService', '_markRelatedAsSynced',
          'Error marking related tables: $e',
          stackTrace: st);
      rethrow;
    }
  }
}
