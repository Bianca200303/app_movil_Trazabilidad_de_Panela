import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/cached_production_batches_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'cached_production_batches_dao.g.dart';

@DriftAccessor(tables: [CachedProductionBatches])
class CachedProductionBatchesDao extends DatabaseAccessor<AppDatabase>
    with _$CachedProductionBatchesDaoMixin {
  CachedProductionBatchesDao(super.db);

  /// Lotes con fecha de proceso dentro de [fromDate]..[toDate]
  /// ('YYYY-MM-DD', inclusive), opcionalmente solo de ciertos módulos.
  Future<List<CachedProductionBatchLocal>> getByRange({
    required String fromDate,
    required String toDate,
    List<String>? moduleIds,
  }) {
    final query = select(cachedProductionBatches)
      ..where((b) =>
          b.processDate.isBiggerOrEqualValue(fromDate) &
          b.processDate.isSmallerOrEqualValue(toDate))
      ..orderBy([(b) => OrderingTerm(expression: b.processDate, mode: OrderingMode.desc)]);
    if (moduleIds != null && moduleIds.isNotEmpty) {
      query.where((b) => b.coopModuleId.isIn(moduleIds));
    }
    return query.get();
  }

  /// Reemplaza la copia completa (al iniciar sesión).
  Future<void> replaceAll(List<CachedProductionBatchesCompanion> batches) async {
    DebugLogger.info('CachedProductionBatchesDao', 'replaceAll',
        'Reemplazando copia local con ${batches.length} lotes');
    await transaction(() async {
      await delete(cachedProductionBatches).go();
      await batch((b) => b.insertAll(cachedProductionBatches, batches));
    });
  }

  /// Agrega/actualiza lotes (tras una consulta con señal) y descarta los que
  /// ya quedaron fuera de la ventana de días.
  Future<void> upsertAndPrune(
    List<CachedProductionBatchesCompanion> batches, {
    required String oldestDateToKeep,
  }) async {
    await transaction(() async {
      await batch((b) => b.insertAllOnConflictUpdate(cachedProductionBatches, batches));
      await (delete(cachedProductionBatches)
            ..where((b) => b.processDate.isSmallerThanValue(oldestDateToKeep)))
          .go();
    });
  }

  Future<void> clear() async {
    await delete(cachedProductionBatches).go();
  }
}
