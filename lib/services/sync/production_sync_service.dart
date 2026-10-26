import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_errors.dart';
import 'package:panela_sys/services/sync/production_batch_uploader.dart';

/// Uno o más lotes fueron rechazados por el servidor (o ya no se pueden
/// subir) en la última sincronización. Quedan pendientes con su motivo en
/// `syncError`; los demás lotes y los controles se enviaron igual.
class ProductionBatchesRejectedException implements Exception {
  final int count;
  final String firstReason;
  const ProductionBatchesRejectedException(this.count, this.firstReason);

  @override
  String toString() => count == 1
      ? 'Un lote de producción no se pudo subir: $firstReason'
      : '$count lotes de producción no se pudieron subir. Primero: $firstReason';
}

/// Sync service for Production Batches
///
/// Sube los lotes pendientes con [ProductionBatchUploader] (una sola
/// llamada atómica e idempotente por lote).
///
///   - Sin señal: se detiene y relanza el error (se reintenta luego).
///   - Productor/parcela aún sin subir: se salta el lote por ahora.
///   - Rechazo del servidor o lote que ya no se puede armar: se guarda el
///     motivo en el lote y se sigue con los demás (no frena a nadie). Al
///     terminar, [rejectedCount] / [firstRejectionReason] lo informan.
class ProductionSyncService {
  final AppDatabase _db;
  final ProductionBatchUploader _uploader;

  int _rejectedCount = 0;
  String? _firstRejectionReason;

  ProductionSyncService(this._db) : _uploader = ProductionBatchUploader(_db);

  /// Lotes rechazados en la última llamada a [sync].
  int get rejectedCount => _rejectedCount;
  String? get firstRejectionReason => _firstRejectionReason;

  /// Sube los lotes pendientes de la cooperativa actual. Emite un evento por
  /// cada lote enviado.
  Stream<void> sync() async* {
    _rejectedCount = 0;
    _firstRejectionReason = null;

    final pending = await _db.productionBatchesDao.getPending(AppConfig.current.id);
    DebugLogger.info('ProductionSyncService', 'sync',
        'Lotes de producción pendientes: ${pending.length}');

    for (final batch in pending) {
      try {
        await _uploader.upload(batch);
      } on BatchDependencyPendingException catch (e) {
        DebugLogger.info('ProductionSyncService', 'sync',
            'Lote ${batch.batchCode} espera: $e');
        continue;
      } catch (e, st) {
        if (isTransientNetworkError(e)) {
          DebugLogger.warning('ProductionSyncService', 'sync',
              'Corte de señal enviando el lote ${batch.batchCode}; se reintentará: $e');
          rethrow;
        }
        final reason = _readableError(e);
        DebugLogger.error('ProductionSyncService', 'sync',
            'Lote ${batch.batchCode} rechazado: $reason', stackTrace: st);
        await _db.productionBatchesDao.markSyncRejected(batch.id, reason);
        _rejectedCount++;
        _firstRejectionReason ??= reason;
        continue;
      }
      yield null;
    }
  }

  static String _readableError(Object e) {
    if (e is PostgrestException) {
      if (e.code == '23505' && e.message.contains('batch_code')) {
        return 'ya existe otro lote con el mismo código';
      }
      return e.message;
    }
    if (e is StateError) return e.message;
    return e.toString().replaceAll('Exception: ', '');
  }
}
