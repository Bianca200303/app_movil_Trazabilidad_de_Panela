import 'package:panela_sys/models/worker_control.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerControlService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<WorkerControl> createWorkerControl(
    CreateWorkerControlRequest request,
  ) async {
    try {
      // 1. PREPARAR LA CABECERA
      final headerData = request.toHeaderJson();
      
      // TRUCO DE COMPATIBILIDAD: Como tu tabla original 'worker_controls' 
      // probablemente exige que la columna 'worker_name' no esté vacía (NOT NULL),
      // le ponemos un texto genérico. Así no rompemos tu historial.
      headerData['worker_name'] = 'Registro Grupal (${request.workers.length} operarios)';

      // 2. INSERTAR CABECERA
      final headerResponse = await _supabase
          .from('worker_controls')
          .insert(headerData)
          .select()
          .single();

      final headerId = headerResponse['id'];

      // 3. INSERTAR DETALLES (Los trabajadores)
      if (request.workers.isNotEmpty) {
        // Convertimos la lista de objetos WorkerEvaluation a una lista de JSONs
        final itemsData = request.workers
            .map((worker) => worker.toJson(headerId))
            .toList();

        // Supabase permite insertar una lista completa de golpe (Bulk Insert)
        await _supabase.from('worker_control_items').insert(itemsData);
      }

      // 4. RETORNAR RESULTADO
      // Devolvemos la cabecera para que la app no se queje y siga su flujo normal
      return WorkerControl.fromJson(headerResponse);
      
    } catch (e) {
      throw Exception('Error al crear control de trabajadores: $e');
    }
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
          .select('*, worker_control_items(*), production_batches!inner(process_date, panela_kg, confitillo_kg, producers!inner(first_name, last_name, dni, coop_modules(name)))')
          .eq('cooperative_id', cooperativeId)
          .gte('created_at', from.toIso8601String().split('T')[0])
          .lte('created_at', '${to.toIso8601String().split('T')[0]}T23:59:59')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final batch = json['production_batches'] as Map<String, dynamic>?;
        final producer = batch?['producers'] as Map<String, dynamic>?;
        final control = WorkerControl.fromJson(json as Map<String, dynamic>);
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
