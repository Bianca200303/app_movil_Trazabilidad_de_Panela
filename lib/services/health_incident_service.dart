import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/health_incident.dart';

class HealthIncidentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new health incident
  Future<HealthIncident> createIncident(
    CreateHealthIncidentRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .insert(request.toJson())
          .select()
          .single();

      return HealthIncident.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear el incidente de salud: $e');
    }
  }

  // Get incident by ID
  Future<HealthIncident?> getIncidentById(String id) async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return HealthIncident.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener el incidente de salud: $e');
    }
  }

  // Get all incidents for the user's cooperative
  Future<List<HealthIncident>> getIncidents() async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .select()
          .order('registration_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HealthIncident.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los incidentes de salud: $e');
    }
  }

  // Get incidents by module
  Future<List<HealthIncident>> getIncidentsByModule(String moduleId) async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .select()
          .eq('coop_module_id', moduleId)
          .order('registration_date', ascending: false);

      return (response as List)
          .map((json) => HealthIncident.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener incidentes por módulo: $e');
    }
  }

  // Get incidents by date range
  Future<List<HealthIncident>> getIncidentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .select()
          .gte('registration_date', startDate.toIso8601String().split('T')[0])
          .lte('registration_date', endDate.toIso8601String().split('T')[0])
          .order('registration_date', ascending: false);

      return (response as List)
          .map((json) => HealthIncident.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener incidentes por rango de fecha: $e');
    }
  }

  // Get incidents with module details (for historial display)
  Future<List<Map<String, dynamic>>> getIncidentsWithModuleDetails() async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .select('''
            *,
            coop_module:coop_modules(
              id,
              name
            )
          ''')
          .order('registration_date', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Error al obtener incidentes con detalles de módulo: $e');
    }
  }

  // Delete incident
  Future<void> deleteIncident(String id) async {
    try {
      await _supabase.from('health_incidents').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar el incidente de salud: $e');
    }
  }

  // Get recent incidents (last N days)
  Future<List<HealthIncident>> getRecentIncidents({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      return await getIncidentsByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Error al obtener incidentes recientes: $e');
    }
  }

  // Get incidents by employee name (search)
  Future<List<HealthIncident>> searchIncidentsByEmployee(
      String employeeName) async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .select()
          .ilike('employee_name', '%$employeeName%')
          .order('registration_date', ascending: false);

      return (response as List)
          .map((json) => HealthIncident.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar incidentes por empleado: $e');
    }
  }

  // Get incidents pending return (return_date is null or certificate not presented)
  Future<List<HealthIncident>> getPendingReturnIncidents() async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .select()
          .or('return_date.is.null,certificate_presented.eq.false')
          .order('registration_date', ascending: false);

      return (response as List)
          .map((json) => HealthIncident.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener incidentes pendientes: $e');
    }
  }

  // Update incident (for follow-up information)
  Future<HealthIncident> updateIncident(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('health_incidents')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return HealthIncident.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar el incidente de salud: $e');
    }
  }
}
