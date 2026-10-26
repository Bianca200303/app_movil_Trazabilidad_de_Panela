import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/plots_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/sync_status.dart';

part 'plots_dao.g.dart';

/// Data Access Object for Plots table
///
/// Provides type-safe queries and CRUD operations for plots
/// with comprehensive logging and local code generation for offline operations.
@DriftAccessor(tables: [Plots])
class PlotsDao extends DatabaseAccessor<AppDatabase> with _$PlotsDaoMixin {
  PlotsDao(super.db);

  /// Create a new plot in local database
  ///
  /// Logs all insert data for debugging. Returns local auto-increment ID.
  Future<int> create(PlotsCompanion plot) async {
    DebugLogger.info('PlotsDao', 'create',
        'Creando parcela: ${plot.name.value} (${plot.code.value})');

    DebugLogger.debug(
        'PlotsDao',
        'create',
        'Insert data: name=${plot.name.value}, '
        'code=${plot.code.value}, '
        'producerLocalId=${plot.producerLocalId.value}, '
        'syncStatus=${plot.syncStatus.value}');

    final id = await into(plots).insert(plot);

    DebugLogger.debug('PlotsDao', 'create', 'Inserted with local ID: $id');
    DebugLogger.info(
        'PlotsDao', 'create', 'Parcela creada exitosamente en DB local');

    return id;
  }

  /// Generate next plot code for a producer
  ///
  /// Calculates code in format: DNI-{sequence}
  /// Example: "12345678-1", "12345678-2", etc.
  /// Logs calculation steps for debugging.
  Future<String> getNextCodeForProducer(int producerLocalId) async {
    DebugLogger.info('PlotsDao', 'getNextCodeForProducer',
        'Calculando próximo código para productor localId=$producerLocalId');

    // 1. Get producer DNI
    final producer = await db.producersDao.getById(producerLocalId);
    if (producer == null) {
      DebugLogger.error('PlotsDao', 'getNextCodeForProducer',
          'Producer not found: $producerLocalId');
      throw Exception('Producer not found: $producerLocalId');
    }

    DebugLogger.debug(
        'PlotsDao', 'getNextCodeForProducer', 'Producer DNI: ${producer.dni}');

    // 2. Count existing plots for this producer
    final query = selectOnly(plots)
      ..addColumns([plots.id.count()])
      ..where(plots.producerLocalId.equals(producerLocalId));

    final count = await query
            .map((row) => row.read(plots.id.count()))
            .getSingleOrNull() ??
        0;

    DebugLogger.debug(
        'PlotsDao', 'getNextCodeForProducer', 'Existing plots count: $count');

    // 3. Generate code: DNI-{sequence}
    final nextNumber = count + 1;
    final code = '${producer.dni}-$nextNumber';

    DebugLogger.info(
        'PlotsDao', 'getNextCodeForProducer', 'Generated code: $code');

    return code;
  }

  /// Get all plots for a specific producer
  ///
  /// Returns plots filtered by local producer ID. Logs results.
  Future<List<Plot>> getByProducerLocalId(int producerLocalId) async {
    DebugLogger.debug('PlotsDao', 'getByProducerLocalId',
        'Obteniendo parcelas para productor: $producerLocalId');

    final query = select(plots)
      ..where((p) => p.producerLocalId.equals(producerLocalId));

    final results = await query.get();

    DebugLogger.debug('PlotsDao', 'getByProducerLocalId',
        'Found ${results.length} plots for producer $producerLocalId');

    return results;
  }

