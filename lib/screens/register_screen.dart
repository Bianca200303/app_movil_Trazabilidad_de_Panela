import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateDNI(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su DNI';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(value)) {
      return 'El DNI debe tener exactamente 8 dígitos';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su $fieldName';
    }
    if (value.length < 2) {
      return 'El $fieldName debe tener al menos 2 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúñÁÉÍÓÚÑ\s]+$').hasMatch(value)) {
      return 'El $fieldName solo puede contener letras';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme su contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerUser(
        dni: _dniController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Usuario registrado exitosamente',
          type: SnackBarType.success,
        );
        
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
      showBackButton: true,
      showSyncStatus: false,
      onBack: () => context.go(AppRoutes.login.path),
      child: Center(
        child: SingleChildScrollView(
          padding: context.responsiveHorizontalPadding.copyWith(
            top: context.responsivePadding.top,
            bottom: context.responsivePadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsiveCardWidth,
            ),
            child: AppCard(
              padding: context.responsivePadding,
              child: Form(
                key: _formKey,
                child: FormGroup(
                  children: [
                    AppTitle(
                      title: 'Crear cuenta',
                      subtitle: AppConfig.current.name,
                    ),
                    
                    AppTextField(
                      label: 'DNI',
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      validator: _validateDNI,
                      enabled: !_isLoading,
                    ),
                    
                    AppTextField(
                      label: 'Nombres',
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => _validateName(value, 'nombre'),
                      enabled: !_isLoading,
                    ),
                    
                    AppTextField(
                      label: 'Apellidos',
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => _validateName(value, 'apellido'),
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
                    
                    AppTextField(
                      label: 'Confirmar Contraseña',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      enabled: !_isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword 
                              ? Icons.visibility_off 
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    
                    AppButton(
                      text: 'REGISTRARSE',
                      onPressed: _register,
                      isLoading: _isLoading,
                    ),
                    
                    context.shouldStackButtons
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: context.responsiveSpacing / 2),
                              Text(
                                '¿Ya tienes cuenta?',
                                style: AppTextStyles.bodyText,
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : () {
                                  context.go(AppRoutes.login.path);
                                },
                                child: Text(
                                  'Iniciar Sesión',
                                  style: AppTextStyles.linkText,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  '¿Ya tienes cuenta? ',
                                  style: AppTextStyles.bodyText,
                                ),
                              ),
                              Flexible(
                                child: TextButton(
                                  onPressed: _isLoading ? null : () {
                                    context.go(AppRoutes.login.path);
                                  },
                                  child: Text(
                                    'Iniciar Sesión',
                                    style: AppTextStyles.linkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}