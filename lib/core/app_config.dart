import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// Central configuration for different cooperatives.
/// This is the single source of truth for app configuration.
///
/// La cooperativa se selecciona en RUNTIME (primera vez que el usuario abre la app),
/// no en tiempo de compilación. Se persiste en SharedPreferences para que no
/// sea necesario volver a ingresarla en los siguientes inicios.
class AppConfig {
  // Configuración activa en runtime (null hasta que el usuario ingrese su código)
  static CooperativeConfig? _runtimeConfig;

  /// Configuración de la cooperativa actualmente activa.
  /// Lanza StateError si la cooperativa aún no fue configurada.
  /// Siempre verificar [isConfigured] antes de acceder a este getter.
  static CooperativeConfig get current {
    if (_runtimeConfig == null) {
      throw StateError(
        'AppConfig no inicializado. '
        'Llama a AppConfig.setCooperative() antes de acceder a current.',
      );
    }
    return _runtimeConfig!;
  }

  /// Retorna true si ya se seleccionó una cooperativa en este ciclo de vida.
  static bool get isConfigured => _runtimeConfig != null;

  /// Establece la cooperativa activa por su código interno (ej: 'NORANDINO', 'CAES').
  /// Lanza Exception si el código no corresponde a ninguna cooperativa conocida.
  static void setCooperative(String code) {
    final config = _findByCode(code);
    if (config == null) {
      throw Exception('Código de cooperativa desconocido: $code');
    }
    _runtimeConfig = config;
  }

  /// Busca la cooperativa que corresponde al [accessCode] ingresado por el usuario.
  /// El accessCode es el código secreto entregado a cada cooperativa.
  /// Retorna null si ninguna cooperativa coincide.
  static CooperativeConfig? findByAccessCode(String accessCode) {
    final upper = accessCode.trim().toUpperCase();
    for (final config in CooperativeConfigs.all) {
      if (config.accessCode.toUpperCase() == upper) {
        return config;
      }
    }
    return null;
  }

  /// Limpia la cooperativa activa (usado cuando el usuario elige "Cambiar cooperativa").
  /// Después de llamar esto, [isConfigured] retorna false y el router redirige
  /// a la pantalla de selección.
  static void clearCooperative() {
    _runtimeConfig = null;
  }

  static CooperativeConfig? _findByCode(String code) {
    final upper = code.trim().toUpperCase();
    for (final config in CooperativeConfigs.all) {
      if (config.code.toUpperCase() == upper) {
        return config;
      }
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // Configuración de Supabase (igual para todas las cooperativas)
  // ─────────────────────────────────────────────────────────────

  /// Si usas 'flutter run', kDebugMode es true -> usa local.
  /// Si usas 'flutter build apk --release', kDebugMode es false -> usa la nube.
  static bool get useLocalSupabase => const bool.fromEnvironment(
        'USE_LOCAL_SUPABASE',
        defaultValue: kDebugMode,
      );

  static String get supabaseUrl {
    if (useLocalSupabase) {
      return _getLocalSupabaseUrl();
    }
    return 'https://mzebhkgusujujskylzdw.supabase.co';
  }

  static String _getLocalSupabaseUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:54321';
    }
    try {
      if (Platform.isAndroid) {
        // En emulador usa 10.0.2.2; en celular físico con cable, usa la IP de tu PC.
        return 'http://10.0.2.2:54321';
      }
    } catch (_) {}
    return 'http://127.0.0.1:54321';
  }

  static String get supabaseAnonKey {
    if (useLocalSupabase) {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
    }
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16ZWJoa2d1c3VqdWpza3lsemR3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzNDI0MTYsImV4cCI6MjA5MzkxODQxNn0.1jo2Z9u3cMPAezldzFwAAZ_jRy20gm3KTl8htJ6yrLM',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature flags por cooperativa
// ─────────────────────────────────────────────────────────────────────────────

class CooperativeFeatures {
  final bool requirePlotNames;
  final bool useAppagropCode;
  final bool enableStowageTransportInspection;
  final bool enableEnvironmentInspection;
  final bool enableCleaningDisinfection;
  final bool enableChlorineControl;
  final bool enablePestControl;
  final bool enableHealthAccidentTracking;
  final bool enableComplaintsReturns;
  final bool enableWorkerControl;
  final bool enableMaintenanceControl;

  const CooperativeFeatures({
    this.requirePlotNames = true,
    this.useAppagropCode = false,
    this.enableStowageTransportInspection = true,
    this.enableEnvironmentInspection = true,
    this.enableCleaningDisinfection = false,
    this.enableChlorineControl = true,
    this.enablePestControl = false,
    this.enableHealthAccidentTracking = false,
    this.enableComplaintsReturns = false,
    this.enableWorkerControl = false,
    this.enableMaintenanceControl = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de configuración de cooperativa
// ─────────────────────────────────────────────────────────────────────────────

class CooperativeConfig {
  final String id;            // UUID de Supabase
  final String code;          // Código interno (NORANDINO, CAES)
  final String name;          // Nombre completo
  final String displayTitle;  // Título corto mostrado en la UI
  final String batchCodePrefix; // Prefijo de 4 chars para códigos de lote
  final String accessCode;    // Código secreto que ingresa el usuario al configurar la app
  final CooperativeFeatures features;

  const CooperativeConfig({
    required this.id,
    required this.code,
    required this.name,
    required this.displayTitle,
    required this.batchCodePrefix,
    required this.accessCode,
    required this.features,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Configuraciones predefinidas de cada cooperativa
// Los IDs deben coincidir con los sembrados en Supabase.
//
// ¡IMPORTANTE! Cambia los accessCode antes de salir a producción.
// Estos códigos son los que cada cooperativa entregará a sus usuarios.
// ─────────────────────────────────────────────────────────────────────────────

class CooperativeConfigs {
  static const norandino = CooperativeConfig(
    id: '550e8400-e29b-41d4-a716-446655440001',
    code: 'NORANDINO',
    name: 'Cooperativa Agraria Norandino',
    displayTitle: 'Cooperativa Norandino',
    batchCodePrefix: 'NORA',
    accessCode: 'NORA2025', // ← Cambiar antes de producción
    features: CooperativeFeatures(
      requirePlotNames: true,
      useAppagropCode: true,
      enableStowageTransportInspection: true,
      enableEnvironmentInspection: true,
      enableCleaningDisinfection: true,
      enableChlorineControl: true,
      enablePestControl: true,
      enableHealthAccidentTracking: true,
      enableComplaintsReturns: true,
      enableWorkerControl: true,
      enableMaintenanceControl: true,
    ),
  );

  static const caes = CooperativeConfig(
    id: '550e8400-e29b-41d4-a716-446655440002',
    code: 'CAES',
    name: 'Cooperativa Agraria Ecológica y Solidaria Piura',
    displayTitle: 'Cooperativa CAES',
    batchCodePrefix: 'CAES',
    accessCode: 'CAES2025', // ← Cambiar antes de producción
    features: CooperativeFeatures(
      requirePlotNames: true,
      useAppagropCode: false,
      enableStowageTransportInspection: true,
      enableEnvironmentInspection: true,
      enableCleaningDisinfection: true,
      enableChlorineControl: true,
      enablePestControl: true,
      enableHealthAccidentTracking: true,
      enableComplaintsReturns: true,
      enableWorkerControl: true,
      enableMaintenanceControl: true,
    ),
  );

  /// Lista de todas las cooperativas registradas.
  /// Al agregar una nueva cooperativa, solo añadirla aquí y en la lista.
  static const List<CooperativeConfig> all = [norandino, caes];
}
