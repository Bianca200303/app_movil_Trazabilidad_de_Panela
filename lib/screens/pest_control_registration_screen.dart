// =====================================================
// Pest Control Registration Screen
// 4-Step Wizard Implementation
// =====================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/models/pest_control.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/pest_control_service.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/pest_control/bait_control_step.dart';
import 'package:panela_sys/widgets/pest_control/insect_control_step.dart';
import 'package:panela_sys/widgets/widgets.dart';

class PestControlRegistrationScreen extends ConsumerStatefulWidget {
  const PestControlRegistrationScreen({super.key});

  @override
  ConsumerState<PestControlRegistrationScreen> createState() =>
      _PestControlRegistrationScreenState();
}

class _PestControlRegistrationScreenState
    extends ConsumerState<PestControlRegistrationScreen> {
  // Services
  final _pestControlService = PestControlService();
  final _moduleService = CoopModulesService();

  // Wizard state
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Step 0: Module and Date
  String? _selectedModuleId;
  DateTime? _selectedDate;
  List<CoopModule> _availableModules = [];
  bool _isLoadingModules = true;
  bool _hadProduction = false;
  bool _isCheckingDate = false;
  bool _duplicateWarningAcknowledged = false;

  // Step 1: Bait Control
  final _baitProductController = TextEditingController();
  final _baitQuantityController = TextEditingController();
  final _baitUnitController = TextEditingController();
  List<BaitStation> _baitStations = [BaitStation(stationNumber: 1, ate: false)];
  final _baitObservationsController = TextEditingController();

  // Step 2: Insect Control
  final _insectProductController = TextEditingController();
  final _insectQuantityController = TextEditingController();
  final _insectUnitController = TextEditingController();
  final _insectFliesController = TextEditingController();
  final _insectBeesController = TextEditingController();
  final _insectAntsController = TextEditingController();
  final _insectCockroachesController = TextEditingController();
  final _insectAreaController = TextEditingController();
  final _insectObservationsController = TextEditingController();

  // Saving state
  bool _isSaving = false;

  // Scroll
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _baitProductController.text = 'Panela';
    _baitUnitController.text = 'gr';
    _insectProductController.text = 'Trampa de Luz';
    _insectUnitController.text = 'lámina';
    _loadModules();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _baitProductController.dispose();
    _baitQuantityController.dispose();
    _baitUnitController.dispose();
    _baitObservationsController.dispose();
    _insectProductController.dispose();
    _insectQuantityController.dispose();
    _insectUnitController.dispose();
    _insectFliesController.dispose();
    _insectBeesController.dispose();
    _insectAntsController.dispose();
    _insectCockroachesController.dispose();
    _insectAreaController.dispose();
    _insectObservationsController.dispose();
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

  // =====================================================
  // Navigation
  // =====================================================

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      if (!_validateStep0()) return;
      if (!_duplicateWarningAcknowledged) {
        final hasExisting = await _pestControlService.hasControlOnDate(_selectedModuleId!, _selectedDate!);
        if (!mounted) return;
        if (hasExisting) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Ya hay un control este día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: const Text('Ya existe un control de plagas para este módulo en esta fecha.\n\n¿Deseas registrar otro igualmente?', style: TextStyle(fontSize: 16)),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCELAR', style: TextStyle(fontSize: 15))),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('CONTINUAR', style: TextStyle(fontSize: 15))),
              ],
            ),
          );
          if (proceed != true || !mounted) return;
          _duplicateWarningAcknowledged = true;
        }
      }
    } else if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      if (_currentStep < _totalSteps - 1) {
        _currentStep++;
      }
    });
    _scrollController.jumpTo(0);
  }

  void _previousStep() {
    if (_currentStep == 0) {
      _showExitConfirmation();
    } else {
      setState(() => _currentStep--);
      _scrollController.jumpTo(0);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStep0();
      case 1:
        return _validateStep1();
      case 2:
        return _validateStep2();
      case 3:
        return true; // Summary step, no validation
      default:
        return true;
    }
  }

  bool _validateStep0() {
    if (_selectedModuleId == null) {
      AppSnackBar.show(context, message: 'Selecciona un módulo', type: SnackBarType.error);
      return false;
    }
    if (_selectedDate == null) {
      AppSnackBar.show(context, message: 'Selecciona la fecha', type: SnackBarType.error);
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    // Only validate if user entered any bait data
    final hasData = _baitProductController.text.trim().isNotEmpty ||
        _baitQuantityController.text.trim().isNotEmpty ||
        _baitUnitController.text.trim().isNotEmpty ||
        _baitObservationsController.text.trim().isNotEmpty;

    if (!hasData) {
      return true; // Allow skipping if no data entered
    }

    if (_baitProductController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ingresa el producto empleado para control de cebos',
        type: SnackBarType.error,
      );
      return false;
    }

    final quantity = double.tryParse(_baitQuantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      AppSnackBar.show(
        context,
        message: 'Ingresa una cantidad válida mayor a 0',
        type: SnackBarType.error,
      );
      return false;
    }

    if (_baitUnitController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ingresa la unidad de medida',
        type: SnackBarType.error,
      );
      return false;
    }

    return true;
  }

  bool _validateStep2() {
    // Only validate if user entered any insect data
    final hasData = _insectProductController.text.trim().isNotEmpty ||
        _insectQuantityController.text.trim().isNotEmpty ||
        _insectUnitController.text.trim().isNotEmpty;

    if (!hasData) {
      return true; // Allow skipping if no data entered
    }

    if (_insectProductController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ingresa el producto empleado para control de insectos',
        type: SnackBarType.error,
      );
      return false;
    }

    final quantity = double.tryParse(_insectQuantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      AppSnackBar.show(
        context,
        message: 'Ingresa una cantidad válida mayor a 0',
        type: SnackBarType.error,
      );
      return false;
    }

    if (_insectUnitController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ingresa la unidad de medida',
        type: SnackBarType.error,
      );
      return false;
    }

    // Validate area is filled if insect data is entered
    if (_insectProductController.text.trim().isNotEmpty &&
        _insectAreaController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ingresa el área para el control de insectos',
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
    final hasProd = await _pestControlService.hasProductionOnDate(_selectedModuleId!, picked);
    if (mounted) setState(() { _hadProduction = hasProd; _isCheckingDate = false; });
  }

  // =====================================================
  // Submit
  // =====================================================

  Future<void> _submitForm() async {
    if (!await AppConfirmDialog.show(context)) return;
    setState(() => _isSaving = true);

    try {
      // Determine what data was entered
      final hasBaitData = _baitProductController.text.trim().isNotEmpty;
      final hasInsectData = _insectProductController.text.trim().isNotEmpty;

      // Validate at least one type
      if (!hasBaitData && !hasInsectData) {
        AppSnackBar.show(
          context,
          message: 'Debe ingresar al menos un tipo de control (cebos o insectos)',
          type: SnackBarType.error,
        );
        setState(() => _isSaving = false);
        return;
      }

      // Build bait request if data entered
      CreatePestControlBaitRequest? baitRequest;
      if (hasBaitData) {
        baitRequest = CreatePestControlBaitRequest(
          productName: _baitProductController.text.trim(),
          quantity: double.parse(_baitQuantityController.text.trim()),
          unit: _baitUnitController.text.trim(),
          baitStations: _baitStations,
          baitObservations: _baitObservationsController.text.trim().isEmpty
              ? null
              : _baitObservationsController.text.trim(),
        );
      }

      // Build insect request if data entered
      CreatePestControlInsectRequest? insectRequest;
      if (hasInsectData) {
        final insectData = [
          InsectData(
            flies: int.tryParse(_insectFliesController.text.trim()),
            bees: int.tryParse(_insectBeesController.text.trim()),
            ants: int.tryParse(_insectAntsController.text.trim()),
            cockroaches: int.tryParse(_insectCockroachesController.text.trim()),
            area: _insectAreaController.text.trim(),
            observations: _insectObservationsController.text.trim().isEmpty
                ? null
                : _insectObservationsController.text.trim(),
          )
        ];

        insectRequest = CreatePestControlInsectRequest(
          productName: _insectProductController.text.trim(),
          quantity: double.parse(_insectQuantityController.text.trim()),
          unit: _insectUnitController.text.trim(),
          insectData: insectData,
        );
      }

      final request = CreatePestControlRequest(
        coopModuleId: _selectedModuleId!,
        controlDate: _selectedDate!,
        cooperativeId: AppConfig.current.id,
        baitRecord: baitRequest,
        insectRecord: insectRequest,
      );

      await _pestControlService.createPestControl(request);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Control de plagas registrado exitosamente',
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
  // Step Builders
  // =====================================================

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0ModuleDate();
      case 1:
        return BaitControlStep(
          productController: _baitProductController,
          quantityController: _baitQuantityController,
          unitController: _baitUnitController,
          baitStations: _baitStations,
          onBaitStationsChanged: (stations) {
            setState(() => _baitStations = stations);
          },
          observationsController: _baitObservationsController,
          onContinue: _nextStep,
          onBack: _previousStep,
        );
      case 2:
        return InsectControlStep(
          productController: _insectProductController,
          quantityController: _insectQuantityController,
          unitController: _insectUnitController,
          fliesController: _insectFliesController,
          beesController: _insectBeesController,
          antsController: _insectAntsController,
          cockroachesController: _insectCockroachesController,
          areaController: _insectAreaController,
          observationsController: _insectObservationsController,
          onContinue: _nextStep,
          onBack: _previousStep,
        );
      case 3:
        return _buildStep3Summary();
      default:
        return const Center(child: Text('Paso inválido'));
    }
  }

  Widget _buildStep0ModuleDate() {
    return FormSection(
      children: [
        AppBackButton(
          onPressed: () => context.go(AppRoutes.controlFormsModulo.path),
          isExpanded: true,
        ),
        SizedBox(height: context.responsiveSpacing),
        const AppTitle(
          title: 'Control de plagas',
        ),
        if (_isLoadingModules)
          const Center(child: CircularProgressIndicator())
        else
          AppDropdown<String>(
            label: 'Módulo',
            value: _selectedModuleId,
            options: _availableModules
                .map((m) => DropdownOption(value: m.id, label: m.name))
                .toList(),
            onChanged: (value) => setState(() {
              _selectedModuleId = value;
              _selectedDate = null;
              _hadProduction = false;
              _duplicateWarningAcknowledged = false;
            }),
          ),
        if (_selectedModuleId != null) ...[
          FormSection(
            title: 'Fecha del control',
            subtitle: 'Selecciona cualquier fecha',
            children: [
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
                      Text('Día con producción registrada',
                        style: AppTextStyles.captionText.copyWith(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
        SizedBox(height: context.responsiveSpacing),
        AppButton(
          text: 'Continuar',
          type: AppButtonType.primary,
          onPressed: _nextStep,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildStep3Summary() {
    // Calculate statistics
    final hasBaitData = _baitProductController.text.trim().isNotEmpty;
    final hasInsectData = _insectProductController.text.trim().isNotEmpty;

    // Bait statistics
    final totalStations = _baitStations.length;
    final stationsEaten = _baitStations.where((s) => s.ate).length;
    final consumptionPercentage =
        totalStations > 0 ? (stationsEaten / totalStations) * 100 : 0.0;

    // Insect statistics (single record)
    final totalFlies = int.tryParse(_insectFliesController.text.trim()) ?? 0;
    final totalBees = int.tryParse(_insectBeesController.text.trim()) ?? 0;
    final totalAnts = int.tryParse(_insectAntsController.text.trim()) ?? 0;
    final totalCockroaches = int.tryParse(_insectCockroachesController.text.trim()) ?? 0;
    final totalInsects = totalFlies + totalBees + totalAnts + totalCockroaches;
    final insectArea = _insectAreaController.text.trim();

    return FormGroup(
      children: [
        AppBackButton(
          onPressed: _previousStep,
          isExpanded: true,
        ),
        SizedBox(height: context.responsiveSpacing),
        const AppTitle(title: 'Resumen'),
        Text(
          'Datos generales',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: context.responsiveSpacing / 2),
        _buildSummaryRow(
          'Módulo',
          _availableModules
                  .firstWhere((m) => m.id == _selectedModuleId)
                  .name,
        ),
        _buildSummaryRow(
          'Fecha',
          AppDateUtils.formatDDMMYYYY(_selectedDate!),
        ),
        if (hasBaitData) ...[
          SizedBox(height: context.responsiveSpacing),
          const Divider(),
          SizedBox(height: context.responsiveSpacing),
          Text(
            'Control de Cebos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: context.responsiveSpacing / 2),
          _buildSummaryRow(
            'Producto',
            _baitProductController.text.trim(),
          ),
          _buildSummaryRow(
            'Cantidad',
            '${_baitQuantityController.text.trim()} ${_baitUnitController.text.trim()}',
          ),
          _buildSummaryRow('Total estaciones', '$totalStations'),
          _buildSummaryRow('Estaciones con cebo comido', '$stationsEaten'),
          _buildSummaryRow(
            '% Consumo',
            '${consumptionPercentage.toStringAsFixed(1)}%',
          ),
        ],
        if (hasInsectData) ...[
          SizedBox(height: context.responsiveSpacing),
          const Divider(),
          SizedBox(height: context.responsiveSpacing),
          Text(
            'Control de Insectos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: context.responsiveSpacing / 2),
          _buildSummaryRow(
            'Producto',
            _insectProductController.text.trim(),
          ),
          _buildSummaryRow(
            'Cantidad',
            '${_insectQuantityController.text.trim()} ${_insectUnitController.text.trim()}',
          ),
          _buildSummaryRow('Total moscas', '$totalFlies'),
          _buildSummaryRow('Total abejas', '$totalBees'),
          _buildSummaryRow('Total hormigas', '$totalAnts'),
          _buildSummaryRow('Total cucarachas', '$totalCockroaches'),
          _buildSummaryRow('Total insectos', '$totalInsects'),
          _buildSummaryRow('Área', insectArea.isNotEmpty ? insectArea : 'No especificada'),
        ],
        SizedBox(height: context.responsiveSpacing),
        AppButton(
          text: 'Guardar registro',
          type: AppButtonType.primary,
          onPressed: _isSaving ? null : _submitForm,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Control de Plagas',
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
            child: AppCard(
              padding: context.responsivePadding,
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }
}
