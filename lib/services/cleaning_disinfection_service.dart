// =====================================================
// Cleaning and Disinfection Service
// =====================================================

import 'package:panela_sys/models/cleaning_disinfection.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:panela_sys/services/production_dates_service.dart';
import 'package:panela_sys/services/sync/pending_submissions_service.dart';
import 'package:panela_sys/services/sync/submissions/submission_kinds.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Service for managing cleaning and disinfection records
class CleaningDisinfectionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PendingSubmissionsService _pending;
  final ProductionDatesService _productionDates;

  CleaningDisinfectionService({
    PendingSubmissionsService? pending,
    ProductionDatesService? productionDates,
  })  : _pending = pending ?? PendingSubmissionsService(),
        _productionDates = productionDates ?? ProductionDatesService();

  // =====================================================
  // Create Operations
  // =====================================================

  /// Registra una limpieza nueva (cabecera + puntos), con o sin señal (ver
  /// PendingSubmissionsService.submit). Se envía con la RPC atómica e
  /// idempotente submit_cleaning_disinfection.
  ///
  /// Si el servidor la rechaza en el momento (p. ej. UNIQUE de módulo+fecha),
  /// lanza el error.
  Future<SubmissionOutcome> submitCleaningRecord(CreateCleaningDisinfectionRequest request) {
    return _pending.submit(
      kind: SubmissionKinds.cleaningDisinfection,
      payload: {
        ...request.toParentJson(),
        'items': request.items.map((item) => item.toJson()).toList(),
      },
    );
  }

  // =====================================================
  // Read Operations
  // =====================================================

  /// Gets all cleaning records for the current user's cooperative
  ///
  /// Returns records ordered by date DESC (most recent first)
  ///
  /// Includes joined data:
  /// - Module name
  Future<List<CleaningDisinfection>> getCleaningRecords({
    String? moduleId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('cleaning_disinfections')
          .select('''
            *,
            module:coop_modules(name)
          ''');

      // Apply filters if provided
      if (moduleId != null) {
        query = query.eq('coop_module_id', moduleId);
      }

      if (fromDate != null) {
        query = query.gte(
          'cleaning_date',
          DateFormat('yyyy-MM-dd').format(fromDate),
        );
      }

      if (toDate != null) {
        query = query.lte(
          'cleaning_date',
          DateFormat('yyyy-MM-dd').format(toDate),
        );
      }

      final response = await query.order('cleaning_date', ascending: false);

      final rows = response as List;

      // cleaning_disinfections.created_by no tiene FK a users -- se resuelve
      // con una consulta aparte y se cruza en memoria (igual que en
      // chlorine_residual_control_service.dart).
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

        // Create CleaningDisinfection with joined data
        return CleaningDisinfection.fromJson({
          ...json,
          'module_name': moduleName,
          'created_by_name': namesByUserId[json['created_by']],
        });
      }).toList();
    } catch (e) {
      throw Exception('Error fetching cleaning records: $e');
    }
  }

  /// Gets a specific cleaning record by ID with all items
  ///
  /// Returns null if not found or user doesn't have permission
  Future<CleaningDisinfection?> getCleaningRecordById(String id) async {
    try {
      final response = await _supabase
          .from('cleaning_disinfections')
          .select('''
            *,
            module:coop_modules(name)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      // Extract joined data
      final moduleName =
          response['module'] != null ? response['module']['name'] as String : null;

      return CleaningDisinfection.fromJson({
        ...response,
        'module_name': moduleName,
      });
    } catch (e) {
      throw Exception('Error fetching cleaning record: $e');
    }
  }

  /// Gets all items for a specific cleaning record
  Future<List<CleaningDisinfectionItem>> getItemsByRecordId(
    String recordId,
  ) async {
    try {
      final response = await _supabase
          .from('cleaning_disinfection_items')
          .select()
          .eq('cleaning_disinfection_id', recordId)
          .order('area_code')
          .order('point_code');

      return (response as List)
          .map((json) => CleaningDisinfectionItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error fetching cleaning items: $e');
    }
  }

  /// Áreas ya cubiertas por registros de limpieza de ese módulo y día:
  /// guardados en el celular sin enviar + (con señal) los del servidor.
  Future<List<String>> getAreasCoveredOnDate(
    String moduleId,
    DateTime date,
  ) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final areas = <String>{
      for (final p in await _pending.pendingPayloads(SubmissionKinds.cleaningDisinfection))
        if (p['coop_module_id'] == moduleId && p['cleaning_date'] == dateStr)
          for (final item in p['items'] as List) (item as Map<String, dynamic>)['area_code'] as String,
    };
    if (!await NetworkDetector().isConnected) return areas.toList();

    try {
      final records = await _supabase
          .from('cleaning_disinfections')
          .select('id')
          .eq('coop_module_id', moduleId)
          .eq('cleaning_date', dateStr);
      if ((records as List).isNotEmpty) {
        final ids = records.map((r) => r['id'] as String).toList();
        final items = await _supabase
            .from('cleaning_disinfection_items')
            .select('area_code')
            .inFilter('cleaning_disinfection_id', ids);
        areas.addAll((items as List).map((i) => i['area_code'] as String));
      }
    } catch (_) {
      // Orientativo: si falla la consulta, se muestra solo lo del celular.
    }
    return areas.toList();
  }

  /// ¿Ya hay limpieza registrada de este módulo ese día? (servidor + pendientes)
  Future<bool> hasCleaningOnDate(String moduleId, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _pending.existsOnServerOrPending(
      kind: SubmissionKinds.cleaningDisinfection,
      matches: (p) => p['coop_module_id'] == moduleId && p['cleaning_date'] == dateStr,
      serverCheck: () async {
        final response = await _supabase
            .from('cleaning_disinfections')
            .select('id')
            .eq('coop_module_id', moduleId)
            .eq('cleaning_date', dateStr)
            .limit(1);
        return (response as List).isNotEmpty;
      },
    );
  }

  /// ¿Hubo producción en el módulo ese día? (con o sin señal)
  Future<bool> hasProductionOnDate(String moduleId, DateTime date) {
    return _productionDates.hasProductionOnDate(moduleId, date);
  }

  // =====================================================
  // Statistics Operations
  // =====================================================

  /// Gets cleaning statistics for a date range
  ///
  /// Returns aggregated data such as:
  /// - Total cleaning sessions
  /// - Product usage frequency
  /// - Most cleaned areas
  Future<Map<String, dynamic>> getCleaningStatistics({
    required DateTime fromDate,
    required DateTime toDate,
    String? moduleId,
  }) async {
    try {
      // Get all records in date range
      final records = await getCleaningRecords(
        moduleId: moduleId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Get all items for these records
      final allItems = <CleaningDisinfectionItem>[];
      for (final record in records) {
        final items = await getItemsByRecordId(record.id);
        allItems.addAll(items);
      }

      // Calculate statistics
      final totalSessions = records.length;
      final totalPointsCleaned = allItems.length;

      // Product usage counts
      final chlorineCount =
          allItems.where((item) => item.usesChlorine).length;
      final detergentCount =
          allItems.where((item) => item.usesDetergent).length;
      final otherProductCount =
          allItems.where((item) => item.usesOtherProduct).length;

      // Cleaning type counts from parent records
      final dailyCount =
          records.where((r) => r.cleaningTypes.contains(CleaningType.daily)).length;
      final generalCount =
          records.where((r) => r.cleaningTypes.contains(CleaningType.general)).length;
      final deepCount =
          records.where((r) => r.cleaningTypes.contains(CleaningType.deep)).length;

      // Area cleaning frequency
      final areaFrequency = <String, int>{};
      for (final item in allItems) {
        areaFrequency[item.areaCode] =
            (areaFrequency[item.areaCode] ?? 0) + 1;
      }

      return {
        'total_sessions': totalSessions,
        'total_points_cleaned': totalPointsCleaned,
        'product_usage': {
          'chlorine': chlorineCount,
          'detergent': detergentCount,
          'other': otherProductCount,
        },
        'cleaning_types': {
          'daily': dailyCount,
          'general': generalCount,
          'deep': deepCount,
        },
        'area_frequency': areaFrequency,
      };
    } catch (e) {
      throw Exception('Error calculating statistics: $e');
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
            .from('cleaning_disinfections')
            .select('cleaning_date')
            .eq('coop_module_id', moduleId)
            .gte('cleaning_date', fromStr)
            .lte('cleaning_date', toStr),
      ]);
      final batchesByDate = <String, ({int count, double panela})>{};
      for (final b in results[0] as List) {
        final d = b['process_date'] as String;
        final p = (b['panela_kg'] as num?)?.toDouble() ?? 0.0;
        final c = batchesByDate[d];
        batchesByDate[d] = c == null ? (count: 1, panela: p) : (count: c.count + 1, panela: c.panela + p);
      }
      final recorded = <String>{for (final r in results[1] as List) r['cleaning_date'] as String};
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
