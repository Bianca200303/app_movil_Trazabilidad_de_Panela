// =====================================================
// Cleaning and Disinfection Registration Screen
// Dynamic Wizard Implementation (2-10 steps based on selected areas)
// =====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
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
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedAreas = {};
  CleaningType? _cleaningType;
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

  void _nextStep() {
    // Validate current step
    if (_currentStep == 0 && !_validateConfigStep()) {
      return;
    }

    setState(() {
      if (_currentStep < _totalSteps - 1) {
        _currentStep++;
      }
    });
  }

  void _previousStep() {
    if (_currentStep == 0) {
      _showExitConfirmation();
    } else {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateConfigStep() {
    if (_selectedModuleId == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona un módulo',
        type: SnackBarType.error,
      );
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

    if (_cleaningType == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona el tipo de limpieza',
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

  // =====================================================
  // Date Picker
  // =====================================================

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // =====================================================
  // Submit
  // =====================================================

  Future<void> _submitForm() async {
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
                // Type and products are the same for all (from step 0 config)
                cleaningType: _cleaningType!,
                cleaningProducts: _selectedProducts,
              ),
            );
          }
        }
      }

      final request = CreateCleaningDisinfectionRequest(
        coopModuleId: _selectedModuleId!,
        cleaningDate: _selectedDate,
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
            onChanged: (moduleId) {
              setState(() => _selectedModuleId = moduleId);
            },
          ),

          // Date picker
          AppTextField(
            label: 'Fecha de limpieza',
            controller: TextEditingController(
              text: DateFormat('dd/MM/yyyy').format(_selectedDate),
            ),
            readOnly: true,
            onTap: _selectDate,
            suffixIcon: const Icon(Icons.calendar_today),
          ),

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

          // Cleaning type (radio buttons)
          const SizedBox(height: 16),
          Text('Tipo de limpieza:', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          ...CleaningType.values.map((type) {
            return RadioListTile<CleaningType>(
              title: Text(type.getDisplayName()),
              value: type,
              groupValue: _cleaningType,
              onChanged: (value) {
                setState(() => _cleaningType = value);
              },
              dense: true,
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
