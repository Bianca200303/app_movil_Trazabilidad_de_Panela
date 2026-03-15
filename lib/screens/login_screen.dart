import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/providers/offline_provider.dart';

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

  @override
  void dispose() {
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
          message: e.message,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error: ${e.toString()}',
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
      child: Center(
        child: SingleChildScrollView(
          padding: context.responsiveHorizontalPadding.copyWith(
            top: context.responsivePadding.top,
            bottom: context.responsivePadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsiveCardWidth,
              minHeight: context.screenSize.height - (context.responsivePadding.vertical),
            ),
            child: IntrinsicHeight(
              child: AppCard(
                padding: context.responsivePadding,
                child: Form(
                  key: _formKey,
                  child: FormGroup(
                    children: [
                      AppTitle(
                        title: 'UDEP Captura',
                        subtitle: AppConfig.current.name,
                      ),
                      
                      AppTextField(
                        label: 'DNI',
                        controller: _identifierController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        validator: _validateDNI,
                        enabled: !_isLoading,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
