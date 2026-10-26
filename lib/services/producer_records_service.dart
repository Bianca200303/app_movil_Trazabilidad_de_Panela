import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/supabase_paging.dart';

/// Registro de productor de un usuario. Un mismo DNI puede tener un
/// registro por módulo (restricción unique_dni_per_module), y cualquier rol
/// salvo el Administrador del sistema puede ser además productor.
class ProducerRecord {
  const ProducerRecord({
    required this.id,
    required this.dni,
    required this.moduleId,
    required this.isMember,
    required this.isActive,
  });

  factory ProducerRecord.fromJson(Map<String, dynamic> json) => ProducerRecord(
        id: json['id'] as String,
        dni: json['dni'] as String,
        moduleId: json['coop_module_id'] as String,
        isMember: json['is_member'] as bool? ?? true,
        isActive: json['is_active'] as bool? ?? true,
      );

  final String id;
  final String dni;
  final String moduleId;
  final bool isMember;
  final bool isActive;
}

/// Consulta y mantiene la condición de productor de los usuarios desde
/// Gestión de usuarios. Requiere conexión. La base de datos solo deja
/// escribir productores a los administradores: si otro rol lo intenta, el
/// UPDATE no afecta filas y se informa como falta de permiso.
class ProducerRecordsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _noPermission = 'Solo los administradores pueden modificar productores';

  /// Registros de productor de la cooperativa, agrupados por DNI. Incluye
  /// los dados de baja, para poder reactivarlos.
  Future<Map<String, List<ProducerRecord>>> fetchByDni() async {
    final response = await fetchAllRows(() => _supabase
        .from('producers')
        .select('id, dni, coop_module_id, is_member, is_active')
        .eq('cooperative_id', AppConfig.current.id)
        .order('is_active', ascending: false)
        .order('id'));
    final byDni = <String, List<ProducerRecord>>{};
    for (final row in response) {
      final record = ProducerRecord.fromJson(row);
      byDni.putIfAbsent(record.dni, () => []).add(record);
    }
    return byDni;
  }

  /// Cambia el módulo y la condición (socio / no socio) de un registro.
  Future<void> update(String id, {required String moduleId, required bool isMember}) =>
      _write(id, {'coop_module_id': moduleId, 'is_member': isMember});

  /// Da de baja (false) o reactiva (true) un registro de productor. No borra
  /// nada: sus lotes, parcelas y cupos se conservan.
  Future<void> setActive(String id, bool isActive) => _write(id, {'is_active': isActive});

  Future<void> _write(String id, Map<String, dynamic> data) async {
    try {
      final List response =
          await _supabase.from('producers').update(data).eq('id', id).select('id');
      if (response.isEmpty) throw Exception(_noPermission);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Ya está registrado como productor en ese módulo');
      }
      if (e.code == '42501') throw Exception(_noPermission);
      throw Exception('No se pudo guardar: ${e.message}');
    }
  }
}
