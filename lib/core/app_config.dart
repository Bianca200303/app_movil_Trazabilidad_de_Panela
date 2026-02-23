import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central configuration for different cooperatives
/// This is the single source of truth for app configuration
class AppConfig {
  // Current cooperative configuration
  static CooperativeConfig get current => _getCurrentConfig();

  // Environment configuration - determines if we use local or remote Supabase
  // Default: true (use local Supabase for development)
  // For production builds: pass --dart-define=USE_LOCAL_SUPABASE=false
  static const bool useLocalSupabase = bool.fromEnvironment(
    'USE_LOCAL_SUPABASE',
    defaultValue: false,
  );

  // Supabase URL - automatically selects local or remote based on environment
  static String get supabaseUrl {
    return 'https://jmvpjinvvjlhhboieens.supabase.co';
  }
  // Get the appropriate localhost URL based on platform
  static String _getLocalSupabaseUrl() {
    // On web, always use 127.0.0.1
    if (kIsWeb) {
      return 'http://127.0.0.1:54321';
    }

    // On Android emulator, use 10.0.2.2 to access host machine
    // On other platforms (iOS, desktop), use 127.0.0.1
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:54321';
      }
    } catch (e) {
      // Fallback if Platform is not available
    }

    return 'http://127.0.0.1:54321';
  }
  
  static String get supabaseAnonKey => const String.fromEnvironment(
    'SUPABASE_ANON_KEY', 
    defaultValue: 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptdnBqaW52dmpsaGhib2llZW5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkyNzE4MzcsImV4cCI6MjA4NDg0NzgzN30.PEfXECsgOuzxWg1Xz8p7fKS2RGhNjnyrWvf9wm_6kJE',
  );

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
      requirePlotNames: false, // Nombres opcionales para CAES
      useAppagropCode: false,  // Código APPAGROP oculto
      enableStowageTransportInspection: true, // Control forms enabled
      // New control forms
      enableEnvironmentInspection: true, // Enabled
      enableCleaningDisinfection: true, // Enabled
      enableChlorineControl: true, // Enabled
      enablePestControl: true, // Enabled
      enableHealthAccidentTracking: true, // Enabled
      enableComplaintsReturns: false,
      enableWorkerControl: true,
      enableMaintenanceControl: false,
    ),
  );
}
