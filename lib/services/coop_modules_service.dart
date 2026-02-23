import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';

class CoopModulesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppDatabase? _db;

  CoopModulesService({AppDatabase? db}) : _db = db;

  /// Fetches all modules available for the current user's cooperative
  ///
  /// Strategy:
  /// 1. If database is available, try to get from cache first (fast)
  /// 2. If cache is empty or online, fetch from Supabase
  /// 3. If fetched from Supabase and db available, update cache
  Future<List<CoopModule>> getModules() async {
    DebugLogger.info('CoopModulesService', 'getModules',
        'Fetching modules (db available: ${_db != null})');

    try {
      // Strategy 1: Try cache first if database available
      if (_db != null) {
        final cachedModules = await _getCachedModules();

        // If we have cached data, check if we should refresh in background
        if (cachedModules.isNotEmpty) {
          DebugLogger.info('CoopModulesService', 'getModules',
              'Returning ${cachedModules.length} cached modules');

          // Background refresh if online (don't await)
          _refreshCacheInBackground();

          return cachedModules;
        }

        DebugLogger.info('CoopModulesService', 'getModules',
            'Cache empty, fetching from Supabase');
      }

      // Strategy 2: Fetch from Supabase (cache empty or no db)
      final modules = await _fetchFromSupabase();

      // Strategy 3: Update cache if database available
      if (_db != null && modules.isNotEmpty) {
        await _updateCache(modules);
      }

      return modules;
    } catch (e, st) {
      DebugLogger.error('CoopModulesService', 'getModules',
          'Error fetching modules: $e',
          stackTrace: st);

      // Last resort: try cache even if it was empty before
      if (_db != null) {
        final cachedModules = await _getCachedModules();
        if (cachedModules.isNotEmpty) {
          DebugLogger.warning('CoopModulesService', 'getModules',
              'Returning stale cache due to error');
          return cachedModules;
        }
      }

      throw Exception('Failed to fetch modules: $e');
    }
  }

  /// Fetches modules directly from Supabase (public method for refresh operations)
  Future<List<CoopModule>> fetchFromSupabase() async {
    return await _fetchFromSupabase();
  }

  /// Internal method to fetch from Supabase
  Future<List<CoopModule>> _fetchFromSupabase() async {
    DebugLogger.info('CoopModulesService', '_fetchFromSupabase',
        'Fetching modules from Supabase');

    try {
      final response = await _supabase
          .from('coop_modules')
          .select('id, name')
          .eq('is_active', true)
          .order('name', ascending: true);

      final modules = (response as List)
          .map((json) => CoopModule.fromJson(json))
          .toList();

      DebugLogger.info('CoopModulesService', '_fetchFromSupabase',
          'Fetched ${modules.length} modules from Supabase');

      return modules;
    } catch (e) {
      throw Exception('Failed to fetch modules from Supabase: $e');
    }
  }

  /// Get modules from local cache
  Future<List<CoopModule>> _getCachedModules() async {
    if (_db == null) return [];

    try {
      final localModules = await _db.coopModulesDao.getActive();

      return localModules
          .map((local) => CoopModule(
                id: local.id,
                name: local.name,
              ))
          .toList();
    } catch (e) {
      DebugLogger.warning('CoopModulesService', '_getCachedModules',
          'Error reading cache: $e');
      return [];
    }
  }

  /// Update local cache with modules from Supabase
  Future<void> _updateCache(List<CoopModule> modules) async {
    if (_db == null) return;

    try {
      DebugLogger.info('CoopModulesService', '_updateCache',
          'Updating cache with ${modules.length} modules');

      final companions = modules
          .map((module) => CoopModulesCompanion.insert(
                id: module.id,
                name: module.name,
              ))
          .toList();

      await _db.coopModulesDao.upsertBatch(companions);

      DebugLogger.info('CoopModulesService', '_updateCache',
          'Cache updated successfully');
    } catch (e) {
      DebugLogger.warning('CoopModulesService', '_updateCache',
          'Error updating cache: $e');
      // Don't throw - cache update failure shouldn't break the flow
    }
  }

  /// Refresh cache in background if online (fire and forget)
  void _refreshCacheInBackground() async {
    try {
      final isConnected = await NetworkDetector().isConnected;

      if (isConnected) {
        DebugLogger.debug('CoopModulesService', '_refreshCacheInBackground',
            'Refreshing cache in background');

        final modules = await _fetchFromSupabase();
        await _updateCache(modules);

        DebugLogger.debug('CoopModulesService', '_refreshCacheInBackground',
            'Background refresh completed');
      }
    } catch (e) {
      DebugLogger.warning('CoopModulesService', '_refreshCacheInBackground',
          'Background refresh failed: $e');
      // Silently fail - this is background operation
    }
  }

  /// Fetches a specific module by ID
  ///
  /// Strategy:
  /// 1. Try cache first if database available
  /// 2. If not in cache, check connectivity
  /// 3. If online, fetch from Supabase
  /// 4. If offline, return null
  Future<CoopModule?> getModuleById(String moduleId) async {
    DebugLogger.info('CoopModulesService', 'getModuleById',
        'Fetching module by ID: $moduleId (db available: ${_db != null})');

    // Strategy 1: Try cache first if database available
    if (_db != null) {
      try {
        final local = await _db.coopModulesDao.getById(moduleId);

        if (local != null) {
          DebugLogger.info('CoopModulesService', 'getModuleById',
              'Found module in local cache: ${local.name}');
          return CoopModule(id: local.id, name: local.name);
        }

        DebugLogger.debug('CoopModulesService', 'getModuleById',
            'Module not in cache, checking connectivity');
      } catch (e) {
        DebugLogger.warning('CoopModulesService', 'getModuleById',
            'Error accessing local DB: $e, falling back to Supabase');
      }
    }

    // Strategy 2: Check connectivity before attempting Supabase
    final isConnected = await NetworkDetector().isConnected;

    if (!isConnected) {
      DebugLogger.info('CoopModulesService', 'getModuleById',
          'Offline and not in cache, returning null');
      return null;
    }

    // Strategy 3: Fetch from Supabase (only if online)
    DebugLogger.info('CoopModulesService', 'getModuleById',
        'Online, fetching from Supabase');

    try {
      final response = await _supabase
          .from('coop_modules')
          .select('id, name')
          .eq('id', moduleId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        DebugLogger.warning('CoopModulesService', 'getModuleById',
            'Module not found in Supabase: $moduleId');
        return null;
      }

      final module = CoopModule.fromJson(response);

      DebugLogger.info('CoopModulesService', 'getModuleById',
          'Found module in Supabase: ${module.name}');

      return module;
    } catch (e) {
      DebugLogger.error('CoopModulesService', 'getModuleById',
          'Failed to fetch module from Supabase: $e');
      throw Exception('Failed to fetch module: $e');
    }
  }
}