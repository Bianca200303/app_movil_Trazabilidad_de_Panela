/// Feature flags for offline functionality
///
/// This configuration controls which modules have offline capabilities enabled.
/// Set to `true` to enable offline functionality for a specific module.
class OfflineConfig {
  static const OfflineConfig instance = OfflineConfig._();
  const OfflineConfig._();

  /// Feature flags for each module
  final OfflineFeatures features = const OfflineFeatures(
    producers: true, // ✅ ENABLED - Phase 2 complete
    production: true, // ✅ ENABLED - Phase 3 complete (Phases 7-8 finished)
    exits: false, // Enable in Phase 4
  );
}

/// Feature flags for offline capabilities by module
class OfflineFeatures {
  /// Enable offline mode for Producers module
  final bool producers;

  /// Enable offline mode for Production Batches module
  final bool production;

  /// Enable offline mode for Exit Registrations module
  final bool exits;

  const OfflineFeatures({
    required this.producers,
    required this.production,
    required this.exits,
  });

  /// Check if any offline feature is enabled
  bool get hasAnyEnabled => producers || production || exits;

  /// Get count of enabled features
  int get enabledCount =>
      (producers ? 1 : 0) + (production ? 1 : 0) + (exits ? 1 : 0);
}
