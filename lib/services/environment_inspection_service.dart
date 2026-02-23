import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/environment_inspection.dart';

class EnvironmentInspectionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create inspection with all items in a single transaction-like operation
  Future<EnvironmentInspection> createInspection(
    CreateEnvironmentInspectionRequest request,
  ) async {
    try {
      // Use Supabase transaction-like approach:
      // 1. Insert parent
      // 2. Insert all children
      // 3. Query back with joined data

      // Insert parent inspection
      final parentResponse = await _supabase
          .from('environment_inspections')
          .insert(request.toJson())
          .select()
          .single();

      final inspectionId = parentResponse['id'] as String;

      // Insert all items
      if (request.items.isNotEmpty) {
        final itemsData = request.items.map((item) {
          final json = item.toJson();
          json['environment_inspection_id'] = inspectionId;
          return json;
        }).toList();

        await _supabase.from('environment_inspection_items').insert(itemsData);
      }

      // Fetch complete inspection with items
      return await getInspectionById(inspectionId) ??
          EnvironmentInspection.fromJson(parentResponse);
    } catch (e) {
      throw Exception('Error al crear la inspección de ambiente: $e');
    }
  }

  // Get inspection by ID with all items
  Future<EnvironmentInspection?> getInspectionById(String id) async {
    try {
      final response = await _supabase
          .from('environment_inspections')
          .select('''
            *,
            environment_inspection_items(*)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return EnvironmentInspection.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener la inspección de ambiente: $e');
    }
  }

  // Get all inspections for the user's cooperative
  Future<List<EnvironmentInspection>> getInspections() async {
    try {
      final response = await _supabase
          .from('environment_inspections')
          .select('''
            *,
            environment_inspection_items(*)
          ''')
          .order('inspection_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EnvironmentInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las inspecciones de ambiente: $e');
    }
  }

  // Get inspections by module
  Future<List<EnvironmentInspection>> getInspectionsByModule(
    String moduleId,
  ) async {
    try {
      final response = await _supabase
          .from('environment_inspections')
          .select('''
            *,
            environment_inspection_items(*)
          ''')
          .eq('coop_module_id', moduleId)
          .order('inspection_date', ascending: false);

      return (response as List)
          .map((json) => EnvironmentInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Error al obtener inspecciones por módulo: $e');
    }
  }

  // Get inspections by date range
  Future<List<EnvironmentInspection>> getInspectionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('environment_inspections')
          .select('''
            *,
            environment_inspection_items(*)
          ''')
          .gte('inspection_date', startDate.toIso8601String().split('T')[0])
          .lte('inspection_date', endDate.toIso8601String().split('T')[0])
          .order('inspection_date', ascending: false);

      return (response as List)
          .map((json) => EnvironmentInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
          'Error al obtener inspecciones por rango de fecha: $e');
    }
  }

  // Get inspections with module details (for historial display)
  Future<List<Map<String, dynamic>>> getInspectionsWithModuleDetails() async {
    try {
      final response = await _supabase
          .from('environment_inspections')
          .select('''
            *,
            coop_module:coop_modules(
              id,
              name
            ),
            environment_inspection_items(*)
          ''')
          .order('inspection_date', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Error al obtener inspecciones con detalles de módulo: $e');
    }
  }

  // Delete inspection (cascade deletes items)
  Future<void> deleteInspection(String id) async {
    try {
      await _supabase.from('environment_inspections').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar la inspección de ambiente: $e');
    }
  }

  // Get compliance statistics for a date range
  Future<Map<String, dynamic>> getComplianceStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final inspections = await getInspectionsByDateRange(startDate, endDate);

      int totalInspections = inspections.length;
      int fullyCompliantCount =
          inspections.where((i) => i.isFullyCompliant).length;
      int totalItems = inspections.fold(0, (sum, i) => sum + i.totalItems);
      int compliantItems =
          inspections.fold(0, (sum, i) => sum + i.compliantItems);

      return {
        'total_inspections': totalInspections,
        'fully_compliant_count': fullyCompliantCount,
        'total_items_checked': totalItems,
        'compliant_items': compliantItems,
        'overall_compliance_percentage':
            totalItems > 0 ? (compliantItems / totalItems) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Error al calcular estadísticas de cumplimiento: $e');
    }
  }

  // Get recent inspections (last N days)
  Future<List<EnvironmentInspection>> getRecentInspections(
      {int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      return await getInspectionsByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Error al obtener inspecciones recientes: $e');
    }
  }

  // Get non-compliant inspections in date range
  Future<List<EnvironmentInspection>> getNonCompliantInspections(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allInspections =
          await getInspectionsByDateRange(startDate, endDate);
      return allInspections.where((i) => !i.isFullyCompliant).toList();
    } catch (e) {
      throw Exception(
          'Error al obtener inspecciones no conformes: $e');
    }
  }

  // Get fully compliant inspections in date range
  Future<List<EnvironmentInspection>> getCompliantInspections(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allInspections =
          await getInspectionsByDateRange(startDate, endDate);
      return allInspections.where((i) => i.isFullyCompliant).toList();
    } catch (e) {
      throw Exception('Error al obtener inspecciones conformes: $e');
    }
  }
}
