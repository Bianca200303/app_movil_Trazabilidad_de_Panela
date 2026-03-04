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
          .select()
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
          .select()
          .eq('cooperative_id', cooperativeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WorkerControl.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener controles: $e');
    }
  }

  // Get single worker control by ID
  Future<WorkerControl> getWorkerControlById(String id) async {
    try {
      final response = await _supabase
          .from('worker_controls')
          .select()
          .eq('id', id)
          .single();

      return WorkerControl.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener control: $e');
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
