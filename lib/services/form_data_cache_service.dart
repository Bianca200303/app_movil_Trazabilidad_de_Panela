import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/services/batch_cert_service.dart';
import 'package:drift/drift.dart' as drift;

/// Centralized service for managing form data cache
///
/// This service orchestrates the caching of reference data needed for forms
/// (like cooperative modules, product types, etc.) to enable offline form usage.
///
/// Key responsibilities:
/// - Refresh cache from Supabase (called on login)
/// - Provide cached data to screens
/// - Clear cache on logout
class FormDataCacheService {
  final AppDatabase _db;
  final CoopModulesService _coopModulesService;

  FormDataCacheService({
    required AppDatabase db,
    CoopModulesService? coopModulesService,
  })  : _db = db,
        _coopModulesService = coopModulesService ?? CoopModulesService();

  // ==================== COOP MODULES ====================

  /// Get cooperative modules from local cache
  ///
  /// Returns active modules stored locally. If cache is empty, returns empty list.
  /// Call [refreshCoopModules] to populate cache.
  Future<List<CoopModule>> getCoopModules() async {
    DebugLogger.info('FormDataCacheService', 'getCoopModules',
        'Fetching modules from local cache');

    try {
      final localModules = await _db.coopModulesDao.getActive();

      final modules = localModules
          .map((local) => CoopModule(
                id: local.id,
                name: local.name,
              ))
          .toList();

      DebugLogger.info('FormDataCacheService', 'getCoopModules',
          'Retrieved ${modules.length} modules from cache');

      return modules;
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'getCoopModules',
          'Error fetching from cache: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Refresh cooperative modules cache from Supabase
  ///
  /// Fetches latest modules from server and updates local cache.
  /// This should be called on login to ensure fresh data.
  Future<void> refreshCoopModules() async {
    DebugLogger.info('FormDataCacheService', 'refreshCoopModules',
        'Refreshing modules from Supabase');

    try {
      // Fetch from Supabase
      final modules = await _coopModulesService.getModules();

      DebugLogger.info('FormDataCacheService', 'refreshCoopModules',
          'Fetched ${modules.length} modules from Supabase');

      // Convert to Drift companions for batch insert
      final companions = modules
          .map((module) => CoopModulesCompanion.insert(
                id: module.id,
                name: module.name,
                isActive: const drift.Value(true),
                updatedAt: drift.Value(DateTime.now()),
              ))
          .toList();

      // Batch upsert to local cache
      await _db.coopModulesDao.upsertBatch(companions);

      DebugLogger.info('FormDataCacheService', 'refreshCoopModules',
          'Successfully refreshed ${modules.length} modules in cache');
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'refreshCoopModules',
          'Error refreshing modules: $e',
          stackTrace: st);
      rethrow;
    }
  }

  // ==================== ALL FORM DATA ====================

  /// Refresh producers cache
  Future<void> refreshProducers() async {
    DebugLogger.info('FormDataCacheService', 'refreshProducers',
        'Refreshing producers from Supabase');

    try {
      final producerService = ProducerService(db: _db);
      await producerService.refreshCache();

      DebugLogger.info('FormDataCacheService', 'refreshProducers',
          'Producers cache refreshed successfully');
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'refreshProducers',
          'Error refreshing producers: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Refresh plots cache
  Future<void> refreshPlots() async {
    DebugLogger.info('FormDataCacheService', 'refreshPlots',
        'Refreshing plots from Supabase');

    try {
      final plotService = PlotService(db: _db);
      await plotService.refreshCache();

      DebugLogger.info('FormDataCacheService', 'refreshPlots',
          'Plots cache refreshed successfully');
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'refreshPlots',
          'Error refreshing plots: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Refresh batch certificates cache
  Future<void> refreshBatchCerts() async {
    DebugLogger.info('FormDataCacheService', 'refreshBatchCerts',
        'Refreshing batch certificates from Supabase');

    try {
      final batchCertService = BatchCertService(db: _db);
      await batchCertService.refreshCache();

      DebugLogger.info('FormDataCacheService', 'refreshBatchCerts',
          'Certificates cache refreshed successfully');
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'refreshBatchCerts',
          'Error refreshing certificates: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Refresh all form data caches from Supabase
  ///
  /// This method should be called after successful login to ensure
  /// all reference data is up to date for offline form usage.
  ///
  /// Currently refreshes:
  /// - Producers (for production forms) - MUST be first
  /// - Plots (for production forms) - depends on producers
  /// - Cooperative modules
  /// - Batch certificates (for production forms)
  ///
  /// IMPORTANT: Producers must be refreshed BEFORE plots because
  /// plots need to resolve producer local IDs during cache refresh.
  ///
  /// Future additions:
  /// - Product types
  /// - Document types
  /// - Units of measure
  Future<void> refreshAllFormData() async {
    DebugLogger.info('FormDataCacheService', 'refreshAllFormData',
        'Starting full cache refresh');

    try {
      // CRITICAL: Refresh producers first (plots depend on them)
      await refreshProducers();

      // Then refresh plots (needs producers to be cached)
      await refreshPlots();

      // Refresh remaining reference data in parallel
      await Future.wait([
        refreshCoopModules(),
        refreshBatchCerts(),
        // Add more refresh calls as needed:
        // refreshProductTypes(),
        // refreshDocumentTypes(),
      ]);

      DebugLogger.info('FormDataCacheService', 'refreshAllFormData',
          'All form data refreshed successfully');
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'refreshAllFormData',
          'Error refreshing form data: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Clear all form data caches
  ///
  /// This method should be called on logout to clear all cached
  /// reference data and free up storage.
  /// Clears only synced data, preserving local pending entities.
  Future<void> clearAllCache() async {
    DebugLogger.info('FormDataCacheService', 'clearAllCache',
        'Clearing all form data caches');

    try {
      // Clear all reference data tables
      await Future.wait([
        _db.coopModulesDao.clear(),
        _db.batchCertsDao.clear(),
        _db.producersDao.deleteSynced(),  // Only delete synced, keep pending
        _db.plotsDao.deleteSynced(),      // Only delete synced, keep pending
        // Add more clear calls as needed:
        // _db.productTypesDao.clear(),
        // _db.documentTypesDao.clear(),
      ]);

      DebugLogger.info('FormDataCacheService', 'clearAllCache',
          'All caches cleared successfully');
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'clearAllCache',
          'Error clearing caches: $e',
          stackTrace: st);
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if cache is populated with data
  ///
  /// Useful for determining if initial refresh is needed.
  Future<bool> isCachePopulated() async {
    try {
      final moduleCount = await _db.coopModulesDao.count();

      DebugLogger.debug('FormDataCacheService', 'isCachePopulated',
          'Cache status - Modules: $moduleCount');

      // Consider cache populated if we have at least one module
      return moduleCount > 0;
    } catch (e, st) {
      DebugLogger.error('FormDataCacheService', 'isCachePopulated',
          'Error checking cache status: $e',
          stackTrace: st);
      return false;
    }
  }
}
