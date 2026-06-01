// =====================================================
// Cleaning and Disinfection Registration Screen
// Dynamic Wizard Implementation (2-10 steps based on selected areas)
// =====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/cleaning_disinfection.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/cleaning_disinfection_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/widgets/widgets.dart';

class CleaningDisinfectionRegistrationScreen extends ConsumerStatefulWidget {
  const CleaningDisinfectionRegistrationScreen({super.key});

  @override
  ConsumerState<CleaningDisinfectionRegistrationScreen> createState() =>
      _CleaningDisinfectionRegistrationScreenState();
}

class _CleaningDisinfectionRegistrationScreenState
    extends ConsumerState<CleaningDisinfectionRegistrationScreen> {
  // Services
  final _cleaningService = CleaningDisinfectionService();
  final _moduleService = CoopModulesService();

  // Wizard state
  int _currentStep = 0;

  // Step 0: Configuration
  String? _selectedModuleId;
  DateTime? _selectedDate;
  bool _hadProduction = false;
  bool _isCheckingDate = false;
  bool _duplicateWarningAcknowledged = false;
  final Set<String> _selectedAreas = {};
  final Set<CleaningType> _cleaningTypes = {};
  final Set<CleaningProduct> _selectedProducts = {};

  // Steps 1-N: Points per area (only selected areas)
  final Map<String, Set<String>> _selectedPoints = {};

  // Final step: General observations
  final TextEditingController _observationsController =
      TextEditingController();

  // Data loading
  List<CoopModule> _availableModules = [];
  bool _isLoadingModules = true;
  bool _isSaving = false;
  final _scrollController = ScrollController();

  // Computed: Total steps (dynamic based on selected areas)
  int get _totalSteps => 1 + _selectedAreas.length + 1;

  @override
  void initState() {
    super.initState();
    _loadModules();
    _initializeSelectedPoints();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // =====================================================
  // Data Loading
  // =====================================================

  Future<void> _loadModules() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      final allModules = await _moduleService.getModules();
      final modules = (currentUser != null && currentUser.hasModuleRestriction)
          ? allModules.where((m) => currentUser.moduleIds.contains(m.id)).toList()
          : allModules;
      setState(() {
        _availableModules = modules;
        if (modules.length == 1) _selectedModuleId = modules.first.id;
        _isLoadingModules = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al cargar módulos: $e',
          type: SnackBarType.error,
        );
        setState(() => _isLoadingModules = false);
      }
    }
  }

  /// Initialize all points as selected (inverse logic - all marked by default)
  void _initializeSelectedPoints() {
    for (final areaCode in CleaningAreas.all) {
      final points = CleaningPointTemplates.getPointsForArea(areaCode);
      _selectedPoints[areaCode] =
          points.map((p) => p['code']!).toSet();
    }
  }

  // =====================================================
  // Navigation
  // =====================================================

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      if (!_validateConfigStep()) return;
      final hasExisting = await _cleaningService.hasCleaningOnDate(
        _selectedModuleId!,
        _selectedDate!,
      );
      if (!mounted) return;
      if (hasExisting && !_duplicateWarningAcknowledged) {
        final coveredAreas = await _cleaningService.getAreasCoveredOnDate(
          _selectedModuleId!,
          _selectedDate!,
        );
        if (!mounted) return;
        final missingAreas = CleaningAreas.all
            .where((a) => !coveredAreas.contains(a))
            .toList();

        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Ya hay un registro de limpieza este día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Otro usuario ya registró limpieza para este módulo hoy.',
                  style: TextStyle(fontSize: 16),
                ),
                if (coveredAreas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Áreas ya cubiertas:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...coveredAreas.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${CleaningAreas.getDisplayName(a)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  )),
                ],
                const SizedBox(height: 12),
                const Text(
                  '¿Cómo deseas continuar?',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('CANCELAR', style: TextStyle(fontSize: 15)),
              ),
              if (missingAreas.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.of(context).pop('missing'),
                  child: const Text('ÁREAS FALTANTES', style: TextStyle(fontSize: 15)),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('all'),
                child: const Text('ELEGIR MIS ÁREAS', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        );
        if (choice == null || !mounted) return;
        _duplicateWarningAcknowledged = true;
        if (choice == 'missing') {
          setState(() => _selectedAreas
            ..clear()
            ..addAll(missingAreas));
        }
      }
    }

    setState(() {
      if (_currentStep < _totalSteps - 1) _currentStep++;
    });
    _scrollController.jumpTo(0);
  }

  void _previousStep() {
    if (_currentStep == 0) {
      _showExitConfirmation();
    } else {
      setState(() {
        _currentStep--;
      });
      _scrollController.jumpTo(0);
    }
  }

  bool _validateConfigStep() {
    if (_selectedModuleId == null) {
      AppSnackBar.show(context, message: 'Selecciona un módulo', type: SnackBarType.error);
      return false;
    }

    if (_selectedDate == null) {
      AppSnackBar.show(context, message: 'Selecciona la fecha', type: SnackBarType.error);
      return false;
    }

    if (_selectedAreas.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Selecciona al menos un área',
        type: SnackBarType.error,
      );
      return false;
    }

    if (_cleaningTypes.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Selecciona al menos un tipo de limpieza',
        type: SnackBarType.error,
      );
      return false;
    }

    if (_selectedProducts.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Selecciona al menos un producto',
        type: SnackBarType.error,
      );
      return false;
    }

    return true;
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar registro'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar? Se perderán todos los datos ingresados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.controlFormsModulo.path);
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      locale: const Locale('es'),
    );
    if (picked == null || !mounted) return;
    setState(() { _selectedDate = picked; _hadProduction = false; _duplicateWarningAcknowledged = false; });
    if (_selectedModuleId == null) return;
    setState(() => _isCheckingDate = true);
    final hasProd = await _cleaningService.hasProductionOnDate(_selectedModuleId!, picked);
    if (mounted) setState(() { _hadProduction = hasProd; _isCheckingDate = false; });
  }

  // =====================================================
  // Submit
  // =====================================================

  Future<void> _submitForm() async {
    if (!await AppConfirmDialog.show(context)) return;
    setState(() => _isSaving = true);

    try {
      // Build items only for selected areas
      final items = <CreateCleaningDisinfectionItemRequest>[];

      // Iterate only over selected areas
      for (final areaCode in _selectedAreas) {
        final points = CleaningPointTemplates.getPointsForArea(areaCode);
        final selectedPoints = _selectedPoints[areaCode]!;

        // Create item only for checked points
        for (final point in points) {
          final pointCode = point['code']!;
          if (selectedPoints.contains(pointCode)) {
            items.add(
              CreateCleaningDisinfectionItemRequest(
                areaCode: areaCode,
                pointCode: pointCode,
                pointDescription: point['description']!,
                cleaningProducts: _selectedProducts,
              ),
            );
          }
        }
      }

      final request = CreateCleaningDisinfectionRequest(
        coopModuleId: _selectedModuleId!,
        cleaningDate: _selectedDate!,
        cleaningTypes: _cleaningTypes,
        cooperativeId: AppConfig.current.id,
        items: items,
        generalObservations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
      );

      await _cleaningService.createCleaningRecord(request);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Registro de limpieza guardado exitosamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlFormsModulo.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al guardar: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // =====================================================
  // UI Rendering
  // =====================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingModules) {
      return const AppScaffold(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Limpieza y Desinfección',
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: context.responsiveHorizontalPadding.copyWith(
            top: context.responsivePadding.top,
            bottom: context.responsivePadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsiveCardWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current step content
                _buildCurrentStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      return _buildConfigStep();
    } else if (_currentStep <= _selectedAreas.length) {
      // Steps 1-N: Checklist per area
      final areaIndex = _currentStep - 1;
      final areaCode = _selectedAreas.toList()[areaIndex];
      return _buildAreaChecklistStep(areaCode);
    } else {
      // Final step: General observations
      return _buildObservationsStep();
    }
  }

  // =====================================================
  // Step 0: Configuration
  // =====================================================

  Widget _buildConfigStep() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          // Back button at the top
          AppBackButton(
            onPressed: () => context.go(AppRoutes.controlFormsModulo.path),
            isExpanded: true,
          ),
          SizedBox(height: context.responsiveSpacing),

          const AppTitle(
            title: 'Limpieza y desinfección',
          ),
          const SizedBox(height: 8),
          Text(
            'Configura los detalles generales de la limpieza realizada',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Module dropdown
          AppDropdown<String>(
            label: 'Módulo',
            value: _selectedModuleId,
            options: _availableModules
                .map(
                  (m) => DropdownOption(
                    value: m.id,
                    label: m.name,
                  ),
                )
                .toList(),
            onChanged: (moduleId) => setState(() {
              _selectedModuleId = moduleId;
              _selectedDate = null;
              _hadProduction = false;
              _duplicateWarningAcknowledged = false;
            }),
          ),

          if (_selectedModuleId != null) ...[
            const SizedBox(height: 8),
            Text('Fecha de limpieza', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Container(
                padding: context.responsivePadding,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                    SizedBox(width: context.responsiveSpacing / 2),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? AppDateUtils.formatDDMMYYYY(_selectedDate!)
                            : 'Selecciona una fecha',
                        style: AppTextStyles.bodyText.copyWith(
                          color: _selectedDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            if (_isCheckingDate) ...[
              const SizedBox(height: 8),
              const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ] else if (_selectedDate != null && _hadProduction) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.agriculture_outlined, size: 16, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Text(
                      'Día con producción registrada',
                      style: AppTextStyles.captionText.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Areas to clean (checkboxes)
          const SizedBox(height: 16),
          Text('Áreas limpiadas:', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          ...CleaningAreas.all.map((areaCode) {
            return CheckboxListTile(
              title: Text(CleaningAreas.getDisplayName(areaCode)),
              value: _selectedAreas.contains(areaCode),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedAreas.add(areaCode);
                  } else {
                    _selectedAreas.remove(areaCode);
                  }
                });
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),

          // Cleaning type (checkboxes — multiple allowed)
          const SizedBox(height: 16),
          Text('Tipo de limpieza:', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          ...CleaningType.values.map((type) {
            return CheckboxListTile(
              title: Text(type.getDisplayName()),
              value: _cleaningTypes.contains(type),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _cleaningTypes.add(type);
                  } else {
                    _cleaningTypes.remove(type);
                  }
                });
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),

          // Products used (checkboxes)
          const SizedBox(height: 16),
          Text('Productos utilizados:', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          ...CleaningProduct.values.map((product) {
            return CheckboxListTile(
              title: Text(product.getDisplayName()),
              value: _selectedProducts.contains(product),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedProducts.add(product);
                  } else {
                    _selectedProducts.remove(product);
                  }
                });
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),

          const SizedBox(height: 24),

          // Button
          AppButton(
            text: 'Continuar',
            type: AppButtonType.primary,
            onPressed: _nextStep,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Steps 1-N: Area Checklist
  // =====================================================

  Widget _buildAreaChecklistStep(String areaCode) {
    final points = CleaningPointTemplates.getPointsForArea(areaCode);
    final areaSelectedPoints = _selectedPoints[areaCode]!;

    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          // Back button at the top
          AppBackButton(
            onPressed: _previousStep,
            isExpanded: true,
          ),
          SizedBox(height: context.responsiveSpacing),

          AppTitle(title: CleaningAreas.getDisplayName(areaCode)),
          const SizedBox(height: 8),
          Text(
            'Selecciona los puntos que se limpiaron en esta área:',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // List of checkboxes (all checked by default)
          ...points.map((point) {
            final pointCode = point['code']!;
            final isSelected = areaSelectedPoints.contains(pointCode);

            return CheckboxListTile(
              title: Text(point['description']!),
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedPoints[areaCode]!.add(pointCode);
                  } else {
                    _selectedPoints[areaCode]!.remove(pointCode);
                  }
                });
              },
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),

          const SizedBox(height: 24),

          // Button
          AppButton(
            text: 'Continuar',
            type: AppButtonType.primary,
            onPressed: _nextStep,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Final Step: General Observations
  // =====================================================

  Widget _buildObservationsStep() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          // Back button at the top
          AppBackButton(
            onPressed: _previousStep,
            isExpanded: true,
          ),
          SizedBox(height: context.responsiveSpacing),

          const AppTitle(title: 'Observaciones Generales'),
          const SizedBox(height: 8),
          Text(
            'Agrega cualquier observación adicional sobre la limpieza realizada:',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Observaciones (opcional)',
            controller: _observationsController,
            maxLines: 6,
            hintText:
                'Ej: Se encontró humedad en el techo del área de tratamiento térmico...',
          ),

          const SizedBox(height: 24),

          // Button
          AppButton(
            text: _isSaving ? 'Guardando...' : 'Guardar',
            type: AppButtonType.primary,
            onPressed: _isSaving ? null : _submitForm,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}
