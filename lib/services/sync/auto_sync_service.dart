import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/services/sync/sync_service.dart';
import 'package:panela_sys/models/sync_models.dart';
import 'package:panela_sys/models/auto_sync_event.dart';

/// Auto-sync service that manages automatic synchronization when connectivity changes
///
/// Features:
/// - Detects offline → online transitions
/// - Automatically triggers sync when connection is restored
/// - Prevents concurrent synchronization (blocks both auto and manual sync)
/// - Provides global sync state for UI updates across all screens
class AutoSyncNotifier extends StateNotifier<bool> {
  final Ref _ref;
  final AppDatabase _db;
  late final SyncService _syncService;

  // Track last connectivity state to detect transitions
  bool _wasOffline = false;

  // Event stream for UI notifications (SnackBars)
  final _eventController = StreamController<AutoSyncEvent>.broadcast();
  Stream<AutoSyncEvent> get eventStream => _eventController.stream;

  AutoSyncNotifier(this._ref, this._db) : super(false) {
    _syncService = SyncService(db: _db);
    DebugLogger.info('AutoSyncNotifier', 'constructor',
        'Auto-sync service initialized');
  }

  /// Check connectivity state and trigger auto-sync if transitioning to online
  ///
  /// Called by the connectivity listener in the provider.
  /// Only triggers if:
  /// - Previously was offline (_wasOffline == true)
  /// - Now is online (isConnected == true)
  /// - Not currently syncing (state == false)
  void checkConnectivity(bool isConnected) {
    DebugLogger.debug('AutoSyncNotifier', 'checkConnectivity',
        'Connectivity: ${isConnected ? "ONLINE" : "OFFLINE"}, wasOffline: $_wasOffline, isSyncing: $state');

    // Detect offline → online transition
    if (_wasOffline && isConnected && !state) {
      DebugLogger.info('AutoSyncNotifier', 'checkConnectivity',
          '🔄 TRANSITION DETECTED: offline → online - Starting auto-sync');

      // Trigger auto-sync (don't await - runs in background)
      _startAutoSync();
    }

    // Update previous state
    _wasOffline = !isConnected;
  }

  /// Start automatic synchronization
  ///
  /// This is the entry point for auto-sync triggered by connectivity changes.
  /// Sets global sync state to prevent concurrent syncs.
  Future<void> _startAutoSync() async {
    if (state) {
      DebugLogger.warning('AutoSyncNotifier', '_startAutoSync',
          'Sync already in progress - skipping auto-sync');
      return;
    }

    await _executeSyncWithState(isAutoSync: true);
  }

  /// Start manual synchronization
  ///
  /// This is the entry point for manual sync triggered by user action (button press).
  /// Returns a stream for UI progress updates.
  Stream<SyncProgress> startManualSync() async* {
    if (state) {
      DebugLogger.warning('AutoSyncNotifier', 'startManualSync',
          'Sync already in progress - rejecting manual sync');
      throw Exception('Ya hay una sincronización en curso');
    }

    DebugLogger.info('AutoSyncNotifier', 'startManualSync',
        '🔄 Starting manual sync');

    // Execute sync and yield progress
    await for (final progress in _executeSyncWithStateStream()) {
      yield progress;
    }
  }

  /// Execute sync and manage global state (for auto-sync without progress updates)
  Future<void> _executeSyncWithState({required bool isAutoSync}) async {
    // Set syncing state (blocks other syncs)
    state = true;

    DebugLogger.info('AutoSyncNotifier', '_executeSyncWithState',
        '🔒 Global sync state locked - ${isAutoSync ? "AUTO" : "MANUAL"} sync starting');

    // Emit started event (only for auto-sync)
    if (isAutoSync) {
      _eventController.add(const AutoSyncEvent(type: AutoSyncEventType.started));
      DebugLogger.debug('AutoSyncNotifier', '_executeSyncWithState',
          '📢 Emitted STARTED event');
    }

    try {
      // Execute sync (consume stream without yielding)
      await for (final _ in _syncService.syncAll()) {
        // Just consume the stream, no UI updates for auto-sync
      }

      DebugLogger.info('AutoSyncNotifier', '_executeSyncWithState',
          '✅ ${isAutoSync ? "Auto" : "Manual"} sync completed successfully');

      // Emit completed event (only for auto-sync)
      if (isAutoSync) {
        _eventController.add(const AutoSyncEvent(type: AutoSyncEventType.completed));
        DebugLogger.debug('AutoSyncNotifier', '_executeSyncWithState',
            '📢 Emitted COMPLETED event');
      }
    } catch (e) {
      DebugLogger.error('AutoSyncNotifier', '_executeSyncWithState',
          '❌ ${isAutoSync ? "Auto" : "Manual"} sync failed: $e');

      // Emit failed event (only for auto-sync)
      if (isAutoSync) {
        _eventController.add(AutoSyncEvent(
          type: AutoSyncEventType.failed,
          errorMessage: e.toString(),
        ));
        DebugLogger.debug('AutoSyncNotifier', '_executeSyncWithState',
            '📢 Emitted FAILED event: $e');
      }

      rethrow;
    } finally {
      // Release sync state
      state = false;
      DebugLogger.info('AutoSyncNotifier', '_executeSyncWithState',
          '🔓 Global sync state unlocked');
    }
  }

  /// Execute sync and manage global state (for manual sync with progress updates)
  Stream<SyncProgress> _executeSyncWithStateStream() async* {
    // Set syncing state (blocks other syncs)
    state = true;

    DebugLogger.info('AutoSyncNotifier', '_executeSyncWithStateStream',
        '🔒 Global sync state locked - MANUAL sync with progress starting');

    try {
      // Execute sync and yield progress
      await for (final progress in _syncService.syncAll()) {
        yield progress;
      }

      DebugLogger.info('AutoSyncNotifier', '_executeSyncWithStateStream',
          '✅ Manual sync completed successfully');
    } catch (e) {
      DebugLogger.error('AutoSyncNotifier', '_executeSyncWithStateStream',
          '❌ Manual sync failed: $e');
      rethrow;
    } finally {
      // Release sync state
      state = false;
      DebugLogger.info('AutoSyncNotifier', '_executeSyncWithStateStream',
          '🔓 Global sync state unlocked');
    }
  }

  /// Get current sync state
  ///
  /// Returns true if any sync (auto or manual) is currently in progress.
  bool get isSyncing => state;

  @override
  void dispose() {
    _eventController.close();
    DebugLogger.debug('AutoSyncNotifier', 'dispose', 'Event controller closed');
    super.dispose();
  }
}
