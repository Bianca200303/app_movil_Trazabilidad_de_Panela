import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/production_batch.dart';
import 'package:panela_sys/models/batch_temperature.dart';
import 'package:panela_sys/models/batch_ph_control.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/production_calculator.dart';
import 'package:panela_sys/core/batch_code_generator.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:drift/drift.dart' as drift;
import 'package:panela_sys/core/offline/network_errors.dart';
import 'package:panela_sys/core/utils/uuid_v4.dart';
import 'package:panela_sys/services/sync/production_batch_uploader.dart';

class CreateProductionBatchRequest {
  final String? batchCode; // Pre-generated batch code (optional)
  final String producerId;
  final String? plotId;
  final DateTime harvestDate;
  final List<DateTime> additionalHarvestDates;
  final DateTime processDate;
  final double juiceLiters;
  final double panelaKg;
  final double confitilloKg;
  final double extractionPercentage;
  final double cachazaPercentage;
  final List<String> selectedCertificateIds;
  final List<double> temperatures;
  // Paralela a `temperatures` (mismo índice) -- minutos desde la miel
  // anterior. Puede tener valores null (ej. la primera temperatura no tiene
  // "miel anterior" contra la cual medir tiempo).
  final List<double?> timeBetweenMielesMinutes;
  final double phInitial;
  final double phFinal;
  final String regulatorType;
  final double? regulatorQuantityValue;
  final String? regulatorQuantityUnit;
  final double? brix;
  final String? correctiveAction;
  final double density;
  final double? latitude;
  final double? longitude;
  final String? locationText;
  final String? cooperativeId;
  final String? observations;

  CreateProductionBatchRequest({
    this.batchCode,
    required this.producerId,
    this.plotId,
    required this.harvestDate,
    this.additionalHarvestDates = const [],
    required this.processDate,
    required this.juiceLiters,
    required this.panelaKg,
    required this.confitilloKg,
    required this.extractionPercentage,
    required this.cachazaPercentage,
    required this.selectedCertificateIds,
    required this.temperatures,
    this.timeBetweenMielesMinutes = const [],
    required this.phInitial,
    required this.phFinal,
    this.regulatorType = 'cal',
    this.regulatorQuantityValue,
    this.regulatorQuantityUnit,
    this.brix,
    this.correctiveAction,
    this.density = ProductionCalculator.sugarCaneDensity,
    this.latitude,
    this.longitude,
    this.locationText,
    this.cooperativeId,
    this.observations,
  });
}

class ProductionBatchService {
  final AppDatabase _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  ProductionBatchService({AppDatabase? db}) : _db = db ?? AppDatabase();

