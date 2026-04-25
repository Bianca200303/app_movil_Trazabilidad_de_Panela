import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/services/form_data_cache_service.dart';
import 'package:panela_sys/services/sync/sync_service.dart';
import 'package:panela_sys/services/sync/auto_sync_service.dart';
import 'package:panela_sys/models/auto_sync_event.dart';

/// Provider for the main AppDatabase instance
///
/// Creates a single database instance to be shared across the app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  DebugLogger.debug('appDatabaseProvider', 'create', 'Creating AppDatabase instance');
  return AppDatabase();
});

/// Provider for network connectivity state
///
/// Streams `true` when connected (WiFi or mobile), `false` when offline.
/// Updates in real-time as connectivity changes.
final connectivityProvider = StreamProvider<bool>((ref) {
  DebugLogger.debug('connectivityProvider', 'create', 'Creating connectivity stream');

  return NetworkDetector().onConnectivityChanged.map((isConnected) {
    DebugLogger.debug('connectivityProvider', 'onConnectivityChanged',
        'Connectivity changed: ${isConnected ? "ONLINE" : "OFFLINE"}');
    return isConnected;
  });
});

/// Provider for total pending sync count
///
/// Polls database every 30 seconds to count pending items across all enabled modules.
/// Returns total count of producers + plots + production + exits (when enabled).
final syncPendingCountProvider = StreamProvider<int>((ref) async* {
  final db = ref.watch(appDatabaseProvider);

  DebugLogger.debug('syncPendingCountProvider', 'create',
      'Starting pending count stream (polling every 30s)');

  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    int count = 0;

    if (OfflineConfig.instance.features.producers) {
      final producersCount = await db.producersDao.countPending();
      final plotsCount = await db.plotsDao.countPending();

      count += producersCount + plotsCount;

      DebugLogger.debug('syncPendingCountProvider', 'poll',
          'Pending: $producersCount producers, $plotsCount plots');
    }

    if (OfflineConfig.instance.features.production) {
      final productionCount = await db.productionBatchesDao.countPending(AppConfig.current.id);

      count += productionCount;

      DebugLogger.debug('syncPendingCountProvider', 'poll',
          'Production pending: $productionCount');
    }

    // Add other modules when enabled
    // if (OfflineConfig.instance.features.exits) { ... }

    DebugLogger.debug('syncPendingCountProvider', 'poll',
        'Total pending count: $count');

    yield count;
  }
});

/// Provider for ProducerService with database injection
///
/// Creates ProducerService instance with AppDatabase dependency.
final producerServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProducerService(db: db);
});

/// Provider for PlotService with database injection
///
/// Creates PlotService instance with AppDatabase dependency.
final plotServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlotService(db: db);
});

/// Provider for FormDataCacheService with database injection
///
/// Creates FormDataCacheService instance to manage form reference data caching.
/// This service handles refreshing data on login and clearing on logout.
final formDataCacheServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FormDataCacheService(db: db);
});

/// Provider for SyncService with database injection
///
/// Orchestrates synchronization of all pending offline data.
/// Coordinates sync of producers, plots, and other modules in correct order.
final syncServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncService(db: db);
});

/// Provider for global auto-sync state
///
/// Manages automatic synchronization when connectivity changes and provides
/// global sync state to prevent concurrent syncs (both auto and manual).
///
/// State (bool): true if sync is in progress, false otherwise
///
/// Features:
/// - Listens to connectivityProvider for offline → online transitions
/// - Automatically triggers sync when connection is restored
/// - Blocks concurrent syncs (manual sync button will be disabled during auto-sync)
/// - Provides unified sync state across all screens
final autoSyncStateProvider = StateNotifierProvider<AutoSyncNotifier, bool>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final notifier = AutoSyncNotifier(ref, db);

  // Listen to connectivity changes and trigger auto-sync on offline → online transition
  ref.listen<AsyncValue<bool>>(
    connectivityProvider,
    (previous, next) {
      next.whenData((isConnected) {
        notifier.checkConnectivity(isConnected);
      });
    },
  );

  return notifier;
});

/// Stream provider for auto-sync events
///
/// Emits events when automatic synchronization starts, completes, or fails.
/// Used by the UI to show SnackBars with user-friendly notifications.
///
/// Events are only emitted for automatic sync (offline → online transitions),
/// not for manual sync triggered by the user.
final autoSyncEventProvider = StreamProvider<AutoSyncEvent>((ref) {
  final notifier = ref.watch(autoSyncStateProvider.notifier);
  return notifier.eventStream;
});
