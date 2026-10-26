import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/plot.dart' as model;
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:drift/drift.dart' as drift;

class CreatePlotRequest {
  final String name;
  final String? code; // Make code optional for auto-generation
  final String producerId;

  CreatePlotRequest({
    required this.name,
    this.code, // Optional - will be auto-generated if null
    required this.producerId,
  });
}

class PlotData {
  final String name;
  final String? code; // Optional for preview purposes

  PlotData({
    required this.name,
    this.code, // Optional - used only for preview/display
  });
}

class PlotService {
  final AppDatabase? _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  PlotService({AppDatabase? db}) : _db = db;

  /// Gets the next available plot code for preview (UI display only)
  /// Requires producer_id to generate DNI-based code preview
  Future<String> getNextPlotCode(String producerId) async {
    try {
      final response = await _supabase.rpc('get_next_plot_code', params: {
        'producer_id_param': producerId,
      });

      return response as String;
    } catch (e) {
      throw Exception('Error al obtener próximo código: $e');
    }
  }

  /// Creates multiple plots for a producer with offline-first approach
  ///
  /// If offline is enabled:
  /// 1. Saves plots to local database with auto-generated codes
  /// 2. Attempts immediate sync if online
  /// 3. Returns local data if sync fails
  ///
  /// If offline is disabled:
  /// - Creates directly in Supabase (original behavior)
  Future<List<model.Plot>> createMultiplePlots(
      String producerId, List<PlotData> plotsData) async {
    DebugLogger.info('PlotService', 'createMultiplePlots',
        'Creando ${plotsData.length} parcelas para productor: $producerId');

    // Verify if offline is enabled
    final offlineEnabled = OfflineConfig.instance.features.producers;
    DebugLogger.debug('PlotService', 'createMultiplePlots',
        'Offline enabled: $offlineEnabled, Database available: ${_db != null}');

    if (!offlineEnabled || _db == null) {
      DebugLogger.info('PlotService', 'createMultiplePlots',
          'Modo online - creando directamente en Supabase');
      return await _createMultiplePlotsOnline(producerId, plotsData);
    }

    try {
      final db = _db;

      // Parse producerId - could be local ID (int) or remote UUID (string)
      int? producerLocalId;
      try {
        producerLocalId = int.parse(producerId);
        DebugLogger.debug('PlotService', 'createMultiplePlots',
            'Producer ID parsed as local ID: $producerLocalId');
      } catch (e) {
        // If it's a UUID, find local producer by remote ID
        DebugLogger.debug('PlotService', 'createMultiplePlots',
            'Producer ID is UUID, finding local producer: $producerId');
        final localProducer = await db.producersDao.getByRemoteId(producerId);
        if (localProducer == null) {
          throw Exception(
              'Producer not found in local DB with remoteId: $producerId');
        }
        producerLocalId = localProducer.id;
        DebugLogger.debug('PlotService', 'createMultiplePlots',
            'Found local producer ID: $producerLocalId');
      }

      // 1. Save plots to local database
      DebugLogger.info('PlotService', 'createMultiplePlots',
          'Guardando ${plotsData.length} parcelas en DB local');

      final createdPlots = <model.Plot>[];

      for (var i = 0; i < plotsData.length; i++) {
        final plotData = plotsData[i];

        // Generate code locally
        final code = await db.plotsDao.getNextCodeForProducer(producerLocalId);

        DebugLogger.debug('PlotService', 'createMultiplePlots',
            'Creando parcela ${i + 1}/${plotsData.length}: name="${plotData.name}", code=$code');

        final localId = await db.plotsDao.create(
          PlotsCompanion.insert(
            name: plotData.name,
            code: code,
            producerLocalId: producerLocalId,
            syncStatus: drift.Value(SyncStatus.pending.value),
          ),
        );

        final plot = await db.plotsDao.getById(localId);
        createdPlots.add(model.Plot(
          id: localId.toString(),
          name: plot!.name,
          code: plot.code,
          producerId: producerId,
          isActive: true,
          createdAt: plot.createdAt,
          updatedAt: plot.createdAt,
        ));
      }

      DebugLogger.info('PlotService', 'createMultiplePlots',
          '${createdPlots.length} parcelas guardadas localmente');

      // 2. Check connectivity
      final isConnected = await NetworkDetector().isConnected;
      DebugLogger.debug('PlotService', 'createMultiplePlots',
          'Network status: ${isConnected ? "ONLINE" : "OFFLINE"}');

      // 3. If online, try immediate sync
      if (isConnected) {
        DebugLogger.info('PlotService', 'createMultiplePlots',
            'Intentando sincronización inmediata de parcelas');

        try {
          // Get producer's remote ID for sync
          final producer = await db.producersDao.getById(producerLocalId);
          final remoteProducerId = producer?.remoteId;

          if (remoteProducerId == null) {
            DebugLogger.warning('PlotService', 'createMultiplePlots',
                'Producer not synced yet, plots will sync later');
          } else {
            final remotePlots = await _createMultiplePlotsOnline(
                remoteProducerId, plotsData);

            // Mark plots as synced
            for (var i = 0; i < createdPlots.length; i++) {
              final localPlot = createdPlots[i];
              final remotePlot = remotePlots[i];

              await db.plotsDao.markAsSynced(
                localId: int.parse(localPlot.id),
                remoteId: remotePlot.id,
                remoteProducerId: remoteProducerId,
              );
            }

            DebugLogger.info('PlotService', 'createMultiplePlots',
                'Todas las parcelas sincronizadas exitosamente');

            return remotePlots;
          }
        } catch (e) {
          DebugLogger.warning('PlotService', 'createMultiplePlots',
              'Sync inmediato falló: $e. Se sincronizarán después.');
        }
      } else {
        DebugLogger.info('PlotService', 'createMultiplePlots',
            'Sin conexión - parcelas quedarán pendientes de sync');
      }

      return createdPlots;
    } catch (e, st) {
      DebugLogger.error('PlotService', 'createMultiplePlots',
          'Error al crear parcelas: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Creates plots directly in Supabase
  ///
  /// Called when offline is disabled or during sync operations.
  /// Logs all data sent and received for debugging.
  Future<List<model.Plot>> _createMultiplePlotsOnline(
      String producerId, List<PlotData> plotsData) async {
    DebugLogger.info('PlotService', '_createMultiplePlotsOnline',
        'Creando ${plotsData.length} parcelas en Supabase para productor: $producerId');

    try {
      // Prepare data for batch insert - codes will be auto-generated by backend
      final insertData = plotsData.map((plot) {
        final data = {
          'name': plot.name,
          'producer_id': producerId,
        };

        // Only include code if explicitly provided (for legacy support)
        if (plot.code != null && plot.code!.isNotEmpty) {
          data['code'] = plot.code!;
        }

        return data;
      }).toList();

      DebugLogger.debug('PlotService', '_createMultiplePlotsOnline',
          'Sending to Supabase: $insertData');

      final response =
          await _supabase.from('plots').insert(insertData).select();

      DebugLogger.debug('PlotService', '_createMultiplePlotsOnline',
          'Received from Supabase: $response');

      final plots =
          (response as List).map((json) => model.Plot.fromJson(json)).toList();

      DebugLogger.info('PlotService', '_createMultiplePlotsOnline',
          '${plots.length} parcelas creadas en Supabase');

      return plots;
    } catch (e, st) {
      if (e is PostgrestException) {
        if (e.code == '23505' &&
            e.message.contains('unique_plot_name_code_per_producer')) {
          throw Exception(
              'Una o más parcelas tienen nombres duplicados para este productor');
        }
      }
      DebugLogger.error('PlotService', '_createMultiplePlotsOnline',
          'Error en Supabase insert: $e',
          stackTrace: st);
      throw Exception('Error al crear parcelas: $e');
    }
  }

  /// Creates multiple plots for a producer (legacy method with codes only)
  @Deprecated('Use createMultiplePlots with PlotData list instead')
  Future<List<model.Plot>> createMultipleplotsByCode(String producerId, List<String> plotCodes) async {
    final plotsData = plotCodes.map((code) => PlotData(
      name: 'Parcela $code', // Default name based on code
      code: code,
    )).toList();
    
    return createMultiplePlots(producerId, plotsData);
  }

  /// Fetches all plots for a producer
  Future<List<model.Plot>> getPlotsByProducerId(String producerId) async {
    try {
      final response = await _supabase
          .from('plots')
          .select()
          .eq('producer_id', producerId)
          .eq('is_active', true)
          .order('name, code');

      return (response as List)
          .map((json) => model.Plot.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener parcelas: $e');
    }
  }

  /// Fetches all plots for the current user's cooperative producers
  Future<List<model.Plot>> getPlots() async {
    try {
      final response = await _supabase
          .from('plots')
          .select()
          .eq('is_active', true)
          .order('name, code');

      return (response as List)
          .map((json) => model.Plot.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener parcelas: $e');
    }
  }

  /// Fetches a specific plot by ID
  Future<model.Plot?> getPlotById(String plotId) async {
    DebugLogger.info('PlotService', 'getPlotById',
        'Fetching plot by ID: $plotId');

    // If offline enabled and DB available, try cache-first approach
    if (OfflineConfig.instance.features.producers && _db != null) {
      try {
        // Try parsing as local ID
        final localId = int.tryParse(plotId);

        Plot? local;
        if (localId != null) {
          // It's a local ID
          DebugLogger.debug('PlotService', 'getPlotById',
              'Looking up by local ID: $localId');
          local = await _db.plotsDao.getById(localId);
        } else {
          // It's a remote UUID, look up by remoteId
          DebugLogger.debug('PlotService', 'getPlotById',
              'Looking up by remote ID: $plotId');
          local = await _db.plotsDao.getByRemoteId(plotId);
        }

        if (local != null) {
          DebugLogger.info('PlotService', 'getPlotById',
              'Found plot in local cache');
          // Use existing method with producerId parameter
          return _toModelPlot(local, local.remoteProducerId ?? '');
        }

        DebugLogger.debug('PlotService', 'getPlotById',
            'Plot not in cache, checking online');
      } catch (e) {
        DebugLogger.warning('PlotService', 'getPlotById',
            'Error accessing local DB: $e, falling back to Supabase');
      }
    }

    // Fallback to Supabase
    try {
      final response = await _supabase
          .from('plots')
          .select()
          .eq('id', plotId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return model.Plot.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener parcela: $e');
    }
  }

  /// Soft deletes a plot (sets is_active to false)
  Future<void> deletePlot(String plotId) async {
    try {
      await _supabase
          .from('plots')
          .update({'is_active': false})
          .eq('id', plotId);
    } catch (e) {
      throw Exception('Error al eliminar parcela: $e');
    }
  }

  /// Searches plots by name or code
  Future<List<model.Plot>> searchPlots(String query) async {
    try {
      final response = await _supabase
          .from('plots')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,code.ilike.%$query%')
          .order('name, code');

      return (response as List)
          .map((json) => model.Plot.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar parcelas: $e');
    }
  }

  /// Get plots for dropdown with cache-first strategy
  ///
  /// Strategy:
  /// 1. Resolve producer local ID from producerId
  /// 2. Try cache first (synced plots)
  /// 3. If cache empty, fetch from Supabase
  /// 4. If online, refresh cache in background
  Future<List<model.Plot>> getPlotsForDropdown(String producerId) async {
    DebugLogger.info('PlotService', 'getPlotsForDropdown',
        'Fetching plots for dropdown, producerId: $producerId');

    // If offline not enabled, use original behavior
    if (!OfflineConfig.instance.features.producers || _db == null) {
      DebugLogger.debug('PlotService', 'getPlotsForDropdown',
          'Offline disabled, fetching from Supabase');
      return await getPlotsByProducerId(producerId);
    }

    try {
      final db = _db;

      // 1. Resolve producer local ID
      final producerLocalId = await _resolveProducerLocalId(producerId);

      // 2. Try cache first
      final synced = await db.plotsDao.getSyncedByProducerLocalId(producerLocalId);

      if (synced.isNotEmpty) {
        DebugLogger.info('PlotService', 'getPlotsForDropdown',
            'Returning ${synced.length} cached plots');

        // Background refresh if online (don't await)
        _refreshPlotsInBackground(producerId);

        return synced.map((p) => _toModelPlot(p, producerId)).toList();
      }

      DebugLogger.info('PlotService', 'getPlotsForDropdown',
          'Cache empty, checking connectivity');

      // 3. Check connectivity before attempting Supabase
      final isConnected = await NetworkDetector().isConnected;

      if (!isConnected) {
        DebugLogger.info('PlotService', 'getPlotsForDropdown',
            'Offline and no cache, returning empty list');
        return [];
      }

      DebugLogger.info('PlotService', 'getPlotsForDropdown',
          'Online, fetching from Supabase');

      // 4. Fallback to Supabase (only if online)
      final remote = await getPlotsByProducerId(producerId);

      // 5. Update cache
      await _cachePlots(remote, producerLocalId, producerId);

      return remote;
    } catch (e, st) {
      DebugLogger.error('PlotService', 'getPlotsForDropdown',
          'Error: $e', stackTrace: st);
      rethrow;
    }
  }

  /// Refresh plots cache in background (fire and forget)
  void _refreshPlotsInBackground(String producerId) async {
    try {
      final isConnected = await NetworkDetector().isConnected;

      if (!isConnected) {
        DebugLogger.debug('PlotService', '_refreshPlotsInBackground',
            'No connection, skipping background refresh');
        return;
      }

      DebugLogger.debug('PlotService', '_refreshPlotsInBackground',
          'Refreshing cache in background for producer: $producerId');

      final remote = await getPlotsByProducerId(producerId);
      final producerLocalId = await _resolveProducerLocalId(producerId);
      await _cachePlots(remote, producerLocalId, producerId);

      DebugLogger.debug('PlotService', '_refreshPlotsInBackground',
          'Background refresh completed');
    } catch (e) {
      DebugLogger.warning('PlotService', '_refreshPlotsInBackground',
          'Background refresh failed: $e');
      // Silently fail - this is background operation
    }
  }

  /// Cache plots from remote API
  Future<void> _cachePlots(
    List<model.Plot> plots,
    int producerLocalId,
    String remoteProducerId,
  ) async {
    if (_db == null) return;

    DebugLogger.info('PlotService', '_cachePlots',
        'Caching ${plots.length} plots for producer $producerLocalId');

    try {
      // Convert to local Companions with synced status
      final localPlots =
          plots.map((p) => _toCacheCompanion(p, producerLocalId)).toList();

      await _db.plotsDao.cacheFromRemote(
        localPlots,
        onlyForRemoteProducerId: remoteProducerId,
      );

      DebugLogger.info('PlotService', '_cachePlots',
          'Successfully cached ${plots.length} plots');
    } catch (e, st) {
      DebugLogger.error('PlotService', '_cachePlots',
          'Error caching plots: $e', stackTrace: st);
      rethrow;
    }
  }

  /// Resolve producer local ID from producerId (can be local ID or remote UUID)
  Future<int> _resolveProducerLocalId(String producerId) async {
    // Try parsing as local ID first
    final localId = int.tryParse(producerId);
    if (localId != null) {
      DebugLogger.debug('PlotService', '_resolveProducerLocalId',
          'Producer ID is local ID: $localId');
      return localId;
    }

    // Otherwise, it's a UUID - find by remoteId
    DebugLogger.debug('PlotService', '_resolveProducerLocalId',
        'Producer ID is UUID, finding local producer: $producerId');

    final producer = await _db!.producersDao.getByRemoteId(producerId);
    if (producer == null) {
      throw Exception('Producer not found with remoteId: $producerId');
    }

    DebugLogger.debug('PlotService', '_resolveProducerLocalId',
        'Found local producer ID: ${producer.id}');

    return producer.id;
  }

  /// Convert local plot to model Plot
  model.Plot _toModelPlot(Plot local, String producerId) {
    return model.Plot(
      id: local.remoteId ?? local.id.toString(),
      name: local.name,
      code: local.code,
      producerId: producerId,
      isActive: true,
      defaultExtractionPercentage: local.defaultExtractionPercentage,
      defaultCachazaPercentage: local.defaultCachazaPercentage,
      createdAt: local.createdAt,
      updatedAt: local.createdAt,
    );
  }

  /// Fila de caché local (sincronizada) para una parcela del servidor.
  PlotsCompanion _toCacheCompanion(model.Plot p, int producerLocalId) {
    return PlotsCompanion.insert(
      name: p.name,
      code: p.code,
      producerLocalId: producerLocalId,
      defaultExtractionPercentage: drift.Value(p.defaultExtractionPercentage),
      defaultCachazaPercentage: drift.Value(p.defaultCachazaPercentage),
      syncStatus: drift.Value(SyncStatus.synced.value),
      remoteId: drift.Value(p.id),
      remoteProducerId: drift.Value(p.producerId),
      syncedAt: drift.Value(DateTime.now()),
    );
  }

  /// Refresh plots cache from Supabase (public wrapper)
  ///
  /// This method is called by FormDataCacheService during login.
  Future<void> refreshCache() async {
    DebugLogger.info('PlotService', 'refreshCache',
        'Refreshing plots cache from Supabase');

    try {
      // Get all plots from Supabase
      final plots = await getPlots();

      DebugLogger.info('PlotService', 'refreshCache',
          'Fetched ${plots.length} plots from Supabase');

      // Group by producer and cache
      final plotsByProducer = <int, List<model.Plot>>{};
      int failedCount = 0;

      for (final plot in plots) {
        try {
          // Resolve producer local ID
          final producerLocalId = await _resolveProducerLocalId(plot.producerId);
          plotsByProducer.putIfAbsent(producerLocalId, () => []).add(plot);
        } catch (e) {
          // Log error but continue with other plots
          DebugLogger.warning('PlotService', 'refreshCache',
              'Failed to resolve producer for plot ${plot.id} (${plot.name}): $e');
          failedCount++;
        }
      }

      DebugLogger.info('PlotService', 'refreshCache',
          'Grouped ${plots.length - failedCount} plots into ${plotsByProducer.length} producers. Failed: $failedCount');

      if (plotsByProducer.isEmpty) {
        DebugLogger.info('PlotService', 'refreshCache',
            'No plots to cache');
        return;
      }

      // Convert all plots to PlotsCompanion for batch insert
      final allPlotsCompanions = <PlotsCompanion>[];

      for (final entry in plotsByProducer.entries) {
        final producerLocalId = entry.key;
        final producerPlots = entry.value;

        final companions = producerPlots
            .map((p) => _toCacheCompanion(p, producerLocalId))
            .toList();

        allPlotsCompanions.addAll(companions);
      }

      // Actualiza conservando los ids locales (ver PlotsDao.cacheFromRemote)
      DebugLogger.info('PlotService', 'refreshCache',
          'Caching ${allPlotsCompanions.length} plots');

      await _db!.plotsDao.cacheFromRemote(allPlotsCompanions);

      DebugLogger.info('PlotService', 'refreshCache',
          'Successfully cached ${plots.length - failedCount}/${plots.length} plots');
    } catch (e, st) {
      DebugLogger.error('PlotService', 'refreshCache',
          'Error refreshing cache: $e', stackTrace: st);
      rethrow;
    }
  }

  // ── Gestión de parcelas (solo administradores) ─────────────────────────────
  //
  // Requieren conexión. La base de datos solo deja escribir parcelas a
  // admin_sistema, admin_modulo y admin_web; si otro rol lo intenta, el
  // INSERT falla (42501) y el UPDATE no afecta filas: ambos casos se
  // muestran como falta de permiso.

  static const _noPermission =
      'Solo los administradores pueden modificar parcelas';

  /// Todas las parcelas de un productor sincronizado, activas primero.
  Future<List<model.Plot>> getPlotsForManagement(String producerId) async {
    final response = await _supabase
        .from('plots')
        .select()
        .eq('producer_id', producerId)
        .order('is_active', ascending: false)
        .order('name')
        .order('code');
    return (response as List).map((json) => model.Plot.fromJson(json)).toList();
  }

  /// Crea ([id] null) o actualiza una parcela. El código lo asigna la base
  /// de datos al crear. Los % vacíos (null) quedan sin valor por defecto
  /// propio: se usará el del productor o el del sistema.
  Future<model.Plot> savePlot({
    String? id,
    required String producerId,
    required String name,
    double? defaultExtractionPercentage,
    double? defaultCachazaPercentage,
  }) async {
    final data = {
      'name': name.trim(),
      'default_extraction_percentage': defaultExtractionPercentage,
      'default_cachaza_percentage': defaultCachazaPercentage,
    };
    try {
      final List response;
      if (id == null) {
        response = await _supabase
            .from('plots')
            .insert({...data, 'producer_id': producerId})
            .select();
      } else {
        response = await _supabase
            .from('plots')
            .update({...data, 'updated_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id)
            .select();
      }
      if (response.isEmpty) throw Exception(_noPermission);
      await _refreshProducerPlotsCache(producerId);
      return model.Plot.fromJson(response.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(_plotWriteError(e));
    }
  }

  /// Da de baja (false) o reactiva (true) una parcela. Una parcela dada de
  /// baja deja de aparecer al registrar producción; los lotes ya
  /// registrados con ella no cambian.
  Future<void> setPlotActive(String id, String producerId, bool isActive) async {
    try {
      final List response = await _supabase
          .from('plots')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select('id');
      if (response.isEmpty) throw Exception(_noPermission);
      await _refreshProducerPlotsCache(producerId);
    } on PostgrestException catch (e) {
      throw Exception(_plotWriteError(e));
    }
  }

  String _plotWriteError(PostgrestException e) {
    if (e.code == '42501') return _noPermission;
    if (e.code == '23505') return 'Este productor ya tiene una parcela con ese nombre';
    return 'No se pudo guardar la parcela';
  }

  /// Pone al día la caché local de las parcelas de un productor para que el
  /// cambio se vea enseguida al registrar producción (también sin conexión).
  /// Si falla no interrumpe: la caché se refresca igual en la próxima
  /// actualización de datos.
  Future<void> _refreshProducerPlotsCache(String producerId) async {
    if (_db == null) return;
    try {
      final remote = await getPlotsByProducerId(producerId);
      final producerLocalId = await _resolveProducerLocalId(producerId);
      await _cachePlots(remote, producerLocalId, producerId);
    } catch (e) {
      DebugLogger.warning('PlotService', '_refreshProducerPlotsCache',
          'No se pudo actualizar la caché de parcelas: $e');
    }
  }
}
