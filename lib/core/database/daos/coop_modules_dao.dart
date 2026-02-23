import 'package:drift/drift.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/coop_modules_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

part 'coop_modules_dao.g.dart';

/// Data Access Object for cooperative modules cache
///
/// Manages local storage of cooperative modules for offline form usage.
/// These are reference data that get refreshed on login.
@DriftAccessor(tables: [CoopModules])
class CoopModulesDao extends DatabaseAccessor<AppDatabase>
    with _$CoopModulesDaoMixin {
  CoopModulesDao(super.db);

  /// Get all modules from local cache
  Future<List<CoopModuleLocal>> getAll() async {
    DebugLogger.debug('CoopModulesDao', 'getAll', 'Fetching all modules from cache');

    final modules = await select(coopModules).get();

    DebugLogger.info('CoopModulesDao', 'getAll', 'Found ${modules.length} modules in cache');
    return modules;
  }

  /// Get only active modules from local cache
  Future<List<CoopModuleLocal>> getActive() async {
    DebugLogger.debug('CoopModulesDao', 'getActive', 'Fetching active modules from cache');

    final modules = await (select(coopModules)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

    DebugLogger.info('CoopModulesDao', 'getActive', 'Found ${modules.length} active modules in cache');
    return modules;
  }

  /// Insert or update a single module
  Future<void> upsert(CoopModulesCompanion module) async {
    DebugLogger.debug('CoopModulesDao', 'upsert', 'Upserting module: ${module.name.value}');

    await into(coopModules).insertOnConflictUpdate(module);

    DebugLogger.info('CoopModulesDao', 'upsert', 'Module upserted successfully');
  }

  /// Insert or update multiple modules (batch operation)
  Future<void> upsertBatch(List<CoopModulesCompanion> modules) async {
    DebugLogger.info('CoopModulesDao', 'upsertBatch', 'Upserting ${modules.length} modules');

    await batch((batch) {
      batch.insertAllOnConflictUpdate(coopModules, modules);
    });

    DebugLogger.info('CoopModulesDao', 'upsertBatch', 'Batch upsert completed');
  }

  /// Clear all modules from cache
  Future<void> clear() async {
    DebugLogger.info('CoopModulesDao', 'clear', 'Clearing all modules from cache');

    final deletedCount = await delete(coopModules).go();

    DebugLogger.info('CoopModulesDao', 'clear', 'Deleted $deletedCount modules from cache');
  }

  /// Get module by ID
  Future<CoopModuleLocal?> getById(String id) async {
    DebugLogger.debug('CoopModulesDao', 'getById', 'Fetching module with ID: $id');

    final module = await (select(coopModules)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (module != null) {
      DebugLogger.info('CoopModulesDao', 'getById', 'Found module: ${module.name}');
    } else {
      DebugLogger.warning('CoopModulesDao', 'getById', 'Module not found with ID: $id');
    }

    return module;
  }

  /// Count total modules in cache
  Future<int> count() async {
    DebugLogger.debug('CoopModulesDao', 'count', 'Counting modules in cache');

    final query = selectOnly(coopModules)..addColumns([coopModules.id.count()]);
    final result = await query.getSingle();
    final count = result.read(coopModules.id.count()) ?? 0;

    DebugLogger.info('CoopModulesDao', 'count', 'Total modules in cache: $count');
    return count;
  }
}
