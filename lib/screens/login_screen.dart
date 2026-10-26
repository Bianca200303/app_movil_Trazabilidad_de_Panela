import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/services/cooperative_preferences_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/providers/form_data_refresh_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _dniComplete = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_onDniChanged);
  }

  void _onDniChanged() {
    final complete =
        RegExp(r'^\d{8}$').hasMatch(_identifierController.text.trim());
    if (complete != _dniComplete) {
      setState(() => _dniComplete = complete);
    }
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onDniChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateDNI(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su DNI';
    }
    
    // Check if it's a DNI (8 digits)
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      return null; // Valid DNI
    }
    
    return 'Ingrese un DNI válido (8 dígitos)';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String _friendlyAuthError(String _) {
    // Todos los errores de auth muestran el mismo mensaje genérico
    // para no revelar si el usuario existe o a qué cooperativa pertenece.
    return 'DNI o contraseña incorrectos.';
  }

  Future<void> _signInWithDni() async {
    _passwordController.text = _identifierController.text.trim();
    await _signIn();
  }

  Future<void> _changeCooperative() async {
    // Limpia la cooperativa guardada y vuelve a la pantalla de selección
    await CooperativePreferencesService.clearSavedCode();
    AppConfig.clearCooperative();
    if (mounted) {
      context.go(AppRoutes.cooperativeSelection.path);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Authenticate user
      final result = await _authService.signInWithDNI(
        dni: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Save current user to provider
      if (mounted) {
        ref.read(currentUserProvider.notifier).state = result.currentUser;
      }

      // 2. Refresh form data cache for offline usage
      if (mounted) {
        try {
          await ref.read(formDataCacheServiceProvider).refreshAllFormData();
          await ref.read(formDataRefreshProvider.notifier).reload();
        } catch (e) {
          // Don't block login if cache refresh fails
          if (mounted) {
            AppSnackBar.show(
              context,
              message: 'Advertencia: No se pudo actualizar datos locales',
              type: SnackBarType.warning,
            );
          }
        }
      }

      // 3. Navigate to home
      if (mounted) {
        context.go(AppRoutes.home.path);
      }
    } on AuthException catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: _friendlyAuthError(e.message),
          type: SnackBarType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error de conexión. Verifique su internet e intente de nuevo.',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showSyncStatus: false,
      // AppCard ya centra, limita el ancho y desplaza si no entra (p. ej. con
      // el teclado abierto en un celular pequeño).
      child: AppCard(
        padding: context.responsivePadding,
        child: Form(
          key: _formKey,
          child: FormGroup(
            children: [
              Image.asset(AppConfig.current.logoPath, height: 64),
              const SizedBox(height: 12),
              AppTitle(
                title: AppConfig.current.displayTitle,
              ),

              AppTextField(
                label: 'DNI',
                controller: _identifierController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                validator: _validateDNI,
                enabled: !_isLoading,
              ),

              // Botón rápido: aparece al completar los 8 dígitos del DNI
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _dniComplete
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: _isLoading ? null : _signInWithDni,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Usar DNI como contraseña',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              AppTextField(
                label: 'Contraseña',
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                enabled: !_isLoading,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword 
                        ? Icons.visibility_off 
                        : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              
              AppButton(
                text: 'INICIAR SESIÓN',
                onPressed: _signIn,
                isLoading: _isLoading,
              ),

              // Link para corregir la cooperativa si se eligió mal
              TextButton(
                onPressed: _isLoading ? null : _changeCooperative,
                child: Text(
                  '¿Cooperativa incorrecta? Cambiar',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
