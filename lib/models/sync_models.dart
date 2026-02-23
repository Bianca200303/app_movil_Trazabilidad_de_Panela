/// Progress model for sync operations
///
/// Used to track sync progress in real-time and update UI.
class SyncProgress {
  /// Module being synced (e.g., "Productores", "Parcelas")
  final String module;

  /// Current number of synced items
  final int current;

  /// Total number of items to sync
  final int total;

  SyncProgress({
    required this.module,
    required this.current,
    required this.total,
  });

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress => total > 0 ? current / total : 0.0;

  /// Calculate progress percentage (0 to 100)
  int get progressPercent => (progress * 100).round();

  /// Check if sync is complete
  bool get isComplete => current >= total;

  @override
  String toString() =>
      'SyncProgress(module: $module, current: $current, total: $total, progress: $progressPercent%)';
}

/// Result model for sync operations
///
/// Contains final statistics after sync completes.
class SyncResult {
  /// Total items successfully synced
  final int synced;

  /// Total items that failed to sync
  final int failed;

  /// Total items processed
  final int total;

  /// Errors encountered during sync
  final List<String> errors;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.total,
    this.errors = const [],
  });

  /// Check if sync was completely successful
  bool get isSuccess => failed == 0 && synced == total;

  /// Check if sync had any failures
  bool get hasFailures => failed > 0;

  @override
  String toString() =>
      'SyncResult(synced: $synced, failed: $failed, total: $total, success: $isSuccess)';
}
