import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/services/form_data_cache_service.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FormDataCacheService? _cacheService;

  AuthService({FormDataCacheService? cacheService})
      : _cacheService = cacheService;

  // Login with DNI
  Future<AuthResponse> signInWithDNI({
    required String dni,
    required String password,
  }) async {
    try {
      // Call our Edge Function for DNI/email authentication
      final response = await _supabase.functions.invoke(
        'auth-dni',
        body: {
          'identifier': dni,
          'password': password,
          'cooperativeId': AppConfig.current.id,
        },
      );

      if (response.data == null) {
        throw Exception('Error de conexión');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['error'] != null) {
        throw AuthException(data['error']);
      }

      // Set session with returned tokens
      final authResponse = await _supabase.auth.setSession(
        data['refresh_token'],
      );

      return authResponse;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Error al iniciar sesión: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    DebugLogger.info('AuthService', 'signOut', 'Iniciando cierre de sesión');

    try {
      // 1. Clear local cache - use singleton AppDatabase to avoid multiple instances
      try {
        final db = AppDatabase(); // Singleton instance
        final cacheService = FormDataCacheService(db: db);
        await cacheService.clearAllCache();
        DebugLogger.info('AuthService', 'signOut', 'Caché limpiado exitosamente');
      } catch (e) {
        DebugLogger.warning('AuthService', 'signOut', 'No se pudo limpiar caché: $e');
        // Don't block logout if cache clear fails
      }
    } catch (e) {
      DebugLogger.warning('AuthService', 'signOut', 'Error limpiando caché: $e');
      // Don't block logout if cache clear fails
    }

    // 2. Sign out from Supabase
    await _supabase.auth.signOut();
    DebugLogger.info('AuthService', 'signOut', 'Cierre de sesión completado');
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get current user's DNI (user_id)
  Future<String?> getCurrentUserDNI() async {
    final user = currentUser;
    if (user == null) return null;
    
    try {
      final response = await _supabase
          .from('users')
          .select('user_id')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      
      return response?['user_id'] as String?;
    } catch (e) {
      throw Exception('Error al obtener DNI del usuario: $e');
    }
  }

// Register new user
  Future<AuthResponse> registerUser({
    required String dni,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    print('🚀 [FLUTTER] INICIO: Intentando registrar usuario...');
    print('👤 [FLUTTER] Datos: $dni, $firstName, $lastName');

    try {
      // 1. Verificar si AppConfig está vivo
      print('🔍 [FLUTTER] Verificando configuración...');
      final coopId = AppConfig.current.id;
      print('🏢 [FLUTTER] ID Cooperativa detectado: $coopId');

      if (coopId.isEmpty) {
        throw Exception('El ID de la cooperativa está vacío. Revisa AppConfig.');
      }

      // 2. Intentar llamar a la nube
      print('☁️ [FLUTTER] Llamando a Edge Function "register-user"...');
      
      final response = await _supabase.functions.invoke(
        'register-user',
        body: {
          'dni': dni,
          'firstName': firstName,
          'lastName': lastName,
          'password': password,
          'cooperativeId': coopId,
        },
      );

      print('📨 [FLUTTER] Respuesta recibida. Status: ${response.status}');

      if (response.data == null) {
        throw Exception('Error de conexión: Respuesta vacía');
      }

      final data = response.data as Map<String, dynamic>;
      print('📦 [FLUTTER] Data recibida: $data');
      
      if (data['error'] != null) {
        throw AuthException(data['error']);
      }

      // Set session with returned tokens
      print('🔐 [FLUTTER] Guardando sesión...');
      final authResponse = await _supabase.auth.setSession(
        data['refresh_token'],
      );

      print('✅ [FLUTTER] ¡ÉXITO TOTAL!');
      return authResponse;

    } catch (e, stackTrace) {
      // AQUÍ VEREMOS EL ERROR REAL
      print('💥 [FLUTTER] ERROR FATAL EN APP: $e');
      print('📜 [FLUTTER] Stack trace: $stackTrace');
      
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Error local al registrar: ${e.toString()}');
    }
  }

  // Setup DNI user for authentication (admin function)
  Future<Map<String, dynamic>> setupDNIUserAuth({
    required String dni,
    required String password,
    String? email,
  }) async {
    try {
      final response = await _supabase.rpc('setup_dni_user_auth', params: {
        'dni': dni,
        'user_password': password,
        'user_email': email,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al configurar autenticación: ${e.toString()}');
    }
  }
}
