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

class CreateProductionBatchRequest {
  final String? batchCode; // Pre-generated batch code (optional)
  final String producerId;
  final String? plotId;
  final DateTime harvestDate;
  final DateTime processDate;
  final double juiceLiters;
  final double panelaKg;
  final double confitilloKg;
  final double extractionPercentage;
  final double cachazaPercentage;
  final List<String> selectedCertificateIds;
  final List<double> temperatures;
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

  CreateProductionBatchRequest({
    this.batchCode,
    required this.producerId,
    this.plotId,
    required this.harvestDate,
    required this.processDate,
    required this.juiceLiters,
    required this.panelaKg,
    required this.confitilloKg,
    required this.extractionPercentage,
    required this.cachazaPercentage,
    required this.selectedCertificateIds,
    required this.temperatures,
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
  });
}

class ProductionBatchService {
  final AppDatabase? _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  ProductionBatchService({AppDatabase? db}) : _db = db;

  /// Creates a new production batch with offline-first approach
  ///
  /// If offline is enabled:
  /// 1. Saves to local database first (always succeeds)
  /// 2. Attempts immediate sync if online
  /// 3. Returns local data if sync fails
  ///
  /// If offline is disabled:
  /// - Creates directly in Supabase (original behavior)
  Future<ProductionBatch> createProductionBatch(
      CreateProductionBatchRequest request) async {
    DebugLogger.info('ProductionBatchService', 'createProductionBatch',
        'Iniciando registro de lote de producción');

    // Verify if offline is enabled
    final offlineEnabled = OfflineConfig.instance.features.production;
    DebugLogger.debug('ProductionBatchService', 'createProductionBatch',
        'Offline enabled: $offlineEnabled, Database available: ${_db != null}');

    if (!offlineEnabled || _db == null) {
      DebugLogger.info('ProductionBatchService', 'createProductionBatch',
          'Modo online - registrando directamente en Supabase');
      return await createOnline(request);
    }

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
          producerLocalId: producerLocalId,
          plotLocalId: drift.Value(plotLocalId),
          cooperativeId: AppConfig.current.id,
          syncStatus: drift.Value(SyncStatus.pending.value),
        ),
      );

      DebugLogger.info('ProductionBatchService', 'createProductionBatch',
          'Lote guardado localmente con ID: $batchLocalId');

      // 5. Save related tables
      await _saveBatchCerts(batchLocalId, request.selectedCertificateIds);
      await _saveBatchTemperatures(batchLocalId, request.temperatures);
      await _saveBatchPhControl(batchLocalId, request);

      // 6. Check connectivity
      final isConnected = await NetworkDetector().isConnected;
      DebugLogger.debug('ProductionBatchService', 'createProductionBatch',
          'Network status: ${isConnected ? "ONLINE" : "OFFLINE"}');

      // 7. Try immediate sync if online
      if (isConnected) {
        DebugLogger.info('ProductionBatchService', 'createProductionBatch',
            'Intentando sincronización inmediata');

        try {
          // Check if producer and plot are synced
          final producer = await db.producersDao.getById(producerLocalId);
          if (producer?.remoteId == null) {
            throw Exception('Producer not synced yet');
          }

          String? plotRemoteId;
          if (plotLocalId != null) {
            final plot = await db.plotsDao.getById(plotLocalId);
            if (plot?.remoteId == null) {
              throw Exception('Plot not synced yet');
            }
            plotRemoteId = plot!.remoteId;
          }

          // Create request with remote IDs
          final remoteRequest = CreateProductionBatchRequest(
            producerId: producer!.remoteId!,
            plotId: plotRemoteId,
            harvestDate: request.harvestDate,
            processDate: request.processDate,
            juiceLiters: request.juiceLiters,
            panelaKg: request.panelaKg,
            confitilloKg: request.confitilloKg,
            extractionPercentage: request.extractionPercentage,
            cachazaPercentage: request.cachazaPercentage,
            selectedCertificateIds: request.selectedCertificateIds,
            temperatures: request.temperatures,
            phInitial: request.phInitial,
            phFinal: request.phFinal,
            regulatorType: request.regulatorType,
            regulatorQuantityValue: request.regulatorQuantityValue,
            regulatorQuantityUnit: request.regulatorQuantityUnit,
            brix: request.brix,
            correctiveAction: request.correctiveAction,
            density: request.density,
            latitude: request.latitude,
            longitude: request.longitude,
            locationText: request.locationText,
          );

          final remoteBatch = await createOnline(remoteRequest);

          DebugLogger.info('ProductionBatchService', 'createProductionBatch',
              'Sync exitoso, marcando como synced');

          await db.productionBatchesDao.markAsSynced(
            localId: batchLocalId,
            remoteId: remoteBatch.id,
          );

          // Mark related tables as synced
          DebugLogger.debug('ProductionBatchService', 'createProductionBatch',
              'Marking related tables as synced');

          await _markRelatedAsSynced(db, batchLocalId);

          DebugLogger.info('ProductionBatchService', 'createProductionBatch',
              'All tables marked as synced successfully');

          return remoteBatch;
        } catch (e) {
          DebugLogger.warning('ProductionBatchService', 'createProductionBatch',
              'Sync inmediato falló: $e. Se sincronizará después.');
        }
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

  /// Creates production batch directly in Supabase
  ///
  /// This is the original implementation, now called when offline is disabled
  /// or during sync operations.
  ///
  /// Made public for use by ProductionSyncService.
  Future<ProductionBatch> createOnline(
      CreateProductionBatchRequest request) async {
    DebugLogger.info('ProductionBatchService', 'createOnline',
        'Registrando en Supabase');

    try {
      // Check user authentication
      if (_supabase.auth.currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      // Get cooperative ID from configuration
      final cooperativeId = AppConfig.current.id;

      // Use pre-generated batch code or generate new one
      final batchCode = request.batchCode ?? BatchCodeGenerator.generate(
        cooperativePrefix: AppConfig.current.batchCodePrefix,
        harvestDate: request.harvestDate,
      );

      // Calculate cane quantity and efficiency
      final juiceWeightKg =
          ProductionCalculator.calculateJuiceWeight(request.juiceLiters, density: request.density);
      final caneKg = ProductionCalculator.calculateCaneInput(
          juiceWeightKg, request.extractionPercentage);
      final efficiency = ProductionCalculator.calculateYield(
          request.panelaKg, request.juiceLiters).clamp(0.0, 999.99);

      // 1. Create production batch
      final insertData = {
        'batch_code': batchCode,
        'harvest_date': request.harvestDate.toIso8601String().split('T')[0],
        'process_date': request.processDate.toIso8601String().split('T')[0],
        'cane_kg': caneKg,
        'juice_liters': request.juiceLiters,
        'panela_kg': request.panelaKg,
        'confitillo_kg': request.confitilloKg,
        'porcentaje_extraccion': request.extractionPercentage,
        'cachaza_percentage': request.cachazaPercentage,
        'efficiency_percentage': efficiency,
        'cane_density': request.density,
        'producer_id': request.producerId,
        'cooperative_id': cooperativeId,
      };

      // Only include plot_id if provided
      if (request.plotId != null && request.plotId!.isNotEmpty) {
        insertData['plot_id'] = request.plotId!;
      }

      // Include location data if available
      if (request.latitude != null) {
        insertData['latitude'] = request.latitude!;
      }
      if (request.longitude != null) {
        insertData['longitude'] = request.longitude!;
      }
      if (request.locationText != null) {
        insertData['location_text'] = request.locationText!;
      }

      DebugLogger.debug('ProductionBatchService', 'createOnline',
          'Sending to Supabase: $insertData');

      final batchResponse = await _supabase
          .from('production_batches')
          .insert(insertData)
          .select()
          .single();

      DebugLogger.debug('ProductionBatchService', 'createOnline',
          'Received from Supabase: $batchResponse');

      final productionBatch = ProductionBatch.fromJson(batchResponse);
      final batchId = productionBatch.id;

      // 2. Create batch certificates
      if (request.selectedCertificateIds.isNotEmpty) {
        final certInserts = request.selectedCertificateIds.map((certId) => {
          'production_batch_id': batchId,
          'batch_cert_id': certId,
          'cooperative_id': cooperativeId,
        }).toList();

        await _supabase.from('production_batch_certs').insert(certInserts);
      }

      // 3. Create batch temperatures
      if (request.temperatures.isNotEmpty) {
        final tempInserts = request.temperatures.asMap().entries.map((entry) => {
          'production_batch_id': batchId,
          'temperature': entry.value,
          'sequence_number': entry.key + 1,
          'cooperative_id': cooperativeId,
        }).toList();

        await _supabase.from('batch_temperatures').insert(tempInserts);
      }

      // 4. Create pH control record
      await _supabase.from('batch_ph_controls').insert({
        'production_batch_id': batchId,
        'record_date': DateTime.now().toIso8601String(),
        'regulator_type': request.regulatorType,
        'ph_initial': request.phInitial,
        'ph_final': request.phFinal,
        'regulator_quantity_value': request.regulatorQuantityValue,
        'regulator_quantity_unit': request.regulatorQuantityUnit,
        'brix': request.brix,
        'corrective_action': request.correctiveAction,
        'cooperative_id': cooperativeId,
      });

      DebugLogger.info('ProductionBatchService', 'createOnline',
          'Lote creado en Supabase con ID: ${productionBatch.id}');

      return productionBatch;
    } catch (e, st) {
      if (e is PostgrestException) {
        if (e.code == '23505' && e.message.contains('batch_code')) {
          throw Exception('Ya existe un lote con este código');
        }
        if (e.message.contains('foreign key')) {
          throw Exception('El productor seleccionado no es válido');
        }
      }
      DebugLogger.error('ProductionBatchService', 'createOnline',
          'Error en Supabase insert: $e',
          stackTrace: st);
      throw Exception('Error al crear lote de producción: $e');
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
  Future<List<Map<String, dynamic>>> getProductionBatchesForHistorial() async {
    // If offline not enabled, use original Supabase-only behavior
    if (!OfflineConfig.instance.features.production || _db == null) {
      return await _getProductionFromSupabase();
    }

    final isConnected = await NetworkDetector().isConnected;

    if (!isConnected) {
      // OFFLINE: Return only local pending batches
      DebugLogger.info('ProductionBatchService', 'getProductionBatchesForHistorial',
          'Offline mode: returning local pending batches only');
      return await _getLocalPendingBatches();
    } else {
      // ONLINE: Combine local pending + remote
      DebugLogger.info('ProductionBatchService', 'getProductionBatchesForHistorial',
          'Online mode: returning combined local + remote batches');
      return await _getCombinedBatches();
    }
  }

  /// Get local pending batches (offline mode)
  Future<List<Map<String, dynamic>>> _getLocalPendingBatches() async {
    DebugLogger.info('ProductionBatchService', '_getLocalPendingBatches',
        'Fetching local pending batches for historial');

    final pending = await _db!.productionBatchesDao.getPending();
    final results = <Map<String, dynamic>>[];

    for (final batch in pending) {
      // Get producer name
      final producer = await _db.producersDao.getById(batch.producerLocalId);

      // Get plot name if exists
      String? plotName;
      if (batch.plotLocalId != null) {
        final plot = await _db.plotsDao.getById(batch.plotLocalId!);
        plotName = plot?.name;
      }

      results.add({
        'id': batch.id.toString(),
        'codigo_lote': batch.batchCode,
        'productor': producer != null
            ? '${producer.firstName} ${producer.lastName}'
            : 'Desconocido',
        'dni_productor': producer?.dni ?? '',
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
        'syncStatus': batch.syncStatus, // For badge
      });
    }

    DebugLogger.info('ProductionBatchService', '_getLocalPendingBatches',
        'Returning ${results.length} local pending batches');

    return results;
  }

  /// Get combined batches: local pending + remote (online mode)
  Future<List<Map<String, dynamic>>> _getCombinedBatches() async {
    DebugLogger.info('ProductionBatchService', '_getCombinedBatches',
        'Fetching combined local + remote batches for historial');

    final results = <Map<String, dynamic>>[];

    // 1. Get local pending batches FIRST (appear at top)
    final localPending = await _getLocalPendingBatches();
    results.addAll(localPending);

    DebugLogger.debug('ProductionBatchService', '_getCombinedBatches',
        'Added ${localPending.length} local pending batches');

    // 2. Get ALL remote batches from Supabase
    final remoteBatches = await _getProductionFromSupabase();

    // 3. Add ALL remote (no filtering - remote is source of truth)
    for (final remote in remoteBatches) {
      results.add({
        ...remote,
        'syncStatus': SyncStatus.synced.value, // Mark as synced
      });
    }

    DebugLogger.info('ProductionBatchService', '_getCombinedBatches',
        'Returning ${results.length} total (${localPending.length} pending + ${remoteBatches.length} remote)');

    return results;
  }

  /// Get production batches from Supabase (original behavior)
  Future<List<Map<String, dynamic>>> _getProductionFromSupabase() async {
    try {
      // Calculate date range: last month
      final today = DateTime.now();
      final oneMonthAgo = DateTime(today.year, today.month - 1, today.day);
      final todayStr = today.toIso8601String().split('T')[0];
      final oneMonthAgoStr = oneMonthAgo.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('production_batches')
          .select('''
            id,
            batch_code,
            harvest_date,
            process_date,
            cane_kg,
            juice_liters,
            panela_kg,
            confitillo_kg,
            porcentaje_extraccion,
            efficiency_percentage,
            created_at,
            producers!inner(
              first_name,
              last_name,
              dni
            ),
            plots(
              name,
              code
            )
          ''')
          .gte('process_date', oneMonthAgoStr)
          .lte('process_date', todayStr)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final plot = item['plots'];
        return {
          'id': item['id'],
          'codigo_lote': item['batch_code'],
          'productor': '${item['producers']['first_name']} ${item['producers']['last_name']}',
          'dni_productor': item['producers']['dni'],
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

    final producer = await _db!.producersDao.getByRemoteId(producerId);
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

    final plot = await _db!.plotsDao.getByRemoteId(plotId);
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

    await _db!.productionBatchCertsDao.createBatch(companions);
  }

  /// Save batch temperatures to local DB
  Future<void> _saveBatchTemperatures(
      int batchLocalId, List<double> temperatures) async {
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
              cooperativeId: AppConfig.current.id,
              syncStatus: drift.Value(SyncStatus.pending.value),
            ))
        .toList();

    await _db!.batchTemperaturesDao.createBatch(companions);
  }

  /// Save batch pH control to local DB
  Future<void> _saveBatchPhControl(
      int batchLocalId, CreateProductionBatchRequest request) async {
    DebugLogger.debug('ProductionBatchService', '_saveBatchPhControl',
        'Saving pH control for batch $batchLocalId');

    await _db!.batchPhControlsDao.create(
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

  /// Mark related tables as synced after immediate sync success
  ///
  /// This marks certificates, temperatures, and pH control as synced
  /// using placeholder remote IDs since we don't track individual IDs.
  Future<void> _markRelatedAsSynced(AppDatabase db, int batchLocalId) async {
    DebugLogger.debug('ProductionBatchService', '_markRelatedAsSynced',
        'Marking related tables for batch $batchLocalId');

    try {
      // Get all related records
      final certs = await db.productionBatchCertsDao.getByBatchLocalId(batchLocalId);
      final temps = await db.batchTemperaturesDao.getByBatchLocalId(batchLocalId);
      final phControl = await db.batchPhControlsDao.getByBatchLocalId(batchLocalId);

      // Mark certs as synced
      if (certs.isNotEmpty) {
        final certRemoteIds = certs.map((c) => 'SYNCED_${c.id}').toList();
        await db.productionBatchCertsDao.markBatchAsSynced(
          batchLocalId,
          certRemoteIds,
        );
        DebugLogger.debug('ProductionBatchService', '_markRelatedAsSynced',
            'Marked ${certs.length} certificates as synced');
      }

      // Mark temps as synced
      if (temps.isNotEmpty) {
        final tempRemoteIds = temps.map((t) => 'SYNCED_${t.id}').toList();
        await db.batchTemperaturesDao.markBatchAsSynced(
          batchLocalId,
          tempRemoteIds,
        );
        DebugLogger.debug('ProductionBatchService', '_markRelatedAsSynced',
            'Marked ${temps.length} temperatures as synced');
      }

      // Mark pH control as synced
      if (phControl != null) {
        await db.batchPhControlsDao.markAsSynced(
          localId: phControl.id,
          remoteId: 'SYNCED_${phControl.id}',
        );
        DebugLogger.debug('ProductionBatchService', '_markRelatedAsSynced',
            'Marked pH control as synced');
      }
    } catch (e, st) {
      DebugLogger.error('ProductionBatchService', '_markRelatedAsSynced',
          'Error marking related tables: $e', stackTrace: st);
      rethrow;
    }
  }
}
