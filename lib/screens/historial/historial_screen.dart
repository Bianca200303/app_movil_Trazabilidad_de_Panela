import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/models/cleaning_disinfection.dart';
import 'package:panela_sys/models/stowage_transport_inspection.dart';
import 'package:panela_sys/models/health_incident.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/chlorine_residual_control_service.dart';
import 'package:panela_sys/services/cleaning_disinfection_service.dart';
import 'package:panela_sys/services/environment_inspection_service.dart';
import 'package:panela_sys/services/equipment_maintenance_service.dart';
import 'package:panela_sys/services/exit_registration_service.dart';
import 'package:panela_sys/services/health_incident_service.dart';
import 'package:panela_sys/services/pest_control_service.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/product_return_service.dart';
import 'package:panela_sys/services/production_batch_service.dart';
import 'package:panela_sys/services/stowage_transport_inspection_service.dart';
import 'package:panela_sys/services/worker_control_service.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/sync_progress_dialog.dart';

// Widgets locales del historial
import 'widgets/producer_edit_dialog.dart';
import 'widgets/historial_main_menu.dart';
import 'widgets/historial_control_submenu.dart';
import 'widgets/historial_exits_section.dart';
import 'widgets/shared/historial_date_range.dart';
import 'widgets/shared/historial_error.dart';
import 'widgets/shared/historial_loading.dart';
import 'widgets/control_forms/environment_inspection_list.dart';
import 'widgets/control_forms/cleaning_disinfection_list.dart';
import 'widgets/control_forms/chlorine_control_list.dart';
import 'widgets/control_forms/pest_control_list.dart';
import 'widgets/control_forms/health_incidents_list.dart';
import 'widgets/control_forms/stowage_inspection_list.dart';
import 'widgets/control_forms/product_returns_list.dart';
import 'widgets/control_forms/worker_control_list.dart';
import 'widgets/control_forms/maintenance_control_list.dart';

