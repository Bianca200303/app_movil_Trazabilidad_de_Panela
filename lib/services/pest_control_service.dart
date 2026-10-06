// =====================================================
// Pest Control Service
// =====================================================

import 'package:panela_sys/models/pest_control.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Service for managing pest control records
class PestControlService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // Create Operations
  // =====================================================

  /// Creates a complete pest control record with batch insert
  ///
  /// This method performs:
  /// 1. Insert parent record (pest_controls)
  /// 2. Insert bait record if provided (pest_control_bait_records)
  /// 3. Insert insect record if provided (pest_control_insect_records)
  ///
  /// Returns the created parent record
  ///
  /// Throws if:
  /// - Neither baitRecord nor insectRecord is provided
  /// - Duplicate record exists for module+date (UNIQUE constraint)
  /// - User doesn't have permission (RLS)
  /// - Database error occurs
  Future<PestControl> createPestControl(
    CreatePestControlRequest request,
  ) async {
    try {
      // Validation: at least one type of control must be provided
      if (request.baitRecord == null && request.insectRecord == null) {
        throw Exception(
          'Debe proporcionar al menos un tipo de control (cebos o insectos)',
        );
      }

      // 1. Insert parent record
      final parentResponse = await _supabase
          .from('pest_controls')
          .insert(request.toParentJson())
          .select()
          .single();

      final parentId = parentResponse['id'] as String;

      // 2. Insert bait record if provided
      if (request.baitRecord != null) {
        final baitJson = request.baitRecord!.toJson();
        baitJson['pest_control_id'] = parentId;
        await _supabase.from('pest_control_bait_records').insert(baitJson);
      }

      // 3. Insert insect record if provided
      if (request.insectRecord != null) {
        final insectJson = request.insectRecord!.toJson();
        insectJson['pest_control_id'] = parentId;
        await _supabase.from('pest_control_insect_records').insert(insectJson);
      }

      // 4. Return created parent record
      return PestControl.fromJson(parentResponse);
    } catch (e) {
      throw Exception('Error al crear registro de control de plagas: $e');
    }
  }

  // =====================================================
  // Read Operations
  // =====================================================

  /// Gets all pest control records for the current user's cooperative
  ///
  /// Returns records ordered by date DESC (most recent first)
  ///
  /// Includes joined data:
  /// - Module name
  Future<List<PestControl>> getPestControls({
    String? moduleId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase.from('pest_controls').select('''
            *,
            module:coop_modules(name)
          ''');

      // Apply filters if provided
      if (moduleId != null) {
        query = query.eq('coop_module_id', moduleId);
      }

      if (fromDate != null) {
        query = query.gte(
          'control_date',
          DateFormat('yyyy-MM-dd').format(fromDate),
        );
      }

      if (toDate != null) {
        query = query.lte(
          'control_date',
          DateFormat('yyyy-MM-dd').format(toDate),
        );
      }

      final response = await query.order('control_date', ascending: false);

      final rows = response as List;

      // pest_controls.created_by no tiene FK a users -- se resuelve con una
      // consulta aparte y se cruza en memoria (igual que en chlorine y
      // cleaning_disinfection).
      final createdByIds = rows.map((j) => j['created_by'] as String?).whereType<String>().toSet();
      Map<String, String> namesByUserId = {};
      if (createdByIds.isNotEmpty) {
        final users = await _supabase
            .from('users')
            .select('user_id, first_name, last_name')
            .inFilter('user_id', createdByIds.toList());
        namesByUserId = {
          for (final u in users) u['user_id'] as String: '${u['first_name']} ${u['last_name']}',
        };
      }

      return rows.map((json) {
        // Extract joined data
        final moduleName =
            json['module'] != null ? json['module']['name'] as String : null;

        // Create PestControl with joined data
        return PestControl.fromJson({
          ...json,
          if (moduleName != null) 'module': {'name': moduleName},
          'registered_by_name': namesByUserId[json['created_by']],
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener registros de control de plagas: $e');
    }
  }

  /// Gets a specific pest control record by ID
  ///
  /// Returns null if not found or user doesn't have permission
  Future<PestControl?> getPestControlById(String id) async {
    try {
      final response = await _supabase
          .from('pest_controls')
          .select('''
            *,
            module:coop_modules(name)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return PestControl.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener registro de control de plagas: $e');
    }
  }

  /// Gets bait records for a specific pest control
  Future<List<PestControlBaitRecord>> getBaitRecordsByControlId(
    String controlId,
  ) async {
    try {
      final response = await _supabase
          .from('pest_control_bait_records')
          .select()
          .eq('pest_control_id', controlId);

      return (response as List)
          .map((json) => PestControlBaitRecord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener registros de cebos: $e');
    }
  }

  /// Gets insect records for a specific pest control
  Future<List<PestControlInsectRecord>> getInsectRecordsByControlId(
    String controlId,
  ) async {
    try {
      final response = await _supabase
          .from('pest_control_insect_records')
          .select()
          .eq('pest_control_id', controlId);

      return (response as List)
          .map((json) => PestControlInsectRecord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener registros de insectos: $e');
    }
  }

  Future<bool> hasControlOnDate(String moduleId, DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _supabase
          .from('pest_controls')
          .select('id')
          .eq('coop_module_id', moduleId)
          .eq('control_date', dateStr)
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

  // =====================================================
  // Statistics Operations
  // =====================================================

  /// Gets pest control statistics for a date range
  ///
  /// Returns aggregated data such as:
  /// - Total pest control sessions
  /// - Total bait stations monitored
  /// - Bait consumption percentage
  /// - Total insects by type
  Future<Map<String, dynamic>> getPestControlStatistics({
    required DateTime fromDate,
    required DateTime toDate,
    String? moduleId,
  }) async {
    try {
      // Get all records in date range
      final records = await getPestControls(
        moduleId: moduleId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Initialize statistics
      int totalBaitStations = 0;
      int totalStationsWithBaitEaten = 0;
      int totalFlies = 0;
      int totalBees = 0;
      int totalAnts = 0;
      int totalCockroaches = 0;
      final areasMonitored = <String>{};

      // Aggregate data from all records
      for (final record in records) {
        // Get bait records
        final baitRecords = await getBaitRecordsByControlId(record.id);
        for (final baitRecord in baitRecords) {
          totalBaitStations += baitRecord.totalStations;
          totalStationsWithBaitEaten += baitRecord.stationsWithBaitEaten;
        }

        // Get insect records
        final insectRecords = await getInsectRecordsByControlId(record.id);
        for (final insectRecord in insectRecords) {
          totalFlies += insectRecord.totalFlies;
          totalBees += insectRecord.totalBees;
          totalAnts += insectRecord.totalAnts;
          totalCockroaches += insectRecord.totalCockroaches;
          areasMonitored.addAll(insectRecord.uniqueAreas);
        }
      }

      // Calculate percentages
      final baitConsumptionPercentage = totalBaitStations > 0
          ? (totalStationsWithBaitEaten / totalBaitStations) * 100
          : 0.0;

      return {
        'total_sessions': records.length,
        'bait_control': {
          'total_stations': totalBaitStations,
          'stations_with_bait_eaten': totalStationsWithBaitEaten,
          'consumption_percentage': baitConsumptionPercentage,
        },
        'insect_control': {
          'total_flies': totalFlies,
          'total_bees': totalBees,
          'total_ants': totalAnts,
          'total_cockroaches': totalCockroaches,
          'total_insects': totalFlies + totalBees + totalAnts + totalCockroaches,
          'areas_monitored': areasMonitored.length,
        },
      };
    } catch (e) {
      throw Exception('Error al calcular estadísticas: $e');
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
            .from('pest_controls')
            .select('control_date')
            .eq('coop_module_id', moduleId)
            .gte('control_date', fromStr)
            .lte('control_date', toStr),
      ]);
      final batchesByDate = <String, ({int count, double panela})>{};
      for (final b in results[0] as List) {
        final d = b['process_date'] as String;
        final p = (b['panela_kg'] as num?)?.toDouble() ?? 0.0;
        final c = batchesByDate[d];
        batchesByDate[d] = c == null ? (count: 1, panela: p) : (count: c.count + 1, panela: c.panela + p);
      }
      final recorded = <String>{for (final r in results[1] as List) r['control_date'] as String};
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
