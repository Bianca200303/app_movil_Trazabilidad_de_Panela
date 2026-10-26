import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/pending_submissions_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'pending_submissions_dao.g.dart';

@DriftAccessor(tables: [PendingSubmissions])
class PendingSubmissionsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingSubmissionsDaoMixin {
  PendingSubmissionsDao(super.db);

  Future<void> insertSubmission(PendingSubmissionsCompanion submission) async {
    DebugLogger.info('PendingSubmissionsDao', 'insertSubmission',
        'Encolando ${submission.kind.value} ${submission.id.value}');
    await into(pendingSubmissions).insert(submission);
  }

  Future<PendingSubmissionLocal?> getById(String id) {
    return (select(pendingSubmissions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  /// Pendientes que la sesión actual puede enviar, en orden de creación.
  Future<List<PendingSubmissionLocal>> getSendable({
    required String cooperativeId,
    required String authUserId,
  }) {
    return (select(pendingSubmissions)
          ..where((s) =>
              s.cooperativeId.equals(cooperativeId) &
              s.createdByAuthUserId.equals(authUserId))
          ..orderBy([(s) => OrderingTerm(expression: s.createdAt)]))
        .get();
  }

  /// Pendientes de un tipo (ej. para mostrar qué falta enviar de un lote).
  Future<List<PendingSubmissionLocal>> getByKind(String kind, String cooperativeId) {
    return (select(pendingSubmissions)
          ..where((s) => s.kind.equals(kind) & s.cooperativeId.equals(cooperativeId))
          ..orderBy([(s) => OrderingTerm(expression: s.createdAt)]))
        .get();
  }

  /// Total en la bandeja, sin importar usuario: se usa para impedir cerrar
  /// sesión con registros sin enviar.
  Future<int> countAll() async {
    final countExp = pendingSubmissions.id.count();
    final query = selectOnly(pendingSubmissions)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> markAttemptFailed(String id, String error) async {
    final current = await getById(id);
    if (current == null) return;
    await (update(pendingSubmissions)..where((s) => s.id.equals(id))).write(
      PendingSubmissionsCompanion(
        attempts: Value(current.attempts + 1),
        lastError: Value(error),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  /// Envío confirmado por el servidor: el registro sale de la bandeja.
  Future<void> deleteById(String id) async {
    await (delete(pendingSubmissions)..where((s) => s.id.equals(id))).go();
  }

  /// Registros que esperan a un lote creado sin señal en este celular.
  Future<List<PendingSubmissionLocal>> getByProductionBatchLocalId(int batchLocalId) {
    return (select(pendingSubmissions)
          ..where((s) => s.productionBatchLocalId.equals(batchLocalId)))
        .get();
  }

  Future<void> deleteByProductionBatchLocalId(int batchLocalId) async {
    await (delete(pendingSubmissions)
          ..where((s) => s.productionBatchLocalId.equals(batchLocalId)))
        .go();
  }
}
