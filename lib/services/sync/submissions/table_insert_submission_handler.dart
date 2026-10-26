import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/services/sync/submissions/submission_handler.dart';

/// Envío de un control que vive en UNA sola tabla (sin registros hijos).
///
/// Inserta la fila con el id generado en el celular usando
/// `INSERT ... ON CONFLICT (id) DO NOTHING` (upsert con ignoreDuplicates):
/// un reenvío no duplica, y no hace falta una RPC propia. Otras
/// restricciones (p. ej. UNIQUE de módulo+fecha+hora) siguen fallando
/// normalmente y el registro queda marcado como rechazado.
///
/// Para controles con cabecera + hijos usar RpcSubmissionHandler.
class TableInsertSubmissionHandler extends SubmissionHandler {
  final String table;

  @override
  final String kind;

  @override
  final String label;

  const TableInsertSubmissionHandler({
    required this.kind,
    required this.label,
    required this.table,
  });

  @override
  Future<void> send({
    required String id,
    required Map<String, dynamic> payload,
    String? productionBatchRemoteId,
  }) async {
    await Supabase.instance.client
        .from(table)
        .upsert({...payload, 'id': id}, onConflict: 'id', ignoreDuplicates: true);
  }
}