/// Pantalla de historial.
///
/// Navegación de 3 niveles:
///   Nivel 1 → Menú principal (Productores / Producción / Salidas / Inspecciones)
///   Nivel 2 → Submenu de formularios de control (solo opción 3)
///   Nivel 3 → Contenido del formulario seleccionado
///
/// Todo el estado de datos y carga vive aquí; los widgets hijos son puramente presentacionales.
class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  // ── Servicios ───────────────────────────────────────────────────────────────
  late final ProducerService _producerService;
  late final ProductionBatchService _productionBatchService;
  final ExitRegistrationService _exitRegistrationService =
      ExitRegistrationService();
  final StowageTransportInspectionService _inspectionService =
      StowageTransportInspectionService();
  final EnvironmentInspectionService _environmentInspectionService =
      EnvironmentInspectionService();
  final CleaningDisinfectionService _cleaningDisinfectionService =
      CleaningDisinfectionService();
  final ChlorineResidualControlService _chlorineControlService =
      ChlorineResidualControlService();

  // ── Estado de productores ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _producersData = [];
  bool _isLoadingProducers = false;
  String? _producersError;

  // ── Estado de producción ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _productionData = [];
  bool _isLoadingProduction = false;
  String? _productionError;

  // ── Estado de salidas ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _exitsData = [];
  bool _isLoadingExits = false;
  String? _exitsError;

  // ── Estado de inspecciones de estiba ─────────────────────────────────────────
  List<Map<String, dynamic>> _controlData = [];
  bool _isLoadingControl = false;
  String? _controlError;

  // ── Estado de inspecciones de ambiente ───────────────────────────────────────
  List<Map<String, dynamic>> _environmentInspectionsData = [];
  bool _isLoadingEnvironmentInspections = false;
  String? _environmentInspectionsError;

  // ── Estado de limpieza y desinfección ────────────────────────────────────────
  List<Map<String, dynamic>> _cleaningDisinfectionData = [];
  bool _isLoadingCleaningDisinfection = false;
  String? _cleaningDisinfectionError;

  // ── Estado de control de cloro ───────────────────────────────────────────────
  List<Map<String, dynamic>> _chlorineControlData = [];
  bool _isLoadingChlorineControl = false;
  String? _chlorineControlError;

  // ── Estado de control de plagas ──────────────────────────────────────────────
  List<Map<String, dynamic>> _pestControlData = [];
  bool _isLoadingPestControl = false;
  String? _pestControlError;

  // ── Estado de incidentes de salud ────────────────────────────────────────────
  List<Map<String, dynamic>> _healthIncidentsData = [];
  bool _isLoadingHealthIncidents = false;
  String? _healthIncidentsError;

  // ── Estado de mantenimiento ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _maintenanceControlData = [];
  bool _isLoadingMaintenanceControl = false;
  String? _maintenanceControlError;

  // ── Estado de control de personal ────────────────────────────────────────────
  List<Map<String, dynamic>> _workerControlsData = [];
  bool _isLoadingWorkerControls = false;
  String? _workerControlsError;

  // ── Estado de devoluciones ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _productReturnsData = [];
  bool _isLoadingProductReturns = false;
  String? _productReturnsError;

  // ── Navegación ───────────────────────────────────────────────────────────────
  /// Opción principal seleccionada (0-3). Null = menú principal.
  int? _selectedOption;

  /// Subtipo de formulario de control seleccionado (0-8). Null = submenú.
  int? _selectedControlFormType;

  // ── Filtro de fechas ─────────────────────────────────────────────────────────
  late DateTime _startDate;
  late DateTime _endDate;

  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _productionBatchService = ProductionBatchService(db: db);

    // Rango de fechas: último mes
    _endDate = DateTime.now();
    _startDate = DateTime(_endDate.year, _endDate.month - 1, _endDate.day);
  }

  // ── Sync ─────────────────────────────────────────────────────────────────────

  Future<void> _syncAll() async {
    final autoSyncNotifier = ref.read(autoSyncStateProvider.notifier);

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SyncProgressDialog(
          syncStream: autoSyncNotifier.startManualSync(),
        ),
      );

      // Recargar datos del tab activo tras sync exitoso
      if (_selectedOption == 0) {
        await _loadProducersData();
      } else if (_selectedOption == 1) {
        await _loadProductionData();
      } else if (_selectedOption == 2) {
        await _loadExitsData();
      } else if (_selectedOption == 3) {
        await _loadControlFormsData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos subidos correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Carga de datos ───────────────────────────────────────────────────────────

  Future<void> _loadProducersData() async {
    if (_isLoadingProducers) return;
    setState(() {
      _isLoadingProducers = true;
      _producersError = null;
    });
    try {
      final currentUser = ref.read(currentUserProvider);
      var data = await _producerService.getProducersForHistorial();
      // Filter by assigned module for adminModulo
      if (currentUser?.isAdminModulo == true && currentUser!.moduleIds.isNotEmpty) {
        data = data.where((item) => currentUser.moduleIds.contains(item['coopModuleId'])).toList();
      }
      setState(() {
        _producersData = data;
        _isLoadingProducers = false;
      });
    } catch (e) {
      setState(() {
        _producersError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingProducers = false;
      });
    }
  }

  /// Returns the set of producer DNIs that should be visible for the current user.
  /// - adminModulo: only DNIs from their assigned module.
  /// - productor: only their own DNI.
  /// - adminSistema: null (no restriction).
  Future<Set<String>?> _getAllowedProducerDnis() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return null;

    if (currentUser.isProductor) {
      return {currentUser.dni};
    }

    if (currentUser.isAdminModulo && currentUser.moduleIds.isNotEmpty) {
      // Get all producers from historial and filter by assigned modules
      try {
        final all = await _producerService.getProducersForHistorial();
        return all
            .where((p) => currentUser.moduleIds.contains(p['coopModuleId']))
            .map((p) => p['dni'] as String)
            .toSet();
      } catch (_) {
        return null;
      }
    }

    return null; // No restriction for adminSistema
  }

  Future<void> _loadProductionData() async {
    if (_isLoadingProduction) return;
    setState(() {
      _isLoadingProduction = true;
      _productionError = null;
    });
    try {
      final allowedDnis = await _getAllowedProducerDnis();
      var data =
          await _productionBatchService.getProductionBatchesForHistorial();
      if (allowedDnis != null) {
        data = data.where((item) => allowedDnis.contains(item['dni_productor'])).toList();
      }
      final formattedData = data.map((item) {
        final processDate = item['fecha_proceso'] as DateTime;
        return {
          ...item,
          'fecha_proceso': AppDateUtils.formatDDMMYYYY(processDate),
        };
      }).toList();
      setState(() {
        _productionData = formattedData;
        _isLoadingProduction = false;
      });
    } catch (e) {
      setState(() {
        _productionError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingProduction = false;
      });
    }
  }

  Future<void> _loadExitsData() async {
    if (_isLoadingExits) return;
    setState(() {
      _isLoadingExits = true;
      _exitsError = null;
    });
    try {
      final allowedDnis = await _getAllowedProducerDnis();
      var data =
          await _exitRegistrationService.getExitRegistrationsForHistorial();
      if (allowedDnis != null) {
        data = data.where((item) => allowedDnis.contains(item['dni_productor'])).toList();
      }
      final formattedData = data.map((item) {
        final exitDate = item['fecha_salida'] as DateTime;
        return {
          ...item,
          'fecha_salida': AppDateUtils.formatDDMMYYYY(exitDate),
        };
      }).toList();
      setState(() {
        _exitsData = formattedData;
        _isLoadingExits = false;
      });
    } catch (e) {
      setState(() {
        _exitsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingExits = false;
      });
    }
  }

  Future<void> _loadControlFormsData() async {
    if (_isLoadingControl) return;
    setState(() {
      _isLoadingControl = true;
      _controlError = null;
    });
    try {
      final data = await _inspectionService.getInspectionsWithExitDetails();
      final formattedData = data.map((item) {
        final inspection = StowageTransportInspection.fromJson(item);
        final exitData = item['exit_registration'] as Map<String, dynamic>?;
        return {
          'id': inspection.id,
          'document_number': exitData?['document_number'],
          'total_kg': exitData?['total_kg'],
          'exit_items': exitData?['exit_items'],
          'inspection_date': inspection.formattedDate,
          'carrier_name': inspection.carrierName,
          'vehicle_plate': inspection.vehiclePlate,
          'is_compliant': inspection.isFullyCompliant,
          'vehicle_condition': inspection.vehicleCondition.displayName,
          'sack_clean_condition': inspection.sackCleanCondition.displayName,
          'sack_tied_condition': inspection.sackTiedCondition.displayName,
          'observations': inspection.observations,
        };
      }).toList();
      setState(() {
        _controlData = formattedData;
        _isLoadingControl = false;
      });
    } catch (e) {
      setState(() {
        _controlError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingControl = false;
      });
    }
  }

  Future<void> _loadEnvironmentInspectionsData() async {
    if (_isLoadingEnvironmentInspections) return;
    setState(() {
      _isLoadingEnvironmentInspections = true;
      _environmentInspectionsError = null;
    });
    try {
      final data =
          await _environmentInspectionService.getInspectionsWithModuleDetails();
      final formattedData = data.map((item) {
        final inspection = EnvironmentInspection.fromJson(item);
        final moduleData = item['coop_module'] as Map<String, dynamic>?;
        return {
          'id': inspection.id,
          'module_name': moduleData?['name'] ?? 'Módulo desconocido',
          'inspection_date': inspection.formattedDate,
          'is_compliant': inspection.isFullyCompliant,
          'total_items': inspection.totalItems,
          'compliant_items': inspection.compliantItems,
          'non_compliant_items': inspection.nonCompliantItems,
          'compliance_percentage': inspection.compliancePercentage,
          'area_compliance': inspection.getAreaComplianceMap(),
          'non_compliant_by_area': inspection.getNonCompliantCountByArea(),
        };
      }).toList();
      setState(() {
        _environmentInspectionsData = formattedData;
        _isLoadingEnvironmentInspections = false;
      });
    } catch (e) {
      setState(() {
        _environmentInspectionsError =
            e.toString().replaceFirst('Exception: ', '');
        _isLoadingEnvironmentInspections = false;
      });
    }
  }

  Future<void> _loadCleaningDisinfectionData() async {
    if (_isLoadingCleaningDisinfection) return;
    setState(() {
      _isLoadingCleaningDisinfection = true;
      _cleaningDisinfectionError = null;
    });
    try {
      final data = await _cleaningDisinfectionService.getCleaningRecords();
      final formattedData = <Map<String, dynamic>>[];
      for (final record in data) {
        final items =
            await _cleaningDisinfectionService.getItemsByRecordId(record.id);
        final itemsByArea = <String, List<CleaningDisinfectionItem>>{};
        for (final item in items) {
          if (!itemsByArea.containsKey(item.areaCode)) {
            itemsByArea[item.areaCode] = [];
          }
          itemsByArea[item.areaCode]!.add(item);
        }
        formattedData.add({
          'id': record.id,
          'cleaning_date': record.cleaningDate,
          'formatted_date': AppDateUtils.formatDDMMYYYY(record.cleaningDate),
          'module_name': record.moduleName ?? 'Módulo desconocido',
          'has_observations': record.generalObservations != null &&
              record.generalObservations!.isNotEmpty,
          'general_observations': record.generalObservations,
          'items_by_area': itemsByArea,
          'total_items': items.length,
        });
      }
      setState(() {
        _cleaningDisinfectionData = formattedData;
        _isLoadingCleaningDisinfection = false;
      });
    } catch (e) {
      setState(() {
        _cleaningDisinfectionError =
            e.toString().replaceFirst('Exception: ', '');
        _isLoadingCleaningDisinfection = false;
      });
    }
  }

  Future<void> _loadChlorineControlData() async {
    if (_isLoadingChlorineControl) return;
    setState(() {
      _isLoadingChlorineControl = true;
      _chlorineControlError = null;
    });
    try {
      final controls = await _chlorineControlService.getControls();
      final formattedData = controls.map((control) {
        return {
          'id': control.id,
          'module_name': control.moduleName ?? 'Módulo desconocido',
          'control_date': control.formattedDate,
          'control_time': control.formattedTime,
          'control_datetime': control.formattedDateTime,
          'm1': control.measurementPoint1,
          'm2': control.measurementPoint2,
          'is_m1_safe': control.isM1InSafeRange,
          'is_m2_safe': control.isM2InSafeRange,
          'both_safe': control.areBothInSafeRange,
          'requires_action': control.requiresCorrectiveAction,
          'safety_warning': control.safetyWarningMessage,
          'corrective_actions': control.correctiveActions,
          'observations': control.observations,
          'responsible_person': control.responsiblePerson,
        };
      }).toList();
      setState(() {
        _chlorineControlData = formattedData;
        _isLoadingChlorineControl = false;
      });
    } catch (e) {
      setState(() {
        _chlorineControlError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingChlorineControl = false;
      });
    }
  }

  Future<void> _loadPestControlData() async {
    if (_isLoadingPestControl) return;
    setState(() {
      _isLoadingPestControl = true;
      _pestControlError = null;
    });
    try {
      final pestControlService = PestControlService();
      final controls = await pestControlService.getPestControls();
      final formattedDataFutures = controls.map((control) async {
        final baitRecords =
            await pestControlService.getBaitRecordsByControlId(control.id);
        final insectRecords =
            await pestControlService.getInsectRecordsByControlId(control.id);
        return {
          'id': control.id,
          'module_name': control.moduleName ?? 'Módulo desconocido',
          'control_date': control.formattedDate,
          'bait_records': baitRecords,
          'insect_records': insectRecords,
        };
      }).toList();
      final formattedData = await Future.wait(formattedDataFutures);
      setState(() {
        _pestControlData = formattedData;
        _isLoadingPestControl = false;
      });
    } catch (e) {
      setState(() {
        _pestControlError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingPestControl = false;
      });
    }
  }

  Future<void> _loadHealthIncidentsData() async {
    if (_isLoadingHealthIncidents) return;
    setState(() {
      _isLoadingHealthIncidents = true;
      _healthIncidentsError = null;
    });
    try {
      final healthIncidentService = HealthIncidentService();
      final data = await healthIncidentService.getIncidentsWithModuleDetails();
      final formattedData = data.map((item) {
        final incident = HealthIncident.fromJson(item);
        final moduleData = item['coop_module'] as Map<String, dynamic>?;
        return {
          'id': incident.id,
          'module_name': moduleData?['name'] ?? 'Módulo desconocido',
          'employee_name': incident.employeeName,
          'registration_date': incident.formattedRegistrationDate,
          'work_area': incident.workArea,
          'symptoms_description': incident.symptomsDescription,
          'actions_taken': incident.actionsDisplayText,
          'return_date': incident.formattedReturnDate,
          'certificate_presented': incident.certificatePresentedText,
          'has_return_date': incident.returnDate != null,
        };
      }).toList();
      setState(() {
        _healthIncidentsData = formattedData;
        _isLoadingHealthIncidents = false;
      });
    } catch (e) {
      setState(() {
        _healthIncidentsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingHealthIncidents = false;
      });
    }
  }

  Future<void> _loadMaintenanceControlData() async {
    if (_isLoadingMaintenanceControl) return;
    setState(() {
      _isLoadingMaintenanceControl = true;
      _maintenanceControlError = null;
    });
    try {
      final maintenanceService = EquipmentMaintenanceService();
      final records = await maintenanceService.getRecords(
        fromDate: _startDate,
        toDate: _endDate,
      );
      final formattedData = records.map((record) {
        return {
          'id': record.id,
          'maintenance_date': record.formattedDate,
          'equipment_name': record.equipmentName,
          'maintenance_type': record.maintenanceTypeDisplayName,
          'maintenance_type_code': record.maintenanceType.code,
          'maintenance_cause': record.maintenanceCause,
          'materials_used': record.materialsUsed,
          'has_materials': record.hasMaterials,
          'duration_hours': record.formattedDuration,
          'responsible_person': record.responsiblePerson,
          'module_name': record.moduleName ?? 'Módulo desconocido',
        };
      }).toList();
      setState(() {
        _maintenanceControlData = formattedData;
        _isLoadingMaintenanceControl = false;
      });
    } catch (e) {
      setState(() {
        _maintenanceControlError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingMaintenanceControl = false;
      });
    }
  }

