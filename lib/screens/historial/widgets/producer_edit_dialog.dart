import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_snackbar.dart';
import 'package:panela_sys/widgets/forms/module_search_field.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/radio_group.dart';

/// Diálogo de edición de los datos del productor. Las parcelas se gestionan
/// aparte, con "Parcelas" en la tarjeta del productor (showProducerPlotsSheet).
///
/// Soporta dos modos:
/// - Productor sincronizado (id = UUID): edita directamente en Supabase.
///   Requiere conexión a internet.
/// - Productor pendiente (id = entero): edita en la base de datos local.
///   Funciona sin conexión.
class ProducerEditDialog extends ConsumerStatefulWidget {
  const ProducerEditDialog({
    required this.producerData,
    required this.onSaved,
    super.key,
  });

  /// Datos del productor del mapa del historial.
  final Map<String, dynamic> producerData;

  /// Callback invocado tras guardar exitosamente.
  final VoidCallback onSaved;

  @override
  ConsumerState<ProducerEditDialog> createState() => _ProducerEditDialogState();
}

class _ProducerEditDialogState extends ConsumerState<ProducerEditDialog> {
  late final ProducerService _producerService;
  late final CoopModulesService _modulesService;

  final _formKey = GlobalKey<FormState>();
  final _namesController = TextEditingController();
  final _surnamesController = TextEditingController();
  final _appagropCodeController = TextEditingController();

  List<CoopModule> _modules = [];
  String? _selectedModuleId;
  String _memberStatus = 'SOCIO';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  // Whether this producer is synced (UUID) or pending (local int)
  late final bool _isSynced;
  late final String _producerId;

  @override
  void initState() {
    super.initState();

    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _modulesService = CoopModulesService(db: db);

    _producerId = widget.producerData['id'].toString();
    final syncStatus =
        widget.producerData['syncStatus'] as int? ?? SyncStatus.synced.value;
    _isSynced = syncStatus == SyncStatus.synced.value;

    // Pre-fill from historial data using separated firstName/lastName fields
    _namesController.text =
        widget.producerData['firstName']?.toString() ?? '';
    _surnamesController.text =
        widget.producerData['lastName']?.toString() ?? '';
    if (AppConfig.current.features.useAppagropCode) {
      _appagropCodeController.text =
          widget.producerData['appagropCode']?.toString() ?? '';
    }
    _memberStatus =
        widget.producerData['condicion'] == 'Socio' ? 'SOCIO' : 'NO SOCIO';

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Check connectivity for synced producers
      if (_isSynced) {
        final isConnected = await NetworkDetector().isConnected;
        if (!isConnected) {
          setState(() {
            _isLoading = false;
            _loadError =
                'Necesita conexión a internet para editar productores ya sincronizados.';
          });
          return;
        }
      }

      // Load modules
      final modules = await _modulesService.getModules();

      // Try coopModuleId directly; fall back to matching by name
      final coopModuleId = widget.producerData['coopModuleId']?.toString();
      String? resolvedModuleId;
      if (coopModuleId != null && modules.any((m) => m.id == coopModuleId)) {
        resolvedModuleId = coopModuleId;
      } else {
        final moduloName = widget.producerData['modulo'].toString();
        final matchedModule = modules.firstWhere(
          (m) => m.name == moduloName,
          orElse: () => CoopModule(id: '', name: moduloName),
        );
        resolvedModuleId =
            matchedModule.id.isNotEmpty ? matchedModule.id : null;
      }

      if (mounted) {
        setState(() {
          _modules = modules;
          _selectedModuleId = resolvedModuleId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ── Guardar ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedModuleId == null) {
      _showSnack('Seleccione un módulo', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = CreateProducerRequest(
        firstName: _namesController.text.trim(),
        lastName: _surnamesController.text.trim(),
        dni: widget.producerData['dni'].toString(),
        coopModuleId: _selectedModuleId!,
        isMember: _memberStatus == 'SOCIO',
        appagropCode: AppConfig.current.features.useAppagropCode
            ? _appagropCodeController.text.trim().isNotEmpty
                ? _appagropCodeController.text.trim()
                : null
            : null,
      );

      if (_isSynced) {
        // ── Productor sincronizado: actualiza en Supabase ──────────────────
        await _producerService.updateProducer(_producerId, request);
      } else {
        // ── Productor pendiente: actualiza en DB local ─────────────────────
        final localId = int.parse(_producerId);
        await _producerService.updateLocalPendingProducer(localId, request);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        _showSnack('Cambios guardados correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    AppSnackBar.show(
      context,
      message: message,
      type: isError ? SnackBarType.error : SnackBarType.success,
    );
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field es requerido';
    return null;
  }

  @override
  void dispose() {
    _namesController.dispose();
    _surnamesController.dispose();
    _appagropCodeController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusMedium),
          topRight: Radius.circular(AppDimensions.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: AppColors.textWhite, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editar productor',
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textWhite),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.warning, size: 48),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              style: AppTextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // DNI (read-only)
          _buildReadOnlyField(
            label: 'DNI',
            value: widget.producerData['dni'].toString(),
            hint: 'El DNI no puede modificarse',
          ),
          const SizedBox(height: 12),

          AppTextField(
            label: 'Nombres',
            controller: _namesController,
            textCapitalization: TextCapitalization.words,
            validator: (v) => _validateRequired(v, 'Nombres'),
          ),
          const SizedBox(height: 12),

          AppTextField(
            label: 'Apellidos',
            controller: _surnamesController,
            textCapitalization: TextCapitalization.words,
            validator: (v) => _validateRequired(v, 'Apellidos'),
          ),
          const SizedBox(height: 12),

          ModuleSearchField(
            label: 'Módulo',
            hintText: 'Buscar módulo...',
            modules: _modules,
            selectedModuleId: _selectedModuleId,
            onChanged: (v) => setState(() => _selectedModuleId = v),
          ),
          const SizedBox(height: 12),

          if (AppConfig.current.features.useAppagropCode) ...[
            AppTextField(
              label: 'APPAGROP',
              controller: _appagropCodeController,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => _validateRequired(v, 'APPAGROP'),
            ),
            const SizedBox(height: 12),
          ],

          AppRadioGroup<String>(
            label: 'Condición',
            options: [
              RadioOption(value: 'SOCIO', label: 'SOCIO'),
              RadioOption(value: 'NO SOCIO', label: 'NO SOCIO'),
            ],
            groupValue: _memberStatus,
            onChanged: (v) => setState(() => _memberStatus = v ?? 'SOCIO'),
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancelar',
                  type: AppButtonType.secondary,
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Guardar',
                  onPressed: _save,
                  isLoading: _isSaving,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Widgets auxiliares ───────────────────────────────────────────────────────

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyText
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              if (hint != null)
                Tooltip(
                  message: hint,
                  child: const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
