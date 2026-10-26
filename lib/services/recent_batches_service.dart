import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/database/tables/cached_production_batches_table.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/network_errors.dart';
import 'package:panela_sys/services/product_return_service.dart';

/// Lotes de producción para elegir en un control, con o sin señal.
///
/// Devuelve filas con la misma forma que ProductReturnService.getBatchesByRange
/// (lote + `producers`). Un lote creado en este celular y aún no enviado
/// lleva además [localBatchIdKey] (su id local) y su `id` es
/// `local-<idLocal>`, para que el control pueda guardarse igual y vincularse
/// al lote real cuando ambos se sincronicen.
class RecentBatchesService {
  final AppDatabase _db;
  final ProductReturnService _remote;

  static const localBatchIdKey = 'local_batch_id';
  static const _onlineTimeout = Duration(seconds: 10);
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  RecentBatchesService({AppDatabase? db, ProductReturnService? remote})
      : _db = db ?? AppDatabase(),
        _remote = remote ?? ProductReturnService();

  /// Lote creado en este celular y todavía sin enviar.
  static int? localBatchIdOf(Map<String, dynamic> batch) => batch[localBatchIdKey] as int?;

  Future<List<Map<String, dynamic>>> getBatches(
    DateTime from,
    DateTime to, {
    List<String>? moduleIds,
  }) async {
    final remote = await _getRemoteOrCached(from, to, moduleIds: moduleIds);
    final local = await _getLocalPending(from, to, moduleIds: moduleIds);
    return [...local, ...remote];
  }

  /// Recarga la copia completa de los últimos [kRecentBatchesDays] días.
  /// Llamado por FormDataCacheService al iniciar sesión.
  Future<void> refreshCache() async {
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: kRecentBatchesDays));
    final rows = await _remote.getBatchesByRange(from, to);
    await _db.cachedProductionBatchesDao.replaceAll(rows.map(_toCompanion).toList());
    DebugLogger.info('RecentBatchesService', 'refreshCache',
        'Copia local de lotes actualizada: ${rows.length}');
  }

  Future<List<Map<String, dynamic>>> _getRemoteOrCached(
    DateTime from,
    DateTime to, {
    List<String>? moduleIds,
  }) async {
    if (await NetworkDetector().isConnected) {
      try {
        final rows = await _remote
            .getBatchesByRange(from, to, moduleIds: moduleIds)
            .timeout(_onlineTimeout);
        await _updateCache(rows);
        return rows;
      } catch (e) {
        // getBatchesByRange envuelve el error original en Exception; si no
        // es claramente de red igual se cae a la copia local, pero se avisa.
        if (!isTransientNetworkError(e)) {
          DebugLogger.warning('RecentBatchesService', '_getRemoteOrCached',
              'Error al consultar lotes, se usa la copia local: $e');
        }
      }
    }

    final cached = await _db.cachedProductionBatchesDao.getByRange(
      fromDate: _dateFormat.format(from),
      toDate: _dateFormat.format(to),
      moduleIds: moduleIds,
    );
    return cached.map((c) => jsonDecode(c.payload) as Map<String, dynamic>).toList();
  }

  /// Guarda en la copia los lotes recibidos que caen dentro de la ventana
  /// de días, y descarta los que ya quedaron fuera.
  Future<void> _updateCache(List<Map<String, dynamic>> rows) async {
    final oldest = _dateFormat.format(
        DateTime.now().subtract(const Duration(days: kRecentBatchesDays)));
    final inWindow = rows.where((r) => (r['process_date'] as String).compareTo(oldest) >= 0);
    await _db.cachedProductionBatchesDao.upsertAndPrune(
      inWindow.map(_toCompanion).toList(),
      oldestDateToKeep: oldest,
    );
  }

  Future<List<Map<String, dynamic>>> _getLocalPending(
    DateTime from,
    DateTime to, {
    List<String>? moduleIds,
  }) async {
    final fromDate = _dateFormat.format(from);
    final toDate = _dateFormat.format(to);
    final pending = await _db.productionBatchesDao.getPending(AppConfig.current.id);

    final rows = <Map<String, dynamic>>[];
    for (final batch in pending) {
      final processDate = _dateFormat.format(batch.processDate);
      if (processDate.compareTo(fromDate) < 0 || processDate.compareTo(toDate) > 0) continue;

      final producer = await _db.producersDao.getById(batch.producerLocalId);
      if (producer == null) continue;
      if (moduleIds != null && moduleIds.isNotEmpty && !moduleIds.contains(producer.coopModuleId)) {
        continue;
      }

      rows.add({
        'id': 'local-${batch.id}',
        localBatchIdKey: batch.id,
        'batch_code': batch.batchCode,
        'process_date': processDate,
        'panela_kg': batch.panelaKg,
        'confitillo_kg': batch.confitilloKg,
        'producers': {
          'first_name': producer.firstName,
          'last_name': producer.lastName,
          'dni': producer.dni,
          'appagrop_code': producer.appagropCode,
          'coop_module_id': producer.coopModuleId,
        },
      });
    }
    return rows;
  }

  CachedProductionBatchesCompanion _toCompanion(Map<String, dynamic> row) {
    final producer = row['producers'] as Map<String, dynamic>;
    return CachedProductionBatchesCompanion.insert(
      id: row['id'] as String,
      coopModuleId: producer['coop_module_id'] as String,
      processDate: row['process_date'] as String,
      payload: jsonEncode(row),
      cachedAt: Value(DateTime.now()),
    );
  }
}
