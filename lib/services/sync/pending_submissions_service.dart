import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/network_errors.dart';
import 'package:panela_sys/core/utils/uuid_v4.dart';
import 'package:panela_sys/services/sync/submissions/submission_handler.dart';
import 'package:panela_sys/services/sync/submissions/submission_registry.dart';

/// Resultado de guardar un registro desde un formulario.
enum SubmissionOutcome {
  /// Confirmado por el servidor.
  sent,

  /// Guardado en el celular; se enviará solo al volver la señal.
  queued,
}

extension SubmissionOutcomeMessage on SubmissionOutcome {
  /// Mensaje para el usuario tras guardar: [sentMessage] si ya llegó al
  /// servidor, o el aviso de que quedó en el celular.
  String message(String sentMessage) => this == SubmissionOutcome.queued
      ? 'Guardado en el celular. Se enviará cuando haya conexión.'
      : sentMessage;
}

/// Uno o más registros fueron rechazados por el servidor durante la
/// sincronización. Siguen en la bandeja (se reintentan) y el usuario puede
/// verlos o descartarlos desde la lista de pendientes.
class PendingSubmissionsRejectedException implements Exception {
  final int count;
  final String firstError;

  const PendingSubmissionsRejectedException(this.count, this.firstError);

  @override
  String toString() =>
      '$count registro(s) no se pudieron enviar. Primer error: $firstError';
}

/// Bandeja de registros pendientes de envío (controles guardados sin señal).
///
/// Flujo único para todos los controles, con o sin señal:
///   1. [enqueue]: se guarda en el celular con un id generado aquí.
///   2. [trySendNow]: si hay señal se envía en el momento.
///   3. [sync]: lo pendiente se envía en la sincronización (automática al
///      volver la señal, o con el botón de sincronizar).
/// El envío es idempotente por id (ver SubmissionHandler), así que un
/// reintento tras un corte nunca duplica el registro.
class PendingSubmissionsService {
  final AppDatabase _db;

  static const _sendTimeout = Duration(seconds: 20);

  PendingSubmissionsService({AppDatabase? db}) : _db = db ?? AppDatabase();

  String? get _authUserId => Supabase.instance.client.auth.currentUser?.id;

  /// Guarda el registro en la bandeja y devuelve su id.
  Future<String> enqueue({
    required String kind,
    required Map<String, dynamic> payload,
    int? productionBatchLocalId,
  }) async {
    if (!submissionHandlers.containsKey(kind)) {
      throw ArgumentError('Tipo de registro sin manejador de envío: $kind');
    }
    final authUserId = _authUserId;
    if (authUserId == null) {
      throw StateError('No hay una sesión iniciada');
    }

    final id = generateUuidV4();
    await _db.pendingSubmissionsDao.insertSubmission(
      PendingSubmissionsCompanion.insert(
        id: id,
        kind: kind,
        payload: jsonEncode(payload),
        cooperativeId: AppConfig.current.id,
        createdByAuthUserId: authUserId,
        productionBatchLocalId: Value(productionBatchLocalId),
      ),
    );
    return id;
  }

  /// Guarda el registro y, si hay señal, lo envía en el momento. Es lo que
  /// usan los formularios: [enqueue] + [trySendNow].
  Future<SubmissionOutcome> submit({
    required String kind,
    required Map<String, dynamic> payload,
    int? productionBatchLocalId,
  }) async {
    final id = await enqueue(
      kind: kind,
      payload: payload,
      productionBatchLocalId: productionBatchLocalId,
    );
    return trySendNow(id);
  }

  /// Datos de los registros de un tipo que siguen en la bandeja.
  Future<List<Map<String, dynamic>>> pendingPayloads(String kind) async {
    final rows = await _db.pendingSubmissionsDao.getByKind(kind, AppConfig.current.id);
    return rows.map((r) => jsonDecode(r.payload) as Map<String, dynamic>).toList();
  }

  /// Para los avisos de "ya hay un registro este día": consulta el servidor
  /// (si hay señal) y además lo guardado en el celular sin enviar.
  ///
  /// Sin señal, o si la consulta falla, solo se mira lo pendiente: el aviso
  /// es orientativo y no debe impedir registrar en campo.
  Future<bool> existsOnServerOrPending({
    required Future<bool> Function() serverCheck,
    required String kind,
    required bool Function(Map<String, dynamic> payload) matches,
  }) async {
    if ((await pendingPayloads(kind)).any(matches)) return true;
    if (!await NetworkDetector().isConnected) return false;
    try {
      return await serverCheck().timeout(_sendTimeout);
    } catch (e) {
      DebugLogger.warning('PendingSubmissionsService', 'existsOnServerOrPending',
          'No se pudo consultar el servidor ($kind), se omite: $e');
      return false;
    }
  }

