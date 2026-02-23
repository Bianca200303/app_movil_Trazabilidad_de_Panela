import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/batch_temperatures_table.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'batch_temperatures_dao.g.dart';

@DriftAccessor(tables: [BatchTemperatures])
class BatchTemperaturesDao extends DatabaseAccessor<AppDatabase>
    with _$BatchTemperaturesDaoMixin {
  BatchTemperaturesDao(super.db);

  /// Get temperatures for a specific batch (by local ID)
  Future<List<BatchTemperatureLocal>> getByBatchLocalId(int batchLocalId) async {
    DebugLogger.debug('BatchTemperaturesDao', 'getByBatchLocalId',
        'Getting temperatures for batch $batchLocalId');

    return (select(batchTemperatures)
          ..where((t) => t.productionBatchLocalId.equals(batchLocalId))
          ..orderBy([(t) => OrderingTerm(expression: t.sequenceNumber)]))
        .get();
  }

  /// Get pending temperatures
  Future<List<BatchTemperatureLocal>> getPendingByBatchLocalId(
      int batchLocalId) async {
    return (select(batchTemperatures)
          ..where((t) => t.productionBatchLocalId.equals(batchLocalId))
          ..where((t) => t.syncStatus.equals(SyncStatus.pending.value)))
        .get();
  }

  /// Create batch of temperatures
  Future<void> createBatch(List<BatchTemperaturesCompanion> temps) async {
    DebugLogger.info('BatchTemperaturesDao', 'createBatch',
        'Creating ${temps.length} temperature records');

    await batch((batch) {
      batch.insertAll(batchTemperatures, temps);
    });

    DebugLogger.debug('BatchTemperaturesDao', 'createBatch',
        'Temperature records created');
  }

  /// Mark batch temperatures as synced
  Future<void> markBatchAsSynced(
    int batchLocalId,
    List<String> remoteIds,
  ) async {
    DebugLogger.info('BatchTemperaturesDao', 'markBatchAsSynced',
        'Marking ${remoteIds.length} temperatures as synced for batch $batchLocalId');

    final temps = await getByBatchLocalId(batchLocalId);

    if (temps.length != remoteIds.length) {
      throw Exception(
          'Remote IDs count mismatch: expected ${temps.length}, got ${remoteIds.length}');
    }

    // Update each temperature with its remote ID
    for (var i = 0; i < temps.length; i++) {
      await (update(batchTemperatures)
            ..where((t) => t.id.equals(temps[i].id)))
          .write(
        BatchTemperaturesCompanion(
          syncStatus: Value(SyncStatus.synced.value),
          remoteId: Value(remoteIds[i]),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }

    DebugLogger.debug('BatchTemperaturesDao', 'markBatchAsSynced',
        'Temperatures marked as synced');
  }

  /// Delete temperatures for a batch
  Future<void> deleteByBatchLocalId(int batchLocalId) async {
    await (delete(batchTemperatures)
          ..where((t) => t.productionBatchLocalId.equals(batchLocalId)))
        .go();
  }
}
