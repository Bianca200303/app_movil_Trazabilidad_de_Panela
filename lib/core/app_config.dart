import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
/// Central configuration for different cooperatives
/// This is the single source of truth for app configuration
class AppConfig {
  // Current cooperative configuration
  static CooperativeConfig get current => _getCurrentConfig();

  // 2. MAGIA AQUÍ: El defaultValue ahora es kDebugMode
  // Si haces 'flutter run', kDebugMode es true -> usa local.
  // Si haces 'flutter build apk --release', kDebugMode es false -> usa la nube.
  static bool get useLocalSupabase => const bool.fromEnvironment(
    'USE_LOCAL_SUPABASE',
    defaultValue: kDebugMode, 
  );

  // 3. Lógica condicional para la URL
  static String get supabaseUrl {
    if (useLocalSupabase) {
      return _getLocalSupabaseUrl();
    }
    // URL de Producción (La nube)
    return 'https://jmvpjinvvjlhhboieens.supabase.co';
  }

  // Get the appropriate localhost URL based on platform
  static String _getLocalSupabaseUrl() {
    if (kIsWeb) {
      return 'http://127.0.0.1:54321';
    }

    try {
      if (Platform.isAndroid) {
        // OJO: Si vas a probar en tu celular físico con cable, 
        // cambia 10.0.2.2 por la IP de tu computadora (ej: 192.168.1.X)
        return 'http://10.0.2.2:54321'; 
      }
    } catch (e) {
      // Fallback if Platform is not available
    }

    return 'http://127.0.0.1:54321';
  }
  
  // 4. Lógica condicional para la Anon Key
  static String get supabaseAnonKey {
    if (useLocalSupabase) {
      // IMPORTANTE: debe ser la anon key en formato JWT (eyJ...) obtenida con `supabase status`.
      // El formato sb_publishable_* NO es un JWT y el runtime local de Edge Functions lo rechaza.
      // Si usas el JWT secret por defecto de Supabase CLI, esta es la key correcta:
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjIwODc5MjI1MDB9.CWzZIYMqT3Rp7C_J3lqK-1QwJQPqWJLd2QEjzMIiQ';
    }
    
    // Clave de Producción (La nube)
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY', 
      defaultValue: 
      'eyJhbGciOiJFUzI1NiIsImtpZCI6ImI4MTI2OWYxLTIxZDgtNGYyZS1iNzE5LWMyMjQwYTg0MGQ5MCIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjIwODc5MjI1MDB9.mGeZ4LBS90ARgSzln7gvLqX255v1VoDWBB5Hd1M7cvMDUd0DVnt_heDYS_rroMszjBSI4UxsykzJfCOhLhGRtg',
    );
  }

  // Build configuration - this determines which cooperative to use
  static const String cooperativeCode = String.fromEnvironment(
    'COOPERATIVE_CODE',
    defaultValue: 'CAES', // Default to Norandino for development
  );

  // Get current configuration based on build-time cooperative code
  static CooperativeConfig _getCurrentConfig() {
    switch (cooperativeCode.toUpperCase()) {
      case 'NORANDINO':
        return CooperativeConfigs.norandino;
      case 'CAES':
        return CooperativeConfigs.caes;
      default:
        throw Exception('Unknown cooperative: $cooperativeCode');
    }
  }
}

/// Feature flags for each cooperative
class CooperativeFeatures {
  final bool requirePlotNames;
  final bool useAppagropCode;
  final bool enableStowageTransportInspection;

  // Control forms feature flags
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
    this.enableStowageTransportInspection = true, // Enabled by default for all cooperatives
    // Default all new forms to false (disabled)
    this.enableEnvironmentInspection = true, // Now enabled
    this.enableCleaningDisinfection = false,
    this.enableChlorineControl = true,
    this.enablePestControl = false,
    this.enableHealthAccidentTracking = false,
    this.enableComplaintsReturns = false,
    this.enableWorkerControl = false,
    this.enableMaintenanceControl = false,
  });
}

/// Configuration specific to each cooperative
class CooperativeConfig {
  final String id; // UUID from Supabase
  final String code; // Short code (NORANDINO, CAES)
  final String name; // Full name
  final String batchCodePrefix; // 4-char prefix for batch codes (NORA, CAES)
  final CooperativeFeatures features; // Feature configuration

  const CooperativeConfig({
    required this.id,
    required this.code,
    required this.name,
    required this.batchCodePrefix,
    required this.features,
  });
}

/// Predefined configurations for each cooperative
/// These IDs match the ones seeded in Supabase
class CooperativeConfigs {
  static const norandino = CooperativeConfig(
    id: '550e8400-e29b-41d4-a716-446655440001',
    code: 'NORANDINO',
    name: 'Cooperativa Agraria Norandino',
    batchCodePrefix: 'NORA',
    features: CooperativeFeatures(
      requirePlotNames: true, // Nombres obligatorios para Norandino
      useAppagropCode: true,  // Código APPAGROP visible y obligatorio
      enableStowageTransportInspection: true, // Control forms enabled
      // New control forms
      enableEnvironmentInspection: true, // Enabled
      enableCleaningDisinfection: true, // Enabled
      enableChlorineControl: true, // Enabled
      enablePestControl: true, // Enabled
      enableHealthAccidentTracking: true, // Enabled
      enableComplaintsReturns: true,
      enableWorkerControl: true,
      enableMaintenanceControl: true,
    ),
  );

  static const caes = CooperativeConfig(
    id: '550e8400-e29b-41d4-a716-446655440002',
    code: 'CAES',
    name: 'Cooperativa Agraria Ecológica y Solidaria Piura',
    batchCodePrefix: 'CAES',
    features: CooperativeFeatures(
      requirePlotNames: true, // Nombres opcionales para CAES
      useAppagropCode: false,  // Código APPAGROP oculto
      enableStowageTransportInspection: true, // Control forms enabled
      // New control forms
      enableEnvironmentInspection: true, // Enabled
      enableCleaningDisinfection: true, // Enabled
      enableChlorineControl: true, // Enabled
      enablePestControl: true, // Enabled
      enableHealthAccidentTracking: true, // Enabled
      enableComplaintsReturns: true,
      enableWorkerControl: true,
      enableMaintenanceControl: true,
    ),
  );
}
