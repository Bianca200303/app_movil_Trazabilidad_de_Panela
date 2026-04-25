// =====================================================
// Chlorine Residual Control Service
// =====================================================

import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/models/chlorine_residual_control.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing chlorine residual control records
class ChlorineResidualControlService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // Create Operations
  // =====================================================

  /// Creates a new chlorine residual control record
  ///
  /// Throws:
  /// - Exception if duplicate record exists (UNIQUE constraint on module+date+time)
  /// - Exception if user doesn't have permission (RLS)
  /// - Exception if measurements are outside valid range (CHECK constraint)
  Future<ChlorineResidualControl> createControl(
    CreateChlorineResidualControlRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('chlorine_residual_controls')
          .insert(request.toJson())
          .select('''
            *,
            module:coop_modules(name)
          ''').single();

      // Extract joined data
      final moduleName =
          response['module'] != null ? response['module']['name'] as String : null;

      return ChlorineResidualControl.fromJson({
        ...response,
        'module_name': moduleName,
      });
    } on PostgrestException catch (e) {
      // Handle unique constraint violation
      if (e.code == '23505') {
        throw Exception(
            'Ya existe un control para este módulo en esta fecha y hora');
      }
      // Handle check constraint violation
      if (e.code == '23514') {
        throw Exception(
            'Las mediciones deben estar entre 0 y 10 ppm');
      }
      throw Exception('Error al crear control de cloro: ${e.message}');
    } catch (e) {
      throw Exception('Error al crear control de cloro: $e');
    }
  }

  // =====================================================
  // Read Operations
  // =====================================================

  /// Gets all chlorine control records for the current user's cooperative
  ///
  /// Filters:
  /// - [moduleId]: Filter by specific module
  /// - [fromDate]: Get records from this date onwards
  /// - [toDate]: Get records up to this date
  ///
  /// Returns records ordered by date and time DESC (most recent first)
  Future<List<ChlorineResidualControl>> getControls({
    String? moduleId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('chlorine_residual_controls')
          .select('''
            *,
            module:coop_modules(name)
          ''').eq('cooperative_id', AppConfig.current.id);

      // Apply filters
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

      final response = await query
          .order('control_date', ascending: false)
          .order('control_time', ascending: false);

      return (response as List).map((json) {
        // Extract joined data
        final moduleName =
            json['module'] != null ? json['module']['name'] as String : null;

        return ChlorineResidualControl.fromJson({
          ...json,
          'module_name': moduleName,
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener controles de cloro: $e');
    }
  }

  /// Gets a specific chlorine control record by ID
  ///
  /// Returns null if not found or user doesn't have permission
  Future<ChlorineResidualControl?> getControlById(String id) async {
    try {
      final response = await _supabase
          .from('chlorine_residual_controls')
          .select('''
            *,
            module:coop_modules(name)
          ''')
          .eq('id', id)
          .eq('cooperative_id', AppConfig.current.id)
          .maybeSingle();

      if (response == null) return null;

      // Extract joined data
      final moduleName =
          response['module'] != null ? response['module']['name'] as String : null;

      return ChlorineResidualControl.fromJson({
        ...response,
        'module_name': moduleName,
      });
    } catch (e) {
      throw Exception('Error al obtener control de cloro: $e');
    }
  }

  Future<bool> hasControlOnDate(String moduleId, DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _supabase
          .from('chlorine_residual_controls')
          .select('id')
          .eq('coop_module_id', moduleId)
          .eq('control_date', dateStr)
          .eq('cooperative_id', AppConfig.current.id)
          .limit(1);
      return (response as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasControlOnDateTime(String moduleId, DateTime date, String time) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final timeStr = time.split(':').length == 3 ? time : '$time:00';
      final response = await _supabase
          .from('chlorine_residual_controls')
          .select('id')
          .eq('coop_module_id', moduleId)
          .eq('control_date', dateStr)
          .eq('control_time', timeStr)
          .eq('cooperative_id', AppConfig.current.id)
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
  // Update Operations
  // =====================================================

  /// Updates an existing chlorine control record
  ///
  /// Only the owner (created_by) can update their records (enforced by RLS)
  ///
  /// Throws:
  /// - Exception if user doesn't have permission
  /// - Exception if measurements are outside valid range
  Future<ChlorineResidualControl> updateControl(
    UpdateChlorineResidualControlRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('chlorine_residual_controls')
          .update(request.toJson())
          .eq('id', request.id)
          .eq('cooperative_id', AppConfig.current.id)
          .select('''
            *,
            module:coop_modules(name)
          ''').single();

      // Extract joined data
      final moduleName =
          response['module'] != null ? response['module']['name'] as String : null;

      return ChlorineResidualControl.fromJson({
        ...response,
        'module_name': moduleName,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        throw Exception(
            'Las mediciones deben estar entre 0 y 10 ppm');
      }
      throw Exception('Error al actualizar control de cloro: ${e.message}');
    } catch (e) {
      throw Exception('Error al actualizar control de cloro: $e');
    }
  }

  // =====================================================
  // Delete Operations
  // =====================================================

  /// Deletes a chlorine control record
  ///
  /// Only the owner (created_by) can delete their records (enforced by RLS)
  Future<void> deleteControl(String id) async {
    try {
      await _supabase
          .from('chlorine_residual_controls')
          .delete()
          .eq('id', id)
          .eq('cooperative_id', AppConfig.current.id);
    } catch (e) {
      throw Exception('Error al eliminar control de cloro: $e');
    }
  }

  // =====================================================
  // Statistics Operations
  // =====================================================

  /// Gets chlorine control statistics for a date range
  ///
  /// Returns:
  /// - Total number of controls
  /// - Average M1 and M2 measurements
  /// - Count of measurements outside safe range
  /// - Compliance percentage (within safe range)
  Future<Map<String, dynamic>> getStatistics({
    required DateTime fromDate,
    required DateTime toDate,
    String? moduleId,
  }) async {
    try {
      final controls = await getControls(
        moduleId: moduleId,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (controls.isEmpty) {
        return {
          'total_controls': 0,
          'avg_m1': 0.0,
          'avg_m2': 0.0,
          'out_of_range_count': 0,
          'compliance_percentage': 0.0,
        };
      }

      // Calculate statistics
      final totalControls = controls.length;
      final totalPoints = totalControls * 2; // M1 + M2 per control

      final sumM1 = controls.fold<double>(
        0.0,
        (sum, control) => sum + control.measurementPoint1,
      );
      final sumM2 = controls.fold<double>(
        0.0,
        (sum, control) => sum + control.measurementPoint2,
      );

      final avgM1 = sumM1 / totalControls;
      final avgM2 = sumM2 / totalControls;

      // Count measurements outside safe range
      var outOfRangeCount = 0;
      for (final control in controls) {
        if (!control.isM1InSafeRange) outOfRangeCount++;
        if (!control.isM2InSafeRange) outOfRangeCount++;
      }

      final inRangeCount = totalPoints - outOfRangeCount;
      final compliancePercentage = (inRangeCount / totalPoints) * 100;

      return {
        'total_controls': totalControls,
        'total_measurement_points': totalPoints,
        'avg_m1': double.parse(avgM1.toStringAsFixed(2)),
        'avg_m2': double.parse(avgM2.toStringAsFixed(2)),
        'in_range_count': inRangeCount,
        'out_of_range_count': outOfRangeCount,
        'compliance_percentage': double.parse(compliancePercentage.toStringAsFixed(2)),
      };
    } catch (e) {
      throw Exception('Error al calcular estadísticas: $e');
    }
  }

  /// Gets daily summary statistics grouped by date
  ///
  /// Useful for trend analysis and charts
  Future<List<Map<String, dynamic>>> getDailySummary({
    required DateTime fromDate,
    required DateTime toDate,
    String? moduleId,
  }) async {
    try {
      final controls = await getControls(
        moduleId: moduleId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Group by date
      final groupedByDate = <String, List<ChlorineResidualControl>>{};
      for (final control in controls) {
        final dateKey = DateFormat('yyyy-MM-dd').format(control.controlDate);
        groupedByDate.putIfAbsent(dateKey, () => []).add(control);
      }

      // Calculate summary for each date
      final summaries = <Map<String, dynamic>>[];
      for (final entry in groupedByDate.entries) {
        final dateControls = entry.value;
        final totalPoints = dateControls.length * 2;

        var outOfRangeCount = 0;
        for (final control in dateControls) {
          if (!control.isM1InSafeRange) outOfRangeCount++;
          if (!control.isM2InSafeRange) outOfRangeCount++;
        }

        final compliancePercentage =
            ((totalPoints - outOfRangeCount) / totalPoints) * 100;

        summaries.add({
          'date': entry.key,
          'control_count': dateControls.length,
          'total_points': totalPoints,
          'out_of_range_count': outOfRangeCount,
          'compliance_percentage': double.parse(compliancePercentage.toStringAsFixed(2)),
        });
      }

      // Sort by date descending
      summaries.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

      return summaries;
    } catch (e) {
      throw Exception('Error al generar resumen diario: $e');
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
            .from('chlorine_residual_controls')
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