  /// Get all plots pending synchronization (ordered by creation date ASC)
  ///
  /// Returns plots with syncStatus = pending or modified.
  /// Orders by createdAt ascending (oldest first) for proper sync order.
  /// Logs each pending plot for debugging.
  Future<List<Plot>> getPending() async {
    DebugLogger.info('PlotsDao', 'getPending',
        'Obteniendo parcelas pendientes de sync (ordenados por createdAt ASC)');

    final query = select(plots)
      ..where((p) =>
          p.syncStatus.equals(SyncStatus.pending.value) |
          p.syncStatus.equals(SyncStatus.modified.value))
      ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]);

    final results = await query.get();

    DebugLogger.debug(
        'PlotsDao', 'getPending', 'Found ${results.length} pending plots');

    for (final plot in results) {
      DebugLogger.debug(
          'PlotsDao',
          'getPending',
          'Pending: localId=${plot.id}, code=${plot.code}, '
          'name=${plot.name}, '
          'producerLocalId=${plot.producerLocalId}, '
          'syncStatus=${plot.syncStatus}');
    }

    return results;
  }

  /// Count plots pending synchronization
  ///
  /// Returns count of plots with syncStatus = pending or modified.
  Future<int> countPending() async {
    DebugLogger.debug('PlotsDao', 'countPending', 'Contando parcelas pendientes');

    final query = selectOnly(plots)
      ..addColumns([plots.id.count()])
      ..where(plots.syncStatus.equals(SyncStatus.pending.value) |
          plots.syncStatus.equals(SyncStatus.modified.value));

    final count =
        await query.map((row) => row.read(plots.id.count())).getSingleOrNull() ??
            0;

    DebugLogger.debug('PlotsDao', 'countPending', 'Count: $count');

    return count;
  }

  /// Mark plot as synchronized
  ///
  /// Updates syncStatus to synced, stores remote ID and remote producer ID,
  /// and records sync timestamp. Logs all update data for debugging.
  Future<void> markAsSynced({
    required int localId,
    required String remoteId,
    required String remoteProducerId,
  }) async {
    DebugLogger.info('PlotsDao', 'markAsSynced',
        'Marcando parcela como sincronizada: localId=$localId, remoteId=$remoteId');

    final now = DateTime.now();

    DebugLogger.debug(
        'PlotsDao',
        'markAsSynced',
        'Update data: syncStatus=${SyncStatus.synced.value}, '
        'remoteId=$remoteId, '
        'remoteProducerId=$remoteProducerId, '
        'syncedAt=$now');

    await (update(plots)..where((p) => p.id.equals(localId))).write(
      PlotsCompanion(
        syncStatus: Value(SyncStatus.synced.value),
        remoteId: Value(remoteId),
        remoteProducerId: Value(remoteProducerId),
        syncedAt: Value(now),
      ),
    );

    DebugLogger.info(
        'PlotsDao', 'markAsSynced', 'Parcela marcada como synced exitosamente');
  }

  /// Get plot by local ID
  ///
  /// Returns plot or null if not found. Logs result for debugging.
  Future<Plot?> getById(int id) async {
    DebugLogger.debug('PlotsDao', 'getById', 'Buscando parcela con ID: $id');

    final query = select(plots)..where((p) => p.id.equals(id));
    final result = await query.getSingleOrNull();

    if (result != null) {
      DebugLogger.debug('PlotsDao', 'getById',
          'Found: ${result.name} (${result.code})');
    } else {
      DebugLogger.debug('PlotsDao', 'getById', 'No plot found with ID: $id');
    }

    return result;
  }

  /// Get all plots from local database
  ///
  /// Returns all plots regardless of sync status. Logs count for debugging.
  Future<List<Plot>> getAll() async {
    DebugLogger.debug('PlotsDao', 'getAll', 'Obteniendo todas las parcelas');

    final results = await select(plots).get();

    DebugLogger.debug('PlotsDao', 'getAll', 'Found ${results.length} plots');

    return results;
  }

  /// Get plot by remote ID
  ///
  /// Returns plot matching remote Supabase ID, or null if not found.
  Future<Plot?> getByRemoteId(String remoteId) async {
    DebugLogger.debug('PlotsDao', 'getByRemoteId',
        'Buscando parcela con remoteId: $remoteId');

    final query = select(plots)..where((p) => p.remoteId.equals(remoteId));
    final result = await query.getSingleOrNull();

    if (result != null) {
      DebugLogger.debug('PlotsDao', 'getByRemoteId',
          'Found: localId=${result.id}, ${result.name} (${result.code})');
    } else {
      DebugLogger.debug(
          'PlotsDao', 'getByRemoteId', 'No plot found with remoteId: $remoteId');
    }

    return result;
  }

  /// Get synced plots for a specific producer (for dropdown)
  Future<List<Plot>> getSyncedByProducerLocalId(int producerLocalId) async {
    DebugLogger.debug('PlotsDao', 'getSyncedByProducerLocalId',
        'Getting synced plots for producer $producerLocalId');

    return (select(plots)
          ..where((p) => p.producerLocalId.equals(producerLocalId))
          ..where((p) => p.syncStatus.equals(SyncStatus.synced.value))
          ..where((p) => p.remoteId.isNotNull())
          ..orderBy([(p) => OrderingTerm(expression: p.name)]))
        .get();
  }

  /// Get all synced plots (for caching)
  Future<List<Plot>> getAllSynced() async {
    DebugLogger.debug('PlotsDao', 'getAllSynced', 'Getting all synced plots');

    return (select(plots)
          ..where((p) => p.syncStatus.equals(SyncStatus.synced.value))
          ..where((p) => p.remoteId.isNotNull()))
        .get();
  }

  /// Cache plots from remote (for offline dropdown usage)
  ///
  /// Actualiza la copia local CONSERVANDO el id local de cada parcela (se
  /// empareja por remoteId): los lotes pendientes apuntan a ese id, y si se
  /// borrara y reinsertara la parcela quedarían huérfanos.
  ///
  /// [remotePlots] es la lista completa del servidor, o solo las parcelas de
  /// un productor si se indica [onlyForRemoteProducerId]; en ese caso solo
  /// se depuran las parcelas de ese productor y las demás no se tocan.
  /// Las parcelas sincronizadas que ya no vienen del servidor se borran,
  /// salvo que algún lote pendiente todavía las use. Las parcelas pendientes
  /// (sin subir) no se tocan.
  Future<void> cacheFromRemote(
    List<PlotsCompanion> remotePlots, {
    String? onlyForRemoteProducerId,
  }) async {
    DebugLogger.info('PlotsDao', 'cacheFromRemote',
        'Caching ${remotePlots.length} plots from remote'
        '${onlyForRemoteProducerId != null ? ' (producer $onlyForRemoteProducerId)' : ''}');

    await transaction(() async {
      final query = select(plots)
        ..where((p) => p.syncStatus.equals(SyncStatus.synced.value));
      if (onlyForRemoteProducerId != null) {
        query.where((p) => p.remoteProducerId.equals(onlyForRemoteProducerId));
      }
      final existing = await query.get();

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
      for (final plot in remotePlots) {
        final remoteId = plot.remoteId.value!;
        incomingRemoteIds.add(remoteId);
        final localId = idByRemoteId[remoteId] ??
            // Parcela ya guardada pero fuera del alcance de la consulta
            // (p. ej. cambió de productor): se actualiza en su lugar.
            (await (select(plots)
                      ..where((p) =>
                          p.remoteId.equals(remoteId) &
                          p.syncStatus.equals(SyncStatus.synced.value))
                      ..limit(1))
                    .getSingleOrNull())
                ?.id;
        if (localId == null) {
          await into(plots).insert(plot);
        } else {
          await (update(plots)..where((p) => p.id.equals(localId))).write(plot);
        }
      }

      leftovers.addAll(idByRemoteId.entries
          .where((e) => !incomingRemoteIds.contains(e.key))
          .map((e) => e.value));
      final inUse = await _idsReferencedByPendingBatches(leftovers);
      final toDelete = leftovers.difference(inUse);
      if (toDelete.isNotEmpty) {
        await (delete(plots)..where((p) => p.id.isIn(toDelete))).go();
      }
    });

    DebugLogger.debug('PlotsDao', 'cacheFromRemote', 'Cache updated successfully');
  }

  /// De [candidateIds], los que todavía usa algún lote sin subir.
  Future<Set<int>> _idsReferencedByPendingBatches(Set<int> candidateIds) async {
    if (candidateIds.isEmpty) return {};
    final db = attachedDatabase;
    final refs = await (db.select(db.productionBatches)
          ..where((b) =>
              b.plotLocalId.isIn(candidateIds) &
              b.syncStatus.equals(SyncStatus.synced.value).not()))
        .map((b) => b.plotLocalId)
        .get();
    return refs.whereType<int>().toSet();
  }

  /// Update a local plot's name
  ///
  /// Used for editing pending plots (not yet synced) or updating
  /// the local cache after a successful Supabase update.
  Future<void> updateLocal({
    required int localId,
    required String name,
  }) async {
    DebugLogger.info('PlotsDao', 'updateLocal',
        'Actualizando parcela local: localId=$localId, name=$name');

    await (update(plots)..where((p) => p.id.equals(localId))).write(
      PlotsCompanion(name: Value(name)),
    );

    DebugLogger.info('PlotsDao', 'updateLocal',
        'Parcela local actualizada exitosamente');
  }

  /// Delete all synced plots (for cache cleanup)
  ///
  /// This preserves local pending plots while clearing cached remote data.
  Future<void> deleteSynced() async {
    DebugLogger.info('PlotsDao', 'deleteSynced',
        'Deleting synced plots from cache');

    final deleted = await (delete(plots)
          ..where((p) => p.syncStatus.equals(SyncStatus.synced.value)))
        .go();

    DebugLogger.debug('PlotsDao', 'deleteSynced',
        'Deleted $deleted synced plots');
  }
}
