import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:panela_sys/services/recent_batches_service.dart';
import 'package:panela_sys/services/sync/pending_submissions_service.dart';

/// Días con producción de un módulo (para elegir la fecha de un control),
/// con o sin señal.
///
/// Los lotes salen de RecentBatchesService (servidor, o su copia local de
/// los últimos 30 días, más los lotes creados en el celular sin enviar).
/// "Ya registrado" combina lo que hay en el servidor (si hay señal) con lo
/// guardado en el celular pendiente de envío.
class ProductionDatesService {
  final RecentBatchesService _batches;
  final PendingSubmissionsService _pending;

  ProductionDatesService({RecentBatchesService? batches, PendingSubmissionsService? pending})
      : _batches = batches ?? RecentBatchesService(),
        _pending = pending ?? PendingSubmissionsService();

  /// ¿Hubo producción en el módulo ese día? Sin señal responde con la copia
  /// local (últimos 30 días + lotes del celular).
  Future<bool> hasProductionOnDate(String moduleId, DateTime date) async {
    final batches = await _batches.getBatches(date, date, moduleIds: [moduleId]);
    return batches.isNotEmpty;
  }

  /// [kind] y [dateKey]: tipo de registro en la bandeja y la clave de su
  /// fecha en el payload (ej. 'chlorine_control' / 'control_date').
  /// [recordedOnServer]: fechas 'YYYY-MM-DD' ya registradas en el servidor
  /// para ese módulo y rango.
  Future<List<ProductionDateGroup>> groupsForModule({
    required String moduleId,
    required DateTime from,
    required DateTime to,
    required String kind,
    required String dateKey,
    required Future<Set<String>> Function() recordedOnServer,
  }) async {
    final batches = await _batches.getBatches(from, to, moduleIds: [moduleId]);

    final byDate = <String, ({int count, double panela})>{};
    for (final b in batches) {
      final date = b['process_date'] as String;
      final panela = (b['panela_kg'] as num?)?.toDouble() ?? 0.0;
      final current = byDate[date];
      byDate[date] = current == null
          ? (count: 1, panela: panela)
          : (count: current.count + 1, panela: current.panela + panela);
    }

    final recorded = <String>{
      for (final p in await _pending.pendingPayloads(kind))
        if (p['coop_module_id'] == moduleId) p[dateKey] as String,
    };
    if (await NetworkDetector().isConnected) {
      try {
        recorded.addAll(await recordedOnServer());
      } catch (e) {
        DebugLogger.warning('ProductionDatesService', 'groupsForModule',
            'No se pudieron consultar los registros del servidor ($kind): $e');
      }
    }

    return byDate.entries
        .map((e) => ProductionDateGroup(
              date: DateTime.parse(e.key),
              batchCount: e.value.count,
              totalPanelaKg: e.value.panela,
              alreadyRecorded: recorded.contains(e.key),
            ))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
