import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/producer.dart' as model;
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:drift/drift.dart' as drift;

class CreateProducerRequest {
  final String firstName;
  final String lastName;
  final String dni;
  final String coopModuleId;
  final bool isMember;
  final String? appagropCode;

  CreateProducerRequest({
    required this.firstName,
    required this.lastName,
    required this.dni,
    required this.coopModuleId,
    required this.isMember,
    this.appagropCode,
  });
}

class ProducerService {
  final AppDatabase? _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  ProducerService({AppDatabase? db}) : _db = db;

  /// Creates a new producer with offline-first approach
  ///
  /// If offline is enabled:
  /// 1. Saves to local database first (always succeeds)
  /// 2. Attempts immediate sync if online
  /// 3. Returns local data if sync fails
  ///
  /// If offline is disabled:
  /// - Creates directly in Supabase (original behavior)
  Future<model.Producer> createProducer(CreateProducerRequest request) async {
    DebugLogger.info('ProducerService', 'createProducer',
        'Iniciando registro de productor: ${request.firstName} ${request.lastName}');

    // Verify if offline is enabled
    final offlineEnabled = OfflineConfig.instance.features.producers;
    DebugLogger.debug('ProducerService', 'createProducer',
        'Offline enabled: $offlineEnabled, Database available: ${_db != null}');

    if (!offlineEnabled || _db == null) {
      DebugLogger.info('ProducerService', 'createProducer',
          'Modo online - registrando directamente en Supabase');
      return await _registerOnline(request);
    }

    try {
      final db = _db;

      // 1. Save to local database first
      DebugLogger.info('ProducerService', 'createProducer',
          'Guardando productor en DB local');

      final localId = await db.producersDao.create(
        ProducersCompanion.insert(
          firstName: request.firstName,
          lastName: request.lastName,
          dni: request.dni,
          coopModuleId: request.coopModuleId,
          cooperativeId: AppConfig.current.id,
          isMember: request.isMember,
          appagropCode: drift.Value(request.appagropCode),
          syncStatus: drift.Value(SyncStatus.pending.value),
        ),
      );

      DebugLogger.info('ProducerService', 'createProducer',
          'Productor guardado localmente con ID: $localId');

      // 2. Check connectivity
      final isConnected = await NetworkDetector().isConnected;
      DebugLogger.debug('ProducerService', 'createProducer',
          'Network status: ${isConnected ? "ONLINE" : "OFFLINE"}');

      // 3. If online, try immediate sync
      if (isConnected) {
        DebugLogger.info('ProducerService', 'createProducer',
            'Intentando sincronización inmediata');

        try {
          final remoteProducer = await _registerOnline(request);

          DebugLogger.info('ProducerService', 'createProducer',
              'Sync exitoso, marcando como synced');

          await db.producersDao.markAsSynced(
            localId: localId,
            remoteId: remoteProducer.id,
          );

          return remoteProducer;
        } catch (e) {
          DebugLogger.warning('ProducerService', 'createProducer',
              'Sync inmediato falló: $e. Se sincronizará después.');
        }
      } else {
        DebugLogger.info('ProducerService', 'createProducer',
            'Sin conexión - productor quedará pendiente de sync');
      }

      // Return local producer
      final localProducer = await db.producersDao.getById(localId);
      return model.Producer(
        id: localId.toString(),
        firstName: localProducer!.firstName,
        lastName: localProducer.lastName,
        dni: localProducer.dni,
        cooperativeId: localProducer.cooperativeId,
        coopModuleId: localProducer.coopModuleId,
        isMember: localProducer.isMember,
        appagropCode: localProducer.appagropCode,
        isActive: true,
        defaultExtractionPercentage: 62.5,
        defaultCachazaPercentage: 2.5,
        createdAt: localProducer.createdAt,
        updatedAt: localProducer.createdAt,
      );
    } catch (e, st) {
      DebugLogger.error('ProducerService', 'createProducer',
          'Error al crear productor: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Registers producer directly in Supabase
  ///
  /// Called when offline is disabled or during sync operations.
  /// Logs all data sent and received for debugging.
  Future<model.Producer> _registerOnline(CreateProducerRequest request) async {
    DebugLogger.info('ProducerService', '_registerOnline',
        'Registrando en Supabase: ${request.dni}');

    try {
      // Check user authentication
      if (_supabase.auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get cooperative ID from configuration
      final cooperativeId = AppConfig.current.id;

      // Create the producer
      final insertData = {
        'first_name': request.firstName,
        'last_name': request.lastName,
        'dni': request.dni,
        'cooperative_id': cooperativeId,
        'coop_module_id': request.coopModuleId,
        'is_member': request.isMember,
      };

      // Only include appagrop_code if provided
      if (request.appagropCode != null && request.appagropCode!.isNotEmpty) {
        insertData['appagrop_code'] = request.appagropCode!;
      }

      DebugLogger.debug('ProducerService', '_registerOnline',
          'Sending to Supabase: $insertData');

      final response = await _supabase
          .from('producers')
          .insert(insertData)
          .select()
          .single();

      DebugLogger.debug('ProducerService', '_registerOnline',
          'Received from Supabase: $response');

      final producer = model.Producer.fromJson(response);

      DebugLogger.info('ProducerService', '_registerOnline',
          'Productor creado en Supabase con ID: ${producer.id}');

      return producer;
    } catch (e, st) {
      if (e is PostgrestException) {
        // Handle unique constraint violation for DNI
        if (e.code == '23505' &&
            e.message.contains('unique_dni_per_cooperative')) {
          throw Exception(
              'Ya existe un productor con este DNI en la cooperativa');
        }
        // Handle unique constraint violation for APPAGROP code
        if (e.code == '23505' &&
            e.message.contains('unique_appagrop_code_per_cooperative')) {
          throw Exception(
              'Ya existe un productor con este código APPAGROP en la cooperativa');
        }
        // Handle module validation error
        if (e.message.contains('Module must belong to the same cooperative')) {
          throw Exception(
              'El módulo seleccionado no pertenece a tu cooperativa');
        }
      }
      DebugLogger.error('ProducerService', '_registerOnline',
          'Error en Supabase insert: $e',
          stackTrace: st);
      throw Exception('Error al crear productor: $e');
    }
  }

  /// Fetches all producers for the current user's cooperative
  Future<List<model.Producer>> getProducers() async {
    try {
      final response = await _supabase
          .from('producers')
          .select()
          .eq('is_active', true)
          .order('first_name');

      return (response as List)
          .map((json) => model.Producer.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productores: $e');
    }
  }

  /// Fetches a specific producer by ID
  Future<model.Producer?> getProducerById(String producerId) async {
    DebugLogger.info('ProducerService', 'getProducerById',
        'Fetching producer by ID: $producerId');

    // If offline enabled and DB available, try cache-first approach
    if (OfflineConfig.instance.features.producers && _db != null) {
      try {
        // Try parsing as local ID
        final localId = int.tryParse(producerId);

        Producer? local;
        if (localId != null) {
          // It's a local ID
          DebugLogger.debug('ProducerService', 'getProducerById',
              'Looking up by local ID: $localId');
          local = await _db.producersDao.getById(localId);
        } else {
          // It's a remote UUID, look up by remoteId
          DebugLogger.debug('ProducerService', 'getProducerById',
              'Looking up by remote ID: $producerId');
          local = await _db.producersDao.getByRemoteId(producerId);
        }

        if (local != null) {
          DebugLogger.info('ProducerService', 'getProducerById',
              'Found producer in local cache');
          return _toModelProducer(local);
        }

        DebugLogger.debug('ProducerService', 'getProducerById',
            'Producer not in cache, checking online');
      } catch (e) {
        DebugLogger.warning('ProducerService', 'getProducerById',
            'Error accessing local DB: $e, falling back to Supabase');
      }
    }

    // Fallback to Supabase
    try {
      final response = await _supabase
          .from('producers')
          .select()
          .eq('id', producerId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return model.Producer.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener productor: $e');
    }
  }

  /// Updates a producer
  Future<model.Producer> updateProducer(String producerId, CreateProducerRequest request) async {
    try {
      // Check user authentication
      if (_supabase.auth.currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get cooperative ID from configuration
      final cooperativeId = AppConfig.current.id;

      final updateData = {
        'first_name': request.firstName,
        'last_name': request.lastName,
        'dni': request.dni,
        'cooperative_id': cooperativeId,
        'coop_module_id': request.coopModuleId,
        'is_member': request.isMember,
      };

      // Only include appagrop_code if provided
      if (request.appagropCode != null && request.appagropCode!.isNotEmpty) {
        updateData['appagrop_code'] = request.appagropCode!;
      }

      final response = await _supabase
          .from('producers')
          .update(updateData)
          .eq('id', producerId)
          .select()
          .single();

      return model.Producer.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == '23505' && e.message.contains('unique_dni_per_cooperative')) {
          throw Exception('Ya existe un productor con este DNI en la cooperativa');
        }
        if (e.code == '23505' && e.message.contains('unique_appagrop_code_per_cooperative')) {
          throw Exception('Ya existe un productor con este código APPAGROP en la cooperativa');
        }
        if (e.message.contains('Module must belong to the same cooperative')) {
          throw Exception('El módulo seleccionado no pertenece a tu cooperativa');
        }
      }
      throw Exception('Error al actualizar productor: $e');
    }
  }

  /// Soft deletes a producer (sets is_active to false)
  Future<void> deleteProducer(String producerId) async {
    try {
      await _supabase
          .from('producers')
          .update({'is_active': false})
          .eq('id', producerId);
    } catch (e) {
      throw Exception('Error al eliminar productor: $e');
    }
  }

  /// Searches producers by name or DNI
  Future<List<model.Producer>> searchProducers(String query) async {
    try {
      final response = await _supabase
          .from('producers')
          .select()
          .eq('is_active', true)
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%,dni.ilike.%$query%')
          .order('first_name');

      return (response as List)
          .map((json) => model.Producer.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar productores: $e');
    }
  }

  /// Fetches producers with module information for historial
  ///
  /// Behavior depends on offline mode:
  /// - Offline disabled: fetch from Supabase only
  /// - Offline enabled + no connection: fetch local pending only
  /// - Offline enabled + connected: fetch local pending + remote (combined)
  Future<List<Map<String, dynamic>>> getProducersForHistorial() async {
    // If offline not enabled, use original Supabase-only behavior
    if (!OfflineConfig.instance.features.producers || _db == null) {
      return await _getProducersFromSupabase();
    }

    final isConnected = await NetworkDetector().isConnected;

    if (!isConnected) {
      // OFFLINE: Return only local pending producers
      return await _getLocalPendingProducers();
    } else {
      // ONLINE: Combine local pending + remote synced
      return await _getCombinedProducers();
    }
  }

  /// Get local pending producers (offline mode)
  Future<List<Map<String, dynamic>>> _getLocalPendingProducers() async {
    DebugLogger.info('ProducerService', '_getLocalPendingProducers',
        'Fetching local pending producers for historial');

    final pending = await _db!.producersDao.getPending();

    final results = <Map<String, dynamic>>[];

    for (final producer in pending) {
      // Get module name from cache
      final module = await _db.coopModulesDao.getById(producer.coopModuleId);

      results.add({
        'id': producer.id.toString(),
        'nombre': '${producer.firstName} ${producer.lastName}',
        'dni': producer.dni,
        'modulo': module?.name ?? 'Desconocido',
        'condicion': producer.isMember ? 'Socio' : 'No Socio',
        'fecha_registro': producer.createdAt,
        'syncStatus': producer.syncStatus, // Include sync status
      });
    }

    DebugLogger.info('ProducerService', '_getLocalPendingProducers',
        'Returning ${results.length} local pending producers');

    return results;
  }

  /// Get combined producers: local pending + remote synced (online mode)
  ///
  /// Returns pending local producers FIRST, then ALL remote producers.
  /// Remote data is the source of truth - no filtering applied.
  Future<List<Map<String, dynamic>>> _getCombinedProducers() async {
    DebugLogger.info('ProducerService', '_getCombinedProducers',
        'Fetching combined local + remote producers for historial');

    final results = <Map<String, dynamic>>[];

    // 1. Get local pending producers FIRST (appear at top of list)
    final localPending = await _getLocalPendingProducers();
    results.addAll(localPending);

    DebugLogger.debug('ProducerService', '_getCombinedProducers',
        'Added ${localPending.length} local pending producers');

    // 2. Get ALL remote producers from Supabase (source of truth)
    final remoteProducers = await _getProducersFromSupabase();

    // 3. Add ALL remote producers (no filtering - remote data is source of truth)
    for (final remote in remoteProducers) {
      results.add({
        ...remote,
        'syncStatus': SyncStatus.synced.value, // Mark as synced
      });
    }

    DebugLogger.info('ProducerService', '_getCombinedProducers',
        'Returning ${results.length} total producers (${localPending.length} pending + ${remoteProducers.length} remote)');

    return results;
  }

  /// Get producers from Supabase (original behavior)
  Future<List<Map<String, dynamic>>> _getProducersFromSupabase() async {
    DebugLogger.info('ProducerService', '_getProducersFromSupabase',
        'Fetching producers from Supabase for historial');

    try {
      final response = await _supabase
          .from('producers')
          .select('''
            id,
            first_name,
            last_name,
            dni,
            is_member,
            is_active,
            created_at,
            coop_modules!inner(
              name
            )
          ''')
          .eq('is_active', true)
          .order('first_name');

      final results = (response as List).map((item) {
        return {
          'id': item['id'],
          'nombre': '${item['first_name']} ${item['last_name']}',
          'dni': item['dni'],
          'modulo': item['coop_modules']['name'],
          'condicion': item['is_member'] ? 'Socio' : 'No Socio',
          'fecha_registro': DateTime.parse(item['created_at']).toLocal(),
          // No syncStatus field for remote-only items (defaults to synced)
        };
      }).toList();

      DebugLogger.info('ProducerService', '_getProducersFromSupabase',
          'Fetched ${results.length} producers from Supabase');

      return results;
    } catch (e, st) {
      DebugLogger.error('ProducerService', '_getProducersFromSupabase',
          'Error fetching producers from Supabase: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Get producers that are synced (have remoteId)
  Future<List<Producer>> getSynced() async {
    if (_db == null) return [];

    DebugLogger.debug('ProducerService', 'getSynced',
        'Getting synced producers from local DB');

    final allProducers = await _db.producersDao.getAll();
    final synced = allProducers
        .where((p) => p.syncStatus == SyncStatus.synced.value && p.remoteId != null)
        .toList();

    DebugLogger.debug('ProducerService', 'getSynced',
        'Found ${synced.length} synced producers');

    return synced;
  }

  /// Get producers for dropdown with cache-first strategy
  ///
  /// Strategy:
  /// 1. Try cache first (synced producers)
  /// 2. If cache empty, fetch from Supabase
  /// 3. If online, refresh cache in background
  Future<List<model.Producer>> getProducersForDropdown() async {
    DebugLogger.info('ProducerService', 'getProducersForDropdown',
        'Fetching producers for dropdown');

    // If offline not enabled, use original behavior
    if (!OfflineConfig.instance.features.producers || _db == null) {
      DebugLogger.debug('ProducerService', 'getProducersForDropdown',
          'Offline disabled, fetching from Supabase');
      return await getProducers();
    }

    try {
      final db = _db;

      // 1. Try cache first
      final synced = await db.producersDao.getSynced();

      if (synced.isNotEmpty) {
        DebugLogger.info('ProducerService', 'getProducersForDropdown',
            'Returning ${synced.length} cached producers');

        // Background refresh if online (don't await)
        _refreshProducersInBackground();

        return synced.map((p) => _toModelProducer(p)).toList();
      }

      DebugLogger.info('ProducerService', 'getProducersForDropdown',
          'Cache empty, fetching from Supabase');

      // 2. Fallback to Supabase
      final remote = await getProducers();

      // 3. Update cache
      await _cacheProducers(remote);

      return remote;
    } catch (e, st) {
      DebugLogger.error('ProducerService', 'getProducersForDropdown',
          'Error: $e', stackTrace: st);
      rethrow;
    }
  }

  /// Refresh producers cache in background (fire and forget)
  void _refreshProducersInBackground() async {
    try {
      final isConnected = await NetworkDetector().isConnected;

      if (!isConnected) {
        DebugLogger.debug('ProducerService', '_refreshProducersInBackground',
            'No connection, skipping background refresh');
        return;
      }

      DebugLogger.debug('ProducerService', '_refreshProducersInBackground',
          'Refreshing cache in background');

      final remote = await getProducers();
      await _cacheProducers(remote);

      DebugLogger.debug('ProducerService', '_refreshProducersInBackground',
          'Background refresh completed');
    } catch (e) {
      DebugLogger.warning('ProducerService', '_refreshProducersInBackground',
          'Background refresh failed: $e');
      // Silently fail - this is background operation
    }
  }

  /// Cache producers from remote API
  Future<void> _cacheProducers(List<model.Producer> producers) async {
    if (_db == null) return;

    DebugLogger.info('ProducerService', '_cacheProducers',
        'Caching ${producers.length} producers');

    try {
      // Convert to local Companions with synced status
      final localProducers = producers.map((p) => ProducersCompanion.insert(
        firstName: p.firstName,
        lastName: p.lastName,
        dni: p.dni,
        coopModuleId: p.coopModuleId,
        cooperativeId: p.cooperativeId,
        isMember: p.isMember,
        appagropCode: drift.Value(p.appagropCode),
        syncStatus: drift.Value(SyncStatus.synced.value),
        remoteId: drift.Value(p.id),
        syncedAt: drift.Value(DateTime.now()),
      )).toList();

      await _db.producersDao.cacheFromRemote(localProducers);

      DebugLogger.info('ProducerService', '_cacheProducers',
          'Successfully cached ${producers.length} producers');
    } catch (e, st) {
      DebugLogger.error('ProducerService', '_cacheProducers',
          'Error caching producers: $e', stackTrace: st);
      rethrow;
    }
  }

  /// Convert local producer to model Producer
  model.Producer _toModelProducer(Producer local) {
    return model.Producer(
      id: local.remoteId ?? local.id.toString(),
      firstName: local.firstName,
      lastName: local.lastName,
      dni: local.dni,
      cooperativeId: local.cooperativeId,
      coopModuleId: local.coopModuleId,
      isMember: local.isMember,
      appagropCode: local.appagropCode,
      isActive: true,
      defaultExtractionPercentage: 62.5, // System default
      defaultCachazaPercentage: 2.5,     // System default
      createdAt: local.createdAt,
      updatedAt: local.createdAt,
    );
  }

  /// Refresh producers cache from Supabase (public wrapper)
  ///
  /// This method is called by FormDataCacheService during login.
  Future<void> refreshCache() async {
    DebugLogger.info('ProducerService', 'refreshCache',
        'Refreshing producers cache from Supabase');

    try {
      final producers = await getProducers();
      await _cacheProducers(producers);

      DebugLogger.info('ProducerService', 'refreshCache',
          'Cache refreshed successfully');
    } catch (e, st) {
      DebugLogger.error('ProducerService', 'refreshCache',
          'Error refreshing cache: $e', stackTrace: st);
      rethrow;
    }
  }
}