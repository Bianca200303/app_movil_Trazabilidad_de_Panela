import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/inventory_stock.dart';

class InventoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all inventory stock for the user's cooperative
  Future<List<InventoryStock>> getInventoryStock() async {
    try {
      final response = await _supabase
          .from('inventory_stock')
          .select('*')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => InventoryStock.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch inventory stock: $e');
    }
  }

  // Get inventory stock for a specific production batch
  Future<InventoryStock?> getStockByBatchId(String productionBatchId) async {
    try {
      final response = await _supabase
          .from('inventory_stock')
          .select('*')
          .eq('production_batch_id', productionBatchId)
          .maybeSingle();

      if (response == null) return null;
      return InventoryStock.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch stock for batch $productionBatchId: $e');
    }
  }

  // Get inventory stock with production batch details
  Future<List<Map<String, dynamic>>> getInventoryWithBatchDetails() async {
    try {
      final response = await _supabase
          .from('inventory_stock')
          .select('''
            *,
            production_batch:production_batches(
              id,
              batch_code,
              harvest_date,
              process_date,
              juice_liters,
              producer:producers(
                id,
                first_name,
                last_name,
                dni
              )
            )
          ''')
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch inventory with batch details: $e');
    }
  }

  // Get available stock (stock with available_kg > 0)
  Future<List<Map<String, dynamic>>> getAvailableStock() async {
    try {
      final response = await _supabase
          .from('inventory_stock')
          .select('''
            *,
            production_batch:production_batches(
              id,
              batch_code,
              harvest_date,
              process_date,
              juice_liters,
              producer:producers(
                id,
                first_name,
                last_name,
                dni,
                coop_modules(name)
              )
            )
          ''')
          .gt('available_kg', 0);

      final list = List<Map<String, dynamic>>.from(response);

      // Sort by process_date (FIFO - oldest first)
      list.sort((a, b) {
        final dateA = DateTime.parse(a['production_batch']['process_date']);
        final dateB = DateTime.parse(b['production_batch']['process_date']);
        return dateA.compareTo(dateB);
      });

      return list;
    } catch (e) {
      throw Exception('Failed to fetch available stock: $e');
    }
  }

  // Get stock by producer
  Future<List<Map<String, dynamic>>> getStockByProducer(String producerId) async {
    try {
      final response = await _supabase
          .from('inventory_stock')
          .select('''
            *,
            production_batch:production_batches!inner(
              id,
              batch_code,
              harvest_date,
              process_date,
              juice_liters,
              producer_id
            )
          ''')
          .eq('production_batch.producer_id', producerId)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch stock for producer $producerId: $e');
    }
  }

  // Create new inventory stock record
  Future<InventoryStock> createInventoryStock(CreateInventoryStockRequest request) async {
    try {
      final response = await _supabase
          .from('inventory_stock')
          .insert(request.toJson())
          .select()
          .single();

      return InventoryStock.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create inventory stock: $e');
    }
  }

  // Update inventory stock
  Future<InventoryStock> updateInventoryStock(
    String id,
    UpdateInventoryStockRequest request,
  ) async {
    try {
      if (request.isEmpty) {
        throw Exception('No updates provided');
      }

      final response = await _supabase
          .from('inventory_stock')
          .update(request.toJson())
          .eq('id', id)
          .select()
          .single();

      return InventoryStock.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update inventory stock: $e');
    }
  }

  // Reserve stock for an exit
  Future<void> reserveStock(String productionBatchId, double quantityKg) async {
    try {
      // Get current stock
      final currentStock = await getStockByBatchId(productionBatchId);
      if (currentStock == null) {
        throw Exception('Stock record not found for batch $productionBatchId');
      }

      // Check if enough stock is available
      if (currentStock.availableKg < quantityKg) {
        throw Exception(
          'Insufficient stock. Available: ${currentStock.availableKg} kg, '
          'Requested: $quantityKg kg'
        );
      }

      // Update reserved stock
      final newReservedKg = currentStock.reservedKg + quantityKg;
      await updateInventoryStock(
        currentStock.id,
        UpdateInventoryStockRequest(reservedKg: newReservedKg),
      );
    } catch (e) {
      throw Exception('Failed to reserve stock: $e');
    }
  }

  // Release reserved stock
  Future<void> releaseReservedStock(String productionBatchId, double quantityKg) async {
    try {
      final currentStock = await getStockByBatchId(productionBatchId);
      if (currentStock == null) {
        throw Exception('Stock record not found for batch $productionBatchId');
      }

      final newReservedKg = (currentStock.reservedKg - quantityKg).clamp(0.0, currentStock.currentKg);
      await updateInventoryStock(
        currentStock.id,
        UpdateInventoryStockRequest(reservedKg: newReservedKg),
      );
    } catch (e) {
      throw Exception('Failed to release reserved stock: $e');
    }
  }

  // Consume stock (reduce current stock)
  Future<void> consumeStock(String productionBatchId, double quantityKg) async {
    try {
      final currentStock = await getStockByBatchId(productionBatchId);
      if (currentStock == null) {
        throw Exception('Stock record not found for batch $productionBatchId');
      }

      if (currentStock.currentKg < quantityKg) {
        throw Exception(
          'Insufficient stock. Current: ${currentStock.currentKg} kg, '
          'Requested: $quantityKg kg'
        );
      }

      final newCurrentKg = currentStock.currentKg - quantityKg;
      final newReservedKg = (currentStock.reservedKg - quantityKg).clamp(0.0, newCurrentKg);

      await updateInventoryStock(
        currentStock.id,
        UpdateInventoryStockRequest(
          currentKg: newCurrentKg,
          reservedKg: newReservedKg,
        ),
      );
    } catch (e) {
      throw Exception('Failed to consume stock: $e');
    }
  }

  // Get low stock items (less than specified threshold)
  Future<List<Map<String, dynamic>>> getLowStockItems({double threshold = 50.0}) async {
    try {
      final response = await _supabase
          .from('inventory_stock')
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
          .lt('available_kg', threshold)
          .gt('available_kg', 0)
          .order('available_kg', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch low stock items: $e');
    }
  }

  // Get inventory summary
  Future<Map<String, dynamic>> getInventorySummary() async {
    try {
      final response = await _supabase
          .rpc('get_inventory_summary');

      return Map<String, dynamic>.from(response);
    } catch (e) {
      // If the RPC doesn't exist, calculate manually
      final stocks = await getInventoryStock();
      
      double totalCurrent = 0;
      double totalReserved = 0;
      double totalAvailable = 0;
      int batchesWithStock = 0;

      for (final stock in stocks) {
        totalCurrent += stock.currentKg;
        totalReserved += stock.reservedKg;
        totalAvailable += stock.availableKg;
        if (stock.availableKg > 0) batchesWithStock++;
      }

      return {
        'total_current_kg': totalCurrent,
        'total_reserved_kg': totalReserved,
        'total_available_kg': totalAvailable,
        'total_batches': stocks.length,
        'batches_with_stock': batchesWithStock,
        'total_bags': (totalAvailable / 50).floor(),
      };
    }
  }

  // Delete inventory stock record
  Future<void> deleteInventoryStock(String id) async {
    try {
      await _supabase
          .from('inventory_stock')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete inventory stock: $e');
    }
  }

  // Validate if stock operation is possible
  Future<bool> canConsumeStock(String productionBatchId, double quantityKg) async {
    try {
      final stock = await getStockByBatchId(productionBatchId);
      return stock != null && stock.availableKg >= quantityKg;
    } catch (e) {
      return false;
    }
  }
}