import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/services/sync/pending_submissions_service.dart';
import 'package:panela_sys/services/sync/submissions/submission_kinds.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerControlService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PendingSubmissionsService _pending;

  WorkerControlService({PendingSubmissionsService? pending})
      : _pending = pending ?? PendingSubmissionsService();

  /// Registra un control nuevo, con o sin señal.
  ///
  /// Siempre se guarda primero en el celular y, si hay señal, se envía en el
  /// momento ([SubmissionOutcome.sent]); si no, queda pendiente y se envía
  /// solo al volver la señal ([SubmissionOutcome.queued]). Si el lote fue
  /// creado sin señal en este celular ([productionBatchLocalId]), el control
  /// espera a que ese lote se envíe primero.
  ///
  /// Si el servidor rechaza el registro en el momento, lanza el error (y el
  /// registro no queda pendiente).
  Future<SubmissionOutcome> submitNewControl({
    String? productionBatchId,
    int? productionBatchLocalId,
    required WorkArea workArea,
    String? observations,
    required List<WorkerEvaluation> workers,
  }) async {
    if ((productionBatchId == null) == (productionBatchLocalId == null)) {
      throw ArgumentError('Se requiere el lote del servidor o el lote local, uno de los dos');
    }
    if (workers.isEmpty) {
      throw ArgumentError('El control debe tener al menos un trabajador');
    }

    return _pending.submit(
      kind: SubmissionKinds.workerControl,
      productionBatchLocalId: productionBatchLocalId,
      payload: {
        'cooperative_id': AppConfig.current.id,
        'production_batch_id': productionBatchId,
        'work_area': workArea.code,
        'observations': observations,
        'items': workers.map((w) => w.toItemJson()).toList(),
      },
    );
  }

  // Get worker controls by production batch
  Future<List<WorkerControl>> getWorkerControlsByBatch(
    String productionBatchId,
    String cooperativeId,
  ) async {
    try {
      final response = await _supabase
          .from('worker_controls')
          .select('*, worker_control_items(*)')
          .eq('production_batch_id', productionBatchId)
          .eq('cooperative_id', cooperativeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WorkerControl.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener controles: $e');
    }
  }

  // Get all worker controls for a cooperative
  Future<List<WorkerControl>> getWorkerControlsByCoop(
    String cooperativeId,
  ) async {
    try {
      final response = await _supabase
          .from('worker_controls')
          .select('*, worker_control_items(*)')
          .eq('cooperative_id', cooperativeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WorkerControl.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener controles: $e');
    }
  }

  // Get worker controls for historial with producer DNI (for module filtering)
  Future<List<Map<String, dynamic>>> getWorkerControlsForHistorial(
    String cooperativeId,
  ) async {
    return getWorkerControlsForHistorialByRange(
      cooperativeId,
      DateTime(DateTime.now().year, DateTime.now().month, 1),
      DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> getWorkerControlsForHistorialByRange(
    String cooperativeId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final response = await _supabase
          .from('worker_controls')
          .select('*, worker_control_items(*), production_batches!inner(process_date, panela_kg, confitillo_kg, producers!inner(first_name, last_name, dni, coop_modules(name))), registered_by_user:users!worker_controls_created_by_fkey(first_name, last_name)')
          .eq('cooperative_id', cooperativeId)
          // Por la fecha de producción del lote (la que muestra la tarjeta y
          // usa la web), no por created_at: un control registrado sin señal
          // recibe created_at recién al subirse, días después.
          .gte('production_batches.process_date', from.toIso8601String().split('T')[0])
          .lte('production_batches.process_date', to.toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      final rows = (response as List).cast<Map<String, dynamic>>()
        ..sort((a, b) {
          final da = (a['production_batches'] as Map?)?['process_date'] as String? ?? '';
          final db = (b['production_batches'] as Map?)?['process_date'] as String? ?? '';
          return db.compareTo(da); // más reciente primero
        });

      return rows.map((json) {
        final batch = json['production_batches'] as Map<String, dynamic>?;
        final producer = batch?['producers'] as Map<String, dynamic>?;
        final regUser = json['registered_by_user'] as Map<String, dynamic>?;
        final control = WorkerControl.fromJson(json);
        return {
          'control': control,
          'producer_dni': producer?['dni'] as String?,
          'producer_name': producer != null
              ? '${producer['first_name']} ${producer['last_name']}'
              : null,
          'module_name': (producer?['coop_modules'] as Map?)?['name'] as String?,
          'process_date': batch?['process_date'] as String?,
          'panela_kg': batch?['panela_kg'],
          'confitillo_kg': batch?['confitillo_kg'],
          'registered_by': regUser != null ? '${regUser['first_name']} ${regUser['last_name']}' : null,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener controles: $e');
    }
  }

  // Get single worker control by ID
  Future<WorkerControl> getWorkerControlById(String id) async {
    try {
      final response = await _supabase
          .from('worker_controls')
          .select('*, worker_control_items(*)')
          .eq('id', id)
          .single();

      return WorkerControl.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener control: $e');
    }
  }

  /// Returns existing controls grouped by batch_id for the given batch IDs.
  Future<Map<String, List<WorkerControl>>> getControlsByBatchIds(
    String cooperativeId,
    List<String> batchIds,
  ) async {
    if (batchIds.isEmpty) return {};
    try {
      final response = await _supabase
          .from('worker_controls')
          .select('*, worker_control_items(*)')
          .eq('cooperative_id', cooperativeId)
          .filter('production_batch_id', 'in', '(${batchIds.join(',')})');
      final result = <String, List<WorkerControl>>{};
      for (final json in response as List) {
        final control = WorkerControl.fromJson(json as Map<String, dynamic>);
        result.putIfAbsent(control.productionBatchId, () => []).add(control);
      }
      return result;
    } catch (e) {
      throw Exception('Error al obtener controles por lotes: $e');
    }
  }

  /// Updates header + replaces all worker_control_items for an existing record.
  Future<void> updateWorkerControlFull(
    String id,
    CreateWorkerControlRequest request,
  ) async {
    try {
      final headerData = request.toHeaderJson();
      headerData['worker_name'] =
          'Registro Grupal (${request.workers.length} operarios)';
      await _supabase.from('worker_controls').update(headerData).eq('id', id);
      await _supabase
          .from('worker_control_items')
          .delete()
          .eq('worker_control_id', id);
      if (request.workers.isNotEmpty) {
        await _supabase
            .from('worker_control_items')
            .insert(request.workers.map((w) => w.toJson(id)).toList());
      }
    } catch (e) {
      throw Exception('Error al actualizar control: $e');
    }
  }

  // Update worker control record
  Future<WorkerControl> updateWorkerControl(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('worker_controls')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return WorkerControl.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar control: $e');
    }
  }

  // Delete worker control record
  Future<void> deleteWorkerControl(String id) async {
    try {
      await _supabase.from('worker_controls').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar control: $e');
    }
  }
}
