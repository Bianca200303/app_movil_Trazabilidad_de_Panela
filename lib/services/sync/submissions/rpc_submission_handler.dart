import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/services/sync/submissions/submission_handler.dart';

/// Arma los parámetros de la RPC a partir del registro guardado.
/// [productionBatchRemoteId] solo viene si el registro dependía de un lote
/// creado sin señal (ver SubmissionHandler.send).
typedef RpcParamsBuilder = Map<String, dynamic> Function(
  String id,
  Map<String, dynamic> payload,
  String? productionBatchRemoteId,
);

/// Envío de un control con cabecera + registros hijos mediante una RPC del
/// servidor que lo guarda todo junto (atómica) y usa el id del celular para
/// no duplicar un reenvío (idempotente, `ON CONFLICT (id) DO NOTHING`).
///
/// Para un control de UNA sola tabla usar TableInsertSubmissionHandler.
class RpcSubmissionHandler extends SubmissionHandler {
  @override
  final String kind;

  @override
  final String label;

  final String rpcName;
  final RpcParamsBuilder buildParams;

  const RpcSubmissionHandler({
    required this.kind,
    required this.label,
    required this.rpcName,
    required this.buildParams,
  });

  @override
  Future<void> send({
    required String id,
    required Map<String, dynamic> payload,
    String? productionBatchRemoteId,
  }) async {
    await Supabase.instance.client.rpc(
      rpcName,
      params: buildParams(id, payload, productionBatchRemoteId),
    );
  }
}
