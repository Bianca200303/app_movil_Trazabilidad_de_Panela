import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/production_batch_harvest_dates_table.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'production_batch_harvest_dates_dao.g.dart';

@DriftAccessor(tables: [ProductionBatchHarvestDates])
class ProductionBatchHarvestDatesDao extends DatabaseAccessor<AppDatabase>
    with _$ProductionBatchHarvestDatesDaoMixin {
  ProductionBatchHarvestDatesDao(super.db);

  /// Get additional harvest dates for a specific batch (by local ID)
  Future<List<ProductionBatchHarvestDateLocal>> getByBatchLocalId(
      int batchLocalId) async {
    DebugLogger.debug('ProductionBatchHarvestDatesDao', 'getByBatchLocalId',
        'Getting harvest dates for batch $batchLocalId');

    return (select(productionBatchHarvestDates)
          ..where((t) => t.productionBatchLocalId.equals(batchLocalId))
          ..orderBy([(t) => OrderingTerm(expression: t.harvestDate)]))
        .get();
  }

  /// Create batch of harvest dates
  Future<void> createBatch(
      List<ProductionBatchHarvestDatesCompanion> dates) async {
    DebugLogger.info('ProductionBatchHarvestDatesDao', 'createBatch',
        'Creating ${dates.length} harvest date records');

    await batch((batch) {
      batch.insertAll(productionBatchHarvestDates, dates);
    });

    DebugLogger.debug('ProductionBatchHarvestDatesDao', 'createBatch',
        'Harvest date records created');
  }

  /// Mark batch harvest dates as synced
  Future<void> markBatchAsSynced(
    int batchLocalId,
    List<String> remoteIds,
  ) async {
    DebugLogger.info('ProductionBatchHarvestDatesDao', 'markBatchAsSynced',
        'Marking ${remoteIds.length} harvest dates as synced for batch $batchLocalId');

    final dates = await getByBatchLocalId(batchLocalId);

    if (dates.length != remoteIds.length) {
      throw Exception(
          'Remote IDs count mismatch: expected ${dates.length}, got ${remoteIds.length}');
    }

    for (var i = 0; i < dates.length; i++) {
      await (update(productionBatchHarvestDates)
            ..where((t) => t.id.equals(dates[i].id)))
          .write(
        ProductionBatchHarvestDatesCompanion(
          syncStatus: Value(SyncStatus.synced.value),
          remoteId: Value(remoteIds[i]),
          syncedAt: Value(DateTime.now()),
        ),
      );
    }

    DebugLogger.debug('ProductionBatchHarvestDatesDao', 'markBatchAsSynced',
        'Harvest dates marked as synced');
  }

  /// Delete harvest dates for a batch
  Future<void> deleteByBatchLocalId(int batchLocalId) async {
    await (delete(productionBatchHarvestDates)
          ..where((t) => t.productionBatchLocalId.equals(batchLocalId)))
        .go();
  }
}
