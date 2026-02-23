import 'package:panela_sys/models/worker_control.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkerControlService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create new worker control record
  Future<WorkerControl> createWorkerControl(
    CreateWorkerControlRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('worker_controls')
          .insert(request.toJson())
          .select()
          .single();

      return WorkerControl.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear control de trabajador: $e');
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
