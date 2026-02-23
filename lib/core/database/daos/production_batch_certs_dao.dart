import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/production_batch_certs_table.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'production_batch_certs_dao.g.dart';

@DriftAccessor(tables: [ProductionBatchCerts])
class ProductionBatchCertsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductionBatchCertsDaoMixin {
  ProductionBatchCertsDao(super.db);

  /// Get certificates for a specific batch (by local ID)
  Future<List<ProductionBatchCertLocal>> getByBatchLocalId(
      int batchLocalId) async {
    DebugLogger.debug('ProductionBatchCertsDao', 'getByBatchLocalId',
        'Getting certificates for batch $batchLocalId');

    return (select(productionBatchCerts)
          ..where((c) => c.productionBatchLocalId.equals(batchLocalId)))
        .get();
  }

  /// Get pending batch certificates
  Future<List<ProductionBatchCertLocal>> getPendingByBatchLocalId(
      int batchLocalId) async {
    return (select(productionBatchCerts)
          ..where((c) => c.productionBatchLocalId.equals(batchLocalId))
          ..where((c) => c.syncStatus.equals(SyncStatus.pending.value)))
        .get();
  }

  /// Create batch of certificates
  Future<void> createBatch(List<ProductionBatchCertsCompanion> certs) async {
    DebugLogger.info('ProductionBatchCertsDao', 'createBatch',
        'Creating ${certs.length} certificate records');

    await batch((batch) {
      batch.insertAll(productionBatchCerts, certs);
    });

    DebugLogger.debug('ProductionBatchCertsDao', 'createBatch',
        'Certificate records created');
  }

  /// Mark batch certificates as synced
  Future<void> markBatchAsSynced(
    int batchLocalId,
    List<String> remoteIds,
  ) async {
    DebugLogger.info('ProductionBatchCertsDao', 'markBatchAsSynced',
        'Marking ${remoteIds.length} certificates as synced for batch $batchLocalId');

    final certs = await getByBatchLocalId(batchLocalId);

    if (certs.length != remoteIds.length) {
      throw Exception(
          'Remote IDs count mismatch: expected ${certs.length}, got ${remoteIds.length}');
    }

    // Update each certificate with its remote ID
    for (var i = 0; i < certs.length; i++) {
      await (update(productionBatchCerts)
            ..where((c) => c.id.equals(certs[i].id)))
          .write(
        ProductionBatchCertsCompanion(
          syncStatus: Value(SyncStatus.synced.value),
          remoteId: Value(remoteIds[i]),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }

    DebugLogger.debug('ProductionBatchCertsDao', 'markBatchAsSynced',
        'Certificates marked as synced');
  }

  /// Delete certificates for a batch
  Future<void> deleteByBatchLocalId(int batchLocalId) async {
    await (delete(productionBatchCerts)
          ..where((c) => c.productionBatchLocalId.equals(batchLocalId)))
        .go();
  }
}
