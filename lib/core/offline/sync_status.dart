/// Synchronization status for offline entities
///
/// Tracks the sync state of local database records with the remote server.
enum SyncStatus {
  /// Entity is pending synchronization with remote server
  pending(0),

  /// Entity is synchronized with remote server
  synced(1),

  /// Entity has been modified locally after being synced
  modified(2);

  /// Integer value for database storage
  final int value;

  const SyncStatus(this.value);

  /// Convert integer value to SyncStatus enum
  ///
  /// Throws [ArgumentError] if value is not valid
  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid SyncStatus value: $value'),
    );
  }

  /// Check if entity needs synchronization
  bool get needsSync => this == SyncStatus.pending || this == SyncStatus.modified;

  /// Check if entity is synchronized
  bool get isSynced => this == SyncStatus.synced;
}
