import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/models/certified_worker.dart';

/// Lista de trabajadores certificados por módulo (se mantiene desde la web,
/// en Catálogos). Con conexión se lee del servidor y se actualiza la copia
/// local de ese módulo; sin conexión se usa la copia local, que se carga
/// completa al iniciar sesión (ver FormDataCacheService).
class CertifiedWorkersService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppDatabase _db;

  static const _columns = 'id, first_name, last_name, position, certified_until, coop_module_id';
  static const _onlineTimeout = Duration(seconds: 8);

  CertifiedWorkersService({AppDatabase? db}) : _db = db ?? AppDatabase();

  /// Retorna los trabajadores certificados activos de un módulo.
  ///
  /// Retorna lista vacía si el módulo no tiene trabajadores configurados (ni
  /// en el servidor ni en la copia local) — la UI decide si mostrar fallback
  /// a texto libre.
  Future<List<CertifiedWorker>> getByModule(String moduleId) async {
    DebugLogger.info(
      'CertifiedWorkersService',
      'getByModule',
      'Cargando trabajadores para módulo: $moduleId',
    );

    final isConnected = await NetworkDetector().isConnected;
    if (isConnected) {
      try {
        final response = await _supabase
            .from('certified_workers')
            .select(_columns)
            .eq('cooperative_id', AppConfig.current.id)
            .eq('coop_module_id', moduleId)
            .eq('is_active', true)
            .order('last_name', ascending: true)
            // NetworkDetector solo mira si hay wifi/datos, no si hay señal
            // real: en campo puede "haber conexión" y la consulta quedarse
            // colgada. Pasado este tiempo se usa la copia local.
            .timeout(_onlineTimeout);

        final rows = (response as List).cast<Map<String, dynamic>>();
        await _db.certifiedWorkersDao.replaceModule(
          moduleId,
          rows.map(_toCompanion).toList(),
        );

        DebugLogger.info(
          'CertifiedWorkersService',
          'getByModule',
          'Trabajadores encontrados (servidor): ${rows.length}',
        );
        return rows.map(CertifiedWorker.fromJson).toList();
      } catch (e, st) {
        DebugLogger.error(
          'CertifiedWorkersService',
          'getByModule',
          'Error al cargar del servidor, se usa la copia local: $e',
          stackTrace: st,
        );
      }
    }

    return _getCached(moduleId);
  }

  Future<List<CertifiedWorker>> _getCached(String moduleId) async {
    try {
      final local = await _db.certifiedWorkersDao.getByModule(moduleId);
      DebugLogger.info(
        'CertifiedWorkersService',
        '_getCached',
        'Trabajadores encontrados (copia local): ${local.length}',
      );
      return local
          .map((w) => CertifiedWorker(
                id: w.id,
                firstName: w.firstName,
                lastName: w.lastName,
                position: w.position,
                certifiedUntil: w.certifiedUntil,
              ))
          .toList();
    } catch (e, st) {
      DebugLogger.error(
        'CertifiedWorkersService',
        '_getCached',
        'Error al leer la copia local: $e',
        stackTrace: st,
      );
      return [];
    }
  }

  // ── Gestión (pantalla "Trabajadores certificados", Administrador del
  // sistema). Solo con conexión; la base rechaza a otros roles (RLS). ──────

  static const _managementColumns =
      '$_columns, dni, is_active';

  /// Todos los trabajadores de la cooperativa, activos y dados de baja.
  Future<List<CertifiedWorker>> fetchAllForManagement() async {
    final response = await _supabase
        .from('certified_workers')
        .select(_managementColumns)
        .eq('cooperative_id', AppConfig.current.id)
        .order('last_name', ascending: true);
    return (response as List)
        .cast<Map<String, dynamic>>()
        .map(CertifiedWorker.fromJson)
        .toList();
  }

  /// Crea ([id] null) o actualiza un trabajador y pone al día la copia
  /// local, para que aparezca en los formularios aun sin señal después.
  Future<void> save({
    String? id,
    required String firstName,
    required String lastName,
    required String coopModuleId,
    String? dni,
    String? position,
    String? certifiedUntil,
  }) async {
    final payload = {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'coop_module_id': coopModuleId,
      'dni': _emptyToNull(dni),
      'position': _emptyToNull(position),
      'certified_until': _emptyToNull(certifiedUntil),
    };
    try {
      if (id == null) {
        await _supabase
            .from('certified_workers')
            .insert({...payload, 'cooperative_id': AppConfig.current.id});
      } else {
        // Si la base rechaza el cambio (RLS), no da error: devuelve 0 filas.
        final rows = await _supabase
            .from('certified_workers')
            .update(payload)
            .eq('id', id)
            .select('id');
        if ((rows as List).isEmpty) throw Exception(_noPermission);
      }
    } on PostgrestException catch (e) {
      // idx_cw_unique_dni_per_module: mismo DNI dos veces en el mismo módulo.
      if (e.code == '23505') {
        throw Exception('Ya existe un trabajador con ese DNI en este módulo');
      }
      if (e.code == '42501') throw Exception(_noPermission);
      rethrow;
    }
    await _refreshCacheQuietly();
  }

  /// Da de baja (o reactiva) sin borrar: los controles ya registrados con
  /// ese nombre no se tocan.
  Future<void> setActive(String id, bool isActive) async {
    // Si la base rechaza el cambio (RLS), no da error: devuelve 0 filas.
    final rows = await _supabase
        .from('certified_workers')
        .update({'is_active': isActive})
        .eq('id', id)
        .select('id');
    if ((rows as List).isEmpty) throw Exception(_noPermission);
    await _refreshCacheQuietly();
  }

  static const _noPermission =
      'Solo el Administrador del sistema puede modificar esta lista';

  Future<void> _refreshCacheQuietly() async {
    try {
      await refreshCache();
    } catch (e) {
      // El cambio ya se guardó en el servidor; la copia local se pone al
      // día en la próxima actualización automática.
      DebugLogger.warning('CertifiedWorkersService', '_refreshCacheQuietly',
          'No se pudo actualizar la copia local: $e');
    }
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Recarga la copia local completa (todos los módulos de la cooperativa).
  ///
  /// Llamado por FormDataCacheService al iniciar sesión.
  Future<void> refreshCache() async {
    DebugLogger.info('CertifiedWorkersService', 'refreshCache',
        'Refrescando copia local de trabajadores certificados');

    final response = await _supabase
        .from('certified_workers')
        .select(_columns)
        .eq('cooperative_id', AppConfig.current.id)
        .eq('is_active', true);

    final rows = (response as List).cast<Map<String, dynamic>>();
    await _db.certifiedWorkersDao.replaceAll(rows.map(_toCompanion).toList());

    DebugLogger.info('CertifiedWorkersService', 'refreshCache',
        'Copia local actualizada: ${rows.length} trabajadores');
  }

  CertifiedWorkersCompanion _toCompanion(Map<String, dynamic> json) {
    return CertifiedWorkersCompanion.insert(
      id: json['id'] as String,
      coopModuleId: json['coop_module_id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      position: drift.Value(json['position'] as String?),
      certifiedUntil: drift.Value(json['certified_until'] as String?),
    );
  }
}
