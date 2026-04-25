import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/models/health_incident.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/health_incident_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/widgets/health_incident/identification_data_step.dart';
import 'package:panela_sys/widgets/health_incident/incident_description_step.dart';
import 'package:panela_sys/widgets/health_incident/actions_taken_step.dart';
import 'package:panela_sys/widgets/health_incident/followup_step.dart';
import 'package:panela_sys/widgets/health_incident/review_summary_step.dart';

class HealthAccidentTrackingRegistrationScreen extends ConsumerStatefulWidget {
  const HealthAccidentTrackingRegistrationScreen({super.key});

  @override
  ConsumerState<HealthAccidentTrackingRegistrationScreen> createState() =>
      _HealthAccidentTrackingRegistrationScreenState();
}

class _HealthAccidentTrackingRegistrationScreenState
    extends ConsumerState<HealthAccidentTrackingRegistrationScreen> {
  final CoopModulesService _moduleService = CoopModulesService();
  final HealthIncidentService _incidentService = HealthIncidentService();

  int _currentStep = 0;

  // Step 0: Identification data
  String? _selectedModuleId;
  List<CoopModule> _availableModules = [];
  final TextEditingController _employeeNameController =
      TextEditingController();
  final TextEditingController _workAreaController = TextEditingController();
  DateTime? _registrationDate;

  // Step 1: Incident description
  final TextEditingController _symptomsController = TextEditingController();

  // Step 2: Actions taken
  bool _actionRest = false;
  bool _actionMedicalAttention = false;
  bool _actionRelocation = false;
  bool _actionMedication = false;
  bool _actionOther = false;
  final TextEditingController _otherActionController = TextEditingController();

  // Step 3: Follow-up
  final TextEditingController _returnDateController = TextEditingController();
  bool _certificatePresented = false;

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
    _registrationDate = DateTime.now();
    // Show confirmation dialog immediately after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showConfirmationDialog();
    });
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        ),
        backgroundColor: AppColors.surface,
        contentPadding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLarge,
          AppDimensions.paddingLarge,
          AppDimensions.paddingLarge,
          AppDimensions.paddingMedium,
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.primary,
                size: AppDimensions.iconXLarge,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            Text(
              '¿Registrar nuevo caso?',
              style: AppTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Este formulario solo debe llenarse si algún trabajador se ha reportado enfermo o accidentado. ¿Deseas registrar un caso ahora?',
          style: AppTextStyles.bodyTextSecondary,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingLarge,
          AppDimensions.paddingSmall,
          AppDimensions.paddingLarge,
          AppDimensions.paddingLarge,
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                text: 'Sí, registrar caso',
                type: AppButtonType.primary,
                icon: Icons.check_circle_outline,
                isExpanded: true,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              AppButton(
                text: 'No, todos están bien',
                type: AppButtonType.secondary,
                isExpanded: true,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go(AppRoutes.controlFormsModulo.path);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      locale: const Locale('es'),
    );
    if (picked == null || !mounted) return;
    setState(() => _registrationDate = picked);
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _workAreaController.dispose();
    _symptomsController.dispose();
    _otherActionController.dispose();
    _returnDateController.dispose();
    super.dispose();
  }

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
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al cargar los módulos: $e',
          type: SnackBarType.error,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goToNextStep() async {
    if (_currentStep == 0 && _selectedModuleId != null && _registrationDate != null &&
        _employeeNameController.text.trim().isNotEmpty) {
      final date = _registrationDate!;
      final hasExisting = await _incidentService.hasIncidentForEmployeeOnDate(
          _selectedModuleId!, _employeeNameController.text.trim(), date);
      if (!mounted) return;
      if (hasExisting) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ya hay un registro este día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Text(
              'Ya existe un incidente registrado para este módulo el ${AppDateUtils.formatDDMMYYYY(date)}.\n\n¿Deseas registrar otro igualmente?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCELAR', style: TextStyle(fontSize: 15))),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('CONTINUAR', style: TextStyle(fontSize: 15))),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }
    }
    if (_currentStep < 4) setState(() => _currentStep++);
  }

  void _goToPreviousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        context.go(AppRoutes.controlFormsModulo.path);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!await AppConfirmDialog.show(context)) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final registrationDate = _registrationDate!;

      // Parse return date if provided
      DateTime? returnDate;
      if (_returnDateController.text.isNotEmpty) {
        returnDate = DateFormat('dd/MM/yyyy').parse(_returnDateController.text);
      }

      final request = CreateHealthIncidentRequest(
        coopModuleId: _selectedModuleId!,
        employeeName: _employeeNameController.text.trim(),
        workArea: _workAreaController.text.trim(),
        registrationDate: registrationDate,
        symptomsDescription: _symptomsController.text.trim(),
        actionRest: _actionRest,
        actionMedicalAttention: _actionMedicalAttention,
        actionRelocation: _actionRelocation,
        actionMedication: _actionMedication,
        actionOther: _actionOther,
        otherActionDetail:
            _actionOther ? _otherActionController.text.trim() : null,
        returnDate: returnDate,
        certificatePresented: _certificatePresented,
        cooperativeId: AppConfig.current.id,
      );

      await _incidentService.createIncident(request);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Incidente de salud registrado exitosamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlFormsModulo.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al guardar el incidente: $e',
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
        return IdentificationDataStep(
          availableModules: _availableModules,
          selectedModuleId: _selectedModuleId,
          employeeNameController: _employeeNameController,
          workAreaController: _workAreaController,
          registrationDate: _registrationDate,
          onDateTap: _pickDate,
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onModuleChanged: (value) {
            setState(() {
              _selectedModuleId = value;
            });
          },
        );
      case 1:
        return IncidentDescriptionStep(
          symptomsController: _symptomsController,
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
        );
      case 2:
        return ActionsTakenStep(
          actionRest: _actionRest,
          actionMedicalAttention: _actionMedicalAttention,
          actionRelocation: _actionRelocation,
          actionMedication: _actionMedication,
          actionOther: _actionOther,
          otherActionController: _otherActionController,
          onActionRestChanged: (value) {
            setState(() {
              _actionRest = value ?? false;
            });
          },
          onActionMedicalAttentionChanged: (value) {
            setState(() {
              _actionMedicalAttention = value ?? false;
            });
          },
          onActionRelocationChanged: (value) {
            setState(() {
              _actionRelocation = value ?? false;
            });
          },
          onActionMedicationChanged: (value) {
            setState(() {
              _actionMedication = value ?? false;
            });
          },
          onActionOtherChanged: (value) {
            setState(() {
              _actionOther = value ?? false;
              if (!_actionOther) {
                _otherActionController.clear();
              }
            });
          },
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
        );
      case 3:
        return FollowupStep(
          returnDateController: _returnDateController,
          certificatePresented: _certificatePresented,
          onCertificatePresentedChanged: (value) {
            setState(() {
              _certificatePresented = value;
            });
          },
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
        );
      case 4:
        return ReviewSummaryStep(
          moduleName: _availableModules
                  .firstWhere((m) => m.id == _selectedModuleId,
                      orElse: () => CoopModule(id: '', name: ''))
                  .name,
          employeeName: _employeeNameController.text,
          workArea: _workAreaController.text,
          registrationDate: _registrationDate != null ? AppDateUtils.formatDDMMYYYY(_registrationDate!) : '',
          symptomsDescription: _symptomsController.text,
          actionRest: _actionRest,
          actionMedicalAttention: _actionMedicalAttention,
          actionRelocation: _actionRelocation,
          actionMedication: _actionMedication,
          actionOther: _actionOther,
          otherActionDetail:
              _actionOther ? _otherActionController.text : null,
          returnDate: _returnDateController.text.isEmpty
              ? null
              : _returnDateController.text,
          certificatePresented: _certificatePresented,
          isSaving: _isSaving,
          onSubmit: _submitForm,
          onBack: _goToPreviousStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AppScaffold(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppTitle(
                    title: 'Seguimiento de enfermedades y accidentes',
                  ),
                  const SizedBox(height: 16),
                  _buildCurrentStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
