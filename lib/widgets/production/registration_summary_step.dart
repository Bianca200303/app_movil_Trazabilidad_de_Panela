import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_confirm_dialog.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/screens/success_registration_screen.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/models/producer.dart' as model;
import 'package:panela_sys/models/plot.dart' as model;
import 'package:panela_sys/models/batch_cert.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/services/production_batch_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/core/production_calculator.dart';
import 'package:panela_sys/core/batch_code_generator.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/widgets/common/app_snackbar.dart';

class RegistrationSummaryStep extends StatefulWidget {
  final AppDatabase db;
  final TextEditingController producerController;
  final TextEditingController plotController;
  final TextEditingController harvestDateController;
  final List<DateTime> additionalHarvestDates;
  final TextEditingController processingDateController;
  final TextEditingController juiceQuantityController;
  final TextEditingController panelaQuantityController;
  final TextEditingController confitilloQuantityController;
  final TextEditingController extractionPercentageController;
  final TextEditingController cachazaPercentageController;
  final TextEditingController initialPHController;
  final TextEditingController regulatorQuantityController;
  final TextEditingController regulatorUnitController;
  final TextEditingController finalPHController;
  final List<BatchCert> certificates;
  final Map<String, bool> selectedCertificates;
  final List<double> temperatures;
  final List<double?> timeBetweenMielesMinutes;
  final VoidCallback onBack;
  final double density;
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationText;
  final TextEditingController observationsController;

  const RegistrationSummaryStep({
    super.key,
    required this.db,
    required this.producerController,
    required this.plotController,
    required this.harvestDateController,
    this.additionalHarvestDates = const [],
    required this.processingDateController,
    required this.juiceQuantityController,
    required this.panelaQuantityController,
    required this.confitilloQuantityController,
    required this.extractionPercentageController,
    required this.cachazaPercentageController,
    required this.initialPHController,
    required this.regulatorQuantityController,
    required this.regulatorUnitController,
    required this.finalPHController,
    required this.certificates,
    required this.selectedCertificates,
    required this.temperatures,
    this.timeBetweenMielesMinutes = const [],
    required this.onBack,
    this.density = ProductionCalculator.sugarCaneDensity,
    this.locationLatitude,
    this.locationLongitude,
    this.locationText,
    required this.observationsController,
  });

  @override
  State<RegistrationSummaryStep> createState() => _RegistrationSummaryStepState();
}

class _RegistrationSummaryStepState extends State<RegistrationSummaryStep> {
  late final ProducerService _producerService;
  late final PlotService _plotService;
  late final ProductionBatchService _productionBatchService;
  late final CoopModulesService _coopModulesService;
  model.Producer? _selectedProducer;
  model.Plot? _selectedPlot;
  CoopModule? _selectedModule;
  bool _isLoadingProducer = false;
  bool _isLoadingPlot = false;
  bool _isLoadingModule = false;
  bool _isSaving = false;
  String? _generatedBatchCode;

  @override
  void initState() {
    super.initState();

    // Inject database into services for offline support
    _producerService = ProducerService(db: widget.db);
    _plotService = PlotService(db: widget.db);
    _productionBatchService = ProductionBatchService(db: widget.db);
    _coopModulesService = CoopModulesService(db: widget.db);

    _loadSelectedProducer();
    _loadSelectedPlot();
    _generateBatchCode();
  }

  Future<void> _loadSelectedModule() async {
    if (_selectedProducer == null) return;

    setState(() {
      _isLoadingModule = true;
    });

    try {
      final module = await _coopModulesService.getModuleById(_selectedProducer!.coopModuleId);
      setState(() {
        _selectedModule = module;
        _isLoadingModule = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingModule = false;
      });
    }
  }

  Future<void> _loadSelectedProducer() async {
    if (widget.producerController.text.isEmpty) return;

    setState(() {
      _isLoadingProducer = true;
    });

    try {
      final producer = await _producerService.getProducerById(widget.producerController.text);
      setState(() {
        _selectedProducer = producer;
        _isLoadingProducer = false;
      });
      // Load module after producer is loaded
      _loadSelectedModule();
    } catch (e) {
      setState(() {
        _isLoadingProducer = false;
      });
    }
  }

  Future<void> _loadSelectedPlot() async {
    if (widget.plotController.text.isEmpty) return;

    setState(() {
      _isLoadingPlot = true;
    });

    try {
      final plot = await _plotService.getPlotById(widget.plotController.text);
      setState(() {
        _selectedPlot = plot;
        _isLoadingPlot = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlot = false;
      });
    }
  }

