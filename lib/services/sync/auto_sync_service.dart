import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/user_error_message.dart';
import 'package:panela_sys/providers/form_data_refresh_provider.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/services/sync/pending_count.dart';
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

  /// Espera tras volver la señal antes de subir: Android avisa "conectado"
  /// antes de que el WiFi o los datos terminen de levantar la red, y un
  /// envío inmediato falla con "No route to host".
  static const _settleDelay = Duration(seconds: 3);

  /// Esperas entre reintentos si la subida falla por falta de conexión; la
  /// última se repite mientras siga habiendo señal.
  static const _retryDelays = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
  ];

  Timer? _scheduledSync;
  int _retryAttempt = 0;

  // Event stream for UI notifications (SnackBars)
  final _eventController = StreamController<AutoSyncEvent>.broadcast();
  Stream<AutoSyncEvent> get eventStream => _eventController.stream;

  late final AppLifecycleListener _lifecycleListener;

  AutoSyncNotifier(this._ref, this._db) : super(false) {
    _syncService = SyncService(db: _db);
    _lifecycleListener = AppLifecycleListener(onResume: syncIfPending);
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

    if (!isConnected) {
      // Sin señal no tiene sentido reintentar; se vuelve a empezar al volver.
      _cancelScheduledSync();
    } else if (_wasOffline && !state) {
      DebugLogger.info('AutoSyncNotifier', 'checkConnectivity',
          '🔄 TRANSITION DETECTED: offline → online - Starting auto-sync');
      _retryAttempt = 0;
      _scheduleAutoSync(_settleDelay);
    }

    // Update previous state
    _wasOffline = !isConnected;
  }

  /// Sube los pendientes si los hay y hay señal. Cubre lo que el cambio
  /// "sin señal → con señal" no detecta: abrir la app (o volver a ella) ya
  /// con señal teniendo registros guardados de antes.
  Future<void> syncIfPending() async {
    if (state || _scheduledSync?.isActive == true) return;
    if (!await NetworkDetector().isConnected) return;
    if (await countPendingSync(_db) == 0) return;

    DebugLogger.info('AutoSyncNotifier', 'syncIfPending',
        'Hay registros pendientes y hay señal - subiendo');
    _retryAttempt = 0;
    await _startAutoSync();
  }

  /// Tras subir los pendientes, actualiza los datos para trabajar sin señal
  /// (respeta el intervalo mínimo de FormDataRefreshNotifier).
  void _refreshFormData() {
    unawaited(_ref.read(formDataRefreshProvider.notifier).refreshIfStale());
  }

  void _scheduleAutoSync(Duration delay) {
    _scheduledSync?.cancel();
    _scheduledSync = Timer(delay, _startAutoSync);
  }

  void _cancelScheduledSync() {
    _scheduledSync?.cancel();
    _scheduledSync = null;
    _retryAttempt = 0;
  }

  /// Start automatic synchronization
  ///
  /// This is the entry point for auto-sync triggered by connectivity changes.
  /// Sets global sync state to prevent concurrent syncs.
  ///
  /// Si falla por falta de conexión, se reintenta solo (ver [_retryDelays]).
  /// Un rechazo del servidor no se reintenta: daría el mismo resultado.
  Future<void> _startAutoSync() async {
    if (state) {
      DebugLogger.warning('AutoSyncNotifier', '_startAutoSync',
          'Sync already in progress - skipping auto-sync');
      return;
    }

    // Solo el primer intento avisa en pantalla; los reintentos van en
    // silencio hasta que uno termine bien.
    final isRetry = _retryAttempt > 0;
    try {
      await _executeSyncWithState(isAutoSync: true, notifyStartAndFailure: !isRetry);
      _retryAttempt = 0;
      _refreshFormData();
    } catch (e) {
      if (!looksLikeNetworkError(e)) {
        // Hubo conexión (el servidor rechazó algo): igual conviene traer
        // los datos al día.
        _refreshFormData();
        return;
      }
      if (_wasOffline) return;
      final delay = _retryDelays[_retryAttempt.clamp(0, _retryDelays.length - 1)];
      _retryAttempt++;
      DebugLogger.info('AutoSyncNotifier', '_startAutoSync',
          'Sin conexión estable con el servidor - reintento $_retryAttempt en ${delay.inSeconds}s');
      _scheduleAutoSync(delay);
    }
  }

  /// Start manual synchronization
  ///
  /// This is the entry point for manual sync triggered by user action (button press).
  /// Returns a stream for UI progress updates.
  ///
  /// La sincronización corre por su cuenta hasta terminar: si quien escucha
  /// deja de hacerlo (p. ej. se cierra el diálogo de progreso), solo deja de
  /// recibir el avance. Antes, al dejar de escuchar se cortaba la
  /// sincronización tras el primer registro enviado.
  Stream<SyncProgress> startManualSync() {
    if (state) {
      DebugLogger.warning('AutoSyncNotifier', 'startManualSync',
          'Sync already in progress - rejecting manual sync');
      return Stream.error(Exception('Ya hay una sincronización en curso'));
    }

    DebugLogger.info('AutoSyncNotifier', 'startManualSync',
        '🔄 Starting manual sync');

    final progress = StreamController<SyncProgress>(
      onCancel: () => DebugLogger.debug('AutoSyncNotifier', 'startManualSync',
          'Se dejó de escuchar el avance; la sincronización continúa'),
    );
    unawaited(() async {
      try {
        await for (final step in _executeSyncWithStateStream()) {
          progress.add(step); // si ya no escuchan, se descarta
        }
        _refreshFormData();
      } catch (e, st) {
        progress.addError(e, st);
      } finally {
        await progress.close();
      }
    }());
    return progress.stream;
  }

  /// Execute sync and manage global state (for auto-sync without progress updates)
  Future<void> _executeSyncWithState({
    required bool isAutoSync,
    bool notifyStartAndFailure = true,
  }) async {
    // Set syncing state (blocks other syncs)
    state = true;

    DebugLogger.info('AutoSyncNotifier', '_executeSyncWithState',
        '🔒 Global sync state locked - ${isAutoSync ? "AUTO" : "MANUAL"} sync starting');

    // Emit started event (only for auto-sync)
    if (isAutoSync && notifyStartAndFailure) {
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
      if (isAutoSync && notifyStartAndFailure) {
        _eventController.add(AutoSyncEvent(
          type: AutoSyncEventType.failed,
          errorMessage: looksLikeNetworkError(e)
              ? 'Aún no hay conexión estable con el servidor. '
                  'Se volverá a intentar automáticamente.'
              : userErrorMessage(e, action: 'No se pudieron subir algunos datos'),
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
    _scheduledSync?.cancel();
    _lifecycleListener.dispose();
    _eventController.close();
    DebugLogger.debug('AutoSyncNotifier', 'dispose', 'Event controller closed');
    super.dispose();
  }
}
