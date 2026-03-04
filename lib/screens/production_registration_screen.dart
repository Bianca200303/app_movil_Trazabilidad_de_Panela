import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/production/producer_selection_step.dart';
import 'package:panela_sys/widgets/production/date_selection_step.dart';
import 'package:panela_sys/widgets/production/sugar_cane_type_step.dart';
import 'package:panela_sys/widgets/production/results_input_step.dart';
import 'package:panela_sys/widgets/production/sugar_cane_details_step.dart';
import 'package:panela_sys/widgets/production/ph_control_step.dart';
import 'package:panela_sys/widgets/production/temperature_control_step.dart';
import 'package:panela_sys/widgets/production/registration_summary_step.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/models/batch_cert.dart';
import 'package:panela_sys/services/batch_cert_service.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/models/producer.dart';
import 'package:panela_sys/models/plot.dart';
import 'package:panela_sys/providers/offline_provider.dart';

class ProductionRegistrationScreen extends ConsumerStatefulWidget {
  const ProductionRegistrationScreen({super.key});

  @override
  ConsumerState<ProductionRegistrationScreen> createState() => _ProductionRegistrationScreenState();
}

class _ProductionRegistrationScreenState extends ConsumerState<ProductionRegistrationScreen> {
  // Controllers for the different screens in the flow
  final TextEditingController _producerController = TextEditingController();
  final TextEditingController _plotController = TextEditingController();
  final TextEditingController _harvestDateController = TextEditingController();
  final TextEditingController _processingDateController = TextEditingController();
  final TextEditingController _juiceQuantityController = TextEditingController();
  final TextEditingController _panelaQuantityController = TextEditingController();
  final TextEditingController _confitilloQuantityController = TextEditingController();
  final TextEditingController _extractionPercentageController = TextEditingController();
  final TextEditingController _cachazaPercentageController = TextEditingController();
  final TextEditingController _initialPHController = TextEditingController();
  final TextEditingController _regulatorQuantityController = TextEditingController();
  final TextEditingController _regulatorUnitController = TextEditingController();
  final TextEditingController _finalPHController = TextEditingController();

  // Variables for batch certificates selection
  List<BatchCert> _certificates = [];
  Map<String, bool> _selectedCertificates = {};
  bool _certificatesLoading = false;
  String? _certificatesError;

  late final BatchCertService _batchCertService;

  // Temperature values (dynamic list)
  List<double> _temperatures = [0.0];

  // Current step in the registration process
  int _currentStep = 0;

  // Scroll controller to reset position on step change
  final ScrollController _scrollController = ScrollController();

  // Selected producer and plot for default percentage values
  Producer? _selectedProducer;
  Plot? _selectedPlot;

  @override
  void initState() {
    super.initState();

    // Inject database from providers for offline support
    final db = ref.read(appDatabaseProvider);
    _batchCertService = BatchCertService(db: db);

    _loadCertificates();
    // Listen to plot selection to load defaults
    _plotController.addListener(_onPlotChanged);
  }

  void _onPlotChanged() {
    if (_plotController.text.isNotEmpty) {
      _loadSelectedProducerAndPlot();
    }
  }

