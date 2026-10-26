/// Envío al servidor de un tipo de registro guardado en la bandeja de
/// pendientes (pending_submissions).
///
/// Para sumar un control nuevo al modo sin conexión: implementar esta clase
/// (con su RPC idempotente en el servidor) y registrarla en
/// submission_registry.dart. El resto (bandeja, reintentos, contador,
/// sincronización automática) ya lo resuelve PendingSubmissionsService.
abstract class SubmissionHandler {
  const SubmissionHandler();

  /// Identificador del tipo, guardado en pending_submissions.kind.
  String get kind;

  /// Nombre para mostrar al usuario (ej. en la lista de pendientes).
  String get label;

  /// Envía el registro. DEBE ser idempotente respecto de [id]: si el
  /// servidor ya lo tiene (reenvío tras un corte), no debe duplicarlo.
  ///
  /// [productionBatchRemoteId] viene resuelto cuando el registro dependía de
  /// un lote creado sin señal en este celular; si no, es null y el id del
  /// lote (si aplica) ya está en [payload].
  Future<void> send({
    required String id,
    required Map<String, dynamic> payload,
    String? productionBatchRemoteId,
  });
}
