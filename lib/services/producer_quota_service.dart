import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/producer_quota_status.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

/// Servicio para verificar el estado de cupos de productores.
///
/// Llama al RPC get_producer_quota_statuses en Supabase.
/// No usa cache local (Drift) porque el acumulado cambia con cada registro
/// y debe reflejar el estado real del servidor.
class ProducerQuotaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Verifica el estado de cupos de un productor para una fecha de proceso.
  ///
  /// [producerId]  — id del productor seleccionado en el formulario.
  /// [processDate] — fecha del lote a registrar (no necesariamente hoy).
  ///                 Determina qué campaña aplica.
  ///
  /// Retorna [QuotaCheckResult.offline] si no hay conexión → la UI muestra
  /// un aviso suave sin bloquear el flujo.
  /// Retorna [QuotaCheckResult.empty] si el productor no tiene cupos
  /// configurados para esa fecha → la UI no muestra alerta.
  Future<QuotaCheckResult> getQuotaStatuses({
    required String producerId,
    required DateTime processDate,
  }) async {
    DebugLogger.info(
      'ProducerQuotaService',
      'getQuotaStatuses',
      'Verificando cupos para productor: $producerId, fecha: ${processDate.toIso8601String().split('T')[0]}',
    );

    final isConnected = await NetworkDetector().isConnected;
    if (!isConnected) {
      DebugLogger.warning(
        'ProducerQuotaService',
        'getQuotaStatuses',
        'Sin conexión — omitiendo verificación de cupo',
      );
      return QuotaCheckResult.offline;
    }

    try {
      final response = await _supabase.rpc(
        'get_producer_quota_statuses',
        params: {
          'p_producer_id':  producerId,
          'p_process_date': processDate.toIso8601String().split('T')[0],
        },
      );

      final statuses = (response as List)
          .map((json) => ProducerQuotaStatus.fromJson(json as Map<String, dynamic>))
          .toList();

      DebugLogger.info(
        'ProducerQuotaService',
        'getQuotaStatuses',
        'Cupos encontrados: ${statuses.length}',
      );

      return QuotaCheckResult(statuses: statuses);
    } catch (e, st) {
      DebugLogger.error(
        'ProducerQuotaService',
        'getQuotaStatuses',
        'Error al verificar cupos: $e',
        stackTrace: st,
      );
      // Ante un error inesperado devolvemos vacío para no bloquear el flujo.
      // El técnico puede registrar sin alerta; el admin revisará en Supabase.
      return QuotaCheckResult.empty;
    }
  }
}
