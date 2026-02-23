/// Event types for automatic synchronization notifications
enum AutoSyncEventType {
  /// Auto-sync started (offline → online transition detected)
  started,

  /// Auto-sync completed successfully
  completed,

  /// Auto-sync failed with error
  failed,
}

/// Event emitted by AutoSyncNotifier to notify UI of sync status
///
/// These events are used to show SnackBars to the user during
/// automatic synchronization (not manual sync).
class AutoSyncEvent {
  final AutoSyncEventType type;
  final String? errorMessage;

  const AutoSyncEvent({
    required this.type,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'AutoSyncEvent(type: $type, errorMessage: $errorMessage)';
  }
}
