import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/models/production_date_group.dart';

class EnvironmentInspectionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create inspection with all items atomically via RPC (un solo insert falla
  // o aplica todo junto; ver migración create_environment_inspection_rpc).
  Future<EnvironmentInspection> createInspection(
    CreateEnvironmentInspectionRequest request,
  ) async {
    try {
      final inspectionDate = request.inspectionDate ?? DateTime.now();
      final inspectionId = await _supabase.rpc(
        'create_environment_inspection',
        params: {
          'p_coop_module_id': request.coopModuleId,
          'p_inspection_date': inspectionDate.toIso8601String().split('T')[0],
          'p_cooperative_id': request.cooperativeId,
          'p_items': request.items.map((item) => item.toJson()).toList(),
        },
      ) as String;

      final created = await getInspectionById(inspectionId);
      if (created == null) {
        throw Exception('La inspección se creó pero no se pudo recuperar');
      }
      return created;
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
  Future<List<Map<String, dynamic>>> getInspectionsWithModuleDetails({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('environment_inspections')
          .select('''
            *,
            coop_module:coop_modules(
              id,
              name
            ),
            environment_inspection_items(*),
            registered_by_user:users!environment_inspections_created_by_fkey(first_name, last_name)
          ''');

      if (fromDate != null) {
        query = query.gte('inspection_date', fromDate.toIso8601String().split('T')[0]);
      }
      if (toDate != null) {
        query = query.lte('inspection_date', toDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('inspection_date', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception(
          'Error al obtener inspecciones con detalles de módulo: $e');
    }
  }

  Future<bool> hasInspectionOnDate(String moduleId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('environment_inspections')
          .select('id')
          .eq('coop_module_id', moduleId)
          .eq('inspection_date', dateStr)
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasProductionOnDate(String moduleId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('production_batches')
          .select('id, producers!inner(coop_module_id)')
          .eq('producers.coop_module_id', moduleId)
          .eq('process_date', dateStr)
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Production dates with batch summary for a module in a date range.
  // Also marks which dates already have an inspection.
  Future<List<ProductionDateGroup>> getProductionDateGroups(
    String moduleId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final fromStr = from.toIso8601String().split('T')[0];
      final toStr = to.toIso8601String().split('T')[0];

      final results = await Future.wait([
        _supabase
            .from('production_batches')
            .select('process_date, panela_kg, producers!inner(coop_module_id)')
            .eq('producers.coop_module_id', moduleId)
            .gte('process_date', fromStr)
            .lte('process_date', toStr),
        _supabase
            .from('environment_inspections')
            .select('inspection_date')
            .eq('coop_module_id', moduleId)
            .gte('inspection_date', fromStr)
            .lte('inspection_date', toStr),
      ]);

      final batchesByDate = <String, ({int count, double panela})>{};
      for (final batch in results[0] as List) {
        final dateStr = batch['process_date'] as String;
        final panela = (batch['panela_kg'] as num?)?.toDouble() ?? 0.0;
        final current = batchesByDate[dateStr];
        batchesByDate[dateStr] = current == null
            ? (count: 1, panela: panela)
            : (count: current.count + 1, panela: current.panela + panela);
      }

      final inspectedDates = <String>{
        for (final i in results[1] as List) i['inspection_date'] as String,
      };

      return (batchesByDate.entries.map((e) => ProductionDateGroup(
        date: DateTime.parse(e.key),
        batchCount: e.value.count,
        totalPanelaKg: e.value.panela,
        alreadyRecorded: inspectedDates.contains(e.key),
      )).toList()
        ..sort((a, b) => b.date.compareTo(a.date)));
    } catch (e) {
      throw Exception('Error al cargar fechas de producción: $e');
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