  /// Registra un lote nuevo, con o sin señal.
  ///
  /// 1. Lo guarda siempre primero en el celular, con su id fijo (clientId)
  ///    y su código definitivo (el que el técnico vio en el resumen).
  /// 2. Si hay señal, lo sube en el momento con ProductionBatchUploader
  ///    (una sola llamada atómica e idempotente).
  /// 3. Si no hay señal o la subida falla, queda pendiente y se sube solo
  ///    después (ProductionSyncService), con el mismo id y código.
  Future<ProductionBatch> createProductionBatch(
      CreateProductionBatchRequest request) async {
    DebugLogger.info('ProductionBatchService', 'createProductionBatch',
        'Iniciando registro de lote de producción');

    try {
      final db = _db;

      // 1. Resolve producer and plot LOCAL IDs
      final producerLocalId = await _resolveProducerLocalId(request.producerId);
      final plotLocalId = request.plotId != null
          ? await _resolvePlotLocalId(request.plotId!)
          : null;

      DebugLogger.debug('ProductionBatchService', 'createProductionBatch',
          'Resolved IDs - Producer: $producerLocalId, Plot: $plotLocalId');

      // 2. Use pre-generated batch code or generate new one
      final batchCode = request.batchCode ?? BatchCodeGenerator.generate(
        cooperativePrefix: AppConfig.current.batchCodePrefix,
        harvestDate: request.harvestDate,
      );

      // 3. Calculate fields using ProductionCalculator
      final juiceWeightKg =
          ProductionCalculator.calculateJuiceWeight(request.juiceLiters, density: request.density);
      final caneKg = ProductionCalculator.calculateCaneInput(
          juiceWeightKg, request.extractionPercentage);
      final efficiency = ProductionCalculator.calculateYield(
          request.panelaKg, request.juiceLiters).clamp(0.0, 999.99);

      DebugLogger.debug('ProductionBatchService', 'createProductionBatch',
          'Calculated: caneKg=$caneKg, efficiency=$efficiency');

      // 4. Save batch to local DB
      DebugLogger.info('ProductionBatchService', 'createProductionBatch',
          'Guardando lote en DB local');

      final batchLocalId = await db.productionBatchesDao.create(
        ProductionBatchesCompanion.insert(
          batchCode: batchCode,
          harvestDate: request.harvestDate,
          processDate: request.processDate,
          caneKg: caneKg,
          juiceLiters: request.juiceLiters,
          panelaKg: request.panelaKg,
          confitilloKg: request.confitilloKg,
          porcentajeExtraccion: drift.Value(request.extractionPercentage),
          cachazaPercentage: drift.Value(request.cachazaPercentage),
          efficiencyPercentage: efficiency,
          caneDensity: drift.Value(request.density),
          latitude: drift.Value(request.latitude),
          longitude: drift.Value(request.longitude),
          locationText: drift.Value(request.locationText),
          observations: drift.Value(request.observations),
          producerLocalId: producerLocalId,
          plotLocalId: drift.Value(plotLocalId),
          cooperativeId: AppConfig.current.id,
          syncStatus: drift.Value(SyncStatus.pending.value),
          clientId: drift.Value(generateUuidV4()),
        ),
      );

      DebugLogger.info('ProductionBatchService', 'createProductionBatch',
          'Lote guardado localmente con ID: $batchLocalId');

      // 5. Save related tables
      await _saveBatchCerts(batchLocalId, request.selectedCertificateIds);
      await _saveBatchTemperatures(batchLocalId, request.temperatures, request.timeBetweenMielesMinutes);
      await _saveBatchHarvestDates(batchLocalId, request.additionalHarvestDates);
      await _saveBatchPhControl(batchLocalId, request);

      // 6. Si hay señal, se sube ya; si no, queda pendiente.
      if (await NetworkDetector().isConnected) {
        await _tryUploadNow(batchLocalId);
      } else {
        DebugLogger.info('ProductionBatchService', 'createProductionBatch',
            'Sin conexión - lote quedará pendiente de sync');
      }

      // 8. Return local batch
      final localBatch = await db.productionBatchesDao.getById(batchLocalId);
      return _buildFromLocal(localBatch!, producerLocalId, plotLocalId);
    } catch (e, st) {
      DebugLogger.error('ProductionBatchService', 'createProductionBatch',
          'Error al crear lote: $e',
          stackTrace: st);
      rethrow;
    }
  }

  /// Elimina del celular un lote que todavía no se subió (decisión del
  /// usuario, p. ej. uno rechazado que ya no se puede corregir), junto con
  /// sus datos y los controles guardados sin señal que dependían de él.
  /// No toca nada del servidor. Un lote ya subido no se puede descartar.
  Future<void> discardUnsentBatch(int batchLocalId) async {
    await _db.transaction(() async {
      final batch = await _db.productionBatchesDao.getById(batchLocalId);
      if (batch == null) return;
      if (batch.remoteId != null) {
        throw StateError('El lote ${batch.batchCode} ya se subió y no se puede descartar');
      }
      await _db.pendingSubmissionsDao.deleteByProductionBatchLocalId(batchLocalId);
      await _db.productionBatchCertsDao.deleteByBatchLocalId(batchLocalId);
      await _db.batchTemperaturesDao.deleteByBatchLocalId(batchLocalId);
      await _db.productionBatchHarvestDatesDao.deleteByBatchLocalId(batchLocalId);
      await _db.batchPhControlsDao.deleteByBatchLocalId(batchLocalId);
      await _db.productionBatchesDao.deleteById(batchLocalId);
    });
    DebugLogger.warning('ProductionBatchService', 'discardUnsentBatch',
        'Lote local $batchLocalId descartado por el usuario');
  }

