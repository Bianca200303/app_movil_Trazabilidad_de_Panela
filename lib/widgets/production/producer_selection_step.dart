import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:go_router/go_router.dart';
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

class ProducerSelectionStep extends ConsumerStatefulWidget {
  final TextEditingController producerController;
  final TextEditingController plotController;
  final TextEditingController extractionPercentageController;
  final TextEditingController cachazaPercentageController;
  final Producer? selectedProducer;
  final Plot? selectedPlot;
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
    this.selectedProducer,
    this.selectedPlot,
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

  List<Producer> get _filteredProducers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _producers;
    return _producers.where((p) =>
      p.fullName.toLowerCase().contains(q) || p.dni.contains(q),
    ).toList();
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
    if (currentUser != null && currentUser.moduleIds.length > 1) {
      _loadAssignedModules(currentUser.moduleIds);
    } else {
      if (currentUser != null && currentUser.moduleIds.length == 1) {
        _selectedModuleId = currentUser.moduleIds.first;
      }
      _loadProducers();
    }
    // Restaurar parcelas si ya hay productor seleccionado (usuario regresó)
    if (widget.producerController.text.isNotEmpty) {
      _loadPlotsForProducer(widget.producerController.text, clearSelection: false);
    }

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

  Future<void> _loadAssignedModules(List<String> moduleIds) async {
    try {
      final all = await _modulesService.getModules();
      setState(() {
        _assignedModules = all.where((m) => moduleIds.contains(m.id)).toList();
      });
    } catch (_) {}
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

  Widget _buildProducerSearch() {
    final selected = widget.producerController.text.isNotEmpty
        ? _producers.where((p) => p.id == widget.producerController.text).firstOrNull
        : null;

    if (selected != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2E7D32), width: 2),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF1F8E9),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF2E7D32), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'DNI: ${selected.dni}',
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _onProducerChanged(null);
              },
              child: const Text(
                'Cambiar',
                style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredProducers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.black, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o DNI',
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black54),
                    onPressed: () => setState(() => _searchController.clear()),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${filtered.length} productor${filtered.length == 1 ? '' : 'es'}',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBDBDBD)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No se encontraron productores',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return InkWell(
                      onTap: () {
                        _searchController.clear();
                        _onProducerChanged(p.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: Colors.black54),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'DNI: ${p.dni}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
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
          AppDropdown<String>(
            label: 'Seleccione el módulo',
            value: _selectedModuleId,
            hintText: 'Seleccionar módulo',
            options: _assignedModules
                .map((m) => DropdownOption(value: m.id, label: m.name))
                .toList(),
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
                text: 'REINTENTAR',
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
                    'Este productor no tiene parcelas registradas',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
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
              ],
              if (widget.plotController.text.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing * 1.5),
                Text(
                  'Porcentajes de producción',
                  style: AppTextStyles.sectionTitle,
                ),
                SizedBox(height: context.responsiveSpacing),
                AppTextField(
                  controller: widget.extractionPercentageController,
                  label: 'Ingrese el % de extracción (%)',
                  hintText: _getDefaultHintText('extraction'),
                  keyboardType: TextInputType.number,
                  validator: (value) => _validatePercentage(value, '% de extracción'),
                ),
                SizedBox(height: context.responsiveSpacing),
                AppTextField(
                  controller: widget.cachazaPercentageController,
                  label: 'Ingrese el % de cachaza (%)',
                  hintText: _getDefaultHintText('cachaza'),
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
          text: 'CONTINUAR',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Ubicación del registro',
                style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
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
                Text(
                  'Detectando ubicación...',
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
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
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                AppTextField(
                  controller: _manualLocationController,
                  label: 'Escriba la ubicación',
                  hintText: 'Ej: Finca El Roble, Vereda La Esperanza',
                  onChanged: (value) {
                    widget.onLocationTextChanged(value);
                  },
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _detectLocation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Reintentar detección automática',
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ubicación detectada (${widget.locationLatitude?.toStringAsFixed(4)}, ${widget.locationLongitude?.toStringAsFixed(4)})',
                        style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingLocation = true;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Corregir ubicación manualmente',
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}