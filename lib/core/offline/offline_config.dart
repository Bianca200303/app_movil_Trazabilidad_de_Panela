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
    // Controles vía bandeja de pendientes (pending_submissions):
    workerControl: true,
    chlorineControl: true,
    maintenanceControl: true,
    healthIncidents: true,
    environmentInspection: true,
    cleaningDisinfection: true,
    pestControl: true,
  );
}

/// Feature flags for offline capabilities by module
///
/// Los flags de controles indican que el formulario se puede abrir y guardar
/// sin señal (se envía después vía PendingSubmissionsService). Para sumar
/// uno: SubmissionHandler registrado + flag aquí + botón del menú.
class OfflineFeatures {
  /// Enable offline mode for Producers module
  final bool producers;

  /// Enable offline mode for Production Batches module
  final bool production;

  /// Enable offline mode for Exit Registrations module
  final bool exits;

  /// Control de personal operario
  final bool workerControl;

  /// Control de cloro libre residual
  final bool chlorineControl;

  /// Mantenimiento hornilla/maquinaria/equipos
  final bool maintenanceControl;

  /// Seguimiento de enfermedades y accidentes
  final bool healthIncidents;

  /// Inspección de ambientes, equipo y personal
  final bool environmentInspection;

  /// Limpieza y desinfección
  final bool cleaningDisinfection;

  /// Control de plagas
  final bool pestControl;

  const OfflineFeatures({
    required this.producers,
    required this.production,
    required this.exits,
    required this.workerControl,
    required this.chlorineControl,
    required this.maintenanceControl,
    required this.healthIncidents,
    required this.environmentInspection,
    required this.cleaningDisinfection,
    required this.pestControl,
  });

  List<bool> get _all => [
        producers,
        production,
        exits,
        workerControl,
        chlorineControl,
        maintenanceControl,
        healthIncidents,
        environmentInspection,
        cleaningDisinfection,
        pestControl,
      ];

  /// Check if any offline feature is enabled
  bool get hasAnyEnabled => _all.any((enabled) => enabled);

  /// Get count of enabled features
  int get enabledCount => _all.where((enabled) => enabled).length;
}