  /// Intenta subir en el momento un lote recién guardado. Nunca falla: si
  /// no se puede (sin señal, productor/parcela aún sin subir, rechazo), el
  /// lote queda pendiente y ProductionSyncService lo reintenta.
  Future<void> _tryUploadNow(int batchLocalId) async {
    final batch = await _db.productionBatchesDao.getById(batchLocalId);
    if (batch == null) return;
    try {
      await ProductionBatchUploader(_db, supabase: _supabase).upload(batch);
    } on BatchDependencyPendingException catch (e) {
      DebugLogger.info('ProductionBatchService', '_tryUploadNow',
          'Lote ${batch.batchCode} queda pendiente: $e');
    } catch (e) {
      if (!isTransientNetworkError(e)) {
        await _db.productionBatchesDao.markSyncRejected(
          batchLocalId,
          e is PostgrestException ? e.message : e.toString().replaceAll('Exception: ', ''),
        );
      }
      DebugLogger.warning('ProductionBatchService', '_tryUploadNow',
          'Subida inmediata falló: $e. Se sincronizará después.');
    }
  }

  /// Fetches all production batches for the current user's cooperative
  Future<List<ProductionBatch>> getProductionBatches() async {
    try {
      final response = await _supabase
          .from('production_batches')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductionBatch.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener lotes de producción: $e');
    }
  }

  /// Fetches a specific production batch by ID with related data
  Future<Map<String, dynamic>?> getProductionBatchWithDetails(String batchId) async {
    try {
      // Get production batch
      final batchResponse = await _supabase
          .from('production_batches')
          .select('''
            *,
            producers!inner(
              first_name,
              last_name,
              dni
            ),
            plots(
              id,
              name,
              code
            )
          ''')
          .eq('id', batchId)
          .maybeSingle();

      if (batchResponse == null) return null;

      final batch = ProductionBatch.fromJson(batchResponse);

      // Get certificates
      final certsResponse = await _supabase
          .from('production_batch_certs')
          .select('''
            *,
            batch_certs!inner(
              name
            )
          ''')
          .eq('production_batch_id', batchId);

      // Get temperatures
      final tempsResponse = await _supabase
          .from('batch_temperatures')
          .select()
          .eq('production_batch_id', batchId)
          .order('sequence_number');

      // Get pH controls
      final phResponse = await _supabase
          .from('batch_ph_controls')
          .select()
          .eq('production_batch_id', batchId);

      return {
        'batch': batch,
        'producer': batchResponse['producers'],
        'plot': batchResponse['plots'],
        'certificates': certsResponse,
        'temperatures': tempsResponse.map((temp) => BatchTemperature.fromJson(temp)).toList(),
        'phControls': phResponse.map((ph) => BatchPhControl.fromJson(ph)).toList(),
      };
    } catch (e) {
      throw Exception('Error al obtener detalles del lote: $e');
    }
  }

