import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/stowage_transport_inspection.dart';

class StowageTransportInspectionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all inspections for the user's cooperative
  Future<List<StowageTransportInspection>> getInspections() async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('*')
          .order('inspection_date', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => StowageTransportInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inspections: $e');
    }
  }

  // Get inspection by ID
  Future<StowageTransportInspection?> getInspectionById(String id) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return StowageTransportInspection.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch inspection: $e');
    }
  }

  // Get inspections by exit registration
  Future<List<StowageTransportInspection>> getInspectionsByExitRegistration(
    String exitRegistrationId,
  ) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('*')
          .eq('exit_registration_id', exitRegistrationId)
          .order('inspection_date', ascending: false);

      return (response as List)
          .map((json) => StowageTransportInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inspections by exit registration: $e');
    }
  }

  // Get inspections by date range
  Future<List<StowageTransportInspection>> getInspectionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('*')
          .gte('inspection_date', startDate.toIso8601String().split('T')[0])
          .lte('inspection_date', endDate.toIso8601String().split('T')[0])
          .order('inspection_date', ascending: false);

      return (response as List)
          .map((json) => StowageTransportInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inspections by date range: $e');
    }
  }

  // Get recent inspections (last 30 days by default)
  Future<List<StowageTransportInspection>> getRecentInspections({
    int days = 30,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return getInspectionsByDateRange(startDate, endDate);
  }

  // Get inspections with exit registration details (including items and producers)
  Future<List<Map<String, dynamic>>> getInspectionsWithExitDetails() async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('''
            *,
            exit_registration:exit_registrations(
              id,
              document_number,
              total_kg,
              dni_productor,
              exit_items(
                bags_count,
                quantity_kg,
                is_autoconsumo,
                item_document_number,
                production_batch:production_batches(
                  producer:producers(
                    first_name,
                    last_name
                  )
                )
              )
            )
          ''')
          .order('inspection_date', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch inspections with exit details: $e');
    }
  }

  // Create new inspection
  Future<StowageTransportInspection> createInspection(
    CreateStowageTransportInspectionRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .insert(request.toJson())
          .select()
          .single();

      return StowageTransportInspection.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create inspection: $e');
    }
  }

  // Update inspection
  Future<StowageTransportInspection> updateInspection(
    String id,
    UpdateStowageTransportInspectionRequest request,
  ) async {
    try {
      if (request.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await _supabase
          .from('stowage_transport_inspections')
          .update(request.toJson())
          .eq('id', id)
          .select()
          .single();

      return StowageTransportInspection.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update inspection: $e');
    }
  }

  // Delete inspection
  Future<void> deleteInspection(String id) async {
    try {
      await _supabase
          .from('stowage_transport_inspections')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete inspection: $e');
    }
  }

  // Get inspection count by exit registration
  Future<int> getInspectionCountByExit(String exitRegistrationId) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('id')
          .eq('exit_registration_id', exitRegistrationId);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to count inspections: $e');
    }
  }

  // Get compliant inspections (fully compliant)
  Future<List<StowageTransportInspection>> getCompliantInspections(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('*')
          .gte('inspection_date', startDate.toIso8601String().split('T')[0])
          .lte('inspection_date', endDate.toIso8601String().split('T')[0])
          .eq('vehicle_condition', 'adequate')
          .eq('sack_clean_condition', 'good')
          .eq('sack_tied_condition', 'good')
          .order('inspection_date', ascending: false);

      final inspections = (response as List)
          .map((json) => StowageTransportInspection.fromJson(json))
          .toList();

      // Filter fully compliant in Dart (checking all boolean fields)
      return inspections.where((i) => i.isFullyCompliant).toList();
    } catch (e) {
      throw Exception('Failed to fetch compliant inspections: $e');
    }
  }

  // Get non-compliant inspections
  Future<List<StowageTransportInspection>> getNonCompliantInspections(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allInspections = await getInspectionsByDateRange(startDate, endDate);
      return allInspections.where((i) => !i.isFullyCompliant).toList();
    } catch (e) {
      throw Exception('Failed to fetch non-compliant inspections: $e');
    }
  }

  // Search inspections by carrier name
  Future<List<StowageTransportInspection>> searchByCarrier(String carrierName) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('*')
          .ilike('carrier_name', '%$carrierName%')
          .order('inspection_date', ascending: false);

      return (response as List)
          .map((json) => StowageTransportInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inspections by carrier: $e');
    }
  }

  // Search inspections by vehicle plate
  Future<List<StowageTransportInspection>> searchByVehiclePlate(String plate) async {
    try {
      final response = await _supabase
          .from('stowage_transport_inspections')
          .select('*')
          .ilike('vehicle_plate', '%$plate%')
          .order('inspection_date', ascending: false);

      return (response as List)
          .map((json) => StowageTransportInspection.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search inspections by vehicle plate: $e');
    }
  }
}
