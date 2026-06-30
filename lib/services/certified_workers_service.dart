import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/models/certified_worker.dart';

class CertifiedWorkersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retorna los trabajadores certificados activos de un módulo.
  ///
  /// Retorna lista vacía si no hay conexión o si el módulo no tiene
  /// trabajadores configurados — la UI decide si mostrar fallback a texto libre.
  Future<List<CertifiedWorker>> getByModule(String moduleId) async {
    DebugLogger.info(
      'CertifiedWorkersService',
      'getByModule',
      'Cargando trabajadores para módulo: $moduleId',
    );

    final isConnected = await NetworkDetector().isConnected;
    if (!isConnected) {
      DebugLogger.warning(
        'CertifiedWorkersService',
        'getByModule',
        'Sin conexión — retornando lista vacía',
      );
      return [];
    }

    try {
      final response = await _supabase
          .from('certified_workers')
          .select('id, first_name, last_name, position')
          .eq('cooperative_id', AppConfig.current.id)
          .eq('coop_module_id', moduleId)
          .eq('is_active', true)
          .order('last_name', ascending: true);

      final workers = (response as List)
          .map((json) => CertifiedWorker.fromJson(json as Map<String, dynamic>))
          .toList();

      DebugLogger.info(
        'CertifiedWorkersService',
        'getByModule',
        'Trabajadores encontrados: ${workers.length}',
      );

      return workers;
    } catch (e, st) {
      DebugLogger.error(
        'CertifiedWorkersService',
        'getByModule',
        'Error al cargar trabajadores: $e',
        stackTrace: st,
      );
      return [];
    }
  }
}
