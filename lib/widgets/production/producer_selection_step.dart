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
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

class ProducerSelectionStep extends ConsumerStatefulWidget {
  final TextEditingController producerController;
  final TextEditingController plotController;
  final TextEditingController extractionPercentageController;
  final TextEditingController cachazaPercentageController;
  final Producer? selectedProducer;
  final Plot? selectedPlot;
  final VoidCallback onContinue;

  const ProducerSelectionStep({
    super.key,
    required this.producerController,
    required this.plotController,
    required this.extractionPercentageController,
    required this.cachazaPercentageController,
    this.selectedProducer,
    this.selectedPlot,
    required this.onContinue,
  });

  @override
  ConsumerState<ProducerSelectionStep> createState() => _ProducerSelectionStepState();
}

class _ProducerSelectionStepState extends ConsumerState<ProducerSelectionStep> {
  late final ProducerService _producerService;
  late final PlotService _plotService;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<Producer> _producers = [];
  List<Plot> _plots = [];
  bool _isLoadingProducers = false;
  bool _isLoadingPlots = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Inject database from providers for offline support
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _plotService = PlotService(db: db);

    _loadProducers();
    // Restaurar parcelas si ya hay productor seleccionado (usuario regresó)
    if (widget.producerController.text.isNotEmpty) {
      _loadPlotsForProducer(widget.producerController.text, clearSelection: false);
    }
  }

  Future<void> _loadProducers() async {
    setState(() {
      _isLoadingProducers = true;
      _errorMessage = null;
    });

    try {
      var producers = await _producerService.getProducersForDropdown();
      // Restrict to assigned modules for adminModulo
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.hasModuleRestriction == true && currentUser!.moduleIds.isNotEmpty) {
        producers = producers
            .where((p) => currentUser.moduleIds.contains(p.coopModuleId))
            .toList();
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
        if (_isLoadingProducers)
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
              AppDropdown<String>(
                label: 'Seleccione el productor',
                value: widget.producerController.text.isNotEmpty ? widget.producerController.text : null,
                hintText: 'Seleccionar productor',
                options: _producers
                    .map((producer) => DropdownOption(
                          value: producer.id,
                          label: '${producer.fullName} (${producer.dni})',
                        ))
                    .toList(),
                onChanged: _onProducerChanged,
              ),
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
}