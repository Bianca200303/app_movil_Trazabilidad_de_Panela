import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/services/sync/producers_sync_service.dart';
import 'package:panela_sys/services/sync/plots_sync_service.dart';
import 'package:panela_sys/services/sync/production_sync_service.dart';
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
    if (OfflineConfig.instance.features.production) {
      DebugLogger.info('SyncService', 'syncAll',
          '=== INICIANDO SYNC DE LOTES DE PRODUCCIÓN ===');

      await for (final _ in ProductionSyncService(_db).sync()) {
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

    DebugLogger.info('SyncService', 'syncAll',
        'Sincronización general completada: $synced/$total items synced');
  }

  /// Calculate total pending items across all enabled modules
  Future<int> _getTotalPending() async {
    DebugLogger.debug('SyncService', '_getTotalPending',
        'Calculando total de items pendientes');

    int count = 0;

    if (OfflineConfig.instance.features.producers) {
      final producersCount = await _db.producersDao.countPending();
      final plotsCount = await _db.plotsDao.countPending();

      DebugLogger.debug('SyncService', '_getTotalPending',
          'Productores pendientes: $producersCount');
      DebugLogger.debug(
          'SyncService', '_getTotalPending', 'Parcelas pendientes: $plotsCount');

      count += producersCount + plotsCount;
    }

    if (OfflineConfig.instance.features.production) {
      final productionCount = await _db.productionBatchesDao.countPending();

      DebugLogger.debug('SyncService', '_getTotalPending',
          'Lotes de producción pendientes: $productionCount');

      count += productionCount;
    }

    // Add other modules when implemented
    // if (OfflineConfig.instance.features.exits) { ... }

    DebugLogger.debug(
        'SyncService', '_getTotalPending', 'Total pendientes: $count');

    return count;
  }
}
