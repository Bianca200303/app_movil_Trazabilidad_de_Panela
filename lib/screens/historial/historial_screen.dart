import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/services/chlorine_residual_control_service.dart';
import 'package:panela_sys/services/cleaning_disinfection_service.dart';
import 'package:panela_sys/services/environment_inspection_service.dart';
import 'package:panela_sys/services/equipment_maintenance_service.dart';
import 'package:panela_sys/models/exit_registration.dart';
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
import 'widgets/shared/historial_period_filter.dart';
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
import 'widgets/control_forms/production_batch_list.dart';

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
  final ProductReturnService _productReturnService = ProductReturnService();
  final WorkerControlService _workerControlService = WorkerControlService();
  final EnvironmentInspectionService _environmentInspectionService =
      EnvironmentInspectionService();
  final CleaningDisinfectionService _cleaningDisinfectionService =
      CleaningDisinfectionService();
  final ChlorineResidualControlService _chlorineControlService =
      ChlorineResidualControlService();
  final PestControlService _pestControlService = PestControlService();
  final HealthIncidentService _healthIncidentService = HealthIncidentService();
  final EquipmentMaintenanceService _maintenanceService =
      EquipmentMaintenanceService();

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

  // ── Navegación ───────────────────────────────────────────────────────────────
  /// Opción principal seleccionada (0-3). Null = menú principal.
  int? _selectedOption;

  /// Subtipo de formulario de control seleccionado (0-8). Null = submenú.
  int? _selectedControlFormType;

  // ── Rango de fechas para historial de salidas ─────────────────────────────
  late DateTime _startDate;
  late DateTime _endDate;

  // ────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _productionBatchService = ProductionBatchService(db: db);
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
      // Filter by assigned module for adminModulo and tecnicoCampo
      if (currentUser?.hasModuleRestriction == true && currentUser!.moduleIds.isNotEmpty) {
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

    if (currentUser.hasModuleRestriction && currentUser.moduleIds.isNotEmpty) {
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
        final harvestDate = item['fecha_cosecha'] as DateTime?;
        final registroDate = item['fecha_registro'] as DateTime?;
        return {
          ...item,
          'fecha_proceso': AppDateUtils.formatDDMMYYYY(processDate),
          if (harvestDate != null) 'fecha_cosecha': AppDateUtils.formatDDMMYYYY(harvestDate),
          if (registroDate != null) 'fecha_registro': AppDateUtils.formatDDMMYYYY(registroDate),
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
          await _exitRegistrationService.getExitRegistrationsForHistorial(
            from: _startDate,
            to: _endDate,
          );
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

  Future<void> _addGRToExit(String exitRegistrationId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Guía de Remisión'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Número de GR',
            hintText: 'Ej: GR-001, T001-0012345',
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty) return;

    try {
      await _exitRegistrationService.updateExitRegistration(
        exitRegistrationId,
        UpdateExitRegistrationRequest(documentNumber: controller.text.trim()),
      );
      await _loadExitsData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guía de Remisión agregada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar GR: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Helpers de navegación ────────────────────────────────────────────────────

  String _getTitle() {
    if (_selectedOption == null) return 'Historial';

    if (_selectedOption == 3) {
      if (_selectedControlFormType == null) return 'Formulario de control Módulo';
      return _getControlFormTypeName(_selectedControlFormType!);
    }

    if (_selectedOption == 4) {
      if (_selectedControlFormType == null) return 'Formulario de control Producción';
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
    }
  }

  Set<String>? get _allowedModuleIds {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return null;
    if (currentUser.hasModuleRestriction && currentUser.moduleIds.isNotEmpty) {
      return currentUser.moduleIds.toSet();
    }
    return null;
  }

  void _onFormTypeSelected(int index) {
    setState(() => _selectedControlFormType = index);
  }

  void _handleBack() {
    if (_selectedControlFormType != null) {
      // Nivel 3 → Nivel 2
      setState(() {
        _selectedControlFormType = null;
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
        return ProductionBatchList(
          service: _productionBatchService,
          getAllowedDnis: _getAllowedProducerDnis,
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
            HistorialPeriodFilter(
              initial: HistorialPeriodo.esteMes,
              onChanged: (from, to) {
                setState(() { _startDate = from; _endDate = to; });
                _loadExitsData();
              },
            ),
            SizedBox(height: context.responsiveSpacing),
            HistorialExitsSection(
              exitsData: _exitsData,
              onAddGR: _addGRToExit,
            ),
          ],
        );

      // ── Formularios de control Módulo ─────────────────────────────────────────
      case 3:
        final connectivityAsync = ref.watch(connectivityProvider);
        return connectivityAsync.when(
          data: (isOnline) => _buildControlSection(isOnline, isModulo: true),
          loading: () => _buildControlSection(true, isModulo: true),
          error: (_, __) => _buildControlSection(false, isModulo: true),
        );

      // ── Formularios de control Producción ─────────────────────────────────────
      case 4:
        final connectivityAsync2 = ref.watch(connectivityProvider);
        return connectivityAsync2.when(
          data: (isOnline) => _buildControlSection(isOnline, isModulo: false),
          loading: () => _buildControlSection(true, isModulo: false),
          error: (_, __) => _buildControlSection(false, isModulo: false),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Enrutador de nivel 2 (submenú) y nivel 3 (contenido) para formularios.
  Widget _buildControlSection(bool isOnline, {required bool isModulo}) {
    if (_selectedControlFormType == null) {
      // Nivel 2: submenú de tipos de formulario
      return HistorialControlSubmenu(
        isOnline: isOnline,
        isModulo: isModulo,
        onFormTypeSelected: _onFormTypeSelected,
      );
    }
    // Nivel 3: contenido del formulario seleccionado
    return _buildControlFormContent();
  }

  /// Enrutador de contenido para cada tipo de formulario de control.
  Widget _buildControlFormContent() {
    final moduleIds = _allowedModuleIds;
    switch (_selectedControlFormType) {
      case 0:
        return EnvironmentInspectionList(
          service: _environmentInspectionService,
          allowedModuleIds: moduleIds,
        );
      case 1:
        return CleaningDisinfectionList(
          service: _cleaningDisinfectionService,
          allowedModuleIds: moduleIds,
        );
      case 2:
        return ChlorineControlList(
          service: _chlorineControlService,
          allowedModuleIds: moduleIds,
        );
      case 3:
        return PestControlList(
          service: _pestControlService,
          allowedModuleIds: moduleIds,
        );
      case 4:
        return HealthIncidentsList(
          service: _healthIncidentService,
          allowedModuleIds: moduleIds,
        );
      case 5:
        return StowageInspectionList(service: _inspectionService);
      case 6:
        return ProductReturnsList(service: _productReturnService);
      case 7:
        return WorkerControlList(service: _workerControlService, getAllowedDnis: _getAllowedProducerDnis);
      case 8:
        return MaintenanceControlList(
          service: _maintenanceService,
          allowedModuleIds: moduleIds,
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
