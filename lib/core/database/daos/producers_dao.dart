import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/producers_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/sync_status.dart';

part 'producers_dao.g.dart';

/// Data Access Object for Producers table
///
/// Provides type-safe queries and CRUD operations for producers
/// with comprehensive logging for debugging offline operations.
@DriftAccessor(tables: [Producers])
class ProducersDao extends DatabaseAccessor<AppDatabase>
    with _$ProducersDaoMixin {
  ProducersDao(super.db);

  /// Create a new producer in local database
  ///
  /// Logs all insert data for debugging. Returns local auto-increment ID.
  Future<int> create(ProducersCompanion producer) async {
    DebugLogger.info('ProducersDao', 'create',
        'Creando productor: ${producer.firstName.value} ${producer.lastName.value}');

    DebugLogger.debug(
        'ProducersDao',
        'create',
        'Insert data: firstName=${producer.firstName.value}, '
        'lastName=${producer.lastName.value}, '
        'dni=${producer.dni.value}, '
        'moduleId=${producer.coopModuleId.value}, '
        'cooperativeId=${producer.cooperativeId.value}, '
        'isMember=${producer.isMember.value}, '
        'appagropCode=${producer.appagropCode.value}, '
        'syncStatus=${producer.syncStatus.value}');

    final id = await into(producers).insert(producer);

    DebugLogger.debug('ProducersDao', 'create', 'Inserted with local ID: $id');
    DebugLogger.info(
        'ProducersDao', 'create', 'Productor creado exitosamente en DB local');

    return id;
  }

  /// Get all producers pending synchronization (ordered by creation date ASC)
  ///
  /// Returns producers with syncStatus = pending or modified.
  /// Orders by createdAt ascending (oldest first) for proper sync order.
  /// Logs each pending producer for debugging.
  Future<List<Producer>> getPending() async {
    DebugLogger.info('ProducersDao', 'getPending',
        'Obteniendo productores pendientes de sync (ordenados por createdAt ASC)');

    final query = select(producers)
      ..where((p) =>
          p.syncStatus.equals(SyncStatus.pending.value) |
          p.syncStatus.equals(SyncStatus.modified.value))
      ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]);

    final results = await query.get();

    DebugLogger.debug(
        'ProducersDao', 'getPending', 'Found ${results.length} pending producers');

    for (final producer in results) {
      DebugLogger.debug(
          'ProducersDao',
          'getPending',
          'Pending: localId=${producer.id}, dni=${producer.dni}, '
          'name=${producer.firstName} ${producer.lastName}, '
          'syncStatus=${producer.syncStatus}');
    }

    return results;
  }

  /// Count producers pending synchronization
  ///
  /// Returns count of producers with syncStatus = pending or modified.
  Future<int> countPending() async {
    DebugLogger.debug(
        'ProducersDao', 'countPending', 'Contando productores pendientes');

    final query = selectOnly(producers)
      ..addColumns([producers.id.count()])
      ..where(producers.syncStatus.equals(SyncStatus.pending.value) |
          producers.syncStatus.equals(SyncStatus.modified.value));

    final count = await query
            .map((row) => row.read(producers.id.count()))
            .getSingleOrNull() ??
        0;

    DebugLogger.debug('ProducersDao', 'countPending', 'Count: $count');

    return count;
  }

  /// Mark producer as synchronized
  ///
  /// Updates syncStatus to synced, stores remote ID, and records sync timestamp.
  /// Logs all update data for debugging.
  Future<void> markAsSynced({
    required int localId,
    required String remoteId,
  }) async {
    DebugLogger.info('ProducersDao', 'markAsSynced',
        'Marcando productor como sincronizado: localId=$localId, remoteId=$remoteId');

    final now = DateTime.now();

    DebugLogger.debug(
        'ProducersDao',
        'markAsSynced',
        'Update data: syncStatus=${SyncStatus.synced.value}, '
        'remoteId=$remoteId, '
        'syncedAt=$now');

    await (update(producers)..where((p) => p.id.equals(localId))).write(
      ProducersCompanion(
        syncStatus: Value(SyncStatus.synced.value),
        remoteId: Value(remoteId),
        syncedAt: Value(now),
      ),
    );

    DebugLogger.info('ProducersDao', 'markAsSynced',
        'Productor marcado como synced exitosamente');
  }

  /// Get producer by local ID
  ///
  /// Returns producer or null if not found. Logs result for debugging.
  Future<Producer?> getById(int id) async {
    DebugLogger.debug(
        'ProducersDao', 'getById', 'Buscando productor con ID: $id');

    final query = select(producers)..where((p) => p.id.equals(id));
    final result = await query.getSingleOrNull();

    if (result != null) {
      DebugLogger.debug('ProducersDao', 'getById',
          'Found: ${result.firstName} ${result.lastName} (${result.dni})');
    } else {
      DebugLogger.debug(
          'ProducersDao', 'getById', 'No producer found with ID: $id');
    }

    return result;
  }

  /// Get all producers from local database
  ///
  /// Returns all producers regardless of sync status. Logs count for debugging.
  Future<List<Producer>> getAll() async {
    DebugLogger.debug(
        'ProducersDao', 'getAll', 'Obteniendo todos los productores');

    final results = await select(producers).get();

    DebugLogger.debug(
        'ProducersDao', 'getAll', 'Found ${results.length} producers');

    return results;
  }

  /// Get producer by remote ID
  ///
  /// Returns producer matching remote Supabase ID, or null if not found.
  Future<Producer?> getByRemoteId(String remoteId) async {
    DebugLogger.debug('ProducersDao', 'getByRemoteId',
        'Buscando productor con remoteId: $remoteId');

    final query = select(producers)..where((p) => p.remoteId.equals(remoteId));
    final result = await query.getSingleOrNull();

    if (result != null) {
      DebugLogger.debug('ProducersDao', 'getByRemoteId',
          'Found: localId=${result.id}, ${result.firstName} ${result.lastName}');
    } else {
      DebugLogger.debug('ProducersDao', 'getByRemoteId',
          'No producer found with remoteId: $remoteId');
    }

    return result;
  }

  /// Get all synced producers
  ///
  /// Returns producers with syncStatus = synced and remoteId not null.
  Future<List<Producer>> getSynced() async {
    DebugLogger.debug(
        'ProducersDao', 'getSynced', 'Getting synced producers');

    final query = select(producers)
      ..where((p) =>
          p.syncStatus.equals(SyncStatus.synced.value) &
          p.remoteId.isNotNull())
      ..orderBy([(p) => OrderingTerm(expression: p.firstName)]);

    final results = await query.get();

    DebugLogger.debug('ProducersDao', 'getSynced',
        'Found ${results.length} synced producers');

    return results;
  }

  /// Cache producers from remote (for offline dropdown usage)
  ///
  /// Actualiza la copia local con la lista completa del servidor CONSERVANDO
  /// el id local de cada productor (se empareja por remoteId): los lotes y
  /// parcelas pendientes apuntan a ese id, y si se borrara y reinsertara el
  /// productor quedarían huérfanos y nunca se subirían.
  ///
  /// Los productores sincronizados que ya no vienen del servidor se borran,
  /// salvo que algún lote o parcela pendiente todavía los use.
  /// Los productores pendientes (sin subir) no se tocan.
  Future<void> cacheFromRemote(List<ProducersCompanion> remoteProducers) async {
    DebugLogger.info('ProducersDao', 'cacheFromRemote',
        'Caching ${remoteProducers.length} producers from remote');

    await transaction(() async {
      final existing = await (select(producers)
            ..where((p) => p.syncStatus.equals(SyncStatus.synced.value)))
          .get();

      // Un id local por remoteId; filas repetidas o sin remoteId sobran.
      final idByRemoteId = <String, int>{};
      final leftovers = <int>{};
      for (final row in existing) {
        final remoteId = row.remoteId;
        if (remoteId == null || idByRemoteId.containsKey(remoteId)) {
          leftovers.add(row.id);
        } else {
          idByRemoteId[remoteId] = row.id;
        }
      }

      final incomingRemoteIds = <String>{};
      for (final producer in remoteProducers) {
        final remoteId = producer.remoteId.value!;
        incomingRemoteIds.add(remoteId);
        final localId = idByRemoteId[remoteId];
        if (localId == null) {
          await into(producers).insert(producer);
        } else {
          await (update(producers)..where((p) => p.id.equals(localId))).write(producer);
        }
      }

      leftovers.addAll(idByRemoteId.entries
          .where((e) => !incomingRemoteIds.contains(e.key))
          .map((e) => e.value));
      final inUse = await _idsReferencedByPendingData(leftovers);
      final toDelete = leftovers.difference(inUse);
      if (toDelete.isNotEmpty) {
        await (delete(producers)..where((p) => p.id.isIn(toDelete))).go();
      }
    });

    DebugLogger.debug('ProducersDao', 'cacheFromRemote', 'Cache updated successfully');
  }

  /// De [candidateIds], los que todavía usa algún lote o parcela sin subir.
  Future<Set<int>> _idsReferencedByPendingData(Set<int> candidateIds) async {
    if (candidateIds.isEmpty) return {};
    final db = attachedDatabase;
    final synced = SyncStatus.synced.value;
    final batchRefs = await (db.select(db.productionBatches)
          ..where((b) =>
              b.producerLocalId.isIn(candidateIds) & b.syncStatus.equals(synced).not()))
        .map((b) => b.producerLocalId)
        .get();
    final plotRefs = await (db.select(db.plots)
          ..where((p) =>
              p.producerLocalId.isIn(candidateIds) & p.syncStatus.equals(synced).not()))
        .map((p) => p.producerLocalId)
        .get();
    return {...batchRefs, ...plotRefs};
  }

  /// Update a local producer's fields
  ///
  /// Used for editing pending producers (not yet synced) or updating
  /// the local cache after a successful Supabase update.
  Future<void> updateLocal({
    required int localId,
    required String firstName,
    required String lastName,
    required String coopModuleId,
    required bool isMember,
    String? appagropCode,
  }) async {
    DebugLogger.info('ProducersDao', 'updateLocal',
        'Actualizando productor local: localId=$localId');

    await (update(producers)..where((p) => p.id.equals(localId))).write(
      ProducersCompanion(
        firstName: Value(firstName),
        lastName: Value(lastName),
        coopModuleId: Value(coopModuleId),
        isMember: Value(isMember),
        appagropCode: Value(appagropCode),
      ),
    );

    DebugLogger.info('ProducersDao', 'updateLocal',
        'Productor local actualizado exitosamente');
  }

  /// Delete all synced producers (for cache cleanup)
  ///
  /// This preserves local pending producers while clearing cached remote data.
  Future<void> deleteSynced() async {
    DebugLogger.info('ProducersDao', 'deleteSynced',
        'Deleting synced producers from cache');

    final deleted = await (delete(producers)
          ..where((p) => p.syncStatus.equals(SyncStatus.synced.value)))
        .go();

    DebugLogger.debug('ProducersDao', 'deleteSynced',
        'Deleted $deleted synced producers');
  }
}