  /// Intenta enviar ya un registro recién encolado.
  ///
  /// - Sin señal (o se corta durante el envío): queda en la bandeja → queued.
  /// - Depende de un lote aún no enviado: queda en la bandeja → queued.
  /// - Rechazado por el servidor: se quita de la bandeja y se relanza el
  ///   error, para que el usuario lo corrija en el mismo formulario (igual
  ///   que antes, cuando se enviaba directo).
  Future<SubmissionOutcome> trySendNow(String id) async {
    if (!await NetworkDetector().isConnected) return SubmissionOutcome.queued;

    final row = await _db.pendingSubmissionsDao.getById(id);
    if (row == null) return SubmissionOutcome.sent;

    try {
      final sent = await _send(row);
      return sent ? SubmissionOutcome.sent : SubmissionOutcome.queued;
    } catch (e) {
      if (isTransientNetworkError(e)) return SubmissionOutcome.queued;
      await _db.pendingSubmissionsDao.deleteById(id);
      rethrow;
    }
  }

  /// Envía todo lo pendiente de la sesión actual. Emite un evento por cada
  /// registro enviado (para la barra de progreso de SyncService).
  ///
  /// Un registro rechazado no frena a los demás: se marca con su error y,
  /// al final, se lanza [PendingSubmissionsRejectedException]. Si se corta
  /// la señal, se detiene y lanza el error de red (se reintenta luego).
  Stream<void> sync() async* {
    final authUserId = _authUserId;
    if (authUserId == null) return;

    final rows = await _db.pendingSubmissionsDao.getSendable(
      cooperativeId: AppConfig.current.id,
      authUserId: authUserId,
    );
    DebugLogger.info('PendingSubmissionsService', 'sync',
        'Registros pendientes de envío: ${rows.length}');

    var rejected = 0;
    String? firstError;

    for (final row in rows) {
      try {
        if (await _send(row)) yield null;
      } catch (e, st) {
        if (isTransientNetworkError(e)) {
          DebugLogger.warning('PendingSubmissionsService', 'sync',
              'Corte de señal enviando ${row.id}; se reintentará: $e');
          rethrow;
        }
        DebugLogger.error('PendingSubmissionsService', 'sync',
            'Rechazado ${row.kind} ${row.id}: $e', stackTrace: st);
        final message = _readableError(e);
        await _db.pendingSubmissionsDao.markAttemptFailed(row.id, message);
        rejected++;
        firstError ??= message;
      }
    }

    if (rejected > 0) {
      throw PendingSubmissionsRejectedException(rejected, firstError!);
    }
  }

  /// Quita un registro de la bandeja sin enviarlo (decisión del usuario,
  /// p. ej. uno rechazado que ya no se puede corregir).
  Future<void> discard(String id) => _db.pendingSubmissionsDao.deleteById(id);

  /// Envía una fila. Devuelve false si todavía no se puede enviar porque
  /// depende de un lote creado sin señal que aún no se sincronizó.
  Future<bool> _send(PendingSubmissionLocal row) async {
    final handler = submissionHandlers[row.kind];
    if (handler == null) {
      throw StateError('Tipo de registro sin manejador de envío: ${row.kind}');
    }

    String? batchRemoteId;
    if (row.productionBatchLocalId != null) {
      batchRemoteId = await _resolveBatchRemoteId(row.productionBatchLocalId!);
      if (batchRemoteId == null) {
        DebugLogger.info('PendingSubmissionsService', '_send',
            '${row.id} espera a que se envíe el lote local ${row.productionBatchLocalId}');
        return false;
      }
    }

    await _sendWith(handler, row, batchRemoteId).timeout(_sendTimeout);
    await _db.pendingSubmissionsDao.deleteById(row.id);
    DebugLogger.info('PendingSubmissionsService', '_send', 'Enviado ${row.kind} ${row.id}');
    return true;
  }

  Future<void> _sendWith(
    SubmissionHandler handler,
    PendingSubmissionLocal row,
    String? batchRemoteId,
  ) {
    return handler.send(
      id: row.id,
      payload: jsonDecode(row.payload) as Map<String, dynamic>,
      productionBatchRemoteId: batchRemoteId,
    );
  }

  /// Id del servidor de un lote creado en este celular, o null si aún no se
  /// envió. Si el lote no existe o quedó marcado como duplicado, el
  /// registro no se puede vincular y se rechaza.
  Future<String?> _resolveBatchRemoteId(int localId) async {
    final batch = await _db.productionBatchesDao.getById(localId);
    if (batch == null) {
      throw StateError('El lote local $localId ya no existe en el celular');
    }
    final remoteId = batch.remoteId;
    if (remoteId == null) return null;
    if (remoteId.startsWith('DUPLICATE_')) {
      throw StateError(
          'El lote ${batch.batchCode} ya existía en el servidor y no se pudo vincular');
    }
    return remoteId;
  }

  String _readableError(Object e) {
    if (e is PostgrestException) return e.message;
    if (e is StateError) return e.message;
    return e.toString();
  }
}
