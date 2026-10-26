import 'package:panela_sys/services/sync/submissions/rpc_submission_handler.dart';
import 'package:panela_sys/services/sync/submissions/submission_handler.dart';
import 'package:panela_sys/services/sync/submissions/submission_kinds.dart';
import 'package:panela_sys/services/sync/submissions/table_insert_submission_handler.dart';

/// Manejadores de envío por tipo de registro. Único lugar a tocar para que
/// un control nuevo se pueda guardar sin conexión (ver SubmissionHandler):
///   - una sola tabla → TableInsertSubmissionHandler (sin migración);
///   - cabecera + hijos → RpcSubmissionHandler + RPC idempotente y atómica.
final List<SubmissionHandler> _handlers = [
  RpcSubmissionHandler(
    kind: SubmissionKinds.workerControl,
    label: 'Control de personal operario',
    rpcName: 'submit_worker_control',
    buildParams: (id, p, batchRemoteId) {
      final batchId = batchRemoteId ?? p['production_batch_id'] as String?;
      if (batchId == null) throw StateError('El control no tiene lote asociado');
      return {
        'p_id': id,
        'p_cooperative_id': p['cooperative_id'],
        'p_production_batch_id': batchId,
        'p_work_area': p['work_area'],
        'p_observations': p['observations'],
        'p_items': p['items'],
      };
    },
  ),
  RpcSubmissionHandler(
    kind: SubmissionKinds.environmentInspection,
    label: 'Inspección de ambientes, equipo y personal',
    rpcName: 'submit_environment_inspection',
    buildParams: (id, p, _) => {
      'p_id': id,
      'p_coop_module_id': p['coop_module_id'],
      'p_inspection_date': p['inspection_date'],
      'p_cooperative_id': p['cooperative_id'],
      'p_items': p['items'],
    },
  ),
  RpcSubmissionHandler(
    kind: SubmissionKinds.cleaningDisinfection,
    label: 'Limpieza y desinfección',
    rpcName: 'submit_cleaning_disinfection',
    buildParams: (id, p, _) => {
      'p_id': id,
      'p_cooperative_id': p['cooperative_id'],
      'p_coop_module_id': p['coop_module_id'],
      'p_cleaning_date': p['cleaning_date'],
      'p_cleaning_types': p['cleaning_types'],
      'p_general_observations': p['general_observations'],
      'p_items': p['items'],
    },
  ),
  RpcSubmissionHandler(
    kind: SubmissionKinds.pestControl,
    label: 'Control de plagas',
    rpcName: 'submit_pest_control',
    buildParams: (id, p, _) => {
      'p_id': id,
      'p_cooperative_id': p['cooperative_id'],
      'p_coop_module_id': p['coop_module_id'],
      'p_control_date': p['control_date'],
      'p_bait_record': p['bait_record'],
      'p_insect_record': p['insect_record'],
    },
  ),
  const TableInsertSubmissionHandler(
    kind: SubmissionKinds.chlorineControl,
    label: 'Control de cloro libre residual',
    table: 'chlorine_residual_controls',
  ),
  const TableInsertSubmissionHandler(
    kind: SubmissionKinds.maintenanceRecord,
    label: 'Mantenimiento hornilla/maquinaria/equipos',
    table: 'equipment_maintenance_records',
  ),
  const TableInsertSubmissionHandler(
    kind: SubmissionKinds.healthIncident,
    label: 'Seguimiento de enfermedades y accidentes',
    table: 'health_incidents',
  ),
];

final Map<String, SubmissionHandler> submissionHandlers = {
  for (final handler in _handlers) handler.kind: handler,
};