  void _generateBatchCode() {
    if (widget.harvestDateController.text.isEmpty) return;

    final date = AppDateUtils.parseDDMMYYYY(widget.harvestDateController.text);
    if (date != null) {
      setState(() {
        _generatedBatchCode = BatchCodeGenerator.generate(
          cooperativePrefix: AppConfig.current.batchCodePrefix,
          harvestDate: date,
        );
        DebugLogger.info('RegistrationSummaryStep', '_generateBatchCode', 'Batch code generated: $_generatedBatchCode');
      });
    }
  }

  ProductionCalculations? get _calculations {
    final juiceLiters = double.tryParse(widget.juiceQuantityController.text);
    final panelaKg = double.tryParse(widget.panelaQuantityController.text);
    final confitilloKg = double.tryParse(widget.confitilloQuantityController.text);
    final extractionPercentage = double.tryParse(widget.extractionPercentageController.text);
    final cachazaPercentage = double.tryParse(widget.cachazaPercentageController.text);

    if (juiceLiters == null || juiceLiters <= 0 ||
        panelaKg == null || panelaKg < 0 ||
        confitilloKg == null || confitilloKg < 0 ||
        extractionPercentage == null || extractionPercentage <= 0 ||
        cachazaPercentage == null || cachazaPercentage < 0) {
      return null;
    }

    return ProductionCalculator.calculateAll(
      juiceLiters: juiceLiters,
      panelaKg: panelaKg,
      confitilloKg: confitilloKg,
      extractionPercentage: extractionPercentage,
      cachazaPercentage: cachazaPercentage,
      density: widget.density,
    );
  }

