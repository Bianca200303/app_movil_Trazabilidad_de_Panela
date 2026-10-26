import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/models/current_user.dart';
import 'package:panela_sys/services/form_data_cache_service.dart';
import 'package:panela_sys/services/sync/pending_count.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';

/// No se puede cerrar sesión: hay registros guardados en el celular que
/// todavía no se enviaron (se perderían o se subirían con otro usuario).
class PendingSyncBlocksSignOutException implements Exception {
  final int pendingCount;
  const PendingSyncBlocksSignOutException(this.pendingCount);

  @override
  String toString() =>
      'Tiene $pendingCount registro(s) sin enviar. Conéctese a internet y '
      'sincronice antes de cerrar sesión.';
}

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
  //
  // Lanza [PendingSyncBlocksSignOutException] si quedan registros sin enviar.
  Future<void> signOut() async {
    DebugLogger.info('AuthService', 'signOut', 'Iniciando cierre de sesión');

    final pending = await countPendingSync(AppDatabase());
    if (pending > 0) {
      DebugLogger.warning('AuthService', 'signOut',
          'Cierre de sesión bloqueado: $pending registros sin enviar');
      throw PendingSyncBlocksSignOutException(pending);
    }

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
    if (kDebugMode) {
      print('🚀 [FLUTTER] Intentando registrar usuario: $dni');
    }

    try {
      final coopId = AppConfig.current.id;

      if (coopId.isEmpty) {
        throw Exception('El ID de la cooperativa está vacío. Revisa AppConfig.');
      }

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

      if (response.data == null) {
        throw Exception('Error de conexión: Respuesta vacía');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw AuthException(data['error']);
      }

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('💥 [FLUTTER] Error al registrar usuario: $e');
        print('📜 Stack trace: $stackTrace');
      }
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException('Error local al registrar: ${e.toString()}');
    }
  }

  // Restore CurrentUser from existing session (called on app restart)
  Future<CurrentUser?> restoreCurrentUser() async {
    final authUser = currentUser;
    if (authUser == null) return null;

    try {
      final profile = await _supabase
          .from('users')
          .select('user_id, first_name, last_name, role')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (profile == null) return null;

      final moduleData = await _supabase
          .from('user_module_assignments')
          .select('coop_module_id')
          .eq('user_id', profile['user_id'] as String)
          .eq('cooperative_id', AppConfig.current.id);

      final moduleIds = (moduleData as List)
          .map((m) => m['coop_module_id'] as String)
          .toList();

      return CurrentUser(
        dni: profile['user_id'] as String,
        firstName: profile['first_name'] as String,
        lastName: profile['last_name'] as String,
        role: UserRole.fromString(profile['role'] as String? ?? 'productor'),
        moduleIds: moduleIds,
      );
    } catch (e) {
      return null;
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
