import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/common/app_confirm_dialog.dart';
import 'package:panela_sys/widgets/common/app_snackbar.dart';
import 'package:panela_sys/widgets/stowage/exit_and_date_step.dart';
import 'package:panela_sys/widgets/stowage/carrier_step.dart';
import 'package:panela_sys/widgets/stowage/vehicle_and_condition_step.dart';
import 'package:panela_sys/widgets/stowage/vehicle_checklist_step.dart';
import 'package:panela_sys/widgets/stowage/bag_conditions_step.dart';
import 'package:panela_sys/widgets/stowage/observations_step.dart';
import 'package:panela_sys/models/stowage_transport_inspection.dart';
import 'package:panela_sys/services/exit_registration_service.dart';
import 'package:panela_sys/services/stowage_transport_inspection_service.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:go_router/go_router.dart';

class StowageTransportInspectionRegistrationScreen extends StatefulWidget {
  const StowageTransportInspectionRegistrationScreen({super.key});

  @override
  State<StowageTransportInspectionRegistrationScreen> createState() =>
      _StowageTransportInspectionRegistrationScreenState();
}

class _StowageTransportInspectionRegistrationScreenState
    extends State<StowageTransportInspectionRegistrationScreen> {
  final ExitRegistrationService _exitService = ExitRegistrationService();
  final StowageTransportInspectionService _inspectionService =
      StowageTransportInspectionService();
  final AuthService _authService = AuthService();

  int _currentStep = 0;

  // Loading states
  bool _isLoadingExits = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _availableExits = [];

  // Form controllers - Page 1: General data
  String? _selectedExitId;
  final TextEditingController _inspectionDateController = TextEditingController();
  final TextEditingController _carrierNameController = TextEditingController();
  final TextEditingController _carrierRucController = TextEditingController();
  final TextEditingController _carrierLicenseController = TextEditingController();
  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();

  // Form data - Page 2: Vehicle condition
  VehicleCondition _vehicleCondition = VehicleCondition.adequate;
  bool _hasSpareTire = true;
  bool _hasValidSoat = true;
  bool _hasTechnicalReview = true;
  bool _hasFirstAidKit = true;
  bool _hasFireExtinguisher = true;
  bool _hasGps = true;
  bool _hasCleaningSupplies = true;

  // Form data - Page 3: Cleaning and sack conditions
  bool _floorsClean = true;
  bool _wallsClean = true;
  bool _ceilingsClean = true;
  bool _noStrangeOdors = true;
  bool _tarpClean = true;
  bool _palletsClean = true;
  SackCondition _sackCleanCondition = SackCondition.good;
  SackCondition _sackTiedCondition = SackCondition.good;

  // Form data - Page 4: Observations
  final TextEditingController _observationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inspectionDateController.text = AppDateUtils.getCurrentDDMMYYYY();
    _inspectionDateController.addListener(_onDateChanged);
    _loadExitsForDate(DateTime.now());
  }

  void _onDateChanged() {
    final dateText = _inspectionDateController.text.trim();
    if (dateText.isNotEmpty && AppDateUtils.isValidDDMMYYYY(dateText)) {
      final date = AppDateUtils.parseDDMMYYYY(dateText);
      if (date != null) {
        _loadExitsForDate(date);
        // Clear selection when date changes
        setState(() => _selectedExitId = null);
      }
    }
  }

  @override
  void dispose() {
    _inspectionDateController.removeListener(_onDateChanged);
    _inspectionDateController.dispose();
    _carrierNameController.dispose();
    _carrierRucController.dispose();
    _carrierLicenseController.dispose();
    _vehicleBrandController.dispose();
    _vehiclePlateController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<void> _loadExitsForDate(DateTime date) async {
    setState(() => _isLoadingExits = true);
    try {
      final exits = await _exitService.getExitRegistrationsWithItemsByDate(date);
      setState(() {
        _availableExits = exits;
        _isLoadingExits = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableExits = [];
          _isLoadingExits = false;
        });
        AppSnackBar.show(
          context,
          message: 'Error al cargar salidas: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _nextStep() {
    // Paso 0: Validar salida y fecha
    if (_currentStep == 0) {
      if (_selectedExitId == null) {
        AppSnackBar.show(
          context,
          message: 'Selecciona una salida de referencia',
          type: SnackBarType.error,
        );
        return;
      }
      if (_inspectionDateController.text.trim().isEmpty) {
        AppSnackBar.show(
          context,
          message: 'Selecciona la fecha de inspección',
          type: SnackBarType.error,
        );
        return;
      }
    }

    // Paso 1: Validar nombre del transportista (único campo requerido)
    if (_currentStep == 1) {
      if (_carrierNameController.text.trim().isEmpty) {
        AppSnackBar.show(
          context,
          message: 'Ingresa el nombre del transportista',
          type: SnackBarType.error,
        );
        return;
      }
    }

    // Paso 2: No requiere validación adicional (vehículo y condición ya están presentes)

    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        context.go(AppRoutes.controlFormsProduccion.path);
      }
    });
  }

  Future<void> _submitForm() async {
    if (!await AppConfirmDialog.show(context)) return;
    setState(() => _isSaving = true);

    try {
      final userDNI = await _authService.getCurrentUserDNI();
      if (userDNI == null) {
        throw Exception('No user logged in');
      }

      // Parse inspection date from controller
      final inspectionDate = AppDateUtils.parseDDMMYYYY(_inspectionDateController.text);

      final request = CreateStowageTransportInspectionRequest(
        exitRegistrationId: _selectedExitId!,
        inspectionDate: inspectionDate,
        cooperativeId: AppConfig.current.id,
        carrierName: _carrierNameController.text.trim(),
        carrierRuc: _carrierRucController.text.trim().isEmpty
            ? null
            : _carrierRucController.text.trim(),
        carrierLicense: _carrierLicenseController.text.trim().isEmpty
            ? null
            : _carrierLicenseController.text.trim(),
        vehicleBrand: _vehicleBrandController.text.trim(),
        vehiclePlate: _vehiclePlateController.text.trim(),
        vehicleCondition: _vehicleCondition,
        hasSpareTire: _hasSpareTire,
        hasValidSoat: _hasValidSoat,
        hasTechnicalReview: _hasTechnicalReview,
        hasFirstAidKit: _hasFirstAidKit,
        hasFireExtinguisher: _hasFireExtinguisher,
        hasGps: _hasGps,
        hasCleaningSupplies: _hasCleaningSupplies,
        floorsClean: _floorsClean,
        wallsClean: _wallsClean,
        ceilingsClean: _ceilingsClean,
        noStrangeOdors: _noStrangeOdors,
        tarpClean: _tarpClean,
        palletsClean: _palletsClean,
        sackCleanCondition: _sackCleanCondition,
        sackTiedCondition: _sackTiedCondition,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        createdBy: userDNI,
      );

      await _inspectionService.createInspection(request);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Inspección guardada correctamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlFormsProduccion.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.show(
          context,
          message: 'Error al guardar inspección: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'PE'),
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _inspectionDateController.text = AppDateUtils.formatDDMMYYYY(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    title: 'Inspección de estiba y transporte',
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

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return ExitAndDateStep(
          selectedExitId: _selectedExitId,
          availableExits: _availableExits,
          isLoadingExits: _isLoadingExits,
          inspectionDateController: _inspectionDateController,
          onExitChanged: (value) {
            setState(() => _selectedExitId = value);
          },
          onDateTap: () => _selectDate(context),
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 1:
        return CarrierStep(
          carrierNameController: _carrierNameController,
          carrierRucController: _carrierRucController,
          carrierLicenseController: _carrierLicenseController,
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 2:
        return VehicleAndConditionStep(
          vehicleBrandController: _vehicleBrandController,
          vehiclePlateController: _vehiclePlateController,
          vehicleCondition: _vehicleCondition,
          onConditionChanged: (value) {
            setState(() => _vehicleCondition = value);
          },
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 3:
        return VehicleChecklistStep(
          hasSpareTire: _hasSpareTire,
          hasValidSoat: _hasValidSoat,
          hasTechnicalReview: _hasTechnicalReview,
          hasFirstAidKit: _hasFirstAidKit,
          hasFireExtinguisher: _hasFireExtinguisher,
          hasGps: _hasGps,
          hasCleaningSupplies: _hasCleaningSupplies,
          floorsClean: _floorsClean,
          wallsClean: _wallsClean,
          ceilingsClean: _ceilingsClean,
          noStrangeOdors: _noStrangeOdors,
          tarpClean: _tarpClean,
          palletsClean: _palletsClean,
          onSpareTireChanged: (value) {
            setState(() => _hasSpareTire = value);
          },
          onValidSoatChanged: (value) {
            setState(() => _hasValidSoat = value);
          },
          onTechnicalReviewChanged: (value) {
            setState(() => _hasTechnicalReview = value);
          },
          onFirstAidKitChanged: (value) {
            setState(() => _hasFirstAidKit = value);
          },
          onFireExtinguisherChanged: (value) {
            setState(() => _hasFireExtinguisher = value);
          },
          onGpsChanged: (value) {
            setState(() => _hasGps = value);
          },
          onCleaningSuppliesChanged: (value) {
            setState(() => _hasCleaningSupplies = value);
          },
          onFloorsCleanChanged: (value) {
            setState(() => _floorsClean = value);
          },
          onWallsCleanChanged: (value) {
            setState(() => _wallsClean = value);
          },
          onCeilingsCleanChanged: (value) {
            setState(() => _ceilingsClean = value);
          },
          onNoStrangeOdorsChanged: (value) {
            setState(() => _noStrangeOdors = value);
          },
          onTarpCleanChanged: (value) {
            setState(() => _tarpClean = value);
          },
          onPalletsCleanChanged: (value) {
            setState(() => _palletsClean = value);
          },
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 4:
        return BagConditionsStep(
          sackCleanCondition: _sackCleanCondition,
          sackTiedCondition: _sackTiedCondition,
          onSackCleanConditionChanged: (value) {
            setState(() => _sackCleanCondition = value);
          },
          onSackTiedConditionChanged: (value) {
            setState(() => _sackTiedCondition = value);
          },
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 5:
        return ObservationsStep(
          observationsController: _observationsController,
          isSaving: _isSaving,
          onSubmit: () => _submitForm(),
          onBack: () => _previousStep(),
        );
      default:
        return ExitAndDateStep(
          selectedExitId: _selectedExitId,
          availableExits: _availableExits,
          isLoadingExits: _isLoadingExits,
          inspectionDateController: _inspectionDateController,
          onExitChanged: (value) {
            setState(() => _selectedExitId = value);
          },
          onDateTap: () => _selectDate(context),
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
    }
  }
}