  List<String> get _selectedCertificateIds {
    return widget.selectedCertificates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> get _selectedCertificateNames {
    final selectedIds = _selectedCertificateIds;
    return widget.certificates
        .where((cert) => selectedIds.contains(cert.id))
        .map((cert) => cert.name)
        .toList();
  }

  String? _validateInputData() {
    // Validate pH values
    final phInitialText = widget.initialPHController.text;
    final phFinalText = widget.finalPHController.text;
    
    if (phInitialText.isEmpty) {
      return 'El pH inicial es obligatorio';
    }
    
    if (phFinalText.isEmpty) {
      return 'El pH final es obligatorio';
    }
    
    final phInitial = double.tryParse(phInitialText);
    final phFinal = double.tryParse(phFinalText);
    
    if (phInitial == null) {
      return 'El pH inicial debe ser un número válido';
    }
    
    if (phFinal == null) {
      return 'El pH final debe ser un número válido';
    }
    
    if (phInitial < 0 || phInitial > 14) {
      return 'El pH inicial debe estar entre 0 y 14';
    }
    
    if (phFinal < 0 || phFinal > 14) {
      return 'El pH final debe estar entre 0 y 14';
    }
    
    // Validate other required fields
    if (widget.producerController.text.isEmpty) {
      return 'Debe seleccionar un productor';
    }

    if (widget.harvestDateController.text.isEmpty) {
      return 'La fecha de cosecha es obligatoria';
    }

    if (widget.processingDateController.text.isEmpty) {
      return 'La fecha de proceso es obligatoria';
    }

    if (widget.juiceQuantityController.text.isEmpty) {
      return 'La cantidad de jugo es obligatoria';
    }

    if (widget.panelaQuantityController.text.isEmpty) {
      return 'La cantidad de panela es obligatoria';
    }

    if (widget.confitilloQuantityController.text.isEmpty) {
      return 'La cantidad de confitillo es obligatoria';
    }

    if (widget.extractionPercentageController.text.isEmpty) {
      return 'El porcentaje de extracción es obligatorio';
    }

    if (widget.cachazaPercentageController.text.isEmpty) {
      return 'El porcentaje de cachaza es obligatorio';
    }

    if (widget.regulatorQuantityController.text.isEmpty) {
      return 'La cantidad de regulador es obligatoria';
    }

    if (widget.regulatorUnitController.text.isEmpty) {
      return 'La unidad de regulador es obligatoria';
    }

    // Validate numeric values
    final juiceQuantity = double.tryParse(widget.juiceQuantityController.text);
    final panelaQuantity = double.tryParse(widget.panelaQuantityController.text);
    final confitilloQuantity = double.tryParse(widget.confitilloQuantityController.text);
    final extractionPercentage = double.tryParse(widget.extractionPercentageController.text);
    final cachazaPercentage = double.tryParse(widget.cachazaPercentageController.text);
    final regulatorQuantity = double.tryParse(widget.regulatorQuantityController.text);

    if (juiceQuantity == null || juiceQuantity <= 0) {
      return 'La cantidad de jugo debe ser un número positivo';
    }

    if (panelaQuantity == null || panelaQuantity < 0) {
      return 'La cantidad de panela debe ser un número no negativo';
    }

    if (confitilloQuantity == null || confitilloQuantity < 0) {
      return 'La cantidad de confitillo debe ser un número no negativo';
    }

    if (extractionPercentage == null || extractionPercentage <= 0 || extractionPercentage > 100) {
      return 'El porcentaje de extracción debe estar entre 0 y 100';
    }

    if (cachazaPercentage == null || cachazaPercentage < 0 || cachazaPercentage > 100) {
      return 'El porcentaje de cachaza debe estar entre 0 y 100';
    }

    if (regulatorQuantity == null || regulatorQuantity < 0) {
      return 'La cantidad de regulador debe ser un número no negativo';
    }
    
    return null;
  }

  Future<void> _saveProductionBatch() async {
    if (_isSaving) return;
    if (!await AppConfirmDialog.show(context)) return;
    if (!mounted || _isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      // Validate input data before proceeding
      final validationError = _validateInputData();
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Parse dates using the utility
      final harvestDate = AppDateUtils.parseDDMMYYYY(widget.harvestDateController.text);
      final processDate = AppDateUtils.parseDDMMYYYY(widget.processingDateController.text);
      
      if (harvestDate == null || processDate == null) {
        throw Exception('Las fechas deben tener formato DD/MM/YYYY');
      }

      final request = CreateProductionBatchRequest(
        batchCode: _generatedBatchCode, // Use pre-generated code from preview
        producerId: widget.producerController.text,
        plotId: widget.plotController.text.isNotEmpty ? widget.plotController.text : null,
        harvestDate: harvestDate,
        additionalHarvestDates: widget.additionalHarvestDates,
        processDate: processDate,
        juiceLiters: double.parse(widget.juiceQuantityController.text),
        panelaKg: double.parse(widget.panelaQuantityController.text),
        confitilloKg: double.parse(widget.confitilloQuantityController.text),
        extractionPercentage: double.parse(widget.extractionPercentageController.text),
        cachazaPercentage: double.parse(widget.cachazaPercentageController.text),
        selectedCertificateIds: _selectedCertificateIds,
        temperatures: widget.temperatures,
        timeBetweenMielesMinutes: widget.timeBetweenMielesMinutes,
        phInitial: double.parse(widget.initialPHController.text),
        phFinal: double.parse(widget.finalPHController.text),
        regulatorType: 'cal',
        regulatorQuantityValue: double.parse(widget.regulatorQuantityController.text),
        regulatorQuantityUnit: widget.regulatorUnitController.text,
        brix: null,
        correctiveAction: null,
        density: widget.density,
        latitude: widget.locationLatitude,
        longitude: widget.locationLongitude,
        locationText: widget.locationText,
        observations: widget.observationsController.text.trim().isEmpty
            ? null
            : widget.observationsController.text.trim(),
      );

      await _productionBatchService.createProductionBatch(request);
      final isOnline = await NetworkDetector().isConnected;

      if (mounted) {
        AppSnackBar.show(
          context,
          message: isOnline
              ? 'Lote de producción registrado exitosamente.'
              : 'Lote guardado localmente. Se sincronizará cuando recupere conexión.',
          type: isOnline ? SnackBarType.success : SnackBarType.info,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SuccessRegistrationScreen(
              type: RegistrationType.production,
            ),
          ),
        );
      }
    } catch (e) {
      // Regenerate batch code for next attempt to avoid duplicates
      _generateBatchCode();

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al registrar lote: $e',
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

  @override
  Widget build(BuildContext context) {
    return FormSection(
      children: [
        ProductionStepHeader(
          title: 'Registro de producción',
          onBack: widget.onBack,
        ),
        SizedBox(height: context.responsiveSpacing),
        Text(
          'Información registrada',
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: context.responsiveSpacing * 0.5),
        ..._buildSummaryRows(context),
        SizedBox(height: context.responsiveSpacing),
        Text(
          'Observaciones (opcional)',
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: context.responsiveSpacing * 0.5),
        TextField(
          controller: widget.observationsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ingrese observaciones sobre este lote...',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        AppButton(
          text: _isSaving ? 'GUARDANDO...' : 'GUARDAR LOTE',
          onPressed: _isSaving ? null : _saveProductionBatch,
          isLoading: _isSaving,
        ),
      ],
    );
  }

  String _getLocationDisplayText() {
    if (widget.locationText != null && widget.locationText!.isNotEmpty) {
      return widget.locationText!;
    }
    if (widget.locationLatitude != null && widget.locationLongitude != null) {
      return '${widget.locationLatitude!.toStringAsFixed(4)}, ${widget.locationLongitude!.toStringAsFixed(4)}';
    }
    return 'No registrada';
  }

  List<Widget> _buildSummaryRows(BuildContext context) {
    final selectedCerts = _selectedCertificateNames;
    final certText = selectedCerts.isNotEmpty ? selectedCerts.join(', ') : 'Ninguna seleccionada';

    final tempText = widget.temperatures.isNotEmpty
        ? widget.temperatures.asMap().entries.map((entry) {
            final minutes = entry.key < widget.timeBetweenMielesMinutes.length
                ? widget.timeBetweenMielesMinutes[entry.key]
                : null;
            final tempStr = '${entry.value.toStringAsFixed(1)}°C';
            return minutes != null ? '$tempStr (${minutes.toStringAsFixed(0)} min)' : tempStr;
          }).join(', ')
        : 'No registradas';

    final plotText = _isLoadingPlot
        ? 'Cargando...'
        : (_selectedPlot != null
            ? '${_selectedPlot!.name} (${_selectedPlot!.code})'
            : 'No especificada');

    final moduleText = _isLoadingModule
        ? 'Cargando...'
        : (_selectedModule?.name ?? 'No especificado');

    // Build summary items list
    final summaryItems = <List<String>>[
      ['Productor:', _isLoadingProducer ? 'Cargando...' : (_selectedProducer?.fullName ?? 'No especificado')],
      ['Módulo:', moduleText],
    ];

    // Add APPAGROP code only if feature is enabled
    if (AppConfig.current.features.useAppagropCode) {
      summaryItems.add([
        'APPAGROP:',
        _selectedProducer?.appagropCode ?? 'No especificado'
      ]);
    }

    // Get calculations (or use zeros if invalid)
    final calc = _calculations;

    // Continue with remaining fields
    summaryItems.addAll([
      ['Parcela:', plotText],
      ['Fecha de proceso:', widget.processingDateController.text.isNotEmpty ? widget.processingDateController.text : 'No especificada'],
      ['Fecha de corte:', widget.harvestDateController.text.isNotEmpty ? widget.harvestDateController.text : 'No especificada'],
      if (widget.additionalHarvestDates.isNotEmpty)
        ['Fechas de corte adicionales:', widget.additionalHarvestDates.map((d) => AppDateUtils.formatDDMMYYYY(d)).join(', ')],
      ['Certificaciones:', certText],
      ['Cantidad de caña:', '${(calc?.caneKg ?? 0.0).toStringAsFixed(2)} kg'],
      ['Cantidad de jugo:', widget.juiceQuantityController.text.isNotEmpty ? '${widget.juiceQuantityController.text} L' : '0 L'],
      ['Cantidad de panela:', widget.panelaQuantityController.text.isNotEmpty ? '${widget.panelaQuantityController.text} kg' : '0 kg'],
      ['Cantidad de confitillo:', widget.confitilloQuantityController.text.isNotEmpty ? '${widget.confitilloQuantityController.text} kg' : '0 kg'],
      ['% de extracción:', widget.extractionPercentageController.text.isNotEmpty ? '${widget.extractionPercentageController.text}%' : '0%'],
      ['% de cachaza:', widget.cachazaPercentageController.text.isNotEmpty ? '${widget.cachazaPercentageController.text}%' : '0%'],
      ['Peso de jugo:', '${(calc?.juiceWeightKg ?? 0.0).toStringAsFixed(2)} kg'],
      ['Bagazo:', '${(calc?.bagazoKg ?? 0.0).toStringAsFixed(2)} kg'],
      ['Cachaza:', '${(calc?.cachazaKg ?? 0.0).toStringAsFixed(2)} kg'],
      ['Rendimiento:', '${(calc?.rendimientoPercentage ?? 0.0).toStringAsFixed(2)}%'],
      ['Pérdida de agua:', '${(calc?.perdidaAguaKg ?? 0.0).toStringAsFixed(2)} kg'],
      ['pH inicial:', widget.initialPHController.text.isNotEmpty ? widget.initialPHController.text : '0'],
      ['Regulador pH:', widget.regulatorQuantityController.text.isNotEmpty ? '${widget.regulatorQuantityController.text} ${widget.regulatorUnitController.text}' : '0 gr'],
      ['pH final:', widget.finalPHController.text.isNotEmpty ? widget.finalPHController.text : '0'],
      ['Temperaturas:', tempText],
      ['Ubicación:', _getLocationDisplayText()],
    ]);

    List<Widget> widgets = [];
    for (var item in summaryItems) {
      // Check if this is a multi-value field that needs wrapping
      final isMultiValueField = item[0] == 'Certificaciones:' || item[0] == 'Temperaturas:' || item[0] == 'Fechas de corte adicionales:';

      widgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item[0], style: AppTextStyles.bodyText),
            Expanded(
              child: Text(
                item[1],
                style: AppTextStyles.bodyText,
                textAlign: TextAlign.right,
                // Remove ellipsis for multi-value fields to allow wrapping
                overflow: isMultiValueField ? null : TextOverflow.ellipsis,
                softWrap: isMultiValueField,
              ),
            ),
          ],
        ),
      );
      widgets.add(
        Divider(
          height: context.responsiveSpacing,
          color: AppColors.border,
        ),
      );
    }

    return widgets;
  }

}
