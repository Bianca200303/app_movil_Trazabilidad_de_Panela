import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/production_batches_table.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'production_batches_dao.g.dart';

@DriftAccessor(tables: [ProductionBatches])
class ProductionBatchesDao extends DatabaseAccessor<AppDatabase>
    with _$ProductionBatchesDaoMixin {
  ProductionBatchesDao(super.db);

  /// Get all pending production batches (not synced yet) for a specific cooperative
  Future<List<ProductionBatchLocal>> getPending(String cooperativeId) async {
    DebugLogger.debug('ProductionBatchesDao', 'getPending',
        'Fetching pending production batches for coop: $cooperativeId');

    final pending = await (select(productionBatches)
          ..where((b) =>
              b.syncStatus.equals(SyncStatus.pending.value) &
              b.cooperativeId.equals(cooperativeId)))
        .get();

    DebugLogger.info('ProductionBatchesDao', 'getPending',
        'Found ${pending.length} pending batches');

    return pending;
  }

  /// Count pending production batches for a specific cooperative
  Future<int> countPending(String cooperativeId) async {
    final count = await (selectOnly(productionBatches)
          ..addColumns([productionBatches.id.count()])
          ..where(productionBatches.syncStatus.equals(SyncStatus.pending.value) &
              productionBatches.cooperativeId.equals(cooperativeId)))
        .getSingle();

    final pendingCount = count.read(productionBatches.id.count()) ?? 0;

    DebugLogger.debug('ProductionBatchesDao', 'countPending',
        'Pending count: $pendingCount');

    return pendingCount;
  }

  /// Create a new production batch locally
  Future<int> create(ProductionBatchesCompanion batch) async {
    DebugLogger.info('ProductionBatchesDao', 'create',
        'Creating production batch: ${batch.batchCode.value}');

    final id = await into(productionBatches).insert(batch);

    DebugLogger.info('ProductionBatchesDao', 'create',
        'Production batch created with local ID: $id');

    return id;
  }

  /// Mark production batch as synced
  Future<void> markAsSynced({
    required int localId,
    required String remoteId,
  }) async {
    DebugLogger.info('ProductionBatchesDao', 'markAsSynced',
        'Marking batch $localId as synced with remoteId: $remoteId');

    await (update(productionBatches)..where((b) => b.id.equals(localId))).write(
      ProductionBatchesCompanion(
        syncStatus: Value(SyncStatus.synced.value),
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
        syncError: const Value(null),
      ),
    );

    DebugLogger.debug('ProductionBatchesDao', 'markAsSynced',
        'Batch marked as synced');
  }

  /// Guarda el motivo por el que el servidor rechazó el lote. Sigue
  /// pendiente (se reintenta en cada sincronización) pero ya no frena a los
  /// demás.
  Future<void> markSyncRejected(int localId, String reason) async {
    await (update(productionBatches)..where((b) => b.id.equals(localId)))
        .write(ProductionBatchesCompanion(syncError: Value(reason)));
  }

  /// Asigna el id fijo del celular a un lote que no lo tenga (lotes de
  /// antes de la v13 que no pasaron por la migración) y lo devuelve. Se
  /// guarda ANTES de enviar: si se generara en cada intento, un reenvío
  /// tras un corte de señal duplicaría el lote en el servidor.
  Future<String> ensureClientId(ProductionBatchLocal batch, String Function() generate) async {
    final existing = batch.clientId;
    if (existing != null) return existing;
    final clientId = generate();
    await (update(productionBatches)..where((b) => b.id.equals(batch.id)))
        .write(ProductionBatchesCompanion(clientId: Value(clientId)));
    return clientId;
  }

  /// Get production batch by local ID
  Future<ProductionBatchLocal?> getById(int id) async {
    DebugLogger.debug('ProductionBatchesDao', 'getById',
        'Getting batch with ID: $id');

    return (select(productionBatches)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get production batch by remote ID
  Future<ProductionBatchLocal?> getByRemoteId(String remoteId) async {
    return (select(productionBatches)
          ..where((b) => b.remoteId.equals(remoteId)))
        .getSingleOrNull();
  }

  /// Get all production batches for historial (ordered by date)
  Future<List<ProductionBatchLocal>> getAllForHistorial() async {
    DebugLogger.debug('ProductionBatchesDao', 'getAllForHistorial',
        'Getting all batches for historial');

    return (select(productionBatches)
          ..orderBy([(b) => OrderingTerm.desc(b.processDate)]))
        .get();
  }

  /// Get all synced production batches
  Future<List<ProductionBatchLocal>> getSynced() async {
    return (select(productionBatches)
          ..where((b) => b.syncStatus.equals(SyncStatus.synced.value)))
        .get();
  }

  /// Delete production batch (for testing/cleanup)
  Future<void> deleteById(int id) async {
    DebugLogger.warning('ProductionBatchesDao', 'deleteById',
        'Deleting batch with ID: $id');

    await (delete(productionBatches)..where((b) => b.id.equals(id))).go();
  }
}
