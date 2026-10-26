import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/module_search_field.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_confirm_dialog.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/models/current_user.dart';
import 'package:panela_sys/models/producer.dart';
import 'package:panela_sys/models/plot.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/services/location_service.dart';
import 'package:panela_sys/models/producer_quota_status.dart';
import 'package:panela_sys/widgets/plots/plot_form_sheet.dart';

class ProducerSelectionStep extends ConsumerStatefulWidget {
  final TextEditingController producerController;
  final TextEditingController plotController;
  final TextEditingController extractionPercentageController;
  final TextEditingController cachazaPercentageController;
  /// Si es false, % de extracción y % de cachaza se muestran con el valor
  /// por defecto (parcela > productor > sistema) y no se pueden editar.
  /// Estos porcentajes deben reflejar la medición real del técnico de campo
  /// en planta, por lo que otros roles (ej. Admin de módulo) solo los ven.
  final bool canEditYieldPercentages;
  final Producer? selectedProducer;
  final Plot? selectedPlot;
  /// Resultado de la verificación de cupos del productor seleccionado.
  /// null mientras carga o cuando no hay productor/parcela seleccionados.
  final QuotaCheckResult? quotaResult;
  final bool isLoadingQuota;
  final VoidCallback onContinue;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationText;
  final ValueChanged<LocationResult> onLocationChanged;
  final ValueChanged<String> onLocationTextChanged;

  const ProducerSelectionStep({
    super.key,
    required this.producerController,
    required this.plotController,
    required this.extractionPercentageController,
    required this.cachazaPercentageController,
    this.canEditYieldPercentages = true,
    this.selectedProducer,
    this.selectedPlot,
    this.quotaResult,
    this.isLoadingQuota = false,
    required this.onContinue,
    this.locationLatitude,
    this.locationLongitude,
    this.locationText,
    required this.onLocationChanged,
    required this.onLocationTextChanged,
  });

  @override
  ConsumerState<ProducerSelectionStep> createState() => _ProducerSelectionStepState();
}

class _ProducerSelectionStepState extends ConsumerState<ProducerSelectionStep> {
  late final ProducerService _producerService;
  late final PlotService _plotService;
  late final CoopModulesService _modulesService;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Producer> _producers = [];
  List<Plot> _plots = [];
  List<CoopModule> _assignedModules = [];
  String? _selectedModuleId;
  bool _isLoadingProducers = false;
  bool _isLoadingPlots = false;
  String? _errorMessage;
  bool _isLoadingLocation = false;
  String? _locationError;
  bool _isEditingLocation = false;
  final TextEditingController _manualLocationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  // IDs de cupos excedidos para los que ya se mostró el dialog (evita re-mostrar)
  final Set<String> _exceededDialogShownIds = {};