  @override
  void dispose() {
    _plotController.removeListener(_onPlotChanged);
    _scrollController.dispose();
    _producerController.dispose();
    _plotController.dispose();
    _harvestDateController.dispose();
    _processingDateController.dispose();
    _juiceQuantityController.dispose();
    _panelaQuantityController.dispose();
    _confitilloQuantityController.dispose();
    _extractionPercentageController.dispose();
    _cachazaPercentageController.dispose();
    _initialPHController.dispose();
    _regulatorQuantityController.dispose();
    _regulatorUnitController.dispose();
    _finalPHController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
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
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return ProducerSelectionStep(
          producerController: _producerController,
          plotController: _plotController,
          extractionPercentageController: _extractionPercentageController,
          cachazaPercentageController: _cachazaPercentageController,
          selectedProducer: _selectedProducer,
          selectedPlot: _selectedPlot,
          onContinue: () => _nextStep(),
        );
      case 1:
        return DateSelectionStep(
          harvestDateController: _harvestDateController,
          processingDateController: _processingDateController,
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 2:
        return SugarCaneTypeStep(
          certificates: _certificates,
          selectedCertificates: _selectedCertificates,
          onSelectionChanged: _updateCertificateSelection,
          onExclusiveSelectionChanged: _updateExclusiveSelection,
          isLoading: _certificatesLoading,
          errorMessage: _certificatesError,
          onContinue: () => _validateAndNextStep(),
          onBack: () => _previousStep(),
        );
      case 3:
        return ResultsInputStep(
          juiceQuantityController: _juiceQuantityController,
          panelaQuantityController: _panelaQuantityController,
          confitilloQuantityController: _confitilloQuantityController,
          extractionPercentageController: _extractionPercentageController,
          cachazaPercentageController: _cachazaPercentageController,
          selectedProducer: _selectedProducer,
          selectedPlot: _selectedPlot,
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 4:
        return SugarCaneDetailsStep(
          juiceQuantityController: _juiceQuantityController,
          panelaQuantityController: _panelaQuantityController,
          confitilloQuantityController: _confitilloQuantityController,
          extractionPercentageController: _extractionPercentageController,
          cachazaPercentageController: _cachazaPercentageController,
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 5:
        return PhControlStep(
          initialPHController: _initialPHController,
          regulatorQuantityController: _regulatorQuantityController,
          regulatorUnitController: _regulatorUnitController,
          finalPHController: _finalPHController,
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 6:
        return TemperatureControlStep(
          temperatures: _temperatures,
          onTemperaturesChanged: (temperatures) {
            setState(() {
              _temperatures = temperatures;
            });
          },
          onContinue: () => _nextStep(),
          onBack: () => _previousStep(),
        );
      case 7:
        return RegistrationSummaryStep(
          db: ref.read(appDatabaseProvider),
          producerController: _producerController,
          plotController: _plotController,
          harvestDateController: _harvestDateController,
          processingDateController: _processingDateController,
          juiceQuantityController: _juiceQuantityController,
          panelaQuantityController: _panelaQuantityController,
          confitilloQuantityController: _confitilloQuantityController,
          extractionPercentageController: _extractionPercentageController,
          cachazaPercentageController: _cachazaPercentageController,
          initialPHController: _initialPHController,
          regulatorQuantityController: _regulatorQuantityController,
          regulatorUnitController: _regulatorUnitController,
          finalPHController: _finalPHController,
          certificates: _certificates,
          selectedCertificates: _selectedCertificates,
          temperatures: _temperatures,
          onBack: () => _previousStep(),
        );
      default:
        return ProducerSelectionStep(
          producerController: _producerController,
          plotController: _plotController,
          extractionPercentageController: _extractionPercentageController,
          cachazaPercentageController: _cachazaPercentageController,
          selectedProducer: _selectedProducer,
          selectedPlot: _selectedPlot,
          onContinue: () => _nextStep(),
        );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
    _scrollToTop();
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      } else {
        context.go(AppRoutes.home.path);
      }
    });
    _scrollToTop();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _certificatesLoading = true;
      _certificatesError = null;
    });

    try {
      final certificates = await _batchCertService.getBatchCerts();
      setState(() {
        _certificates = certificates;
        _selectedCertificates = {
          for (var cert in certificates) cert.id: cert.isDefault
        };
        _certificatesLoading = false;
      });
    } catch (e) {
      setState(() {
        _certificatesError = e.toString();
        _certificatesLoading = false;
      });
    }
  }

  void _updateCertificateSelection(String certId, bool selected) {
    setState(() {
      _selectedCertificates[certId] = selected;
    });
  }

  void _updateExclusiveSelection(String groupId, String certId) {
    setState(() {
      // First, unselect all certificates in the same group
      for (final cert in _certificates) {
        if (cert.exclusionGroupId == groupId) {
          _selectedCertificates[cert.id] = false;
        }
      }
      // Then select the chosen certificate
      _selectedCertificates[certId] = true;
    });
  }

  Future<void> _loadSelectedProducerAndPlot() async {
    final producerId = _producerController.text;
    final plotId = _plotController.text;

    // System defaults as fallback
    double extractionPercentage = 62.5;
    double cachazaPercentage = 2.5;

    try {
      // Load producer
      if (producerId.isNotEmpty) {
        final producer = await ProducerService().getProducerById(producerId);
        if (producer != null) {
          _selectedProducer = producer;
          // Use producer defaults as second priority
          extractionPercentage = producer.defaultExtractionPercentage;
          cachazaPercentage = producer.defaultCachazaPercentage;
        }
      }

      // Load plot (overrides producer if plot has defaults)
      if (plotId.isNotEmpty) {
        final plot = await PlotService().getPlotById(plotId);
        if (plot != null) {
          _selectedPlot = plot;
          // Use plot defaults as first priority (if they exist)
          if (plot.defaultExtractionPercentage != null) {
            extractionPercentage = plot.defaultExtractionPercentage!;
          }
          if (plot.defaultCachazaPercentage != null) {
            cachazaPercentage = plot.defaultCachazaPercentage!;
          }
        }
      }
    } catch (e) {
      // On error, use system defaults (already set above)
    }

    // Update controllers with hierarchical defaults
    setState(() {
      _extractionPercentageController.text = extractionPercentage.toString();
      _cachazaPercentageController.text = cachazaPercentage.toString();
    });
  }

  void _validateAndNextStep() {
    // Check if at least one certificate from each required exclusion group is selected
    final requiredGroups = _certificates
        .where((cert) => cert.exclusionGroup?.isRequired == true)
        .map((cert) => cert.exclusionGroup!)
        .toSet();

    for (final group in requiredGroups) {
      final groupCertificates = _certificates.where((cert) => cert.exclusionGroupId == group.id);
      final hasSelection = groupCertificates.any((cert) => _selectedCertificates[cert.id] == true);

      if (!hasSelection) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debe seleccionar ${group.displayName}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // If validation passes, proceed to next step
    _nextStep();
  }

}