import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/certified_workers_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'certified_workers_dao.g.dart';

@DriftAccessor(tables: [CertifiedWorkers])
class CertifiedWorkersDao extends DatabaseAccessor<AppDatabase>
    with _$CertifiedWorkersDaoMixin {
  CertifiedWorkersDao(super.db);

  /// Get cached workers of a module, ordered by last name
  Future<List<CertifiedWorkerLocal>> getByModule(String moduleId) async {
    DebugLogger.debug('CertifiedWorkersDao', 'getByModule',
        'Getting cached workers for module: $moduleId');

    return (select(certifiedWorkers)
          ..where((w) => w.coopModuleId.equals(moduleId))
          ..orderBy([(w) => OrderingTerm(expression: w.lastName)]))
        .get();
  }

  /// Replace the whole cache (login refresh). Only active workers are
  /// cached, so a deactivated worker disappears on the next refresh.
  Future<void> replaceAll(List<CertifiedWorkersCompanion> workers) async {
    DebugLogger.info('CertifiedWorkersDao', 'replaceAll',
        'Replacing cache with ${workers.length} workers');

    await transaction(() async {
      await delete(certifiedWorkers).go();
      await batch((b) => b.insertAll(certifiedWorkers, workers));
    });
  }

  /// Replace only one module's workers (after an online fetch of that module)
  Future<void> replaceModule(
      String moduleId, List<CertifiedWorkersCompanion> workers) async {
    await transaction(() async {
      await (delete(certifiedWorkers)
            ..where((w) => w.coopModuleId.equals(moduleId)))
          .go();
      await batch((b) => b.insertAll(certifiedWorkers, workers));
    });
  }

  /// Clear all cached workers
  Future<void> clear() async {
    DebugLogger.warning('CertifiedWorkersDao', 'clear',
        'Clearing all cached certified workers');

    await delete(certifiedWorkers).go();
  }
}
