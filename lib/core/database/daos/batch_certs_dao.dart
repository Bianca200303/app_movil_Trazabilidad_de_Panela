import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/batch_certs_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'batch_certs_dao.g.dart';

@DriftAccessor(tables: [BatchCerts])
class BatchCertsDao extends DatabaseAccessor<AppDatabase>
    with _$BatchCertsDaoMixin {
  BatchCertsDao(super.db);

  /// Get all active batch certificates
  Future<List<BatchCertLocal>> getAll() async {
    DebugLogger.debug('BatchCertsDao', 'getAll',
        'Getting all cached batch certificates');

    return (select(batchCerts)
          ..where((c) => c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm(expression: c.name)]))
        .get();
  }

  /// Get batch certificate by ID
  Future<BatchCertLocal?> getById(String id) async {
    return (select(batchCerts)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Upsert batch of certificates (for caching)
  Future<void> upsertBatch(List<BatchCertsCompanion> certs) async {
    DebugLogger.info('BatchCertsDao', 'upsertBatch',
        'Upserting ${certs.length} certificates to cache');

    await batch((batch) {
      batch.insertAllOnConflictUpdate(batchCerts, certs);
    });

    DebugLogger.debug('BatchCertsDao', 'upsertBatch', 'Cache updated');
  }

  /// Clear all cached certificates
  Future<void> clear() async {
    DebugLogger.warning('BatchCertsDao', 'clear',
        'Clearing all cached certificates');

    await delete(batchCerts).go();
  }

  /// Get certificates by exclusion group
  Future<List<BatchCertLocal>> getByExclusionGroup(String groupId) async {
    return (select(batchCerts)
          ..where((c) => c.exclusionGroupId.equals(groupId))
          ..where((c) => c.isActive.equals(true)))
        .get();
  }

  /// Get default certificates
  Future<List<BatchCertLocal>> getDefaults() async {
    return (select(batchCerts)
          ..where((c) => c.isDefault.equals(true))
          ..where((c) => c.isActive.equals(true)))
        .get();
  }
}
