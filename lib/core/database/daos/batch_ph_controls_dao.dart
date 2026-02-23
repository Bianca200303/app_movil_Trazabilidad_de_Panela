import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/batch_ph_controls_table.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'batch_ph_controls_dao.g.dart';

@DriftAccessor(tables: [BatchPhControls])
class BatchPhControlsDao extends DatabaseAccessor<AppDatabase>
    with _$BatchPhControlsDaoMixin {
  BatchPhControlsDao(super.db);

  /// Get pH control for a specific batch (by local ID)
  Future<BatchPhControlLocal?> getByBatchLocalId(int batchLocalId) async {
    DebugLogger.debug('BatchPhControlsDao', 'getByBatchLocalId',
        'Getting pH control for batch $batchLocalId');

    return (select(batchPhControls)
          ..where((p) => p.productionBatchLocalId.equals(batchLocalId)))
        .getSingleOrNull();
  }

  /// Get pending pH controls
  Future<List<BatchPhControlLocal>> getPending() async {
    return (select(batchPhControls)
          ..where((p) => p.syncStatus.equals(SyncStatus.pending.value)))
        .get();
  }

  /// Create pH control record
  Future<int> create(BatchPhControlsCompanion phControl) async {
    DebugLogger.info('BatchPhControlsDao', 'create',
        'Creating pH control for batch ${phControl.productionBatchLocalId.value}');

    final id = await into(batchPhControls).insert(phControl);

    DebugLogger.debug('BatchPhControlsDao', 'create',
        'pH control created with local ID: $id');

    return id;
  }

  /// Mark pH control as synced
  Future<void> markAsSynced({
    required int localId,
    required String remoteId,
  }) async {
    DebugLogger.info('BatchPhControlsDao', 'markAsSynced',
        'Marking pH control $localId as synced with remoteId: $remoteId');

    await (update(batchPhControls)..where((p) => p.id.equals(localId))).write(
      BatchPhControlsCompanion(
        syncStatus: Value(SyncStatus.synced.value),
        remoteId: Value(remoteId),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete pH control for a batch
  Future<void> deleteByBatchLocalId(int batchLocalId) async {
    await (delete(batchPhControls)
          ..where((p) => p.productionBatchLocalId.equals(batchLocalId)))
        .go();
  }
}
