/// Tipos de registro de la bandeja de pendientes (pending_submissions.kind).
///
/// Constantes compartidas entre el registro de manejadores
/// (submission_registry.dart) y los servicios que encolan. No cambiar un
/// valor existente: puede haber registros guardados en celulares con él.
abstract final class SubmissionKinds {
  static const workerControl = 'worker_control';
  static const environmentInspection = 'environment_inspection';
  static const chlorineControl = 'chlorine_control';
  static const maintenanceRecord = 'maintenance_record';
  static const healthIncident = 'health_incident';
  static const cleaningDisinfection = 'cleaning_disinfection';
  static const pestControl = 'pest_control';
}
