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

  int _currentStep = 0;

  // Step 0: Module and date
  String? _selectedModuleId;
  DateTime? _selectedDate;
  List<CoopModule> _availableModules = [];
  bool _isLoadingModules = false;
  bool _isCheckingStep0 = false;

  // Steps 1-8: Checklist data — areaCode -> itemCode -> ItemData
  final Map<String, Map<String, ItemChecklistData>> _checklistData = {};

  // Saving state
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadModules();
    _initializeChecklistData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _loadModules() async {
    setState(() => _isLoadingModules = true);
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
      setState(() => _isLoadingModules = false);
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Error al cargar módulos: $e', type: SnackBarType.error);
      }
    }
  }

  void _initializeChecklistData() {
    for (final areaCode in EnvironmentInspectionAreas.all) {
      _checklistData[areaCode] = {};
      for (final item in EnvironmentInspectionItemTemplates.getItemsForArea(areaCode)) {
        _checklistData[areaCode]![item['code']!] = ItemChecklistData(
          itemCode: item['code']!,
          itemDescription: item['description']!,
          condition: InspectionCondition.compliant,
          correctiveActions: '',
          observations: '',
        );
      }
    }
  }

  Future<void> _handleStep0Continue() async {
    // Button is disabled unless both are selected — these are safety guards only
    if (_selectedModuleId == null || _selectedDate == null) return;

    setState(() => _isCheckingStep0 = true);
    try {
      final existing = await _inspectionService.getInspectionByModuleAndDate(
        _selectedModuleId!,
        _selectedDate!,
      );
      if (!mounted) return;

      if (existing != null) {
        setState(() => _isCheckingStep0 = false);
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Inspección ya registrada'),
            content: const Text(
              'Ya existe una inspección para este módulo en esta fecha. '
              'Puedes verla en el historial.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ENTENDIDO'),
              ),
            ],
          ),
        );
        return;
      }

      if (mounted) {
        setState(() {
          _isCheckingStep0 = false;
          _currentStep = 1;
        });
        _scrollToTop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingStep0 = false);
        AppSnackBar.show(context,
            message: 'Error al verificar: $e', type: SnackBarType.error);
      }
    }
  }

  bool _validateStep() {
    if (_currentStep >= 1 && _currentStep <= 8) {
      final areaCode = EnvironmentInspectionAreas.all[_currentStep - 1];
      final ncWithoutActions = _checklistData[areaCode]!
          .values
          .where((item) =>
              item.condition == InspectionCondition.nonCompliant &&
              item.correctiveActions.trim().isEmpty)
          .length;
      if (ncWithoutActions > 0) {
        AppSnackBar.show(
          context,
          message: 'Hay $ncWithoutActions ítems NC sin acciones correctivas',
          type: SnackBarType.warning,
        );
      }
    }
    return true;
  }

  void _nextStep() {
    if (!_validateStep()) return;
    setState(() {
      if (_currentStep < 9) _currentStep++;
    });
    _scrollToTop();
  }

  void _previousStep() {
    if (_currentStep == 0) {
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
      setState(() => _currentStep--);
      _scrollToTop();
    }
  }

  Future<void> _submitForm() async {
    if (!await AppConfirmDialog.show(context)) return;
    setState(() => _isSaving = true);

    try {
      final items = <CreateEnvironmentInspectionItemRequest>[];
      for (final areaCode in EnvironmentInspectionAreas.all) {
        for (final item in _checklistData[areaCode]!.values) {
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

      await _inspectionService.createInspection(
        CreateEnvironmentInspectionRequest(
          coopModuleId: _selectedModuleId!,
          inspectionDate: _selectedDate,
          cooperativeId: AppConfig.current.id,
          items: items,
        ),
      );

      if (mounted) {
        AppSnackBar.show(context,
            message: 'Inspección registrada exitosamente',
            type: SnackBarType.success);
        context.go(AppRoutes.controlFormsModulo.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Error al guardar la inspección: $e',
            type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return ModuleAndDateStep(
          availableModules: _availableModules,
          isLoadingModules: _isLoadingModules,
          selectedModuleId: _selectedModuleId,
          selectedDate: _selectedDate,
          onModuleChanged: (moduleId) => setState(() {
            _selectedModuleId = moduleId;
            _selectedDate = null;
          }),
          onDateSelected: (date) => setState(() => _selectedDate = date),
          onContinue: _handleStep0Continue,
          onBack: _previousStep,
          isChecking: _isCheckingStep0,
        );

      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
        final areaCode = EnvironmentInspectionAreas.all[_currentStep - 1];
        return AreaChecklistStep(
          areaCode: areaCode,
          itemsData: _checklistData[areaCode]!,
          onItemChanged: (itemCode, updatedData) => setState(() {
            _checklistData[areaCode]![itemCode] = updatedData;
          }),
          onContinue: _nextStep,
          onBack: _previousStep,
        );

      case 9:
        final selectedModule = _availableModules.firstWhere(
          (m) => m.id == _selectedModuleId,
          orElse: () => CoopModule(id: '', name: 'Desconocido'),
        );
        return ReviewSummaryStep(
          moduleName: selectedModule.name,
          inspectionDate: AppDateUtils.formatDDMMYYYY(_selectedDate!),
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
                  constraints: BoxConstraints(maxWidth: context.responsiveCardWidth),
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
