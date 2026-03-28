import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/equipment_maintenance_record.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/equipment_maintenance_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/widgets/widgets.dart';

class MaintenanceControlRegistrationScreen extends ConsumerStatefulWidget {
  const MaintenanceControlRegistrationScreen({super.key});

  @override
  ConsumerState<MaintenanceControlRegistrationScreen> createState() =>
      _MaintenanceControlRegistrationScreenState();
}

class _MaintenanceControlRegistrationScreenState
    extends ConsumerState<MaintenanceControlRegistrationScreen> {
  // ============================================================================
  // EQUIPMENT SUGGESTIONS — add more options here as needed
  // ============================================================================
  static const List<String> _kEquipmentSuggestions = [
    'Trapiche',
    'Motor',
    'Hornilla',
  ];

  // ============================================================================
  // SERVICES
  // ============================================================================
  final _maintenanceService = EquipmentMaintenanceService();
  final _moduleService = CoopModulesService();

  // ============================================================================
  // FORM & STATE
  // ============================================================================
  final _formKey = GlobalKey<FormState>();

  final _equipmentNameController = TextEditingController();
  final _equipmentNameFocusNode = FocusNode();
  final _maintenanceCauseController = TextEditingController();
  final _materialsUsedController = TextEditingController();
  final _durationController = TextEditingController();
  final _responsiblePersonController = TextEditingController();

  String? _selectedModuleId;
  DateTime _maintenanceDate = DateTime.now();
  MaintenanceType? _maintenanceType;
  bool _isSubmitting = false;
  List<CoopModule> _availableModules = [];
  bool _isLoadingModules = false;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _equipmentNameFocusNode.dispose();
    _maintenanceCauseController.dispose();
    _materialsUsedController.dispose();
    _durationController.dispose();
    _responsiblePersonController.dispose();
    super.dispose();
  }

  // ============================================================================
  // LOADING
  // ============================================================================

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
      if (mounted) {
        setState(() {
          _availableModules = modules;
          if (modules.length == 1) _selectedModuleId = modules.first.id;
          _isLoadingModules = false;
        });
      }
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

  // ============================================================================
  // VALIDATION
  // ============================================================================

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La duración es obligatoria';
    }

    final duration = double.tryParse(value);
    if (duration == null) {
      return 'Ingresa un número válido';
    }

    if (duration <= 0) {
      return 'La duración debe ser mayor a 0';
    }

    return null;
  }

  // ============================================================================
  // DATE PICKER
  // ============================================================================

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _maintenanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Selecciona la fecha de mantenimiento',
    );

    if (picked != null && picked != _maintenanceDate) {
      setState(() {
        _maintenanceDate = picked;
      });
    }
  }

  // ============================================================================
  // SUBMIT
  // ============================================================================

  Future<void> _submitRecord() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate module selection
    if (_selectedModuleId == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona un módulo',
        type: SnackBarType.error,
      );
      return;
    }

    // Validate maintenance type selection
    if (_maintenanceType == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona el tipo de mantenimiento',
        type: SnackBarType.error,
      );
      return;
    }

    if (!await AppConfirmDialog.show(context)) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create request
      final request = CreateEquipmentMaintenanceRequest(
        coopModuleId: _selectedModuleId!,
        maintenanceDate: _maintenanceDate,
        equipmentName: _equipmentNameController.text.trim(),
        maintenanceType: _maintenanceType!,
        maintenanceCause: _maintenanceCauseController.text.trim(),
        materialsUsed: _materialsUsedController.text.trim().isEmpty
            ? null
            : _materialsUsedController.text.trim(),
        durationHours: double.parse(_durationController.text),
        responsiblePerson: _responsiblePersonController.text.trim(),
      );

      // Submit to service
      await _maintenanceService.createRecord(request);

      // Show success message and navigate
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Registro de mantenimiento guardado exitosamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlFormsModulo.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al registrar mantenimiento: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingModules) {
      return const AppScaffold(
        hasTopLabel: true,
        topLabelText: 'Mantenimiento de Equipos',
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Mantenimiento de Equipos',
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
                    const AppTitle(
                      title: 'Mantenimiento hornilla/maquinaria/equipos',
                    ),

                    // ============================================================
                    // Module Dropdown
                    // ============================================================
                    AppDropdown<String>(
                      label: 'Módulo',
                      value: _selectedModuleId,
                      options: _availableModules
                          .map((m) => DropdownOption(
                                value: m.id,
                                label: m.name,
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedModuleId = value;
                        });
                      },
                    ),

                    // ============================================================
                    // Date Picker
                    // ============================================================
                    AppTextField(
                      label: 'Fecha de mantenimiento',
                      controller: TextEditingController(
                        text: DateFormat('dd/MM/yyyy').format(_maintenanceDate),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),

                    // ============================================================
                    // Equipment Name — autocomplete with free text fallback
                    // ============================================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nombre del equipo',
                          style: AppTextStyles.fieldLabel,
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        RawAutocomplete<String>(
                          textEditingController: _equipmentNameController,
                          focusNode: _equipmentNameFocusNode,
                          optionsBuilder: (TextEditingValue textValue) {
                            if (textValue.text.isEmpty) {
                              return _kEquipmentSuggestions;
                            }
                            return _kEquipmentSuggestions.where(
                              (option) => option.toLowerCase().contains(
                                    textValue.text.toLowerCase(),
                                  ),
                            );
                          },
                          displayStringForOption: (option) => option,
                          fieldViewBuilder: (
                            context,
                            fieldController,
                            fieldFocusNode,
                            onFieldSubmitted,
                          ) {
                            return TextFormField(
                              controller: fieldController,
                              focusNode: fieldFocusNode,
                              onFieldSubmitted: (_) => onFieldSubmitted(),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  _validateRequired(value, 'Nombre del equipo'),
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: 'Ej: Trapiche, Motor, Hornilla',
                                hintStyle: AppTextStyles.hintText.copyWith(
                                  color: AppColors.placeholder,
                                ),
                                suffixIcon: Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.inputFill,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingMedium,
                                  vertical: AppDimensions.paddingMedium,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMedium),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorder,
                                    width: AppDimensions.inputBorderWidth,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMedium),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorder,
                                    width: AppDimensions.inputBorderWidth,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMedium),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorderFocused,
                                    width: AppDimensions.inputFocusedBorderWidth,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMedium),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorderError,
                                    width: AppDimensions.inputBorderWidth,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMedium),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorderError,
                                    width: AppDimensions.inputFocusedBorderWidth,
                                  ),
                                ),
                                errorStyle:
                                    AppTextStyles.bodyTextSecondary.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            );
                          },
                          optionsViewBuilder: (
                            context,
                            onSelected,
                            options,
                          ) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMedium),
                                color: AppColors.surface,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                    itemBuilder: (context, index) {
                                      final option =
                                          options.elementAt(index);
                                      return ListTile(
                                        leading: Icon(
                                          Icons.build_outlined,
                                          color: AppColors.primary,
                                          size: AppDimensions.iconSmall,
                                        ),
                                        title: Text(
                                          option,
                                          style: AppTextStyles.bodyText,
                                        ),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // ============================================================
                    // Maintenance Type (Radio Buttons)
                    // ============================================================
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo de mantenimiento',
                          style: AppTextStyles.fieldLabel,
                        ),
                        SizedBox(height: context.responsiveSpacing / 2),
                        RadioListTile<MaintenanceType>(
                          title: const Text('Preventivo (P)'),
                          value: MaintenanceType.preventive,
                          groupValue: _maintenanceType,
                          onChanged: (value) {
                            setState(() {
                              _maintenanceType = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<MaintenanceType>(
                          title: const Text('Correctivo (C)'),
                          value: MaintenanceType.corrective,
                          groupValue: _maintenanceType,
                          onChanged: (value) {
                            setState(() {
                              _maintenanceType = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SizedBox(height: context.responsiveSpacing / 2),
                      ],
                    ),

                    // Maintenance Cause

                    AppTextField(
                      label: 'Causa del mantenimiento',
                      controller: _maintenanceCauseController,
                      validator: (value) =>
                          _validateRequired(value, 'Causa del mantenimiento'),
                      hintText: 'Ej: Mantenimiento preventivo mensual',
                      maxLines: 2,
                    ),

                    // Materials Used (Optional)
                    AppTextField(
                      label: 'Materiales / Repuestos usados (opcional)',
                      controller: _materialsUsedController,
                      maxLines: 3,
                      hintText: 'Ej: Grasa, Filtros, Aceite',
                    ),

                    // ============================================================
                    // Duration in Hours
                    // ============================================================
                    AppTextField(
                      label: 'Duración del mantenimiento',
                      controller: _durationController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _validateDuration,
                      suffixText: 'horas',
                      hintText: 'Ej: 4.5',
                    ),

                    // ============================================================
                    // Responsible Person
                    // ============================================================
                    AppTextField(
                      label: 'Responsable del mantenimiento',
                      controller: _responsiblePersonController,
                      validator: (value) =>
                          _validateRequired(value, 'Responsable'),
                      hintText: 'Nombre completo',
                    ),

                    SizedBox(height: context.responsiveSpacing),

                    // ============================================================
                    // Action Buttons
                    // ============================================================
                    if (context.shouldStackButtons)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppButton(
                            text: 'Registrar mantenimiento',
                            type: AppButtonType.primary,
                            onPressed: _isSubmitting ? null : _submitRecord,
                            isExpanded: true,
                          ),
                          SizedBox(height: context.responsiveSpacing / 2),
                          AppBackButton(
                            label: 'Cancelar',
                            onPressed: () =>
                                context.go(AppRoutes.controlFormsModulo.path),
                            isExpanded: true,
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
                              onPressed: _isSubmitting ? null : _submitRecord,
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
