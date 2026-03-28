import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/environment_inspection_service.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/environment/module_and_date_step.dart';
import 'package:panela_sys/widgets/environment/area_checklist_step.dart';
import 'package:panela_sys/widgets/environment/review_summary_step.dart';

class EnvironmentInspectionRegistrationScreen extends ConsumerStatefulWidget {
  const EnvironmentInspectionRegistrationScreen({super.key});

  @override
  ConsumerState<EnvironmentInspectionRegistrationScreen> createState() =>
      _EnvironmentInspectionRegistrationScreenState();
}

class _EnvironmentInspectionRegistrationScreenState
    extends ConsumerState<EnvironmentInspectionRegistrationScreen> {
  final EnvironmentInspectionService _inspectionService =
      EnvironmentInspectionService();
  final CoopModulesService _modulesService = CoopModulesService();

  int _currentStep = 0; // 0-9 (10 steps total)

  // Step 0: Module and date
  String? _selectedModuleId;
  List<CoopModule> _availableModules = [];
  bool _isLoadingModules = false;
  final TextEditingController _inspectionDateController =
      TextEditingController();

  // Steps 1-8: Checklist data
  // Structure: areaCode -> itemCode -> ItemData
  final Map<String, Map<String, ItemChecklistData>> _checklistData = {};

  // Saving state
  bool _isSaving = false;

  // Scroll controller to reset position on step change
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _inspectionDateController.text = AppDateUtils.getCurrentDDMMYYYY();
    _loadModules();
    _initializeChecklistData();
  }

  @override
  void dispose() {
    _inspectionDateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoadingModules = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      final allModules = await _modulesService.getModules();
      final modules = (currentUser != null && currentUser.hasModuleRestriction)
          ? allModules.where((m) => currentUser.moduleIds.contains(m.id)).toList()
          : allModules;
      setState(() {
        _availableModules = modules;
        if (modules.length == 1) _selectedModuleId = modules.first.id;
        _isLoadingModules = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingModules = false;
      });
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al cargar módulos: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _initializeChecklistData() {
    // Initialize all areas with default values
    for (final areaCode in EnvironmentInspectionAreas.all) {
      _checklistData[areaCode] = {};
      final items =
          EnvironmentInspectionItemTemplates.getItemsForArea(areaCode);
      for (final item in items) {
        _checklistData[areaCode]![item['code']!] = ItemChecklistData(
          itemCode: item['code']!,
          itemDescription: item['description']!,
          condition: InspectionCondition.compliant, // Default to compliant
          correctiveActions: '',
          observations: '',
        );
      }
    }
  }

  bool _validateStep() {
    if (_currentStep == 0) {
      // Validate module and date selection
      if (_selectedModuleId == null) {
        AppSnackBar.show(
          context,
          message: 'Selecciona un módulo',
          type: SnackBarType.error,
        );
        return false;
      }
      if (_inspectionDateController.text.trim().isEmpty) {
        AppSnackBar.show(
          context,
          message: 'Selecciona la fecha de inspección',
          type: SnackBarType.error,
        );
        return false;
      }
      return true;
    }

    // Steps 1-8: Optional warning for NC items without corrective actions
    if (_currentStep >= 1 && _currentStep <= 8) {
      final areaCode = EnvironmentInspectionAreas.all[_currentStep - 1];
      final areaData = _checklistData[areaCode]!;

      final ncWithoutActions = areaData.values
          .where((item) =>
              item.condition == InspectionCondition.nonCompliant &&
              item.correctiveActions.trim().isEmpty)
          .toList();

      if (ncWithoutActions.isNotEmpty) {
        AppSnackBar.show(
          context,
          message:
              'Hay ${ncWithoutActions.length} ítems NC sin acciones correctivas',
          type: SnackBarType.warning,
        );
      }
      return true;
    }

    // Step 9: Final review, no validation needed
    return true;
  }

  void _nextStep() {
    if (!_validateStep()) return;

    setState(() {
      if (_currentStep < 9) {
        _currentStep++;
      }
    });
    _scrollToTop();
  }

  void _previousStep() {
    if (_currentStep == 0) {
      // Show exit confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Salir de la inspección?'),
          content: const Text(
              'Se perderán los datos ingresados. ¿Deseas continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.controlFormsModulo.path);
              },
              child: const Text('SALIR'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _currentStep--;
      });
      _scrollToTop();
    }
  }

  Future<void> _submitForm() async {
    if (!await AppConfirmDialog.show(context)) return;
    setState(() {
      _isSaving = true;
    });

    try {
      // Parse inspection date
      final inspectionDate =
          AppDateUtils.parseDDMMYYYY(_inspectionDateController.text);

      // Build list of all items
      final items = <CreateEnvironmentInspectionItemRequest>[];
      for (final areaCode in EnvironmentInspectionAreas.all) {
        final areaData = _checklistData[areaCode]!;
        for (final item in areaData.values) {
          items.add(CreateEnvironmentInspectionItemRequest(
            areaCode: areaCode,
            itemCode: item.itemCode,
            itemDescription: item.itemDescription,
            condition: item.condition,
            correctiveActions: item.correctiveActions.trim().isEmpty
                ? null
                : item.correctiveActions.trim(),
            observations: item.observations.trim().isEmpty
                ? null
                : item.observations.trim(),
          ));
        }
      }

      // Create request (created_by is auto-populated by database trigger)
      final request = CreateEnvironmentInspectionRequest(
        coopModuleId: _selectedModuleId!,
        inspectionDate: inspectionDate,
        cooperativeId: AppConfig.current.id,
        items: items,
      );

      // Submit to service
      await _inspectionService.createInspection(request);

      // Show success message
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Inspección registrada exitosamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlFormsModulo.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al guardar la inspección: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Module and date selection
        return ModuleAndDateStep(
          availableModules: _availableModules,
          isLoadingModules: _isLoadingModules,
          selectedModuleId: _selectedModuleId,
          inspectionDateController: _inspectionDateController,
          onModuleChanged: (moduleId) {
            setState(() {
              _selectedModuleId = moduleId;
            });
          },
          onContinue: _nextStep,
          onBack: _previousStep,
        );

      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
        // Area checklist steps (8 areas)
        final areaCode = EnvironmentInspectionAreas.all[_currentStep - 1];
        return AreaChecklistStep(
          areaCode: areaCode,
          itemsData: _checklistData[areaCode]!,
          onItemChanged: (itemCode, updatedData) {
            setState(() {
              _checklistData[areaCode]![itemCode] = updatedData;
            });
          },
          onContinue: _nextStep,
          onBack: _previousStep,
        );

      case 9:
        // Final review and submit
        final selectedModule = _availableModules.firstWhere(
          (module) => module.id == _selectedModuleId,
          orElse: () => CoopModule(id: '', name: 'Desconocido'),
        );

        return ReviewSummaryStep(
          moduleName: selectedModule.name,
          inspectionDate: _inspectionDateController.text,
          checklistData: _checklistData,
          isSaving: _isSaving,
          onSubmit: _submitForm,
          onBack: _previousStep,
        );

      default:
        return const Center(child: Text('Paso inválido'));
    }
  }


  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Inspección de Ambientes',
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: context.responsiveHorizontalPadding.copyWith(
                top: context.responsivePadding.top,
                bottom: context.responsivePadding.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.responsiveCardWidth,
                  ),
                  child: AppCard(
                    padding: context.responsivePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppTitle(
                          title: 'Inspección de ambientes, equipo y personal',
                        ),
                        const SizedBox(height: 16),
                        _buildCurrentStep(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
