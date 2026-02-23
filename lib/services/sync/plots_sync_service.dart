import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

/// Sync service for Plots
///
/// Handles uploading pending plots to Supabase and marking them as synced.
/// Requires producers to be synced first to get remote producer IDs.
/// Provides detailed logging for debugging synchronization operations.
class PlotsSyncService {
  final AppDatabase _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  PlotsSyncService(this._db);

  /// Synchronize all pending plots
  ///
  /// Yields after each plot is successfully synced.
  /// Logs all data sent to and received from Supabase.
  ///
  /// Note: Skips plots whose producers are not yet synced.
  Stream<void> sync() async* {
    DebugLogger.info(
        'PlotsSyncService', 'sync', 'Iniciando sincronización de parcelas');

    final pending = await _db.plotsDao.getPending();

    DebugLogger.info(
        'PlotsSyncService', 'sync', 'Parcelas pendientes: ${pending.length}');

    if (pending.isEmpty) {
      DebugLogger.info(
          'PlotsSyncService', 'sync', 'No hay parcelas pendientes de sync');
      return;
    }

    for (final plot in pending) {
      bool synced = false;

      try {
        DebugLogger.info(
            'PlotsSyncService',
            'sync',
            'Syncing plot: localId=${plot.id}, '
            'code=${plot.code}, '
            'name="${plot.name}"');

        // Get producer's remote ID
        final producer = await _db.producersDao.getById(plot.producerLocalId);

        if (producer == null) {
          DebugLogger.error('PlotsSyncService', 'sync',
              'Producer not found for plot ${plot.id}: producerLocalId=${plot.producerLocalId}');
          // Skip this plot and continue with next one
          synced = false;
        } else if (producer.remoteId == null) {
          DebugLogger.warning(
              'PlotsSyncService',
              'sync',
              'Producer not synced yet for plot ${plot.id}. '
              'Skipping plot. Producer localId=${producer.id}, dni=${producer.dni}');
          // Skip this plot and continue with next one
          synced = false;
        } else {
          final remoteProducerId = producer.remoteId!;

          DebugLogger.debug('PlotsSyncService', 'sync',
              'Producer remote ID: $remoteProducerId');

          // Prepare insert data
          final insertData = {
            'name': plot.name,
            'code': plot.code,
            'producer_id': remoteProducerId,
          };

          DebugLogger.debug(
              'PlotsSyncService', 'sync', 'Sending to Supabase: $insertData');

          // Insert to Supabase
          final response =
              await _supabase.from('plots').insert(insertData).select().single();

          DebugLogger.debug(
              'PlotsSyncService', 'sync', 'Received from Supabase: $response');

          final remoteId = response['id'] as String;

          DebugLogger.info(
              'PlotsSyncService', 'sync', 'Remote ID received: $remoteId');

          // Mark as synced
          await _db.plotsDao.markAsSynced(
            localId: plot.id,
            remoteId: remoteId,
            remoteProducerId: remoteProducerId,
          );

          DebugLogger.info(
              'PlotsSyncService',
              'sync',
              'Plot synced successfully: localId=${plot.id}, remoteId=$remoteId');

          synced = true;
        }
      } catch (e, st) {
        if (e is PostgrestException) {
          // Handle duplicate plot code
          if (e.code == '23505' &&
              e.message.contains('unique_plot_name_code_per_producer')) {
            DebugLogger.warning(
                'PlotsSyncService',
                'sync',
                'Plot ${plot.id} already exists in Supabase (code: ${plot.code}). '
                'Skipping sync.');
            // Skip this plot and continue with next one
            synced = false;
          } else {
            DebugLogger.error(
                'PlotsSyncService', 'sync', 'Error syncing plot ${plot.id}: $e',
                stackTrace: st);
            rethrow;
          }
        } else {
          DebugLogger.error(
              'PlotsSyncService', 'sync', 'Error syncing plot ${plot.id}: $e',
              stackTrace: st);
          rethrow;
        }
      }

      if (synced) {
        yield null;
      }
    }

    DebugLogger.info(
        'PlotsSyncService', 'sync', 'Sincronización de parcelas completada');
  }
}
