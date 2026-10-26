import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/services/sync/producers_sync_service.dart';
import 'package:panela_sys/services/sync/plots_sync_service.dart';
import 'package:panela_sys/services/sync/production_sync_service.dart';
import 'package:panela_sys/services/sync/pending_count.dart';
import 'package:panela_sys/services/sync/pending_submissions_service.dart';
import 'package:panela_sys/models/sync_models.dart';

/// Main synchronization orchestrator
///
/// Coordinates sync of all enabled offline modules in correct order.
/// Provides progress updates via stream for UI feedback.
class SyncService {
  final AppDatabase _db;
  final NetworkDetector _network;

  SyncService({required AppDatabase db})
      : _db = db,
        _network = NetworkDetector();

  /// Synchronize all pending data
  ///
  /// Order of sync:
  /// 1. Producers (must sync first)
  /// 2. Plots (depends on producers)
  /// 3. Production batches (depends on producers and plots)
  /// 4. Controles pendientes (pueden depender de un lote del paso 3)
  ///
  /// Yields progress after each entity is synced.
  /// Throws if no internet connection is available.
  Stream<SyncProgress> syncAll() async* {
    DebugLogger.info('SyncService', 'syncAll', 'Iniciando sincronización general');

    // Check connectivity first
    if (!await _network.isConnected) {
      DebugLogger.error(
          'SyncService', 'syncAll', 'No hay conexión a internet');
      throw Exception('Sin conexión a internet');
    }

    DebugLogger.info('SyncService', 'syncAll', 'Conexión verificada - procediendo');

    // Calculate total pending
    final total = await _getTotalPending();

    DebugLogger.info(
        'SyncService', 'syncAll', 'Total de items pendientes: $total');

    if (total == 0) {
      DebugLogger.info(
          'SyncService', 'syncAll', 'No hay items pendientes de sync');
      return;
    }

    int synced = 0;

    // Sync producers first (if enabled)
    if (OfflineConfig.instance.features.producers) {
      DebugLogger.info('SyncService', 'syncAll',
          '=== INICIANDO SYNC DE PRODUCTORES ===');

      await for (final _ in ProducersSyncService(_db).sync()) {
        synced++;
        DebugLogger.debug('SyncService', 'syncAll',
            'Progress: $synced/$total (${((synced / total) * 100).toStringAsFixed(1)}%)');

        yield SyncProgress(
          module: 'Productores',
          current: synced,
          total: total,
        );
      }

      DebugLogger.info(
          'SyncService', 'syncAll', '=== SYNC DE PRODUCTORES COMPLETADO ===');

      // Sync plots (if enabled)
      DebugLogger.info(
          'SyncService', 'syncAll', '=== INICIANDO SYNC DE PARCELAS ===');

      await for (final _ in PlotsSyncService(_db).sync()) {
        synced++;
        DebugLogger.debug('SyncService', 'syncAll',
            'Progress: $synced/$total (${((synced / total) * 100).toStringAsFixed(1)}%)');

        yield SyncProgress(
          module: 'Parcelas',
          current: synced,
          total: total,
        );
      }

      DebugLogger.info(
          'SyncService', 'syncAll', '=== SYNC DE PARCELAS COMPLETADO ===');
    }

    // Sync production batches (after plots) - if enabled
    final productionSync = ProductionSyncService(_db);
    if (OfflineConfig.instance.features.production) {
      DebugLogger.info('SyncService', 'syncAll',
          '=== INICIANDO SYNC DE LOTES DE PRODUCCIÓN ===');

      await for (final _ in productionSync.sync()) {
        synced++;
        DebugLogger.debug('SyncService', 'syncAll',
            'Progress: $synced/$total (${((synced / total) * 100).toStringAsFixed(1)}%)');

        yield SyncProgress(
          module: 'Producción',
          current: synced,
          total: total,
        );
      }

      DebugLogger.info('SyncService', 'syncAll',
          '=== SYNC DE LOTES DE PRODUCCIÓN COMPLETADO ===');
    }

    // Controles guardados sin señal (bandeja genérica). Van al final porque
    // pueden depender de un lote creado sin señal que se acaba de enviar.
    DebugLogger.info('SyncService', 'syncAll',
        '=== INICIANDO SYNC DE CONTROLES PENDIENTES ===');

    await for (final _ in PendingSubmissionsService(db: _db).sync()) {
      synced++;
      yield SyncProgress(
        module: 'Controles',
        current: synced,
        total: total,
      );
    }

    DebugLogger.info('SyncService', 'syncAll',
        'Sincronización general completada: $synced/$total items synced');

    // Un lote rechazado no frenó a los demás ni a los controles; se avisa
    // recién al final.
    if (productionSync.rejectedCount > 0) {
      throw ProductionBatchesRejectedException(
        productionSync.rejectedCount,
        productionSync.firstRejectionReason!,
      );
    }
  }

  Future<int> _getTotalPending() => countPendingSync(_db);
}