  List<Producer> get _filteredProducers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _producers;
    return _producers.where((p) =>
      p.fullName.toLowerCase().contains(q) || p.dni.contains(q),
    ).toList();
  }

  @override
  void didUpdateWidget(ProducerSelectionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El padre resuelve selectedProducer/selectedPlot de forma asíncrona tras
    // la selección; cuando cambian, refrescamos el valor por defecto bloqueado.
    if (!widget.canEditYieldPercentages &&
        (widget.selectedProducer != oldWidget.selectedProducer ||
            widget.selectedPlot != oldWidget.selectedPlot)) {
      _applyDefaultPercentagesIfLocked();
    }

    // Mostrar dialog cuando llega un resultado con cupos excedidos.
    // Se usa addPostFrameCallback para no disparar showDialog durante un build.
    if (widget.quotaResult != oldWidget.quotaResult &&
        widget.quotaResult != null &&
        widget.quotaResult!.hasExceeded) {
      final newExceededIds = widget.quotaResult!.statuses
          .where((s) => s.superado)
          .map((s) => s.quotaId)
          .toSet();
      final hasNew = newExceededIds.any((id) => !_exceededDialogShownIds.contains(id));
      if (hasNew) {
        _exceededDialogShownIds.addAll(newExceededIds);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showExceededDialog(widget.quotaResult!);
        });
      }
    }

    // Limpiar tracking cuando cambia productor/parcela (cupo vuelve a null)
    if (widget.quotaResult == null && oldWidget.quotaResult != null) {
      _exceededDialogShownIds.clear();
    }
  }

  @override
  void initState() {
    super.initState();

    // Inject database from providers for offline support
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _plotService = PlotService(db: db);
    _modulesService = CoopModulesService(db: db);

    final currentUser = ref.read(currentUserProvider);
    _initModules(currentUser);
    // Restaurar parcelas si ya hay productor seleccionado (usuario regresó)
    if (widget.producerController.text.isNotEmpty) {
      _loadPlotsForProducer(widget.producerController.text, clearSelection: false);
    }
    _applyDefaultPercentagesIfLocked();

    // Restore manual location text if returning to this step
    if (widget.locationText != null) {
      _manualLocationController.text = widget.locationText!;
    }

    // Auto-detect location if not already obtained
    if (widget.locationLatitude == null && widget.locationText == null) {
      _detectLocation();
    }
  }

  @override
  void dispose() {
    _manualLocationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    final result = await LocationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _isLoadingLocation = false;
      if (result.hasCoordinates) {
        _locationError = null;
        _isEditingLocation = false;
      } else {
        _locationError = result.errorMessage;
        _isEditingLocation = true;
      }
    });

    widget.onLocationChanged(result);
  }

  Future<void> _initModules(CurrentUser? currentUser) async {
    try {
      final all = await _modulesService.getModules();

      // Técnico/admin de módulo → solo sus módulos asignados
      // Admin sistema u otros sin restricción → todos los módulos
      final available = (currentUser?.hasModuleRestriction == true &&
              currentUser!.moduleIds.isNotEmpty)
          ? all.where((m) => currentUser.moduleIds.contains(m.id)).toList()
          : all;

      if (!mounted) return;
      setState(() => _assignedModules = available);

      if (available.length == 1) {
        // Un solo módulo disponible → auto-seleccionar y cargar productores
        setState(() => _selectedModuleId = available.first.id);
        _loadProducers();
      } else if (available.isEmpty) {
        // Sin módulos configurados → cargar todos como fallback
        _loadProducers();
      }
      // Múltiples módulos → esperar selección del usuario en el dropdown
    } catch (_) {
      if (mounted) _loadProducers();
    }
  }

  void _onModuleChanged(String? moduleId) {
    _searchController.clear();
    setState(() {
      _selectedModuleId = moduleId;
      widget.producerController.clear();
      widget.plotController.clear();
      _producers = [];
      _plots = [];
    });
    if (moduleId != null) _loadProducers();
  }

  Future<void> _loadProducers() async {
    setState(() {
      _isLoadingProducers = true;
      _errorMessage = null;
    });

    try {
      var producers = await _producerService.getProducersForDropdown();
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.hasModuleRestriction == true && currentUser!.moduleIds.isNotEmpty) {
        producers = producers
            .where((p) => currentUser.moduleIds.contains(p.coopModuleId))
            .toList();
      }
      if (_selectedModuleId != null) {
        producers = producers.where((p) => p.coopModuleId == _selectedModuleId).toList();
      }
      setState(() {
        _producers = producers;
        _isLoadingProducers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingProducers = false;
      });
    }
  }

  Future<void> _loadPlotsForProducer(String producerId, {bool clearSelection = true}) async {
    setState(() {
      _isLoadingPlots = true;
      _plots = [];
      if (clearSelection) {
        widget.plotController.clear();
      }
    });

    try {
      // Use cache-first method for offline support
      final plots = await _plotService.getPlotsForDropdown(producerId);
      setState(() {
        _plots = plots;
        _isLoadingPlots = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingPlots = false;
      });
    }
  }

  /// Administradores con un productor ya sincronizado (id remoto, no
  /// entero local) pueden agregar una parcela sin salir del registro.
  bool get _canAddPlot =>
      (ref.read(currentUserProvider)?.canManagePlots ?? false) &&
      int.tryParse(widget.producerController.text) == null;

  Future<void> _addPlot() async {
    final producerId = widget.producerController.text;
    final producer = widget.selectedProducer;
    final saved = await showPlotFormSheet(
      context,
      producerId: producerId,
      producerName: producer == null
          ? 'Productor'
          : '${producer.firstName} ${producer.lastName}',
      existingNames: _plots.map((p) => p.name),
    );
    if (saved == null || !mounted) return;
    await _loadPlotsForProducer(producerId, clearSelection: false);
    if (!mounted) return;
    // Queda elegida para seguir con el registro.
    setState(() => widget.plotController.text = saved.id);
  }

  void _onProducerChanged(String? newProducerId) {
    setState(() {
      widget.producerController.text = newProducerId ?? '';
      widget.plotController.clear();
      _plots = [];
    });

    if (newProducerId != null && newProducerId.isNotEmpty) {
      _loadPlotsForProducer(newProducerId);
    }
  }

  bool get _canContinue {
    return widget.producerController.text.isNotEmpty &&
           widget.plotController.text.isNotEmpty &&
           widget.extractionPercentageController.text.isNotEmpty &&
           widget.cachazaPercentageController.text.isNotEmpty &&
           !_isLoadingProducers &&
           !_isLoadingPlots;
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onContinue();
    }
  }

  String? _validatePercentage(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Ingrese el $fieldName';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Debe ser un número válido';
    }

    if (number < 0 || number > 100) {
      return 'Debe estar entre 0 y 100';
    }

    return null;
  }

  /// Resuelve el valor por defecto de un porcentaje de rendimiento
  /// (parcela > productor > sistema), usado cuando el rol actual no puede
  /// editar manualmente % de extracción/cachaza.
  double _resolveDefaultPercentage(String fieldType) {
    if (fieldType == 'extraction') {
      return widget.selectedPlot?.defaultExtractionPercentage ??
          widget.selectedProducer?.defaultExtractionPercentage ??
          62.5;
    }
    return widget.selectedPlot?.defaultCachazaPercentage ??
        widget.selectedProducer?.defaultCachazaPercentage ??
        2.5;
  }

  /// Aplica los valores por defecto a los controllers cuando el usuario no
  /// puede editarlos manualmente, para que el formulario siga siendo válido.
  void _applyDefaultPercentagesIfLocked() {
    if (widget.canEditYieldPercentages) return;
    widget.extractionPercentageController.text =
        _resolveDefaultPercentage('extraction').toString();
    widget.cachazaPercentageController.text =
        _resolveDefaultPercentage('cachaza').toString();
  }

  /// Técnicos y administradores de módulo que además son productores
  /// pueden registrar su propia producción: se marca "(usted)" para que
  /// quede claro a quién se le está registrando.
  String _displayName(Producer p) {
    final currentDni = ref.read(currentUserProvider)?.dni;
    return p.dni == currentDni ? '${p.fullName} (usted)' : p.fullName;
  }

  String _getDefaultHintText(String fieldType) {
    if (fieldType == 'extraction') {
      // Priority: plot -> producer -> system
      if (widget.selectedPlot?.defaultExtractionPercentage != null) {
        return 'Valor por defecto (parcela): ${widget.selectedPlot!.defaultExtractionPercentage}%';
      } else if (widget.selectedProducer != null) {
        return 'Valor por defecto (productor): ${widget.selectedProducer!.defaultExtractionPercentage}%';
      } else {
        return 'Valor por defecto (sistema): 62.5%';
      }
    } else {
      // cachaza
      if (widget.selectedPlot?.defaultCachazaPercentage != null) {
        return 'Valor por defecto (parcela): ${widget.selectedPlot!.defaultCachazaPercentage}%';
      } else if (widget.selectedProducer != null) {
        return 'Valor por defecto (productor): ${widget.selectedProducer!.defaultCachazaPercentage}%';
      } else {
        return 'Valor por defecto (sistema): 2.5%';
      }
    }
  }

  void _showExceededDialog(QuotaCheckResult result) {
    final exceeded = result.statuses.where((s) => s.superado).toList();
    // Solo informa: ambas opciones cierran el aviso y dejan seguir.
    AppConfirmDialog.choose<void>(
      context,
      title: 'Cupo superado',
      message: 'Este productor ha superado el cupo autorizado por la certificadora. '
          'Registrar esta producción puede incumplir los requisitos de certificación.',
      tone: AppDialogTone.danger,
      details: Column(
        children: exceeded.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.certName,
                  style: AppTextStyles.captionText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXSmall),
                Text(
                  'Cupo: ${s.cupoKg.toStringAsFixed(1)} kg  •  '
                  'Producido: ${s.acumuladoKg.toStringAsFixed(1)} kg  •  '
                  '+${(s.acumuladoKg - s.cupoKg).toStringAsFixed(1)} kg',
                  style: AppTextStyles.captionText.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
      actions: const [
        AppDialogAction('Cancelar', null),
        AppDialogAction('Continuar de todas formas', null, style: AppDialogActionStyle.destructive),
      ],
    );
  }

  Widget _buildQuotaBanner(BuildContext context) {
    if (widget.isLoadingQuota) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXSmall),
        child: Row(
          children: [
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Text(
              'Verificando cupo...',
              style: AppTextStyles.captionText.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final result = widget.quotaResult;
    if (result == null) return const SizedBox.shrink();

    if (result.isOffline) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: AppDimensions.iconXSmall, color: AppColors.textSecondary),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(
              child: Text(
                'No se pudo verificar el cupo. Se requiere conexión.',
                style: AppTextStyles.captionText.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (!result.hasQuotas) return const SizedBox.shrink();

    final level = result.hasExceeded
        ? QuotaStatusLevel.exceeded
        : result.hasWarning
            ? QuotaStatusLevel.warning
            : QuotaStatusLevel.ok;

    final bgColor = level == QuotaStatusLevel.exceeded
        ? AppColors.errorLight
        : level == QuotaStatusLevel.warning
            ? AppColors.warningLight
            : AppColors.successLight;

    final borderColor = level == QuotaStatusLevel.exceeded
        ? AppColors.error
        : level == QuotaStatusLevel.warning
            ? AppColors.warning
            : AppColors.success;

    final icon = level == QuotaStatusLevel.exceeded
        ? Icons.error_rounded
        : level == QuotaStatusLevel.warning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded;

    final title = level == QuotaStatusLevel.exceeded
        ? '¡Cupo superado!'
        : level == QuotaStatusLevel.warning
            ? 'Cupo próximo a agotarse'
            : 'Cupo disponible';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: EdgeInsets.all(context.responsiveSpacing * 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor, size: AppDimensions.iconSmall),
              const SizedBox(width: AppDimensions.spacingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          ...result.statuses.map((s) => _buildQuotaRow(s, borderColor)),
        ],
      ),
    );
  }

  Widget _buildQuotaRow(ProducerQuotaStatus s, Color accentColor) {
    final progress = (s.porcentajeUsado / 100).clamp(0.0, 1.0);
    final isExceeded = s.statusLevel == QuotaStatusLevel.exceeded;
    final rowColor = isExceeded ? AppColors.error : accentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.certName,
            style: AppTextStyles.captionText.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXSmall),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(rowColor),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXSmall),
          // Flexible evita overflow: el texto largo cede espacio al badge de estado
          Row(
            children: [
              Flexible(
                child: Text(
                  'Producido: ${s.acumuladoKg.toStringAsFixed(1)} kg  /  '
                  'Cupo: ${s.cupoKg.toStringAsFixed(1)} kg',
                  style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              Text(
                isExceeded
                    ? '+${(s.acumuladoKg - s.cupoKg).toStringAsFixed(1)} kg'
                    : '${s.disponibleKg.toStringAsFixed(1)} kg libre',
                style: AppTextStyles.captionText.copyWith(
                  color: rowColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProducerSearch() {
    final selected = widget.producerController.text.isNotEmpty
        ? _producers.where((p) => p.id == widget.producerController.text).firstOrNull
        : null;

    if (selected != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success, width: 1.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          color: AppColors.successLight,
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName(selected),
                    style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'DNI ${selected.dni}',
                    style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _onProducerChanged(null);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredProducers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          hintText: 'Buscar por nombre o DNI',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () => setState(() => _searchController.clear()),
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          '${filtered.length} productor${filtered.length == 1 ? '' : 'es'}',
          style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Center(
                    child: Text(
                      'No se encontraron productores',
                      style: AppTextStyles.bodyText,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return InkWell(
                      onTap: () {
                        _searchController.clear();
                        _onProducerChanged(p.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName(p),
                                    style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'DNI ${p.dni}',
                                    style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FormSection(
        children: [
        // Back button for home navigation
        AppBackButton(
          onPressed: () => context.go(AppRoutes.home.path),
          isExpanded: true,
        ),
        SizedBox(height: context.responsiveSpacing),
        Text(
          'Registro de producción',
          style: AppTextStyles.mainTitle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.responsiveSpacing * 0.5),
        Text(
          'Seleccione el productor que realizó la producción',
          style: AppTextStyles.bodyText,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        if (_assignedModules.length > 1) ...[
          ModuleSearchField(
            label: 'Seleccione el módulo',
            modules: _assignedModules,
            selectedModuleId: _selectedModuleId,
            hintText: 'Buscar módulo...',
            onChanged: _onModuleChanged,
          ),
          SizedBox(height: context.responsiveSpacing),
        ],
        if (_assignedModules.length > 1 && _selectedModuleId == null)
          Text(
            'Seleccione un módulo para ver sus productores',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          )
        else if (_isLoadingProducers)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_errorMessage != null)
          Column(
            children: [
              Text(
                'Error: $_errorMessage',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsiveSpacing),
              AppButton(
                text: 'Reintentar',
                onPressed: _loadProducers,
                type: AppButtonType.secondary,
              ),
            ],
          )
        else
          Column(
            children: [
              _buildProducerSearch(),
              if (widget.producerController.text.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing),
                if (_isLoadingPlots)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_plots.isEmpty)
                  Text(
                    _canAddPlot
                        ? 'Este productor no tiene parcelas activas. Agregue una para continuar.'
                        : 'Este productor no tiene parcelas activas. Pida a un administrador que agregue una.',
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.primaryDark),
                    textAlign: TextAlign.center,
                  )
                else
                  AppDropdown<String>(
                    label: 'Seleccione la parcela',
                    value: widget.plotController.text.isNotEmpty ? widget.plotController.text : null,
                    hintText: 'Seleccionar parcela',
                    options: _plots
                        .map((plot) => DropdownOption(
                              value: plot.id,
                              label: '${plot.name} (${plot.code})',
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        widget.plotController.text = newValue ?? '';
                      });
                    },
                  ),
                if (!_isLoadingPlots && _canAddPlot)
                  Align(
                    alignment: _plots.isEmpty ? Alignment.center : Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addPlot,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Agregar parcela'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ),
              ],
              if (widget.plotController.text.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing * 1.5),
                _buildQuotaBanner(context),
                SizedBox(height: context.responsiveSpacing),
                Text(
                  'Porcentajes de producción',
                  style: AppTextStyles.sectionTitle,
                ),
                SizedBox(height: context.responsiveSpacing),
                AppTextField(
                  controller: widget.extractionPercentageController,
                  label: 'Ingrese el % de extracción (%)',
                  hintText: _getDefaultHintText('extraction'),
                  helperText: widget.canEditYieldPercentages
                      ? null
                      : 'Solo editable por el técnico de campo',
                  enabled: widget.canEditYieldPercentages,
                  keyboardType: TextInputType.number,
                  validator: (value) => _validatePercentage(value, '% de extracción'),
                ),
                SizedBox(height: context.responsiveSpacing),
                AppTextField(
                  controller: widget.cachazaPercentageController,
                  label: 'Ingrese el % de cachaza (%)',
                  hintText: _getDefaultHintText('cachaza'),
                  helperText: widget.canEditYieldPercentages
                      ? null
                      : 'Solo editable por el técnico de campo',
                  enabled: widget.canEditYieldPercentages,
                  keyboardType: TextInputType.number,
                  validator: (value) => _validatePercentage(value, '% de cachaza'),
                ),
              ],
            ],
          ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        _buildLocationSection(context),
        SizedBox(height: context.responsiveSpacing * 1.5),
        AppButton(
          text: 'Continuar',
          onPressed: _canContinue ? _handleContinue : null,
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        Text(
          'Requerimiento de campos obligatorios',
          style: AppTextStyles.bodyTextSecondary.copyWith(
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    // Acciones de texto: el texto se ajusta en varias líneas en vez de
    // desbordarse en pantallas angostas.
    Widget action(IconData icon, String label, VoidCallback onTap) => TextButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label, textAlign: TextAlign.start),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
            alignment: Alignment.centerLeft,
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall + AppDimensions.paddingXSmall),
      decoration: BoxDecoration(
        color: AppColors.infoLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ubicación del registro',
                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingLocation)
            Row(
              children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detectando ubicación...',
                    style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            )
          else if (_isEditingLocation || (_locationError != null && widget.locationLatitude == null))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _locationError!,
                      style: AppTextStyles.captionText.copyWith(color: AppColors.warning),
                    ),
                  ),
                AppTextField(
                  controller: _manualLocationController,
                  label: 'Escriba la ubicación',
                  hintText: 'Ej: Finca El Roble',
                  onChanged: (value) {
                    widget.onLocationTextChanged(value);
                  },
                ),
                const SizedBox(height: 4),
                action(Icons.refresh, 'Reintentar detección automática', _detectLocation),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ubicación detectada (${widget.locationLatitude?.toStringAsFixed(4)}, ${widget.locationLongitude?.toStringAsFixed(4)})',
                        style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                action(
                  Icons.edit_outlined,
                  'Corregir ubicación manualmente',
                  () => setState(() => _isEditingLocation = true),
                ),
              ],
            ),
        ],
      ),
    );
  }
}