  /// Get production batches for historial with smart loading
  ///
  /// Behavior depends on offline mode:
  /// - Offline disabled: fetch from Supabase only
  /// - Offline enabled + no connection: fetch local pending only
  /// - Offline enabled + connected: fetch local pending + remote (combined)
  Future<List<Map<String, dynamic>>> getProductionBatchesForHistorial({
    DateTime? from,
    DateTime? to,
  }) async {
    if (!OfflineConfig.instance.features.production) {
      return await _getProductionFromSupabase(from: from, to: to);
    }

    final isConnected = await NetworkDetector().isConnected;

    if (!isConnected) {
      DebugLogger.info('ProductionBatchService', 'getProductionBatchesForHistorial',
          'Offline mode: returning local pending batches only');
      return await _getLocalPendingBatches();
    } else {
      DebugLogger.info('ProductionBatchService', 'getProductionBatchesForHistorial',
          'Online mode: returning combined local + remote batches');
      return await _getCombinedBatches(from: from, to: to);
    }
  }

  /// Get local pending batches (offline mode)
  Future<List<Map<String, dynamic>>> _getLocalPendingBatches() async {
    DebugLogger.info('ProductionBatchService', '_getLocalPendingBatches',
        'Fetching local pending batches for historial');

    final pending = await _db.productionBatchesDao.getPending(AppConfig.current.id);
    final results = <Map<String, dynamic>>[];

    for (final batch in pending) {
      final producer = await _db.producersDao.getById(batch.producerLocalId);

      String? plotName;
      if (batch.plotLocalId != null) {
        final plot = await _db.plotsDao.getById(batch.plotLocalId!);
        plotName = plot?.name;
      }

      String moduleName = '';
      if (producer != null && producer.coopModuleId.isNotEmpty) {
        final module = await _db.coopModulesDao.getById(producer.coopModuleId);
        moduleName = module?.name ?? '';
      }

      results.add({
        'id': batch.id.toString(),
        'codigo_lote': batch.batchCode,
        'productor': producer != null
            ? '${producer.firstName} ${producer.lastName}'
            : 'Desconocido',
        'dni_productor': producer?.dni ?? '',
        'modulo': moduleName,
        'parcela': plotName ?? 'No especificada',
        'fecha_cosecha': batch.harvestDate,
        'fecha_proceso': batch.processDate,
        'cana_kg': batch.caneKg,
        'jugo_litros': batch.juiceLiters,
        'panela_kg': batch.panelaKg,
        'confitillo_kg': batch.confitilloKg,
        'porcentaje_extraccion': batch.porcentajeExtraccion ?? 0.0,
        'eficiencia': batch.efficiencyPercentage,
        'fecha_registro': batch.createdAt,
        'syncStatus': batch.syncStatus,
      });
    }

    DebugLogger.info('ProductionBatchService', '_getLocalPendingBatches',
        'Returning ${results.length} local pending batches');

    return results;
  }

