import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/models/current_user.dart';
import 'package:panela_sys/services/form_data_cache_service.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

class SignInResult {
  final AuthResponse authResponse;
  final CurrentUser currentUser;
  SignInResult({required this.authResponse, required this.currentUser});
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FormDataCacheService? _cacheService;

  AuthService({FormDataCacheService? cacheService})
      : _cacheService = cacheService;

  // Login with DNI
  Future<SignInResult> signInWithDNI({
    required String dni,
    required String password,
  }) async {
    try {
      // ── DIAGNÓSTICO 401 ──────────────────────────────────────────────────
      final session = _supabase.auth.currentSession;
      final tokenEnviado = session?.accessToken ?? AppConfig.supabaseAnonKey;
      print('🔑 [AUTH-DNI] URL destino : ${AppConfig.supabaseUrl}/functions/v1/auth-dni');
      print('🔑 [AUTH-DNI] Token que se enviará (primeros 60 chars): ${tokenEnviado.substring(0, tokenEnviado.length.clamp(0, 60))}...');
      print('🔑 [AUTH-DNI] ¿Es JWT? (debe empezar con "eyJ"): ${tokenEnviado.startsWith("eyJ")}');
      print('🔑 [AUTH-DNI] Cooperative ID: ${AppConfig.current.id}');
      // ────────────────────────────────────────────────────────────────────
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

      // Build CurrentUser from response
      final rawModuleIds = data['coop_module_ids'];
      final moduleIds = rawModuleIds is List
          ? rawModuleIds.cast<String>()
          : <String>[];
      final currentUser = CurrentUser(
        dni: data['user_id'] as String? ?? dni,
        firstName: data['first_name'] as String? ?? '',
        lastName: data['last_name'] as String? ?? '',
        role: UserRole.fromString(data['role'] as String? ?? 'productor'),
        moduleIds: moduleIds,
      );

      return SignInResult(authResponse: authResponse, currentUser: currentUser);
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

  // Register new user (only callable by admin_sistema or admin_modulo)
  Future<void> registerUser({
    required String dni,
    required String firstName,
    required String lastName,
    required String password,
    required String role,
    List<String> moduleIds = const [],
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
      // ── DIAGNÓSTICO 401 ──────────────────────────────────────────────────
      final _session = _supabase.auth.currentSession;
      final _tokenEnviado = _session?.accessToken ?? AppConfig.supabaseAnonKey;
      print('🔑 [REGISTER] URL destino : ${AppConfig.supabaseUrl}/functions/v1/register-user');
      print('🔑 [REGISTER] Token que se enviará (primeros 60 chars): ${_tokenEnviado.substring(0, _tokenEnviado.length.clamp(0, 60))}...');
      print('🔑 [REGISTER] ¿Es JWT? (debe empezar con "eyJ"): ${_tokenEnviado.startsWith("eyJ")}');
      // ────────────────────────────────────────────────────────────────────

      final body = {
        'dni': dni,
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
        'cooperativeId': coopId,
        'role': role,
        if (moduleIds.isNotEmpty) 'coopModuleIds': moduleIds,
      };

      final response = await _supabase.functions.invoke(
        'register-user',
        body: body,
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

      print('✅ [FLUTTER] ¡ÉXITO TOTAL!');

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
