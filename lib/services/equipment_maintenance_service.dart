import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/equipment_maintenance_record.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:panela_sys/core/app_config.dart';

/// Service for managing equipment maintenance records
/// Handles CRUD operations for hornilla, maquinaria y equipos maintenance
class EquipmentMaintenanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // CREATE: Insert new equipment maintenance record
  // ============================================================================

  /// Create a new equipment maintenance record
  ///
  /// Note: created_by is auto-populated by database trigger
  ///
  /// Throws Exception if:
  /// - Network error occurs
  /// - Database constraint violation (check constraints, foreign keys)
  /// - User is not authenticated
  Future<EquipmentMaintenanceRecord> createRecord(
    CreateEquipmentMaintenanceRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('equipment_maintenance_records')
          .insert(request.toJson())
          .select('*, module:coop_modules(name)')
          .single();

      return EquipmentMaintenanceRecord.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle specific database errors
      if (e.code == '23514') {
        // Check constraint violation
        throw Exception(
          'Datos inválidos: Verifica que la duración sea mayor a 0 y el tipo de mantenimiento sea válido',
        );
      }
      if (e.code == '23503') {
        // Foreign key violation
        throw Exception(
          'Módulo inválido o no pertenece a la cooperativa',
        );
      }
      throw Exception('Error al crear registro de mantenimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error al crear registro de mantenimiento: $e');
    }
  }

  // ============================================================================
  // READ: Query equipment maintenance records
  // ============================================================================

  /// Get equipment maintenance records with optional filters
  ///
  /// Parameters:
  /// - [moduleId]: Filter by specific module
  /// - [fromDate]: Filter records from this date onwards (inclusive)
  /// - [toDate]: Filter records up to this date (inclusive)
  /// - [maintenanceType]: Filter by maintenance type (P or C)
  /// - [equipmentName]: Filter by equipment name (case-insensitive contains)
  ///
  /// Returns records ordered by date (most recent first)
  Future<List<EquipmentMaintenanceRecord>> getRecords({
    String? moduleId,
    DateTime? fromDate,
    DateTime? toDate,
    MaintenanceType? maintenanceType,
    String? equipmentName,
  }) async {
    try {
      var query = _supabase
          .from('equipment_maintenance_records')
          .select('*, module:coop_modules(name)')
          .eq('cooperative_id', AppConfig.current.id);

      // Apply filters
      if (moduleId != null) {
        query = query.eq('coop_module_id', moduleId);
      }

      if (fromDate != null) {
        final dateStr = fromDate.toIso8601String().split('T')[0];
        query = query.gte('maintenance_date', dateStr);
      }

      if (toDate != null) {
        final dateStr = toDate.toIso8601String().split('T')[0];
        query = query.lte('maintenance_date', dateStr);
      }

      if (maintenanceType != null) {
        query = query.eq('maintenance_type', maintenanceType.code);
      }

      if (equipmentName != null && equipmentName.trim().isNotEmpty) {
        query = query.ilike('equipment_name', '%${equipmentName.trim()}%');
      }

      // Order by date descending (most recent first)
      final response = await query.order('maintenance_date', ascending: false);

      return (response as List)
          .map((json) => EquipmentMaintenanceRecord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener registros de mantenimiento: $e');
    }
  }

  /// Get a single equipment maintenance record by ID
  ///
  /// Returns null if not found or doesn't belong to current cooperative
  Future<EquipmentMaintenanceRecord?> getRecordById(String id) async {
    try {
      final response = await _supabase
          .from('equipment_maintenance_records')
          .select('*, module:coop_modules(name)')
          .eq('id', id)
          .eq('cooperative_id', AppConfig.current.id)
          .maybeSingle();

      if (response == null) return null;

      return EquipmentMaintenanceRecord.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener registro de mantenimiento: $e');
    }
  }

  /// Get recent equipment maintenance records (last 30 days by default)
  ///
  /// Useful for quick dashboard/summary views
  Future<List<EquipmentMaintenanceRecord>> getRecentRecords({
    int days = 30,
  }) async {
    final fromDate = DateTime.now().subtract(Duration(days: days));
    return getRecords(fromDate: fromDate);
  }

  /// Get equipment maintenance records for a specific date
  Future<List<EquipmentMaintenanceRecord>> getRecordsForDate(
    DateTime date,
  ) async {
    return getRecords(fromDate: date, toDate: date);
  }

  // ============================================================================
  // UPDATE: Modify existing equipment maintenance record
  // ============================================================================

  /// Update an existing equipment maintenance record
  ///
  /// Only updates fields that are non-null in the request
  ///
  /// Throws Exception if:
  /// - Record not found
  /// - Record doesn't belong to current cooperative
  /// - Database constraint violation
  Future<EquipmentMaintenanceRecord> updateRecord(
    UpdateEquipmentMaintenanceRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('equipment_maintenance_records')
          .update(request.toJson())
          .eq('id', request.id)
          .eq('cooperative_id', AppConfig.current.id)
          .select('*, module:coop_modules(name)')
          .single();

      return EquipmentMaintenanceRecord.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle specific database errors
      if (e.code == '23514') {
        // Check constraint violation
        throw Exception(
          'Datos inválidos: Verifica que la duración sea mayor a 0 y el tipo de mantenimiento sea válido',
        );
      }
      if (e.code == '23503') {
        // Foreign key violation
        throw Exception(
          'Módulo inválido o no pertenece a la cooperativa',
        );
      }
      if (e.code == 'PGRST116') {
        // No rows returned (not found or wrong cooperative)
        throw Exception(
          'Registro no encontrado o no pertenece a la cooperativa',
        );
      }
      throw Exception(
        'Error al actualizar registro de mantenimiento: ${e.message}',
      );
    } catch (e) {
      throw Exception('Error al actualizar registro de mantenimiento: $e');
    }
  }

  // ============================================================================
  // DELETE: Remove equipment maintenance record
  // ============================================================================

  /// Delete an equipment maintenance record
  ///
  /// Throws Exception if:
  /// - Record not found
  /// - Record doesn't belong to current cooperative
  Future<void> deleteRecord(String id) async {
    try {
      await _supabase
          .from('equipment_maintenance_records')
          .delete()
          .eq('id', id)
          .eq('cooperative_id', AppConfig.current.id);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception(
          'Registro no encontrado o no pertenece a la cooperativa',
        );
      }
      throw Exception('Error al eliminar registro de mantenimiento: ${e.message}');
    } catch (e) {
      throw Exception('Error al eliminar registro de mantenimiento: $e');
    }
  }

  // ============================================================================
  // STATISTICS: Aggregate data and analytics
  // ============================================================================

  /// Get maintenance statistics for a date range
  ///
  /// Returns:
  /// - total: Total number of maintenance records
  /// - preventive: Number of preventive maintenance records
  /// - corrective: Number of corrective maintenance records
  /// - totalHours: Total duration in hours
  /// - avgDuration: Average duration per maintenance
  Future<Map<String, dynamic>> getStatistics({
    required DateTime fromDate,
    required DateTime toDate,
    String? moduleId,
  }) async {
    try {
      final records = await getRecords(
        fromDate: fromDate,
        toDate: toDate,
        moduleId: moduleId,
      );

      if (records.isEmpty) {
        return {
          'total': 0,
          'preventive': 0,
          'corrective': 0,
          'totalHours': 0.0,
          'avgDuration': 0.0,
        };
      }

      final preventiveCount = records
          .where((r) => r.maintenanceType == MaintenanceType.preventive)
          .length;

      final correctiveCount = records
          .where((r) => r.maintenanceType == MaintenanceType.corrective)
          .length;

      final totalHours =
          records.fold(0.0, (sum, r) => sum + r.durationHours);

      return {
        'total': records.length,
        'preventive': preventiveCount,
        'corrective': correctiveCount,
        'totalHours': totalHours,
        'avgDuration': totalHours / records.length,
      };
    } catch (e) {
      throw Exception('Error al calcular estadísticas: $e');
    }
  }

  /// Get maintenance count by equipment name
  ///
  /// Useful for identifying equipment that requires frequent maintenance
  Future<Map<String, int>> getMaintenanceCountByEquipment({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final records = await getRecords(
        fromDate: fromDate,
        toDate: toDate,
      );

      final Map<String, int> counts = {};

      for (final record in records) {
        counts[record.equipmentName] =
            (counts[record.equipmentName] ?? 0) + 1;
      }

      // Sort by count descending
      final sortedEntries = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries);
    } catch (e) {
      throw Exception(
        'Error al obtener conteo de mantenimientos por equipo: $e',
      );
    }
  }

  /// Get total maintenance duration by equipment
  ///
  /// Useful for identifying equipment that requires most maintenance time
  Future<Map<String, double>> getTotalDurationByEquipment({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final records = await getRecords(
        fromDate: fromDate,
        toDate: toDate,
      );

      final Map<String, double> durations = {};

      for (final record in records) {
        durations[record.equipmentName] =
            (durations[record.equipmentName] ?? 0.0) + record.durationHours;
      }

      // Sort by duration descending
      final sortedEntries = durations.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries);
    } catch (e) {
      throw Exception(
        'Error al obtener duración total por equipo: $e',
      );
    }
  }

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
            .from('equipment_maintenance_records')
            .select('maintenance_date')
            .eq('coop_module_id', moduleId)
            .gte('maintenance_date', fromStr)
            .lte('maintenance_date', toStr),
      ]);
      final batchesByDate = <String, ({int count, double panela})>{};
      for (final b in results[0] as List) {
        final d = b['process_date'] as String;
        final p = (b['panela_kg'] as num?)?.toDouble() ?? 0.0;
        final c = batchesByDate[d];
        batchesByDate[d] = c == null ? (count: 1, panela: p) : (count: c.count + 1, panela: c.panela + p);
      }
      final recorded = <String>{for (final r in results[1] as List) r['maintenance_date'] as String};
      return (batchesByDate.entries.map((e) => ProductionDateGroup(
        date: DateTime.parse(e.key),
        batchCount: e.value.count,
        totalPanelaKg: e.value.panela,
        alreadyRecorded: recorded.contains(e.key),
      )).toList()..sort((a, b) => b.date.compareTo(a.date)));
    } catch (e) {
      throw Exception('Error al cargar fechas de producción: $e');
    }
  }
}
