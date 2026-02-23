import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/exit_registration.dart';
import 'package:panela_sys/models/exit_item.dart';
import 'package:panela_sys/services/inventory_service.dart';

class ExitRegistrationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final InventoryService _inventoryService = InventoryService();

  // Get all exit registrations for the user's cooperative
  Future<List<ExitRegistration>> getExitRegistrations() async {
    try {
      final response = await _supabase
          .from('exit_registrations')
          .select('*')
          .order('exit_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ExitRegistration.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exit registrations: $e');
    }
  }

  // Get exit registration by ID
  Future<ExitRegistration?> getExitRegistrationById(String id) async {
    try {
      final response = await _supabase
          .from('exit_registrations')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ExitRegistration.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch exit registration: $e');
    }
  }

  // Get exit registrations with items
  Future<List<Map<String, dynamic>>> getExitRegistrationsWithItems() async {
    try {
      final response = await _supabase
          .from('exit_registrations')
          .select('''
            *,
            exit_items(
              *,
              production_batch:production_batches(
                id,
                batch_code,
                process_date,
                producer:producers(
                  id,
                  first_name,
                  last_name
                )
              )
            )
          ''')
          .order('exit_date', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch exit registrations with items: $e');
    }
  }

  // Get exit registrations by date range
  Future<List<ExitRegistration>> getExitRegistrationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('exit_registrations')
          .select('*')
          .gte('exit_date', startDate.toIso8601String().split('T')[0])
          .lte('exit_date', endDate.toIso8601String().split('T')[0])
          .order('exit_date', ascending: false);

      return (response as List)
          .map((json) => ExitRegistration.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exit registrations by date range: $e');
    }
  }

  // Get exit registrations with items by specific date (for inspection selection)
  Future<List<Map<String, dynamic>>> getExitRegistrationsWithItemsByDate(
    DateTime date,
  ) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('exit_registrations')
          .select('''
            *,
            exit_items(
              *,
              production_batch:production_batches(
                id,
                batch_code,
                process_date,
                producer:producers(
                  id,
                  first_name,
                  last_name,
                  dni
                )
              )
            )
          ''')
          .eq('exit_date', dateStr)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch exits with items by date: $e');
    }
  }

  // Create new exit registration
  Future<ExitRegistration> createExitRegistration(CreateExitRegistrationRequest request) async {
    try {
      final response = await _supabase
          .from('exit_registrations')
          .insert(request.toJson())
          .select()
          .single();

      return ExitRegistration.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create exit registration: $e');
    }
  }

  // Update exit registration
  Future<ExitRegistration> updateExitRegistration(
    String id,
    UpdateExitRegistrationRequest request,
  ) async {
    try {
      if (request.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await _supabase
          .from('exit_registrations')
          .update(request.toJson())
          .eq('id', id)
          .select()
          .single();

      return ExitRegistration.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update exit registration: $e');
    }
  }

  // Delete exit registration (and all its items via CASCADE)
  Future<void> deleteExitRegistration(String id) async {
    try {
      await _supabase
          .from('exit_registrations')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete exit registration: $e');
    }
  }

  // Create exit registration with items (transaction-like behavior)
  Future<ExitRegistration> createExitRegistrationWithItems(
    CreateExitRegistrationRequest exitRequest,
    List<CreateExitItemRequest> itemRequests,
  ) async {
    try {
      // Validate stock availability first
      for (final itemRequest in itemRequests) {
        final canConsume = await _inventoryService.canConsumeStock(
          itemRequest.productionBatchId,
          itemRequest.quantityKg,
        );
        if (!canConsume) {
          throw Exception(
            'Insufficient stock for batch ${itemRequest.productionBatchId}. '
            'Requested: ${itemRequest.quantityKg} kg'
          );
        }
      }

      // Create exit registration
      final exitRegistration = await createExitRegistration(exitRequest);

      // Create exit items
      final List<ExitItem> createdItems = [];
      for (final itemRequest in itemRequests) {
        final itemWithExitId = CreateExitItemRequest(
          exitRegistrationId: exitRegistration.id,
          productionBatchId: itemRequest.productionBatchId,
          quantityKg: itemRequest.quantityKg,
          isAutoconsumo: itemRequest.isAutoconsumo,
          bagsCount: itemRequest.bagsCount,
          unitPrice: itemRequest.unitPrice,
          notes: itemRequest.notes,
          itemDocumentNumber: itemRequest.itemDocumentNumber,
          cooperativeId: itemRequest.cooperativeId,
        );

        final item = await createExitItem(itemWithExitId);
        createdItems.add(item);
      }

      // Return the created exit registration
      return exitRegistration;
    } catch (e) {
      throw Exception('Failed to create exit registration with items: $e');
    }
  }

  // Get exit items for a specific exit registration
  Future<List<ExitItem>> getExitItems(String exitRegistrationId) async {
    try {
      final response = await _supabase
          .from('exit_items')
          .select('*')
          .eq('exit_registration_id', exitRegistrationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ExitItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exit items: $e');
    }
  }

  // Get exit items with production batch details
  Future<List<Map<String, dynamic>>> getExitItemsWithBatchDetails(String exitRegistrationId) async {
    try {
      final response = await _supabase
          .from('exit_items')
          .select('''
            *,
            production_batch:production_batches(
              id,
              batch_code,
              harvest_date,
              process_date,
              producer:producers(
                id,
                first_name,
                last_name
              )
            )
          ''')
          .eq('exit_registration_id', exitRegistrationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch exit items with batch details: $e');
    }
  }

  // Create exit item
  Future<ExitItem> createExitItem(CreateExitItemRequest request) async {
    try {
      final response = await _supabase
          .from('exit_items')
          .insert(request.toJson())
          .select()
          .single();

      return ExitItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create exit item: $e');
    }
  }

  // Update exit item
  Future<ExitItem> updateExitItem(
    String id,
    UpdateExitItemRequest request,
  ) async {
    try {
      if (request.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await _supabase
          .from('exit_items')
          .update(request.toJson())
          .eq('id', id)
          .select()
          .single();

      return ExitItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update exit item: $e');
    }
  }

  // Delete exit item
  Future<void> deleteExitItem(String id) async {
    try {
      await _supabase
          .from('exit_items')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete exit item: $e');
    }
  }

  // Get exit statistics
  Future<Map<String, dynamic>> getExitStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Default to current month if no dates provided
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? DateTime(now.year, now.month + 1, 0);

      final exitRegistrations = await getExitRegistrationsByDateRange(start, end);
      
      double totalKg = 0;
      double totalAutoconsumo = 0;
      double totalSalida = 0;
      int totalExits = exitRegistrations.length;

      for (final exit in exitRegistrations) {
        totalKg += exit.totalKg;
        
        // Get items to calculate autoconsumo vs salida
        final items = await getExitItems(exit.id);
        for (final item in items) {
          if (item.isAutoconsumo) {
            totalAutoconsumo += item.quantityKg;
          } else {
            totalSalida += item.quantityKg;
          }
        }
      }

      return {
        'total_exits': totalExits,
        'total_kg': totalKg,
        'total_autoconsumo_kg': totalAutoconsumo,
        'total_salida_kg': totalSalida,
        'total_bags': (totalKg / 50).floor(),
        'period_start': start.toIso8601String().split('T')[0],
        'period_end': end.toIso8601String().split('T')[0],
      };
    } catch (e) {
      throw Exception('Failed to get exit statistics: $e');
    }
  }

  // Get exits by destination
  Future<List<ExitRegistration>> getExitsByDestination(String destination) async {
    try {
      final response = await _supabase
          .from('exit_registrations')
          .select('*')
          .eq('destination', destination)
          .order('exit_date', ascending: false);

      return (response as List)
          .map((json) => ExitRegistration.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exits by destination: $e');
    }
  }

  // Search exit registrations
  Future<List<ExitRegistration>> searchExitRegistrations(String query) async {
    try {
      final response = await _supabase
          .from('exit_registrations')
          .select('*')
          .or('exit_code.ilike.%$query%,document_number.ilike.%$query%,destination.ilike.%$query%')
          .order('exit_date', ascending: false);

      return (response as List)
          .map((json) => ExitRegistration.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search exit registrations: $e');
    }
  }

  // Get recent exits (last N days)
  Future<List<ExitRegistration>> getRecentExits({int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final response = await _supabase
          .from('exit_registrations')
          .select('*')
          .gte('exit_date', cutoffDate.toIso8601String().split('T')[0])
          .order('exit_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ExitRegistration.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent exits: $e');
    }
  }

  // Get exit registrations for historial with producer info
  Future<List<Map<String, dynamic>>> getExitRegistrationsForHistorial() async {
    try {
      // Calculate date range: last month
      final today = DateTime.now();
      final oneMonthAgo = DateTime(today.year, today.month - 1, today.day);
      final todayStr = today.toIso8601String().split('T')[0];
      final oneMonthAgoStr = oneMonthAgo.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('exit_registrations')
          .select('''
            id,
            exit_code,
            exit_date,
            total_kg,
            exit_type,
            destination,
            document_number,
            created_at,
            exit_items!inner(
              quantity_kg,
              bags_count,
              is_autoconsumo,
              item_document_number,
              production_batch:production_batches!inner(
                id,
                batch_code,
                producers!inner(
                  first_name,
                  last_name,
                  dni
                )
              )
            )
          ''')
          .gte('exit_date', oneMonthAgoStr)
          .lte('exit_date', todayStr)
          .order('exit_date', ascending: false)
          .order('created_at', ascending: false);

      // Expand: 1 card per exit_item (lote), not per exit_registration
      final expandedList = <Map<String, dynamic>>[];

      for (final exit in response as List) {
        final exitItems = exit['exit_items'] as List;
        final exitDate = DateTime.parse(exit['exit_date']).toLocal();

        for (final exitItem in exitItems) {
          final producer = exitItem['production_batch']?['producers'];
          final isAutoconsumo = exitItem['is_autoconsumo'] as bool;
          final quantityKg = (exitItem['quantity_kg'] as num).toDouble();
          final bagsCount = exitItem['bags_count'] as int?;

          // Display logic: show bags if acopio, kg if autoconsumo
          final displayQuantity = isAutoconsumo ? quantityKg : (bagsCount ?? 0);
          final displayUnit = isAutoconsumo ? 'kg' : 'bolsas';

          expandedList.add({
            'id': '${exit['id']}_${exitItem.hashCode}', // Unique ID per item
            'exit_registration_id': exit['id'],
            'codigo_salida': exit['exit_code'],
            'fecha_salida': exitDate,
            'productor': producer != null
                ? '${producer['first_name']} ${producer['last_name']}'
                : 'N/A',
            'dni_productor': producer?['dni'] ?? 'N/A',
            'cantidad_kg': quantityKg,
            'bolsas': bagsCount ?? 0,
            'cantidad_mostrada': displayQuantity.toStringAsFixed(displayQuantity == displayQuantity.toInt() ? 0 : 2),
            'unidad': displayUnit,
            'tipo_salida': exit['exit_type'],
            'is_autoconsumo': isAutoconsumo,
            'destino': exit['destination'] ?? 'N/A',
            'documento': exit['document_number'] ?? 'N/A',
            'item_document_number': exitItem['item_document_number'],
          });
        }
      }

      return expandedList;
    } catch (e) {
      throw Exception('Failed to fetch exit registrations for historial: $e');
    }
  }
}