  /// Get combined batches: local pending + remote (online mode)
  Future<List<Map<String, dynamic>>> _getCombinedBatches({
    DateTime? from,
    DateTime? to,
  }) async {
    final results = <Map<String, dynamic>>[];
    final localPending = await _getLocalPendingBatches();
    results.addAll(localPending);
    final remoteBatches = await _getProductionFromSupabase(from: from, to: to);
    for (final remote in remoteBatches) {
      results.add({ ...remote, 'syncStatus': SyncStatus.synced.value });
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _getProductionFromSupabase({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final today = DateTime.now();
      final fromStr = (from ?? DateTime(today.year, today.month - 1, today.day))
          .toIso8601String().split('T')[0];
      final toStr = (to ?? today).toIso8601String().split('T')[0];

      final response = await _supabase
          .from('production_batches')
          .select('''
            id, batch_code, harvest_date, process_date,
            cane_kg, juice_liters, panela_kg, confitillo_kg,
            porcentaje_extraccion, efficiency_percentage, created_at,
            producers!inner(
              first_name, last_name, dni,
              coop_modules( name )
            ),
            plots( name, code ),
            registered_by_user:users!production_batches_registered_by_fkey(first_name, last_name)
          ''')
          .gte('process_date', fromStr)
          .lte('process_date', toStr)
          .order('process_date', ascending: false);

      return (response as List).map((item) {
        final plot = item['plots'];
        final producer = item['producers'];
        final module = producer['coop_modules'];
        final regUser = item['registered_by_user'] as Map<String, dynamic>?;
        return {
          'id': item['id'],
          'codigo_lote': item['batch_code'],
          'productor': '${producer['first_name']} ${producer['last_name']}',
          'dni_productor': producer['dni'],
          'modulo': module?['name'] ?? '',
          'parcela': plot != null ? '${plot['name']} (${plot['code']})' : 'No especificada',
          'fecha_cosecha': DateTime.parse(item['harvest_date']).toLocal(),
          'fecha_proceso': DateTime.parse(item['process_date']).toLocal(),
          'cana_kg': (item['cane_kg'] as num).toDouble(),
          'jugo_litros': (item['juice_liters'] as num).toDouble(),
          'panela_kg': (item['panela_kg'] as num?)?.toDouble() ?? 0.0,
          'confitillo_kg': (item['confitillo_kg'] as num?)?.toDouble() ?? 0.0,
          'porcentaje_extraccion': (item['porcentaje_extraccion'] as num?)?.toDouble() ?? 0.0,
          'eficiencia': (item['efficiency_percentage'] as num).toDouble(),
          'fecha_registro': DateTime.parse(item['created_at']).toLocal(),
          'registrado_por': regUser != null ? '${regUser['first_name']} ${regUser['last_name']}' : null,
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de lotes: $e');
    }
  }

  // ==================== OFFLINE HELPER METHODS ====================

  /// Resolve producer local ID from producerId (can be local ID or remote UUID)
  Future<int> _resolveProducerLocalId(String producerId) async {
    // Try parsing as local ID first
    final localId = int.tryParse(producerId);
    if (localId != null) {
      DebugLogger.debug('ProductionBatchService', '_resolveProducerLocalId',
          'Producer ID is local ID: $localId');
      return localId;
    }

    // Otherwise, it's a UUID - find by remoteId
    DebugLogger.debug('ProductionBatchService', '_resolveProducerLocalId',
        'Producer ID is UUID, finding local producer: $producerId');

    final producer = await _db.producersDao.getByRemoteId(producerId);
    if (producer == null) {
      throw Exception('Producer not found with remoteId: $producerId');
    }

    DebugLogger.debug('ProductionBatchService', '_resolveProducerLocalId',
        'Found local producer ID: ${producer.id}');

    return producer.id;
  }

  /// Resolve plot local ID from plotId (can be local ID or remote UUID)
  Future<int> _resolvePlotLocalId(String plotId) async {
    // Try parsing as local ID first
    final localId = int.tryParse(plotId);
    if (localId != null) {
      DebugLogger.debug('ProductionBatchService', '_resolvePlotLocalId',
          'Plot ID is local ID: $localId');
      return localId;
    }

    // Otherwise, it's a UUID - find by remoteId
    DebugLogger.debug('ProductionBatchService', '_resolvePlotLocalId',
        'Plot ID is UUID, finding local plot: $plotId');

    final plot = await _db.plotsDao.getByRemoteId(plotId);
    if (plot == null) {
      throw Exception('Plot not found with remoteId: $plotId');
    }

    DebugLogger.debug('ProductionBatchService', '_resolvePlotLocalId',
        'Found local plot ID: ${plot.id}');

    return plot.id;
  }

  /// Save batch certificates to local DB
  Future<void> _saveBatchCerts(
      int batchLocalId, List<String> certificateIds) async {
    if (certificateIds.isEmpty) return;

    DebugLogger.debug('ProductionBatchService', '_saveBatchCerts',
        'Saving ${certificateIds.length} certificates for batch $batchLocalId');

    final companions = certificateIds
        .map((certId) => ProductionBatchCertsCompanion.insert(
              productionBatchLocalId: batchLocalId,
              batchCertId: certId,
              cooperativeId: AppConfig.current.id,
              syncStatus: drift.Value(SyncStatus.pending.value),
            ))
        .toList();

    await _db.productionBatchCertsDao.createBatch(companions);
  }

  /// Save batch temperatures to local DB
  Future<void> _saveBatchTemperatures(
      int batchLocalId, List<double> temperatures, List<double?> timeBetweenMielesMinutes) async {
    if (temperatures.isEmpty) return;

    DebugLogger.debug('ProductionBatchService', '_saveBatchTemperatures',
        'Saving ${temperatures.length} temperatures for batch $batchLocalId');

    final companions = temperatures
        .asMap()
        .entries
        .map((entry) => BatchTemperaturesCompanion.insert(
              productionBatchLocalId: batchLocalId,
              temperature: entry.value,
              sequenceNumber: entry.key + 1,
              timeBetweenMielesMinutes: drift.Value(
                  entry.key < timeBetweenMielesMinutes.length ? timeBetweenMielesMinutes[entry.key] : null),
              cooperativeId: AppConfig.current.id,
              syncStatus: drift.Value(SyncStatus.pending.value),
            ))
        .toList();

    await _db.batchTemperaturesDao.createBatch(companions);
  }

  /// Save additional harvest dates to local DB
  Future<void> _saveBatchHarvestDates(
      int batchLocalId, List<DateTime> additionalHarvestDates) async {
    if (additionalHarvestDates.isEmpty) return;

    DebugLogger.debug('ProductionBatchService', '_saveBatchHarvestDates',
        'Saving ${additionalHarvestDates.length} harvest dates for batch $batchLocalId');

    final companions = additionalHarvestDates
        .map((date) => ProductionBatchHarvestDatesCompanion.insert(
              productionBatchLocalId: batchLocalId,
              harvestDate: date,
              cooperativeId: AppConfig.current.id,
              syncStatus: drift.Value(SyncStatus.pending.value),
            ))
        .toList();

    await _db.productionBatchHarvestDatesDao.createBatch(companions);
  }

  /// Save batch pH control to local DB
  Future<void> _saveBatchPhControl(
      int batchLocalId, CreateProductionBatchRequest request) async {
    DebugLogger.debug('ProductionBatchService', '_saveBatchPhControl',
        'Saving pH control for batch $batchLocalId');

    await _db.batchPhControlsDao.create(
      BatchPhControlsCompanion.insert(
        productionBatchLocalId: batchLocalId,
        recordDate: DateTime.now(),
        regulatorType: request.regulatorType,
        phInitial: request.phInitial,
        phFinal: request.phFinal,
        regulatorQuantityValue: drift.Value(request.regulatorQuantityValue),
        regulatorQuantityUnit: drift.Value(request.regulatorQuantityUnit),
        brix: drift.Value(request.brix),
        correctiveAction: drift.Value(request.correctiveAction),
        cooperativeId: AppConfig.current.id,
        syncStatus: drift.Value(SyncStatus.pending.value),
      ),
    );
  }


  /// Build ProductionBatch model from local data
  ProductionBatch _buildFromLocal(
    ProductionBatchLocal local,
    int producerLocalId,
    int? plotLocalId,
  ) {
    return ProductionBatch(
      id: local.id.toString(), // Use local ID as string
      batchCode: local.batchCode,
      harvestDate: local.harvestDate,
      processDate: local.processDate,
      caneKg: local.caneKg,
      juiceLiters: local.juiceLiters,
      panelaKg: local.panelaKg,
      confitilloKg: local.confitilloKg,
      porcentajeExtraccion: local.porcentajeExtraccion,
      cachazaPercentage: local.cachazaPercentage,
      efficiencyPercentage: local.efficiencyPercentage,
      producerId: producerLocalId.toString(),
      plotId: plotLocalId?.toString(),
      cooperativeId: local.cooperativeId,
      createdAt: local.createdAt,
      updatedAt: local.createdAt,
    );
  }


}