Future<void> _loadWorkerControlsData() async {
    if (_isLoadingWorkerControls) return;
    setState(() {
      _isLoadingWorkerControls = true;
      _workerControlsError = null;
    });
    try {
      final workerControlService = WorkerControlService();
      final controls = await workerControlService.getWorkerControlsByCoop(
        AppConfig.current.id,
      );
      final formattedData = controls.map((control) {
        return {
          'id': control.id,
          'work_area': control.workArea.displayName,
          'work_area_code': control.workArea.code,
          'production_batch_id': control.productionBatchId,
          'compliance_count': control.complianceCount,
          'total_criteria': control.totalCriteria,
          'compliance_percentage': control.compliancePercentage,
          'is_fully_compliant': control.isFullyCompliant,
          'observations': control.observations,
          'created_at': control.createdAt,
          'formatted_date': AppDateUtils.formatDDMMYYYY(control.createdAt),
          'workers': control.workersList,
          // Fallback para registros antiguos sin items
          'worker_name': control.displayNames,
        };
      }).toList();
      setState(() {
        _workerControlsData = formattedData;
        _isLoadingWorkerControls = false;
      });
    } catch (e) {
      setState(() {
        _workerControlsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingWorkerControls = false;
      });
    }
  }

  Future<void> _loadProductReturnsData() async {
    if (_isLoadingProductReturns) return;
    setState(() {
      _isLoadingProductReturns = true;
      _productReturnsError = null;
    });
    try {
      final productReturnService = ProductReturnService();
      final returns = await productReturnService.getReturnsHistory();
      setState(() {
        _productReturnsData = returns;
        _isLoadingProductReturns = false;
      });
    } catch (e) {
      setState(() {
        _productReturnsError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingProductReturns = false;
      });
    }
  }

  // ── Helpers de navegación ────────────────────────────────────────────────────

  String _getTitle() {
    if (_selectedOption == null) return 'Historial';

    if (_selectedOption == 3) {
      if (_selectedControlFormType == null) return 'Formularios de control';
      return _getControlFormTypeName(_selectedControlFormType!);
    }

    switch (_selectedOption) {
      case 0:
        return 'Productores registrados';
      case 1:
        return 'Producción registrada';
      case 2:
        return 'Salidas registradas';
      default:
        return 'Historial';
    }
  }

  String _getControlFormTypeName(int typeIndex) {
    switch (typeIndex) {
      case 0:
        return 'Inspección de ambientes';
      case 1:
        return 'Limpieza y desinfección';
      case 2:
        return 'Control de cloro';
      case 3:
        return 'Control de plagas';
      case 4:
        return 'Enfermedades y accidentes';
      case 5:
        return 'Inspección de estiba';
      case 6:
        return 'Quejas y devoluciones';
      case 7:
        return 'Control de personal';
      case 8:
        return 'Mantenimiento';
      default:
        return 'Formulario de control';
    }
  }

  void _onOptionSelected(int index) {
    setState(() => _selectedOption = index);
    switch (index) {
      case 0:
        _loadProducersData();
      case 1:
        _loadProductionData();
      case 2:
        _loadExitsData();
      case 3:
        _loadControlFormsData();
    }
  }

  void _onFormTypeSelected(int index) {
    setState(() => _selectedControlFormType = index);
    switch (index) {
      case 0:
        _loadEnvironmentInspectionsData();
      case 1:
        _loadCleaningDisinfectionData();
      case 2:
        _loadChlorineControlData();
      case 3:
        _loadPestControlData();
      case 4:
        _loadHealthIncidentsData();
      case 5:
        _loadControlFormsData();
      case 6:
        _loadProductReturnsData();
      case 7:
        _loadWorkerControlsData();
      case 8:
        _loadMaintenanceControlData();
    }
  }

  void _handleBack() {
    if (_selectedControlFormType != null) {
      // Nivel 3 → Nivel 2
      setState(() {
        _selectedControlFormType = null;
        _controlData = [];
      });
    } else if (_selectedOption != null) {
      // Nivel 2 → Nivel 1
      setState(() => _selectedOption = null);
    } else {
      // Nivel 1 → Home
      context.go(AppRoutes.home.path);
    }
  }

  // ── Parcelas en cards de productores ────────────────────────────────────────

  Widget _buildProducerParcelas(Map<String, dynamic> item) {
    final parcelas = (item['parcelas'] as List<dynamic>?) ?? [];
    if (parcelas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: context.responsiveSpacing / 2),
        const Divider(height: 1),
        SizedBox(height: context.responsiveSpacing / 2),
        Row(
          children: [
            const Icon(Icons.landscape, size: 14, color: AppColors.primary),
            SizedBox(width: context.responsiveSpacing / 4),
            Text(
              'Parcelas (${parcelas.length})',
              style: AppTextStyles.smallText.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: context.responsiveSpacing / 4),
        ...parcelas.map((p) {
          final name = (p['name'] as String?) ?? '';
          final code = (p['code'] as String?) ?? '';
          return Padding(
            padding: EdgeInsets.only(
              bottom: context.responsiveSpacing / 4,
              left: 4,
            ),
            child: Row(
              children: [
                const Text('•  ',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text(
                  code,
                  style: AppTextStyles.smallText.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (name.isNotEmpty) ...[
                  const Text('  ·  ',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Edición de productores ───────────────────────────────────────────────────

  void _onEditProducer(Map<String, dynamic> producerData) {
    showDialog(
      context: context,
      builder: (context) => ProducerEditDialog(
        producerData: producerData,
        onSaved: _loadProducersData,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      onSyncPressed: _syncAll,
      child: Center(
        child: SingleChildScrollView(
          padding: context.responsiveHorizontalPadding.copyWith(
            top: context.responsivePadding.top,
            bottom: context.responsivePadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.responsiveCardWidth),
            child: AppCard(
              hasBackButton: true,
              onBack: _handleBack,
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedOption == null ? 'Historial' : _getTitle(),
                    style: AppTextStyles.mainTitle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.responsiveSpacing),
                  _selectedOption == null
                      ? _buildMainMenu()
                      : _buildSelectedContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Nivel 1: menú principal con las 4 opciones.
  Widget _buildMainMenu() {
    final currentUser = ref.read(currentUserProvider);
    return HistorialMainMenu(
      onOptionSelected: _onOptionSelected,
      isProductor: currentUser?.isProductor ?? false,
    );
  }

  /// Enrutador de nivel 2 y 3 según la opción seleccionada.
  Widget _buildSelectedContent() {
    switch (_selectedOption) {
      // ── Productores ──────────────────────────────────────────────────────────
      case 0:
        if (_isLoadingProducers) {
          return const HistorialLoadingWidget();
        }
        if (_producersError != null) {
          return HistorialErrorWidget(
            error: _producersError!,
            onRetry: _loadProducersData,
          );
        }
        return HistorialMobileDataView(
          data: _producersData,
          headers: ['Nombre', 'DNI', 'Módulo', 'Condición'],
          keys: ['nombre', 'dni', 'modulo', 'condicion'],
          onEdit: _onEditProducer,
          footerBuilder: _buildProducerParcelas,
        );

      // ── Producción ───────────────────────────────────────────────────────────
      case 1:
        if (_isLoadingProduction) {
          return const HistorialLoadingWidget();
        }
        if (_productionError != null) {
          return HistorialErrorWidget(
            error: _productionError!,
            onRetry: _loadProductionData,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HistorialDateRangeMessage(
                startDate: _startDate, endDate: _endDate),
            SizedBox(height: context.responsiveSpacing),
            HistorialMobileDataView(
              data: _productionData,
              headers: [
                'Productor',
                'Fecha Proceso',
                'Panela Obtenida (kg)',
                'Rendimiento (%)',
              ],
              keys: [
                'productor',
                'fecha_proceso',
                'panela_kg',
                'eficiencia',
              ],
            ),
          ],
        );

      // ── Salidas ──────────────────────────────────────────────────────────────
      case 2:
        if (_isLoadingExits) {
          return const HistorialLoadingWidget();
        }
        if (_exitsError != null) {
          return HistorialErrorWidget(
            error: _exitsError!,
            onRetry: _loadExitsData,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HistorialDateRangeMessage(
                startDate: _startDate, endDate: _endDate),
            SizedBox(height: context.responsiveSpacing),
            HistorialExitsSection(exitsData: _exitsData),
          ],
        );

      // ── Formularios de control ────────────────────────────────────────────────
      case 3:
        final connectivityAsync = ref.watch(connectivityProvider);
        return connectivityAsync.when(
          data: (isOnline) => _buildControlSection(isOnline),
          loading: () => _buildControlSection(true),
          error: (_, __) => _buildControlSection(false),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Enrutador de nivel 2 (submenú) y nivel 3 (contenido) para formularios.
  Widget _buildControlSection(bool isOnline) {
    if (_selectedControlFormType == null) {
      // Nivel 2: submenú de tipos de formulario
      return HistorialControlSubmenu(
        isOnline: isOnline,
        onFormTypeSelected: _onFormTypeSelected,
      );
    }
    // Nivel 3: contenido del formulario seleccionado
    return _buildControlFormContent();
  }

  /// Enrutador de contenido para cada tipo de formulario de control.
  Widget _buildControlFormContent() {
    switch (_selectedControlFormType) {
      case 0:
        return EnvironmentInspectionList(
          isLoading: _isLoadingEnvironmentInspections,
          error: _environmentInspectionsError,
          data: _environmentInspectionsData,
        );
      case 1:
        return CleaningDisinfectionList(
          error: _cleaningDisinfectionError,
          data: _cleaningDisinfectionData,
        );
      case 2:
        return ChlorineControlList(
          isLoading: _isLoadingChlorineControl,
          error: _chlorineControlError,
          data: _chlorineControlData,
        );
      case 3:
        return PestControlList(
          isLoading: _isLoadingPestControl,
          error: _pestControlError,
          data: _pestControlData,
          onRetry: _loadPestControlData,
        );
      case 4:
        return HealthIncidentsList(
          isLoading: _isLoadingHealthIncidents,
          error: _healthIncidentsError,
          data: _healthIncidentsData,
        );
      case 5:
        return StowageInspectionList(
          isLoading: _isLoadingControl,
          error: _controlError,
          data: _controlData,
        );
      case 6:
        return ProductReturnsList(
          isLoading: _isLoadingProductReturns,
          error: _productReturnsError,
          data: _productReturnsData,
        );
      case 7:
        return WorkerControlList(
          isLoading: _isLoadingWorkerControls,
          error: _workerControlsError,
          data: _workerControlsData,
        );
      case 8:
        return MaintenanceControlList(
          isLoading: _isLoadingMaintenanceControl,
          error: _maintenanceControlError,
          data: _maintenanceControlData,
        );
      default:
        // Formulario no implementado aún
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.grey[400]),
              SizedBox(height: context.responsiveSpacing),
              Text(
                'Este formulario estará disponible próximamente',
                style: AppTextStyles.bodyText.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }
}
