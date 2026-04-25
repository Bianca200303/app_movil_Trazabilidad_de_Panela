import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/product_return.dart';
import 'package:panela_sys/core/app_config.dart';

/// Service for managing product returns and complaints
class ProductReturnService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== CREATE ====================

  /// Creates a new product return record
  Future<ProductReturn> createProductReturn(
    CreateProductReturnRequest request,
  ) async {
    try {
      final response = await _supabase
          .from('product_returns')
          .insert(request.toJson())
          .select()
          .single();

      return ProductReturn.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        if (e.message.contains('foreign key')) {
          throw Exception('El lote de producción seleccionado no es válido');
        }
      }
      throw Exception('Error al registrar devolución: $e');
    }
  }

  // ==================== READ ====================

  /// Get all distinct dates that have production batches (for calendar highlighting).
  /// If [moduleIds] is provided, only dates with batches from those modules are returned.
  Future<Set<DateTime>> getProductionDates({List<String>? moduleIds}) async {
    try {
      var query = _supabase
          .from('production_batches')
          .select('process_date, producers!inner(coop_module_id)')
          .eq('cooperative_id', AppConfig.current.id);

      if (moduleIds != null && moduleIds.isNotEmpty) {
        query = query.filter(
          'producers.coop_module_id',
          'in',
          '(${moduleIds.join(',')})',
        );
      }

      final response = await query;

      return (response as List)
          .map((row) => DateTime.parse(row['process_date'] as String))
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet();
    } catch (e) {
      return {};
    }
  }

  /// Get production batches by process_date.
  /// If [moduleIds] is provided, only batches whose producer belongs to those modules are returned.
  Future<List<Map<String, dynamic>>> getBatchesByDate(
    DateTime date, {
    List<String>? moduleIds,
  }) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      var query = _supabase
          .from('production_batches')
          .select('''
            id,
            batch_code,
            process_date,
            panela_kg,
            confitillo_kg,
            producers!inner(
              first_name,
              last_name,
              dni,
              appagrop_code,
              coop_module_id
            )
          ''')
          .eq('process_date', dateStr)
          .eq('cooperative_id', AppConfig.current.id);

      if (moduleIds != null && moduleIds.isNotEmpty) {
        query = query.filter(
          'producers.coop_module_id',
          'in',
          '(${moduleIds.join(',')})',
        );
      }

      final response = await query.order('batch_code', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Error al cargar lotes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getBatchesByRange(
    DateTime from,
    DateTime to, {
    List<String>? moduleIds,
  }) async {
    try {
      var query = _supabase
          .from('production_batches')
          .select('''
            id,
            batch_code,
            process_date,
            panela_kg,
            confitillo_kg,
            producers!inner(
              first_name,
              last_name,
              dni,
              appagrop_code,
              coop_module_id
            )
          ''')
          .gte('process_date', DateFormat('yyyy-MM-dd').format(from))
          .lte('process_date', DateFormat('yyyy-MM-dd').format(to))
          .eq('cooperative_id', AppConfig.current.id);

      if (moduleIds != null && moduleIds.isNotEmpty) {
        query = query.filter('producers.coop_module_id', 'in', '(${moduleIds.join(',')})');
      }

      final response = await query.order('process_date', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Error al cargar lotes: $e');
    }
  }

  /// Get returns history with production batch details
  /// For history screen: combines return + batch + producer data
  /// Shows last 3 months of returns sorted by most recent first
  Future<List<Map<String, dynamic>>> getReturnsHistoryByRange(DateTime from, DateTime to) async {
    try {
      final response = await _supabase
          .from('product_returns')
          .select('''
            id,
            client_name,
            return_date,
            quantity_kg,
            quantity_sacks,
            return_reason,
            observations,
            created_at,
            registered_by_user:users!product_returns_created_by_fkey(first_name, last_name),
            production_batches!inner(
              batch_code,
              process_date,
              panela_kg,
              producers!inner(
                first_name,
                last_name,
                dni,
                appagrop_code,
                coop_modules(name)
              )
            )
          ''')
          .eq('cooperative_id', AppConfig.current.id)
          .gte('return_date', from.toIso8601String().split('T')[0])
          .lte('return_date', to.toIso8601String().split('T')[0])
          .order('return_date', ascending: false);

      return (response as List).map((item) {
        final batch = item['production_batches'];
        final producer = batch['producers'];
        final regUser = item['registered_by_user'] as Map<String, dynamic>?;
        return {
          'id': item['id'],
          'client_name': item['client_name'],
          'return_date': DateTime.parse(item['return_date']),
          'quantity_kg': (item['quantity_kg'] as num).toDouble(),
          'quantity_sacks': item['quantity_sacks'] as int,
          'return_reason': item['return_reason'],
          'observations': item['observations'],
          'batch_code': batch['batch_code'],
          'batch_panela_kg': batch['panela_kg'],
          'process_date': DateTime.parse(batch['process_date']),
          'producer_name': '${producer['first_name']} ${producer['last_name']}',
          'producer_dni': producer['dni'],
          'appagrop_code': producer['appagrop_code'],
          'module_name': (producer['coop_modules'] as Map<String, dynamic>?)?['name'],
          'registered_by': regUser != null ? '${regUser['first_name']} ${regUser['last_name']}' : null,
          'created_at': DateTime.parse(item['created_at']),
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar historial: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReturnsHistory() async {
    try {
      // Get last 3 months of data
      final today = DateTime.now();
      final threeMonthsAgo = DateTime(today.year, today.month - 3, today.day);
      final todayStr = today.toIso8601String().split('T')[0];
      final threeMonthsAgoStr = threeMonthsAgo.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('product_returns')
          .select('''
            id,
            client_name,
            return_date,
            quantity_kg,
            quantity_sacks,
            return_reason,
            observations,
            created_at,
            production_batches!inner(
              batch_code,
              process_date,
              producers!inner(
                first_name,
                last_name,
                dni,
                appagrop_code
              )
            )
          ''')
          .eq('cooperative_id', AppConfig.current.id)
          .gte('return_date', threeMonthsAgoStr)
          .lte('return_date', todayStr)
          .order('return_date', ascending: false);

      return (response as List).map((item) {
        final batch = item['production_batches'];
        final producer = batch['producers'];

        return {
          'id': item['id'],
          'client_name': item['client_name'],
          'return_date': DateTime.parse(item['return_date']),
          'quantity_kg': (item['quantity_kg'] as num).toDouble(),
          'quantity_sacks': item['quantity_sacks'] as int,
          'return_reason': item['return_reason'],
          'observations': item['observations'],
          'batch_code': batch['batch_code'],
          'process_date': DateTime.parse(batch['process_date']),
          'producer_name': '${producer['first_name']} ${producer['last_name']}',
          'producer_dni': producer['dni'],
          'appagrop_code': producer['appagrop_code'],
          'created_at': DateTime.parse(item['created_at']),
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar historial de devoluciones: $e');
    }
  }

  /// Get single product return by ID with full details
  Future<Map<String, dynamic>?> getReturnById(String id) async {
    try {
      final response = await _supabase
          .from('product_returns')
          .select('''
            *,
            production_batches!inner(
              batch_code,
              process_date,
              panela_kg,
              producers!inner(
                first_name,
                last_name,
                dni,
                appagrop_code,
                coop_modules!inner(name)
              )
            )
          ''')
          .eq('id', id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error al obtener detalles: $e');
    }
  }
}
