import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/utils/uuid_v4.dart';

/// El lote todavía no se puede enviar porque su productor o su parcela se
/// crearon sin señal y aún no se subieron. No es un rechazo: se reintenta en
/// la próxima sincronización (los productores y parcelas se suben antes).
class BatchDependencyPendingException implements Exception {
  final String dependency;
  const BatchDependencyPendingException(this.dependency);

  @override
  String toString() => 'El $dependency del lote aún no se subió';
}

/// Sube al servidor un lote de producción guardado en el celular, con todos
/// sus datos (certificaciones, temperaturas, fechas de cosecha, pH), en UNA
/// sola llamada a la RPC `submit_production_batch`:
///   - atómica: el lote se guarda completo o no se guarda;
///   - idempotente: se envía con el id fijo del celular (clientId), así un
///     reenvío tras un corte de señal no lo duplica (ni duplica su stock).
///
/// Único camino de subida de lotes: lo usan el envío inmediato al registrar
/// (ProductionBatchService) y la sincronización posterior
/// (ProductionSyncService).
class ProductionBatchUploader {
  static const _rpcName = 'submit_production_batch';
  static const _sendTimeout = Duration(seconds: 20);

  final AppDatabase _db;
  final SupabaseClient _supabase;

  ProductionBatchUploader(this._db, {SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Sube [batch] y lo marca como sincronizado. Devuelve su id del servidor.
  ///
  /// Lanza:
  ///   - [BatchDependencyPendingException] si su productor o parcela aún no
  ///     se subieron (reintentar luego);
  ///   - [StateError] si su productor o parcela ya no existen en el celular
  ///     (no se podrá subir);
  ///   - un error de red si no hay conexión (ver isTransientNetworkError);
  ///   - [PostgrestException] si el servidor rechaza el lote.
  Future<String> upload(ProductionBatchLocal batch) async {
    final producer = await _db.producersDao.getById(batch.producerLocalId);
    if (producer == null) {
      throw StateError('El productor del lote ya no está guardado en el celular');
    }
    final producerRemoteId = producer.remoteId;
    if (producerRemoteId == null) {
      throw const BatchDependencyPendingException('productor');
    }

    String? plotRemoteId;
    final plotLocalId = batch.plotLocalId;
    if (plotLocalId != null) {
      final plot = await _db.plotsDao.getById(plotLocalId);
      if (plot == null) {
        throw StateError('La parcela del lote ya no está guardada en el celular');
      }
      plotRemoteId = plot.remoteId;
      if (plotRemoteId == null) {
        throw const BatchDependencyPendingException('parcela');
      }
    }

    final clientId = await _db.productionBatchesDao.ensureClientId(batch, generateUuidV4);
    final certs = await _db.productionBatchCertsDao.getByBatchLocalId(batch.id);
    final temps = await _db.batchTemperaturesDao.getByBatchLocalId(batch.id);
    final harvestDates = await _db.productionBatchHarvestDatesDao.getByBatchLocalId(batch.id);
    final ph = await _db.batchPhControlsDao.getByBatchLocalId(batch.id);

    DebugLogger.info('ProductionBatchUploader', 'upload',
        'Enviando lote ${batch.batchCode} (local ${batch.id}, id $clientId): '
        'certs=${certs.length}, temps=${temps.length}, '
        'harvestDates=${harvestDates.length}, ph=${ph != null}');

    await _supabase.rpc(_rpcName, params: {
      'p_id': clientId,
      'p_batch': {
        'batch_code': batch.batchCode,
        'harvest_date': _dateOnly(batch.harvestDate),
        'process_date': _dateOnly(batch.processDate),
        'cane_kg': batch.caneKg,
        'juice_liters': batch.juiceLiters,
        'panela_kg': batch.panelaKg,
        'confitillo_kg': batch.confitilloKg,
        'porcentaje_extraccion': batch.porcentajeExtraccion,
        'cachaza_percentage': batch.cachazaPercentage,
        'efficiency_percentage': batch.efficiencyPercentage,
        'cane_density': batch.caneDensity,
        'producer_id': producerRemoteId,
        'plot_id': plotRemoteId,
        'cooperative_id': batch.cooperativeId,
        'latitude': batch.latitude,
        'longitude': batch.longitude,
        'location_text': batch.locationText,
        'observations': batch.observations,
      },
      'p_cert_ids': certs.map((c) => c.batchCertId).toList(),
      // Ordenadas por sequenceNumber: el servidor numera según este orden.
      'p_temperatures': temps
          .map((t) => {
                'temperature': t.temperature,
                'time_between_mieles_minutes': t.timeBetweenMielesMinutes,
              })
          .toList(),
      'p_harvest_dates': harvestDates.map((h) => _dateOnly(h.harvestDate)).toList(),
      'p_ph_control': ph == null
          ? null
          : {
              // Momento real del registro, no el de la subida.
              'record_date': ph.recordDate.toUtc().toIso8601String(),
              'regulator_type': ph.regulatorType,
              'ph_initial': ph.phInitial,
              'ph_final': ph.phFinal,
              'regulator_quantity_value': ph.regulatorQuantityValue,
              'regulator_quantity_unit': ph.regulatorQuantityUnit,
              'brix': ph.brix,
              'corrective_action': ph.correctiveAction,
            },
    }).timeout(_sendTimeout);

    await _db.productionBatchesDao.markAsSynced(localId: batch.id, remoteId: clientId);
    await _markRelatedAsSynced(batch.id);

    DebugLogger.info('ProductionBatchUploader', 'upload',
        'Lote ${batch.batchCode} enviado (id $clientId)');
    return clientId;
  }

  static String _dateOnly(DateTime date) => date.toIso8601String().split('T')[0];

  /// Los datos del lote se guardaron junto con él; se marcan como enviados
  /// (sin id propio del servidor: se borran en cascada con el lote).
  Future<void> _markRelatedAsSynced(int batchLocalId) async {
    final certs = await _db.productionBatchCertsDao.getByBatchLocalId(batchLocalId);
    if (certs.isNotEmpty) {
      await _db.productionBatchCertsDao.markBatchAsSynced(
          batchLocalId, certs.map((c) => 'SYNCED_${c.id}').toList());
    }
    final temps = await _db.batchTemperaturesDao.getByBatchLocalId(batchLocalId);
    if (temps.isNotEmpty) {
      await _db.batchTemperaturesDao.markBatchAsSynced(
          batchLocalId, temps.map((t) => 'SYNCED_${t.id}').toList());
    }
    final harvestDates =
        await _db.productionBatchHarvestDatesDao.getByBatchLocalId(batchLocalId);
    if (harvestDates.isNotEmpty) {
      await _db.productionBatchHarvestDatesDao.markBatchAsSynced(
          batchLocalId, harvestDates.map((h) => 'SYNCED_${h.id}').toList());
    }
    final ph = await _db.batchPhControlsDao.getByBatchLocalId(batchLocalId);
    if (ph != null) {
      await _db.batchPhControlsDao.markAsSynced(localId: ph.id, remoteId: 'SYNCED_${ph.id}');
    }
  }
}
