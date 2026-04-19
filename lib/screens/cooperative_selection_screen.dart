import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/services/cooperative_preferences_service.dart';

/// Pantalla de configuración inicial.
///
/// Flujo en dos pasos:
///   1. El usuario ingresa el código secreto de su cooperativa.
///   2. Se muestra el nombre de la cooperativa para confirmar antes de guardar.
///
/// Se muestra UNA SOLA VEZ (primera instalación), o cuando el usuario
/// elige "Cambiar cooperativa" desde la pantalla de login.
class CooperativeSelectionScreen extends StatefulWidget {
  const CooperativeSelectionScreen({super.key});

  @override
  State<CooperativeSelectionScreen> createState() =>
      _CooperativeSelectionScreenState();
}

class _CooperativeSelectionScreenState
    extends State<CooperativeSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _obscureCode = true;
  String? _errorMessage;

  // Cuando es no-null, estamos en el paso 2 (confirmación)
  CooperativeConfig? _pendingConfig;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ── Paso 1: validar el código ──────────────────────────────────────────────
  void _validateCode() {
    if (!_formKey.currentState!.validate()) return;

    final config = AppConfig.findByAccessCode(_codeController.text.trim());

    if (config == null) {
      setState(() {
        _errorMessage =
            'Código incorrecto. Verifica el código con tu cooperativa.';
      });
      return;
    }

    // Código válido → mostrar paso 2
    setState(() {
      _errorMessage = null;
      _pendingConfig = config;
    });
  }

  // ── Paso 2: confirmar y guardar ────────────────────────────────────────────
  Future<void> _confirmAndSave() async {
    final config = _pendingConfig!;

    // Guardar en SharedPreferences ANTES de configurar AppConfig
    await CooperativePreferencesService.saveCode(config.code);

    // Activar en runtime
    AppConfig.setCooperative(config.code);

    if (mounted) {
      context.go(AppRoutes.login.path);
    }
  }

  // ── Volver al paso 1 ───────────────────────────────────────────────────────
  void _goBackToEntry() {
    setState(() {
      _pendingConfig = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _pendingConfig == null
                    ? _buildStep1(key: const ValueKey('step1'))
                    : _buildStep2(key: const ValueKey('step2')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: ingreso de código ──────────────────────────────────────────────
  Widget _buildStep1({Key? key}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.agriculture_rounded,
          size: 72,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Configuración inicial',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el código proporcionado por tu cooperativa para continuar.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeController,
                obscureText: _obscureCode,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Código de cooperativa',
                  hintText: 'Ingresa tu código',
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.inputBorderError),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCode
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCode = !_obscureCode),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el código de tu cooperativa';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _validateCode(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _validateCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Este código solo se ingresa una vez.\nSi no lo tienes, contacta al administrador de tu cooperativa.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }

  // ── Step 2: confirmación ───────────────────────────────────────────────────
  Widget _buildStep2({Key? key}) {
    final config = _pendingConfig!;
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 72,
          color: AppColors.success,
        ),
        const SizedBox(height: 16),
        Text(
          '¿Esta es tu cooperativa?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 24),

        // Tarjeta con el nombre de la cooperativa
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.business_rounded,
                  color: AppColors.primary, size: 36),
              const SizedBox(height: 10),
              Text(
                config.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Botón confirmar
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _confirmAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Sí, confirmar',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botón corregir
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: _goBackToEntry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'No, corregir el código',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
