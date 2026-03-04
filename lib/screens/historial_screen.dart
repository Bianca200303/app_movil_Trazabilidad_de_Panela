import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/sync_progress_dialog.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/production_batch_service.dart';
import 'package:panela_sys/services/exit_registration_service.dart';
import 'package:panela_sys/services/stowage_transport_inspection_service.dart';
import 'package:panela_sys/services/environment_inspection_service.dart';
import 'package:panela_sys/services/cleaning_disinfection_service.dart';
import 'package:panela_sys/services/chlorine_residual_control_service.dart';
import 'package:panela_sys/services/pest_control_service.dart';
import 'package:panela_sys/services/health_incident_service.dart';
import 'package:panela_sys/services/equipment_maintenance_service.dart';
import 'package:panela_sys/services/worker_control_service.dart';
import 'package:panela_sys/services/product_return_service.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/stowage_transport_inspection.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/models/cleaning_disinfection.dart';
import 'package:panela_sys/models/health_incident.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  late final ProducerService _producerService;
  late final ProductionBatchService _productionBatchService;
  final ExitRegistrationService _exitRegistrationService = ExitRegistrationService();
  final StowageTransportInspectionService _inspectionService = StowageTransportInspectionService();
  final EnvironmentInspectionService _environmentInspectionService = EnvironmentInspectionService();
  final CleaningDisinfectionService _cleaningDisinfectionService = CleaningDisinfectionService();
  final ChlorineResidualControlService _chlorineControlService = ChlorineResidualControlService();

  // Real data loaded from database - Producers
  List<Map<String, dynamic>> _producersData = [];
  bool _isLoadingProducers = false;
  String? _producersError;

  // Real data loaded from database - Production
  List<Map<String, dynamic>> _productionData = [];
  bool _isLoadingProduction = false;
  String? _productionError;

  // Real data loaded from database - Exits
  List<Map<String, dynamic>> _exitsData = [];
  bool _isLoadingExits = false;
  String? _exitsError;

  // Real data loaded from database - Control (Inspections)
  List<Map<String, dynamic>> _controlData = [];
  bool _isLoadingControl = false;
  String? _controlError;

  // Real data loaded from database - Environment Inspections
  List<Map<String, dynamic>> _environmentInspectionsData = [];
  bool _isLoadingEnvironmentInspections = false;
  String? _environmentInspectionsError;

  // Real data loaded from database - Cleaning Disinfection
  List<Map<String, dynamic>> _cleaningDisinfectionData = [];
  bool _isLoadingCleaningDisinfection = false;
  String? _cleaningDisinfectionError;

  // Real data loaded from database - Chlorine Control
  List<Map<String, dynamic>> _chlorineControlData = [];
  bool _isLoadingChlorineControl = false;
  String? _chlorineControlError;

  // Real data loaded from database - Pest Control
  List<Map<String, dynamic>> _pestControlData = [];
  bool _isLoadingPestControl = false;
  String? _pestControlError;

  // Real data loaded from database - Health Incidents
  List<Map<String, dynamic>> _healthIncidentsData = [];
  bool _isLoadingHealthIncidents = false;
  String? _healthIncidentsError;

  // Real data loaded from database - Equipment Maintenance
  List<Map<String, dynamic>> _maintenanceControlData = [];
  bool _isLoadingMaintenanceControl = false;
  String? _maintenanceControlError;

  // Real data loaded from database - Worker Controls
  List<Map<String, dynamic>> _workerControlsData = [];
  bool _isLoadingWorkerControls = false;
  String? _workerControlsError;

  // Real data loaded from database - Product Returns
  List<Map<String, dynamic>> _productReturnsData = [];
  bool _isLoadingProductReturns = false;
  String? _productReturnsError;

  // Control de expansión de cards de limpieza
  final Set<String> _expandedCleaningRecords = {};

  int? _selectedOption;
  int? _selectedControlFormType; // Submenu level for control forms

  // Date range for filtering (last month)
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    // Inject database into services
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _productionBatchService = ProductionBatchService(db: db);

    // Calculate date range: last month
    _endDate = DateTime.now();
    _startDate = DateTime(_endDate.year, _endDate.month - 1, _endDate.day);
  }

  Future<void> _syncAll() async {
    // Get auto-sync service from provider
    final autoSyncNotifier = ref.read(autoSyncStateProvider.notifier);

    try {
      // Show progress dialog with manual sync stream
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SyncProgressDialog(
          syncStream: autoSyncNotifier.startManualSync(),
        ),
      );

      // Reload data after successful sync
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

  Future<void> _loadProducersData() async {
    if (_isLoadingProducers) return;
    
    setState(() {
      _isLoadingProducers = true;
      _producersError = null;
    });

    try {
      final data = await _producerService.getProducersForHistorial();
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

  Future<void> _loadProductionData() async {
    if (_isLoadingProduction) return;
    
    setState(() {
      _isLoadingProduction = true;
      _productionError = null;
    });

    try {
      final data = await _productionBatchService.getProductionBatchesForHistorial();
      
      // Format dates for display
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
      final data = await _exitRegistrationService.getExitRegistrationsForHistorial();

      // Format dates for display
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

      // Format dates and prepare display data
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
      final data = await _environmentInspectionService.getInspectionsWithModuleDetails();

      // Format dates and prepare display data
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
        _environmentInspectionsError = e.toString().replaceFirst('Exception: ', '');
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

      // Para cada registro, traer sus items
      final formattedData = <Map<String, dynamic>>[];

      for (final record in data) {
        final items = await _cleaningDisinfectionService.getItemsByRecordId(record.id);

        // Agrupar items por área
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
        _cleaningDisinfectionError = e.toString().replaceFirst('Exception: ', '');
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
        // Fetch child records
        final baitRecords = await pestControlService.getBaitRecordsByControlId(control.id);
        final insectRecords = await pestControlService.getInsectRecordsByControlId(control.id);

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
          'worker_name': control.workerName,
          'work_area': control.workArea.displayName,
          'work_area_code': control.workArea.code,
          'production_batch_id': control.productionBatchId,
          'compliance_count': control.complianceCount,
          'compliance_percentage': control.compliancePercentage,
          'is_fully_compliant': control.isFullyCompliant,
          'observations': control.observations,
          'created_at': control.createdAt,
          'formatted_date': AppDateUtils.formatDDMMYYYY(control.createdAt),
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
            constraints: BoxConstraints(
              maxWidth: context.responsiveCardWidth,
            ),
            child: AppCard(
              hasBackButton: true,
              onBack: () {
                if (_selectedControlFormType != null) {
                  // Level 3 → Level 2: Back to control forms submenu
                  setState(() {
                    _selectedControlFormType = null;
                    _controlData = [];
                  });
                } else if (_selectedOption != null) {
                  // Level 2 → Level 1: Back to main options
                  setState(() {
                    _selectedOption = null;
                  });
                } else {
                  // Level 1 → Home: Exit screen
                  context.go(AppRoutes.home.path);
                }
              },
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    _selectedOption == null ? 'Historial' : _getTitle(),
                    style: AppTextStyles.mainTitle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.responsiveSpacing),

                  // Content based on selection
                  _selectedOption == null
                      ? _buildMainOptions(context)
                      : _buildSelectedContent(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    if (_selectedOption == null) {
      return 'Historial';
    }

    if (_selectedOption == 3) {
      if (_selectedControlFormType == null) {
        return 'Formularios de control';
      } else {
        return _getControlFormTypeName(_selectedControlFormType!);
      }
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

  Widget _buildMainOptions(BuildContext context) {
    // Watch connectivity state
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        // Determine which options are enabled based on connectivity + offline support
        final options = [
          {
            'title': 'Productores registrados',
            'icon': Icons.person,
            'index': 0,
            'enabled': isOnline || OfflineConfig.instance.features.producers,
          },
          {
            'title': 'Producción registrada',
            'icon': Icons.shopping_bag,
            'index': 1,
            'enabled': isOnline || OfflineConfig.instance.features.production,
          },
          {
            'title': 'Salidas registradas',
            'icon': Icons.signpost,
            'index': 2,
            'enabled': isOnline || OfflineConfig.instance.features.exits,
          },
          {
            'title': 'Inspecciones de control',
            'icon': Icons.assignment_outlined,
            'index': 3,
            'enabled': isOnline, // Control forms only online for now
          },
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final isEnabled = option['enabled'] as bool;

            return Padding(
              padding: EdgeInsets.only(bottom: context.responsiveSpacing),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: option['title'] as String,
                  icon: option['icon'] as IconData,
                  type: isEnabled ? AppButtonType.primary : AppButtonType.secondary,
                  onPressed: isEnabled
                      ? () {
                          setState(() {
                            _selectedOption = option['index'] as int;
                          });

                          // Load data when selecting options
                          if (option['index'] == 0) {
                            _loadProducersData();
                          } else if (option['index'] == 1) {
                            _loadProductionData();
                          } else if (option['index'] == 2) {
                            _loadExitsData();
                          } else if (option['index'] == 3) {
                            _loadControlFormsData();
                          }
                        }
                      : null, // Disabled if no offline support
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => _buildMainOptionsLoading(context),
      error: (_, __) => _buildMainOptionsOffline(context),
    );
  }

  /// Build options while loading connectivity state (assume online)
  Widget _buildMainOptionsLoading(BuildContext context) {
    return _buildMainOptionsWithState(context, isOnline: true);
  }

  /// Build options when connectivity error (assume offline)
  Widget _buildMainOptionsOffline(BuildContext context) {
    return _buildMainOptionsWithState(context, isOnline: false);
  }

  /// Helper to build options with explicit online state
  Widget _buildMainOptionsWithState(BuildContext context, {required bool isOnline}) {
    final options = [
      {
        'title': 'Productores registrados',
        'icon': Icons.person,
        'index': 0,
        'enabled': isOnline || OfflineConfig.instance.features.producers,
      },
      {
        'title': 'Producción registrada',
        'icon': Icons.shopping_bag,
        'index': 1,
        'enabled': isOnline || OfflineConfig.instance.features.production,
      },
      {
        'title': 'Salidas registradas',
        'icon': Icons.signpost,
        'index': 2,
        'enabled': isOnline || OfflineConfig.instance.features.exits,
      },
      {
        'title': 'Inspecciones de control',
        'icon': Icons.assignment_outlined,
        'index': 3,
        'enabled': isOnline, // Control forms only online for now
      },
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isEnabled = option['enabled'] as bool;

        return Padding(
          padding: EdgeInsets.only(bottom: context.responsiveSpacing),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              text: option['title'] as String,
              icon: option['icon'] as IconData,
              type: isEnabled ? AppButtonType.primary : AppButtonType.secondary,
              onPressed: isEnabled
                  ? () {
                      setState(() {
                        _selectedOption = option['index'] as int;
                      });

                      // Load data when selecting options
                      if (option['index'] == 0) {
                        _loadProducersData();
                      } else if (option['index'] == 1) {
                        _loadProductionData();
                      } else if (option['index'] == 2) {
                        _loadExitsData();
                      } else if (option['index'] == 3) {
                        _loadControlFormsData();
                      }
                    }
                  : null, // Disabled if no offline support
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControlFormsSubMenu(BuildContext context, bool isOnline) {
    final features = AppConfig.current.features;

    final formTypes = [
      {
        'title': 'Inspección de ambientes, equipo y personal',
        'icon': Icons.business_outlined,
        'index': 0,
        'enabled': isOnline && features.enableEnvironmentInspection,
      },
      {
        'title': 'Limpieza y desinfección',
        'icon': Icons.cleaning_services_outlined,
        'index': 1,
        'enabled': isOnline && features.enableCleaningDisinfection,
      },
      {
        'title': 'Control de cloro libre residual',
        'icon': Icons.water_drop_outlined,
        'index': 2,
        'enabled': isOnline && features.enableChlorineControl,
      },
      {
        'title': 'Control de plagas',
        'icon': Icons.bug_report_outlined,
        'index': 3,
        'enabled': isOnline && features.enablePestControl,
      },
      {
        'title': 'Seguimiento de enfermedades y accidentes',
        'icon': Icons.medical_services_outlined,
        'index': 4,
        'enabled': isOnline && features.enableHealthAccidentTracking,
      },
      {
        'title': 'Inspección de estiba y transporte',
        'icon': Icons.local_shipping_outlined,
        'index': 5,
        'enabled': isOnline && features.enableStowageTransportInspection,
      },
      {
        'title': 'Quejas y devoluciones',
        'icon': Icons.feedback_outlined,
        'index': 6,
        'enabled': isOnline && features.enableComplaintsReturns,
      },
      {
        'title': 'Control de personal operario',
        'icon': Icons.badge_outlined,
        'index': 7,
        'enabled': isOnline && features.enableWorkerControl,
      },
      {
        'title': 'Mantenimiento hornilla/maquinaria/equipos',
        'icon': Icons.build_outlined,
        'index': 8,
        'enabled': isOnline && features.enableMaintenanceControl,
      },
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: formTypes.map((formType) {
        final isEnabled = formType['enabled'] as bool;

        return Padding(
          padding: EdgeInsets.only(bottom: context.responsiveSpacing),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              text: formType['title'] as String,
              icon: formType['icon'] as IconData,
              type: isEnabled ? AppButtonType.primary : AppButtonType.secondary,
              onPressed: isEnabled
                  ? () {
                      setState(() {
                        _selectedControlFormType = formType['index'] as int;
                      });
                      // Load data for implemented forms
                      if (formType['index'] == 0) {
                        _loadEnvironmentInspectionsData();
                      } else if (formType['index'] == 1) {
                        _loadCleaningDisinfectionData();
                      } else if (formType['index'] == 2) {
                        _loadChlorineControlData();
                      } else if (formType['index'] == 3) {
                        _loadPestControlData();
                      } else if (formType['index'] == 4) {
                        _loadHealthIncidentsData();
                      } else if (formType['index'] == 5) {
                        _loadControlFormsData();
                      } else if (formType['index'] == 6) {
                        _loadProductReturnsData();
                      } else if (formType['index'] == 7) {
                        _loadWorkerControlsData();
                      } else if (formType['index'] == 8) {
                        _loadMaintenanceControlData();
                      }
                    }
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControlFormContent() {
    // Route to appropriate content based on selected control form type
    switch (_selectedControlFormType) {
      case 0:
        // Environment inspection
        return _buildEnvironmentInspectionContent();
      case 1:
        // Cleaning and disinfection
        return _buildCleaningDisinfectionContent();
      case 2:
        // Chlorine control
        return _buildChlorineControlContent();
      case 3:
        // Pest control
        return _buildPestControlContent();
      case 4:
        // Health accident tracking
        return _buildHealthIncidentsContent();
      case 5:
        // Stowage transport inspection
        return _buildStowageTransportInspectionContent();
      case 6:
        // Product returns
        return _buildProductReturnsContent();
      case 7:
        // Worker control
        return _buildWorkerControlContent();
      case 8:
        // Equipment maintenance control
        return _buildMaintenanceControlContent();
      default:
        // Other forms not yet implemented
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: context.responsiveSpacing),
              Text(
                'Este formulario estará disponible próximamente',
                style: AppTextStyles.bodyText.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildEnvironmentInspectionContent() {
    if (_isLoadingEnvironmentInspections) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando inspecciones de ambiente...'),
          ],
        ),
      );
    }

    if (_environmentInspectionsError != null) {
      return Center(
        child: Text(
          'Error: $_environmentInspectionsError',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_environmentInspectionsData.isEmpty) {
      return const Center(
        child: Text(
          'No hay inspecciones de ambiente registradas',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show inspections list as cards
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _environmentInspectionsData.map((inspection) {
        final compliancePercentage = inspection['compliance_percentage'] as double;
        final totalItems = inspection['total_items'] as int;
        final compliantItems = inspection['compliant_items'] as int;
        final nonCompliantItems = inspection['non_compliant_items'] as int;
        final moduleName = inspection['module_name'] as String;
        final inspectionDate = inspection['inspection_date'] as String;

        // Determine color based on compliance percentage
        Color backgroundColor;
        Color badgeColor;
        if (compliancePercentage == 100) {
          backgroundColor = Colors.green[50]!;
          badgeColor = AppColors.success;
        } else {
          // Everything below 100% uses orange (not red)
          backgroundColor = Colors.orange[50]!;
          badgeColor = Colors.orange[700]!;
        }

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Compliance badge + date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      '${compliancePercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    inspectionDate,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              // Module name
              _buildInfoRow('Módulo:', moduleName),

              SizedBox(height: context.responsiveSpacing / 2),

              // Items summary
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de ítems',
                      style: AppTextStyles.fieldLabel,
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatChip(context, 'Total', totalItems.toString(), AppColors.textPrimary),
                        _buildStatChip(context, 'Conformes', compliantItems.toString(), AppColors.success),
                        _buildStatChip(context, 'No conformes', nonCompliantItems.toString(), AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),

              // Non-compliant areas (if any)
              if (nonCompliantItems > 0) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[900], size: 16),
                      SizedBox(width: context.responsiveSpacing / 4),
                      Expanded(
                        child: Text(
                          '$nonCompliantItems ítems requieren acciones correctivas',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCleaningDisinfectionContent() {
    if (_cleaningDisinfectionError != null) {
      return Center(
        child: Text(
          'Error: $_cleaningDisinfectionError',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_cleaningDisinfectionData.isEmpty) {
      return const Center(
        child: Text(
          'No hay registros de limpieza y desinfección',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Mostrar cards expandibles
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _cleaningDisinfectionData.map((record) {
        final recordId = record['id'] as String;
        final isExpanded = _expandedCleaningRecords.contains(recordId);
        final moduleName = record['module_name'] as String;
        final formattedDate = record['formatted_date'] as String;
        final hasObservations = record['has_observations'] as bool;
        final generalObservations = record['general_observations'] as String?;
        final itemsByArea = record['items_by_area'] as Map<String, List<CleaningDisinfectionItem>>;
        final totalItems = record['total_items'] as int;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER: Clickeable para expandir/colapsar
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedCleaningRecords.remove(recordId);
                    } else {
                      _expandedCleaningRecords.add(recordId);
                    }
                  });
                },
                child: Padding(
                  padding: context.responsivePadding,
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Icon(
                        Icons.cleaning_services,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              moduleName,
                              style: AppTextStyles.cardTitle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: AppTextStyles.captionText,
                            ),
                          ],
                        ),
                      ),
                      // Badge con total de items
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalItems',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (hasObservations)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // CONTENIDO EXPANDIBLE
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: context.responsivePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Observaciones generales
                      if (hasObservations && generalObservations != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                       size: 16,
                                       color: Colors.orange[900]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Observaciones Generales:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                generalObservations,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Detalles por área
                      Text(
                        'Detalles de limpieza:',
                        style: AppTextStyles.fieldLabel,
                      ),
                      const SizedBox(height: 12),

                      // Iterar sobre áreas
                      ...itemsByArea.entries.map((entry) {
                        final areaCode = entry.key;
                        final items = entry.value;
                        final areaName = CleaningAreas.getDisplayName(areaCode);

                        // Obtener tipo de limpieza y productos del primer item
                        final firstItem = items.first;
                        final cleaningTypes = <String>[];
                        if (firstItem.isDailyCleaning) cleaningTypes.add('Diaria');
                        if (firstItem.isGeneralCleaning) cleaningTypes.add('General');
                        if (firstItem.isDeepCleaning) cleaningTypes.add('Profunda');

                        final products = <String>[];
                        if (firstItem.usesChlorine) products.add('Cloro');
                        if (firstItem.usesDetergent) products.add('Detergente');
                        if (firstItem.usesOtherProduct) products.add('Otro');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre del área
                              Row(
                                children: [
                                  Icon(Icons.room_outlined,
                                       size: 16,
                                       color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      areaName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${items.length} puntos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Tipo de limpieza
                              Row(
                                children: [
                                  Icon(Icons.cleaning_services_outlined,
                                       size: 14,
                                       color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    cleaningTypes.join(', '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Productos
                              Row(
                                children: [
                                  Icon(Icons.science_outlined,
                                       size: 14,
                                       color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    products.join(', '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Lista de puntos
                              ...items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.check_circle,
                                           size: 14,
                                           color: Colors.green[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.pointDescription,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChlorineControlContent() {
    if (_isLoadingChlorineControl) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando controles de cloro...'),
          ],
        ),
      );
    }

    if (_chlorineControlError != null) {
      return Center(
        child: Text(
          'Error: $_chlorineControlError',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_chlorineControlData.isEmpty) {
      return const Center(
        child: Text(
          'No hay controles de cloro registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show controls list as cards
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _chlorineControlData.map((control) {
        final bothSafe = control['both_safe'] as bool;
        final requiresAction = control['requires_action'] as bool;
        final moduleName = control['module_name'] as String;
        final controlDate = control['control_date'] as String;
        final controlTime = control['control_time'] as String;
        final m1 = control['m1'] as double;
        final m2 = control['m2'] as double;
        final isM1Safe = control['is_m1_safe'] as bool;
        final isM2Safe = control['is_m2_safe'] as bool;
        final safetyWarning = control['safety_warning'] as String?;
        final correctiveActions = control['corrective_actions'] as String?;
        final observations = control['observations'] as String?;
        final responsiblePerson = control['responsible_person'] as String;

        // Determine card color based on safety
        Color backgroundColor;
        Color badgeColor;
        if (bothSafe) {
          backgroundColor = Colors.green[50]!;
          badgeColor = AppColors.success;
        } else {
          backgroundColor = Colors.orange[50]!;
          badgeColor = Colors.orange[700]!;
        }

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Status badge + date/time
              Row(
                children: [
                  Icon(
                    bothSafe ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: badgeColor,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      bothSafe ? 'EN RANGO SEGURO' : 'FUERA DE RANGO',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$controlDate $controlTime',
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              // Module name
              _buildInfoRow('Módulo:', moduleName),

              SizedBox(height: context.responsiveSpacing / 2),

              // Measurements
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mediciones (ppm)',
                      style: AppTextStyles.fieldLabel,
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),

                    // M1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isM1Safe ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: isM1Safe ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'M1 - Sanitización:',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          m1.toStringAsFixed(2),
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isM1Safe ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsiveSpacing / 4),

                    // M2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isM2Safe ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: isM2Safe ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'M2 - Proceso:',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          m2.toStringAsFixed(2),
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isM2Safe ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsiveSpacing / 4),

                    // Safe range reference
                    Text(
                      'Rango seguro: 0.5 - 2.0 ppm',
                      style: AppTextStyles.captionText.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Safety warning (if out of range)
              if (requiresAction && safetyWarning != null) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[900], size: 16),
                      SizedBox(width: context.responsiveSpacing / 4),
                      Expanded(
                        child: Text(
                          safetyWarning,
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Corrective actions (if exists)
              if (correctiveActions != null && correctiveActions.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.build, size: 16, color: Colors.blue[900]),
                          const SizedBox(width: 8),
                          Text(
                            'Acciones correctivas:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        correctiveActions,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Observations (if exists)
              if (observations != null && observations.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Observaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        observations,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Responsible person
              SizedBox(height: context.responsiveSpacing / 2),
              _buildInfoRow('Responsable:', responsiblePerson),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStowageTransportInspectionContent() {
    if (_isLoadingControl) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando inspecciones...'),
          ],
        ),
      );
    }

    if (_controlError != null) {
      return Center(
        child: Text(
          'Error: $_controlError',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_controlData.isEmpty) {
      return const Center(
        child: Text(
          'No hay inspecciones registradas',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show inspections list as cards with tap to view detail
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _controlData.map((inspection) {
        final isCompliant = inspection['is_compliant'] as bool;
        final documentNumber = inspection['document_number'] as String?;
        final exitItems = (inspection['exit_items'] as List?) ?? [];
        final vehicleCondition = inspection['vehicle_condition'] as String;
        final sackCleanCondition = inspection['sack_clean_condition'] as String;
        final sackTiedCondition = inspection['sack_tied_condition'] as String;
        final observations = inspection['observations'] as String?;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: isCompliant ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Badge de conformidad + fecha
              Row(
                children: [
                  Icon(
                    isCompliant ? Icons.check_circle : Icons.warning,
                    color: isCompliant ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      isCompliant ? 'CONFORME' : 'NO CONFORME',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: isCompliant ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    inspection['inspection_date'] as String,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              // Guía de remisión (si existe)
              if (documentNumber != null && documentNumber.isNotEmpty)
                _buildInfoRow('Guía de Remisión:', documentNumber),

              // Condición del vehículo
              if (documentNumber != null && documentNumber.isNotEmpty)
                SizedBox(height: context.responsiveSpacing / 2),
              _buildInfoRow('Condición del vehículo:', vehicleCondition),

              // Condiciones de sacos
              SizedBox(height: context.responsiveSpacing),
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(
                    color: AppColors.inputBorder.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Condiciones de sacos:',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    _buildInfoRow('Limpieza:', sackCleanCondition),
                    SizedBox(height: context.responsiveSpacing / 4),
                    _buildInfoRow('Amarrado:', sackTiedCondition),
                  ],
                ),
              ),

              // Lista de lotes inspeccionados
              if (exitItems.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(
                      color: AppColors.inputBorder.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lotes inspeccionados:',
                        style: AppTextStyles.fieldLabel.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      ...exitItems.map((item) {
                        final batch = item['production_batch'] as Map<String, dynamic>?;
                        final producer = batch?['producer'] as Map<String, dynamic>?;
                        final producerName = producer != null
                            ? '${producer['first_name']} ${producer['last_name']}'
                            : 'N/A';

                        final bagsCount = item['bags_count'] as int? ?? 0;
                        final isAutoconsumo = item['is_autoconsumo'] as bool? ?? false;
                        final quantityKg = (item['quantity_kg'] as num?)?.toDouble() ?? 0.0;
                        final itemDoc = item['item_document_number'] as String?;

                        return Padding(
                          padding: EdgeInsets.only(bottom: context.responsiveSpacing / 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$producerName - ${isAutoconsumo ? '${quantityKg.toStringAsFixed(2)} kg' : '$bagsCount ${bagsCount == 1 ? 'saco' : 'sacos'}'}',
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (itemDoc != null && itemDoc.isNotEmpty)
                                      Text(
                                        'Comp: $itemDoc',
                                        style: AppTextStyles.captionText.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              // Observaciones (si existen)
              if (observations != null && observations.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(
                      color: Colors.blue[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notes,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: context.responsiveSpacing / 4),
                          Text(
                            'Observaciones:',
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      Text(
                        observations,
                        style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              // Datos del transporte
              SizedBox(height: context.responsiveSpacing / 2),
              _buildInfoRow('Transportista:', inspection['carrier_name'] as String),
              _buildInfoRow('Vehículo:', inspection['vehicle_plate'] as String),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedContent(BuildContext context) {
    switch (_selectedOption) {
      case 0:
        // Producers registered
        if (_isLoadingProducers) {
          return _buildLoadingWidget(context);
        }
        if (_producersError != null) {
          return _buildErrorWidget(context, _producersError!, () => _loadProducersData());
        }
        return _buildDataSection(
          context,
          data: _producersData,
          headers: ['Nombre', 'DNI', 'Módulo', 'Condición'],
          keys: ['nombre', 'dni', 'modulo', 'condicion'],
        );
      case 1:
        // Production registered
        if (_isLoadingProduction) {
          return _buildLoadingWidget(context);
        }
        if (_productionError != null) {
          return _buildErrorWidget(context, _productionError!, () => _loadProductionData());
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateRangeMessage(context),
            SizedBox(height: context.responsiveSpacing),
            _buildDataSection(
              context,
              data: _productionData,
              headers: ['Productor', 'Fecha Proceso', 'Panela Obtenida (kg)', 'Rendimiento (%)'],
              keys: ['productor', 'fecha_proceso', 'panela_kg', 'eficiencia'],
            ),
          ],
        );
      case 2:
        // Exits registered
        if (_isLoadingExits) {
          return _buildLoadingWidget(context);
        }
        if (_exitsError != null) {
          return _buildErrorWidget(context, _exitsError!, () => _loadExitsData());
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDateRangeMessage(context),
            SizedBox(height: context.responsiveSpacing),
            _buildExitsDataSection(context),
          ],
        );
      case 3:
        // Control forms
        final connectivityAsync = ref.watch(connectivityProvider);
        return connectivityAsync.when(
          data: (isOnline) {
            if (_selectedControlFormType == null) {
              // Level 2: Show submenu of control form types
              return _buildControlFormsSubMenu(context, isOnline);
            } else {
              // Level 3: Show data for selected control form type
              return _buildControlFormContent();
            }
          },
          loading: () {
            if (_selectedControlFormType == null) {
              return _buildControlFormsSubMenu(context, true);
            } else {
              return _buildControlFormContent();
            }
          },
          error: (_, __) {
            if (_selectedControlFormType == null) {
              return _buildControlFormsSubMenu(context, false);
            } else {
              return _buildControlFormContent();
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDataSection(
    BuildContext context, {
    required List<Map<String, dynamic>> data,
    required List<String> headers,
    required List<String> keys,
  }) {
    return _buildMobileDataView(context, data, headers, keys);
  }

  Widget _buildExitsDataSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _exitsData.map((item) {
        final isAutoconsumo = item['is_autoconsumo'] == true;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Código de salida (referencia a la salida principal)
              _buildInfoRow('Código Salida:', item['codigo_salida'].toString()),
              SizedBox(height: context.responsiveSpacing / 2),

              // Fecha de la salida
              _buildInfoRow('Fecha:', item['fecha_salida'].toString()),
              SizedBox(height: context.responsiveSpacing / 2),

              // Productor del lote específico
              _buildInfoRow('Productor:', item['productor'].toString()),
              SizedBox(height: context.responsiveSpacing / 2),

              // Comprobante de acopio por item
              _buildInfoRow(
                'Comprobante:',
                (item['item_document_number'] ?? 'No especificado').toString(),
              ),
              SizedBox(height: context.responsiveSpacing / 2),

              // Cantidad (kg o sacos según tipo)
              _buildInfoRow('Cantidad:', '${item['cantidad_mostrada'].toString()} ${item['unidad'].toString()}'),
              SizedBox(height: context.responsiveSpacing / 2),

              // Documento
              _buildInfoRow('Documento:', item['documento'].toString()),

              // Badge de AUTOCONSUMO si aplica
              if (isAutoconsumo) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '',
                      style: AppTextStyles.fieldLabel,
                    ),
                    Flexible(
                      child: Text(
                        'AUTOCONSUMO',
                        style: AppTextStyles.bodyText.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileDataView(
    BuildContext context,
    List<Map<String, dynamic>> data,
    List<String> headers,
    List<String> keys,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((item) {
        // Detect if pending sync
        final syncStatus = item['syncStatus'] as int? ?? 1;
        final isPending = syncStatus == 0;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              // Orange border if pending
              color: isPending
                  ? const Color(0xFFFF9800)
                  : AppColors.inputBorder,
              width: isPending ? 2 : AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge "Por Sincronizar"
              if (isPending) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.sync_problem,
                      size: 16,
                      color: Color(0xFFFF9800),
                    ),
                    SizedBox(width: context.responsiveSpacing / 4),
                    Text(
                      'Por Sincronizar',
                      style: AppTextStyles.captionText.copyWith(
                        color: const Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing / 2),
              ],

              // Original content
              ...List.generate(headers.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < headers.length - 1
                        ? context.responsiveSpacing / 2
                        : 0,
                  ),
                  child: _buildInfoRow(
                    '${headers[index]}:',
                    item[keys[index]].toString(),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPestControlContent() {
    if (_isLoadingPestControl) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando controles de plagas...'),
          ],
        ),
      );
    }

    if (_pestControlError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_pestControlError',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Reintentar',
              onPressed: _loadPestControlData,
            ),
          ],
        ),
      );
    }

    if (_pestControlData.isEmpty) {
      return const Center(
        child: Text(
          'No hay controles de plagas registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show controls list as cards
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _pestControlData.map((control) {
        final moduleName = control['module_name'] as String;
        final controlDate = control['control_date'] as String;
        final baitRecords = control['bait_records'] as List;
        final insectRecords = control['insect_records'] as List;

        // Determine if there's any data
        final hasBaitData = baitRecords.isNotEmpty;
        final hasInsectData = insectRecords.isNotEmpty;

        // Background color based on content
        final backgroundColor = (hasBaitData && hasInsectData)
            ? Colors.blue[50]!
            : (hasBaitData ? Colors.green[50]! : Colors.orange[50]!);

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Icon + date
              Row(
                children: [
                  Icon(
                    Icons.bug_report,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      'CONTROL DE PLAGAS',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    controlDate,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              // Module name
              _buildInfoRow('Módulo:', moduleName),

              SizedBox(height: context.responsiveSpacing / 2),

              // Bait control section
              if (hasBaitData) ...[
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Control de Cebos',
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      ...baitRecords.map((record) {
                        final baitStations = (record.baitStations as List);
                        final totalStations = record.totalStations;
                        final stationsEaten = record.stationsWithBaitEaten;
                        final consumptionPercent = record.consumptionPercentage;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Producto:', record.productName),
                            _buildInfoRow('Cantidad:', '${record.quantity} ${record.unit}'),
                            SizedBox(height: context.responsiveSpacing / 4),
                            Text(
                              'Estaciones: $totalStations ($stationsEaten comieron, ${consumptionPercent.toStringAsFixed(0)}%)',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                            ),
                            if (record.baitObservations != null) ...[
                              SizedBox(height: context.responsiveSpacing / 4),
                              Text(
                                'Observaciones: ${record.baitObservations}',
                                style: AppTextStyles.bodyText.copyWith(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: context.responsiveSpacing / 2),
              ],

              // Insect control section
              if (hasInsectData) ...[
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Control de Insectos',
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      ...insectRecords.map((record) {
                        final totalFlies = record.totalFlies;
                        final totalBees = record.totalBees;
                        final totalAnts = record.totalAnts;
                        final totalCockroaches = record.totalCockroaches;
                        final totalInsects = record.totalInsects;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Producto:', record.productName),
                            _buildInfoRow('Cantidad:', '${record.quantity} ${record.unit}'),
                            SizedBox(height: context.responsiveSpacing / 4),
                            Text(
                              'Total de insectos: $totalInsects',
                              style: AppTextStyles.bodyText.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (totalFlies > 0)
                              Text('  • Moscas: $totalFlies', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                            if (totalBees > 0)
                              Text('  • Abejas: $totalBees', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                            if (totalAnts > 0)
                              Text('  • Hormigas: $totalAnts', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                            if (totalCockroaches > 0)
                              Text('  • Cucarachas: $totalCockroaches', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHealthIncidentsContent() {
    if (_isLoadingHealthIncidents) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando incidentes de salud...'),
          ],
        ),
      );
    }

    if (_healthIncidentsError != null) {
      return Center(
        child: Text(
          'Error: $_healthIncidentsError',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_healthIncidentsData.isEmpty) {
      return const Center(
        child: Text(
          'No hay incidentes de salud registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _healthIncidentsData.map((incident) {
        final hasReturnDate = incident['has_return_date'] as bool;
        final moduleName = incident['module_name'] as String;
        final employeeName = incident['employee_name'] as String;
        final registrationDate = incident['registration_date'] as String;
        final workArea = incident['work_area'] as String;
        final symptomsDescription = incident['symptoms_description'] as String;
        final actionsTaken = incident['actions_taken'] as String;
        final returnDate = incident['return_date'] as String;
        final certificatePresented = incident['certificate_presented'] as String;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: hasReturnDate ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status header
              Row(
                children: [
                  Icon(
                    hasReturnDate ? Icons.check_circle : Icons.warning,
                    color: hasReturnDate ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      hasReturnDate ? 'REINTEGRADO' : 'PENDIENTE',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: hasReturnDate ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    registrationDate,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              // Employee info
              _buildInfoRow('Empleado:', employeeName),
              SizedBox(height: context.responsiveSpacing / 2),
              _buildInfoRow('Módulo:', moduleName),
              SizedBox(height: context.responsiveSpacing / 2),
              _buildInfoRow('Área:', workArea),
              SizedBox(height: context.responsiveSpacing / 2),

              // Symptoms box
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Síntomas/Lesiones:',
                      style: AppTextStyles.fieldLabel,
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    Text(
                      symptomsDescription,
                      style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              // Actions and certificate
              _buildInfoRow('Acciones:', actionsTaken),
              SizedBox(height: context.responsiveSpacing / 2),
              _buildInfoRow('Certificado:', certificatePresented),

              // Return date badge (if exists)
              if (hasReturnDate) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reintegración: $returnDate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductReturnsContent() {
    if (_isLoadingProductReturns) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando devoluciones de producto...'),
          ],
        ),
      );
    }

    if (_productReturnsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Error: $_productReturnsError',
              style: AppTextStyles.bodyText.copyWith(
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_productReturnsData.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No hay devoluciones registradas',
              style: AppTextStyles.bodyText.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _productReturnsData.length,
      itemBuilder: (context, index) {
        final returnData = _productReturnsData[index];
        final returnDate = returnData['return_date'] as DateTime?;
        final quantity = returnData['quantity_sacks'] > 0
            ? '${returnData['quantity_sacks']} Sacos (${returnData['quantity_kg']} kg)'
            : '${returnData['quantity_kg']} kg';

        return Padding(
          padding: EdgeInsets.only(bottom: context.responsiveSpacing),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Cliente and Fecha Devolución
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        returnData['client_name'] ?? '-',
                        style: AppTextStyles.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      returnDate != null
                          ? DateFormat('dd/MM/yyyy').format(returnDate)
                          : '-',
                      style: AppTextStyles.bodyText.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing),
                Divider(height: 1),
                SizedBox(height: 12),

                // Batch and Production info
                _buildInfoRow('Productor:', returnData['producer_name'] ?? '-'),
                if (AppConfig.current.features.useAppagropCode)
                  _buildInfoRow('APPAGROP:', returnData['appagrop_code'] ?? '-'),
                SizedBox(height: 12),
                Divider(height: 1),
                SizedBox(height: 12),

                // Return details
                _buildInfoRow('Cantidad:', quantity),
                _buildInfoRow('Causa:', returnData['return_reason'] ?? '-'),
                if ((returnData['observations'] as String?)?.isNotEmpty ?? false)
                  _buildInfoRow('Observaciones:', returnData['observations'] ?? '-'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceControlContent() {
    if (_isLoadingMaintenanceControl) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando registros de mantenimiento...'),
          ],
        ),
      );
    }

    if (_maintenanceControlError != null) {
      return Center(
        child: Text(
          'Error: $_maintenanceControlError',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_maintenanceControlData.isEmpty) {
      return const Center(
        child: Text(
          'No hay registros de mantenimiento',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _maintenanceControlData.map((maintenance) {
        final maintenanceDate = maintenance['maintenance_date'] as String;
        final equipmentName = maintenance['equipment_name'] as String;
        final maintenanceType = maintenance['maintenance_type'] as String;
        final maintenanceTypeCode = maintenance['maintenance_type_code'] as String;
        final maintenanceCause = maintenance['maintenance_cause'] as String;
        final materialsUsed = maintenance['materials_used'] as String?;
        final hasMaterials = maintenance['has_materials'] as bool;
        final durationHours = maintenance['duration_hours'] as String;
        final responsiblePerson = maintenance['responsible_person'] as String;
        final moduleName = maintenance['module_name'] as String;

        // Determine badge color based on maintenance type
        Color badgeColor = maintenanceTypeCode == 'P'
            ? AppColors.success  // Preventive = green
            : AppColors.warning; // Corrective = orange

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Date (left) + Type Badge (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    maintenanceDate,
                    style: AppTextStyles.cardTitle,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      maintenanceType,
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              Divider(color: AppColors.inputBorder),
              SizedBox(height: context.responsiveSpacing / 2),

              // Module
              _buildInfoRow('Módulo:', moduleName),
              SizedBox(height: context.responsiveSpacing / 4),

              // Equipment
              _buildInfoRow('Equipo:', equipmentName),
              SizedBox(height: context.responsiveSpacing / 4),

              // Cause
              _buildInfoRow('Causa:', maintenanceCause),
              SizedBox(height: context.responsiveSpacing / 4),

              // Duration
              _buildInfoRow('Duración:', durationHours),
              SizedBox(height: context.responsiveSpacing / 4),

              // Responsible Person
              _buildInfoRow('Responsable:', responsiblePerson),

              // Materials (if present)
              if (hasMaterials) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Text(
                  'Materiales/Repuestos:',
                  style: AppTextStyles.fieldLabel,
                ),
                SizedBox(height: context.responsiveSpacing / 4),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: AppColors.inputBorder, width: 0.5),
                  ),
                  child: Text(
                    materialsUsed ?? '',
                    style: AppTextStyles.bodyText,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeMessage(BuildContext context) {
    final startDateStr = AppDateUtils.formatDDMMYYYY(_startDate);
    final endDateStr = AppDateUtils.formatDDMMYYYY(_endDate);

    return Container(
      padding: EdgeInsets.all(context.responsiveSpacing / 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.inputBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: context.responsiveSpacing / 4),
          Flexible(
            child: Text(
              'Mostrando registros del $startDateStr al $endDateStr',
              style: AppTextStyles.captionText,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: context.responsiveSpacing),
          Text(
            'Cargando datos...',
            style: AppTextStyles.bodyTextSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          SizedBox(height: context.responsiveSpacing),
          Text(
            'Error al cargar datos',
            style: AppTextStyles.fieldLabel,
          ),
          SizedBox(height: context.responsiveSpacing / 2),
          Text(
            error,
            style: AppTextStyles.bodyTextSecondary,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.responsiveSpacing),
          AppButton(
            text: 'Reintentar',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerControlContent() {
    if (_isLoadingWorkerControls) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando controles de personal...'),
          ],
        ),
      );
    }

    if (_workerControlsError != null) {
      return Center(
        child: Text(
          'Error: $_workerControlsError',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_workerControlsData.isEmpty) {
      return const Center(
        child: Text(
          'No hay controles de personal registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show controls list as cards
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _workerControlsData.map((control) {
        final isFullyCompliant = control['is_fully_compliant'] as bool;
        final compliancePercentage = control['compliance_percentage'] as double;
        final complianceCount = control['compliance_count'] as int;
        final workerName = control['worker_name'] as String;
        final workArea = control['work_area'] as String;
        final formattedDate = control['formatted_date'] as String;
        final observations = control['observations'] as String?;

        // Determine card color based on compliance
        Color backgroundColor;
        Color badgeColor;
        if (isFullyCompliant) {
          backgroundColor = Colors.green[50]!;
          badgeColor = AppColors.success;
        } else {
          backgroundColor = Colors.orange[50]!;
          badgeColor = Colors.orange[700]!;
        }

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Status badge + date
              Row(
                children: [
                  Icon(
                    isFullyCompliant ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: badgeColor,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      isFullyCompliant ? 'CUMPLE TOTALMENTE' : 'INCUMPLIMIENTOS',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              // Worker info
              _buildInfoRow('Trabajador:', workerName),
              SizedBox(height: context.responsiveSpacing / 2),
              _buildInfoRow('Área:', workArea),

              SizedBox(height: context.responsiveSpacing / 2),

              // Compliance summary
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cumplimiento de Higiene',
                      style: AppTextStyles.fieldLabel,
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isFullyCompliant ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: isFullyCompliant ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$complianceCount / 9 criterios',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          '${compliancePercentage.toStringAsFixed(0)}%',
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFullyCompliant ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Observations (if exists)
              if (observations != null && observations.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[900]),
                          const SizedBox(width: 8),
                          Text(
                            'Observaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        observations,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
