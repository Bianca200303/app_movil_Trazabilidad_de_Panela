import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/chlorine_residual_control.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/chlorine_residual_control_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/shared/production_date_selector.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChlorineControlRegistrationScreen extends ConsumerStatefulWidget {
  const ChlorineControlRegistrationScreen({super.key});

  @override
  ConsumerState<ChlorineControlRegistrationScreen> createState() =>
      _ChlorineControlRegistrationScreenState();
}

class _ChlorineControlRegistrationScreenState
    extends ConsumerState<ChlorineControlRegistrationScreen> {
  // Services
  final _moduleService = CoopModulesService();
  final _chlorineService = ChlorineResidualControlService();
  final _supabase = Supabase.instance.client;

  // Form state
  final _formKey = GlobalKey<FormState>();
  String? _selectedModuleId;
  List<CoopModule> _availableModules = [];
  bool _isLoadingModules = false;
  bool _isSaving = false;

  // Producers for responsible person autocomplete
  List<String> _producerNames = [];
  bool _isLoadingProducers = false;
  final _responsibleFocusNode = FocusNode();

  // Date and time
  DateTime? _controlDate;
  TimeOfDay _controlTime = const TimeOfDay(hour: 6, minute: 0);
  List<ProductionDateGroup> _productionDates = [];
  bool _isLoadingDates = false;
  DateTime _filterFrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _filterTo = DateTime.now();

  // Text controllers
  final _m1Controller = TextEditingController();
  final _m2Controller = TextEditingController();
  final _correctiveActionsController = TextEditingController();
  final _observationsController = TextEditingController();
  final _responsiblePersonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadProducers();
  }

  @override
  void dispose() {
    _m1Controller.dispose();
    _m2Controller.dispose();
    _correctiveActionsController.dispose();
    _observationsController.dispose();
    _responsiblePersonController.dispose();
    _responsibleFocusNode.dispose();
    super.dispose();
  }

  // =====================================================
  // Data Loading
  // =====================================================

  Future<void> _loadProducers() async {
    setState(() => _isLoadingProducers = true);
    try {
      final response = await _supabase
          .from('producers')
          .select('first_name, last_name')
          .eq('cooperative_id', AppConfig.current.id)
          .eq('is_active', true)
          .order('first_name');
      setState(() {
        _producerNames = (response as List)
            .map((p) => '${p['first_name']} ${p['last_name']}')
            .toList();
        _isLoadingProducers = false;
      });
    } catch (_) {
      setState(() => _isLoadingProducers = false);
    }
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoadingModules = true;
    });

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
        setState(() {
          _isLoadingModules = false;
        });
        AppSnackBar.show(
          context,
          message: 'Error al cargar módulos: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  // =====================================================
  // Validation
  // =====================================================

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  String? _validateMeasurement(String? value, String pointName) {
    if (value == null || value.trim().isEmpty) {
      return '$pointName es obligatorio';
    }

    final measurement = double.tryParse(value);
    if (measurement == null) {
      return 'Ingresa un número válido';
    }

    if (!ChlorineSafeRange.isValid(measurement)) {
      return 'Debe estar entre ${ChlorineSafeRange.minValidPpm} y ${ChlorineSafeRange.maxValidPpm} ppm';
    }

    return null;
  }

  // =====================================================
  // Date Loading
  // =====================================================

  Future<void> _loadProductionDates() async {
    if (_selectedModuleId == null) return;
    setState(() => _isLoadingDates = true);
    try {
      final dates = await _chlorineService.getProductionDateGroups(
        _selectedModuleId!,
        _filterFrom,
        _filterTo,
      );
      if (mounted) setState(() { _productionDates = dates; _isLoadingDates = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingDates = false);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _controlTime,
    );

    if (time != null) {
      setState(() {
        _controlTime = time;
      });
    }
  }

  // =====================================================
  // Form Submission
  // =====================================================

  Future<void> _submitControl() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate module selection
    if (_selectedModuleId == null) {
      AppSnackBar.show(context, message: 'Selecciona un módulo', type: SnackBarType.error);
      return;
    }

    if (_controlDate == null) {
      AppSnackBar.show(context, message: 'Selecciona la fecha', type: SnackBarType.error);
      return;
    }

    final timeString =
        '${_controlTime.hour.toString().padLeft(2, '0')}:${_controlTime.minute.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      _chlorineService.hasControlOnDate(_selectedModuleId!, _controlDate!),
      _chlorineService.hasControlOnDateTime(_selectedModuleId!, _controlDate!, timeString),
    ]);
    if (!mounted) return;
    final hasOnDate = results[0];
    final hasOnDateTime = results[1];

    if (hasOnDate) {
      final message = hasOnDateTime
          ? '¡Atención! Ya existe un control registrado para este módulo el ${AppDateUtils.formatDDMMYYYY(_controlDate!)} a las $timeString exactamente.\n\n¿Deseas registrar otro de todas formas?'
          : 'Ya existe al menos un control de cloro para este módulo en esta fecha.\n\n¿Deseas registrar otro igualmente?';
      final title = hasOnDateTime ? 'Misma fecha y hora exacta' : 'Ya hay un control este día';
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCELAR', style: TextStyle(fontSize: 15))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('CONTINUAR', style: TextStyle(fontSize: 15))),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    if (!await AppConfirmDialog.show(context)) return;

    setState(() => _isSaving = true);

    try {
      final m1 = double.parse(_m1Controller.text.trim());
      final m2 = double.parse(_m2Controller.text.trim());

      // Create request
      final request = CreateChlorineResidualControlRequest(
        coopModuleId: _selectedModuleId!,
        controlDate: _controlDate!,
        controlTime: timeString,
        measurementPoint1: m1,
        measurementPoint2: m2,
        correctiveActions: _correctiveActionsController.text.trim().isEmpty
            ? null
            : _correctiveActionsController.text.trim(),
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        responsiblePerson: _responsiblePersonController.text.trim(),
      );

      // Submit to service
      await _chlorineService.createControl(request);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Control de cloro registrado exitosamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlFormsModulo.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al registrar control: $e',
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

  // =====================================================
  // UI Helpers
  // =====================================================

  /// Show warning if measurement is outside safe range
  Widget? _buildSafetyWarning() {
    final m1 = double.tryParse(_m1Controller.text.trim());
    final m2 = double.tryParse(_m2Controller.text.trim());

    if (m1 == null && m2 == null) return null;

    final warnings = <String>[];
    if (m1 != null && !ChlorineSafeRange.isSafe(m1)) {
      warnings.add('M1: ${ChlorineSafeRange.getStatusMessage(m1)}');
    }
    if (m2 != null && !ChlorineSafeRange.isSafe(m2)) {
      warnings.add('M2: ${ChlorineSafeRange.getStatusMessage(m2)}');
    }

    if (warnings.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuera del rango seguro (0.5-2.0 ppm)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                ...warnings.map((warning) => Text(
                      warning,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Build UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Control de Cloro Libre Residual',
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
                    // Back button
                    AppBackButton(
                      onPressed: () => context.go(AppRoutes.controlFormsModulo.path),
                      isExpanded: true,
                    ),

                    SizedBox(height: context.responsiveSpacing),

                    // Title
                    const AppTitle(
                      title: 'Control de cloro libre residual',
                    ),

                    // Module dropdown
                    AppDropdown<String>(
                      label: 'Módulo',
                      value: _selectedModuleId,
                      options: _availableModules
                          .map((module) => DropdownOption(
                                value: module.id,
                                label: module.name,
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedModuleId = value;
                          _controlDate = null;
                          _productionDates = [];
                        });
                        _loadProductionDates();
                      },
                      isLoading: _isLoadingModules,
                    ),

                    if (_selectedModuleId != null) ...[
                      const SizedBox(height: 8),
                      Text('Selecciona la fecha de producción', style: AppTextStyles.fieldLabel),
                      const SizedBox(height: 8),
                      ProductionDateSelector(
                        productionDates: _productionDates,
                        isLoadingDates: _isLoadingDates,
                        selectedDate: _controlDate,
                        onDateSelected: (date) => setState(() => _controlDate = date),
                        onFilterChanged: (from, to) {
                          setState(() { _filterFrom = from; _filterTo = to; });
                          _loadProductionDates();
                        },
                        blocksAlreadyRecorded: false,
                      ),
                    ],

                    // Control time
                    GestureDetector(
                      onTap: _selectTime,
                      child: AbsorbPointer(
                        child: AppTextField(
                          label: 'Hora del control',
                          controller: TextEditingController(
                            text:
                                '${_controlTime.hour.toString().padLeft(2, '0')}:${_controlTime.minute.toString().padLeft(2, '0')}',
                          ),
                          readOnly: true,
                          suffixIcon: const Icon(Icons.access_time),
                          hintText: '06:00',
                        ),
                      ),
                    ),

                    const Divider(height: 32),

                    // Measurements section
                    const AppTitle(title: 'Mediciones (ppm)'),

                    // M1 - Sanitization
                    AppTextField(
                      label: 'M1 - Llave de agua zona de sanitización',
                      controller: _m1Controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => _validateMeasurement(value, 'M1'),
                      hintText: 'Ej: 0.5',
                      onChanged: (_) => setState(() {}), // Trigger rebuild for warning
                    ),

                    // M2 - Process/Sieving
                    AppTextField(
                      label: 'M2 - Llave de agua zona de proceso/tamizado',
                      controller: _m2Controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => _validateMeasurement(value, 'M2'),
                      hintText: 'Ej: 0.5',
                      onChanged: (_) => setState(() {}), // Trigger rebuild for warning
                    ),

                    // Safety warning (if measurements are outside safe range)
                    if (_buildSafetyWarning() != null) ...[
                      _buildSafetyWarning()!,
                      SizedBox(height: context.responsiveSpacing / 2),
                    ],

                    const Divider(height: 32),

                    // Additional information
                    const AppTitle(title: 'Información adicional'),

                    // Corrective actions
                    AppTextField(
                      label: 'Acciones correctivas (opcional)',
                      controller: _correctiveActionsController,
                      maxLines: 2,
                      hintText: 'Ej: Se certifica a 3 ppm',
                    ),

                    // Observations
                    AppTextField(
                      label: 'Observaciones (opcional)',
                      controller: _observationsController,
                      maxLines: 3,
                      hintText: 'Notas adicionales...',
                    ),

                    // Responsible person — autocomplete
                    if (_isLoadingProducers)
                      const Center(child: CircularProgressIndicator())
                    else
                      RawAutocomplete<String>(
                        textEditingController: _responsiblePersonController,
                        focusNode: _responsibleFocusNode,
                        optionsBuilder: (TextEditingValue value) {
                          if (value.text.isEmpty) return _producerNames;
                          final query = value.text.toLowerCase();
                          return _producerNames.where(
                            (name) => name.toLowerCase().contains(query),
                          );
                        },
                        displayStringForOption: (option) => option,
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmitted) {
                          return AppTextField(
                            label: 'Productor que realizó la medida',
                            controller: controller,
                            focusNode: focusNode,
                            validator: (value) =>
                                _validateRequired(value, 'Productor'),
                            hintText: 'Buscar o escribir nombre...',
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 220),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final name = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      title: Text(name),
                                      onTap: () => onSelected(name),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    SizedBox(height: context.responsiveSpacing),

                    // Buttons
                    if (context.shouldStackButtons)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppButton(
                            text: 'Registrar control',
                            type: AppButtonType.primary,
                            onPressed: _isSaving ? null : _submitControl,
                            isExpanded: true,
                          ),
                          SizedBox(height: context.responsiveSpacing / 2),
                          AppBackButton(
                            label: 'Cancelar',
                            onPressed: () =>
                                context.go(AppRoutes.controlFormsModulo.path),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: AppBackButton(
                              label: 'Cancelar',
                              onPressed: () =>
                                  context.go(AppRoutes.controlFormsModulo.path),
                            ),
                          ),
                          SizedBox(width: context.responsiveSpacing / 2),
                          Expanded(
                            child: AppButton(
                              text: 'Registrar',
                              type: AppButtonType.primary,
                              onPressed: _isSaving ? null : _submitControl,
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
