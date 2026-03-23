import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/batch_cert.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:drift/drift.dart' as drift;

class BatchCertService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppDatabase? _db;

  BatchCertService({AppDatabase? db}) : _db = db;

  /// Fetches all active batch certificates with cache-first strategy
  ///
  /// Strategy:
  /// 1. If database available, try cache first (fast)
  /// 2. If cache empty or stale, fetch from Supabase
  /// 3. If fetched from Supabase and db available, update cache
  /// 4. If online, refresh cache in background
  Future<List<BatchCert>> getBatchCerts() async {
    DebugLogger.info('BatchCertService', 'getBatchCerts',
        'Fetching batch certificates (db available: ${_db != null})');

    try {
      // Strategy 1: Try cache first
      if (_db != null) {
        final cachedCerts = await _getCachedCerts();

        if (cachedCerts.isNotEmpty) {
          DebugLogger.info('BatchCertService', 'getBatchCerts',
              'Returning ${cachedCerts.length} cached certificates');

          // Background refresh if online (don't await)
          _refreshCacheInBackground();

          return cachedCerts;
        }

        DebugLogger.info('BatchCertService', 'getBatchCerts',
            'Cache empty, fetching from Supabase');
      }

      // Strategy 2: Fetch from Supabase
      final certs = await _fetchFromSupabase();

      // Strategy 3: Update cache
      if (_db != null && certs.isNotEmpty) {
        await _updateCache(certs);
      }

      return certs;
    } catch (e, st) {
      DebugLogger.error('BatchCertService', 'getBatchCerts',
          'Error fetching certificates: $e',
          stackTrace: st);

      // Last resort: try stale cache
      if (_db != null) {
        final cachedCerts = await _getCachedCerts();
        if (cachedCerts.isNotEmpty) {
          DebugLogger.warning('BatchCertService', 'getBatchCerts',
              'Returning stale cache due to error');
          return cachedCerts;
        }
      }

      throw Exception('Failed to fetch certificates: $e');
    }
  }

  /// Get cached certificates from local DB
  Future<List<BatchCert>> _getCachedCerts() async {
    if (_db == null) return [];

    DebugLogger.debug('BatchCertService', '_getCachedCerts',
        'Fetching from cache');

    final cached = await _db.batchCertsDao.getAll();

    return cached.map((c) => _toModel(c)).toList();
  }

  /// Fetch certificates from Supabase
  Future<List<BatchCert>> _fetchFromSupabase() async {
    DebugLogger.debug('BatchCertService', '_fetchFromSupabase',
        'Fetching from Supabase');

    final response = await _supabase.from('batch_certs').select('''
          id,
          name,
          exclusion_group_id,
          is_default,
          certificate_exclusion_groups (
            id,
            name,
            display_name,
            description,
            is_required,
            cooperative_id,
            created_at,
            updated_at,
            is_active
          )
        ''')
        .eq('cooperative_id', AppConfig.current.id)
        .eq('is_active', true)
        .order('name');

    return (response as List).map((json) => BatchCert.fromJson(json)).toList();
  }

  /// Update cache with certificates
  Future<void> _updateCache(List<BatchCert> certs) async {
    if (_db == null) return;

    DebugLogger.debug('BatchCertService', '_updateCache',
        'Updating cache with ${certs.length} certificates');

    final companions = certs.map((c) => BatchCertsCompanion.insert(
          id: c.id,
          name: c.name,
          exclusionGroupId: drift.Value(c.exclusionGroupId),
          isDefault: c.isDefault,
          isActive: const drift.Value(true),
          cachedAt: drift.Value(DateTime.now()),
        )).toList();

    await _db.batchCertsDao.upsertBatch(companions);

    DebugLogger.debug('BatchCertService', '_updateCache', 'Cache updated');
  }

  /// Refresh cache in background if online (fire and forget)
  void _refreshCacheInBackground() async {
    try {
      final isConnected = await NetworkDetector().isConnected;

      if (isConnected) {
        DebugLogger.debug('BatchCertService', '_refreshCacheInBackground',
            'Refreshing cache in background');

        final certs = await _fetchFromSupabase();
        if (_db != null) {
          await _db.batchCertsDao.clear();
        }
        await _updateCache(certs);

        DebugLogger.debug('BatchCertService', '_refreshCacheInBackground',
            'Background refresh completed');
      }
    } catch (e) {
      DebugLogger.warning('BatchCertService', '_refreshCacheInBackground',
          'Background refresh failed: $e');
      // Silently fail - this is background operation
    }
  }

  /// Convert local to model
  BatchCert _toModel(BatchCertLocal local) {
    return BatchCert(
      id: local.id,
      name: local.name,
      exclusionGroupId: local.exclusionGroupId,
      isDefault: local.isDefault,
      exclusionGroup: null, // Not cached in local DB
    );
  }

  /// Refresh certificates cache from Supabase (public wrapper)
  ///
  /// This method is called by FormDataCacheService during login.
  Future<void> refreshCache() async {
    DebugLogger.info('BatchCertService', 'refreshCache',
        'Refreshing certificates cache from Supabase');

    try {
      final certs = await _fetchFromSupabase();
      // Clear old cache first to avoid mixing data from different cooperatives
      // (e.g., if logout failed to clear cache, stale certs from another
      // cooperative would remain alongside new ones via upsert)
      if (_db != null) {
        await _db.batchCertsDao.clear();
      }
      await _updateCache(certs);

      DebugLogger.info('BatchCertService', 'refreshCache',
          'Cache refreshed successfully');
    } catch (e, st) {
      DebugLogger.error('BatchCertService', 'refreshCache',
          'Error refreshing cache: $e', stackTrace: st);
      rethrow;
    }
  }

  /// Fetches a specific batch certificate by ID
  Future<BatchCert?> getBatchCertById(String certId) async {
    try {
      final response = await _supabase.from('batch_certs').select('''
            id,
            name,
            exclusion_group_id,
            is_default,
            certificate_exclusion_groups (
              id,
              name,
              display_name,
              description,
              is_required,
              cooperative_id,
              created_at,
              updated_at,
              is_active
            )
          ''').eq('id', certId).eq('is_active', true).maybeSingle();

      if (response == null) return null;

      return BatchCert.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener certificado: $e');
    }
  }
}
