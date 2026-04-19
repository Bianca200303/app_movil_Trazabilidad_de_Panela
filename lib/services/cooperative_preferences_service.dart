import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para persistir la selección de cooperativa entre sesiones.
///
/// La cooperativa se guarda UNA SOLA VEZ al configurar la app por primera vez.
/// No hay forma de cambiarla desde dentro de la app (requiere borrar datos de la app).
class CooperativePreferencesService {
  static const _keyCooperativeCode = 'cooperative_code';

  /// Retorna el código de cooperativa guardado, o null si nunca se configuró.
  static Future<String?> getSavedCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyCooperativeCode);
    } catch (_) {
      return null;
    }
  }

  /// Guarda el código de cooperativa de forma permanente.
  static Future<void> saveCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCooperativeCode, code);
  }

  /// Elimina el código guardado. Usado cuando el usuario elige "Cambiar cooperativa".
  static Future<void> clearSavedCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCooperativeCode);
  }
}
