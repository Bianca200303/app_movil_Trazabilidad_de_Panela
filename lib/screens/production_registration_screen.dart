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
import 'package:panela_sys/providers/cane_density_provider.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/core/production_calculator.dart';
import 'package:panela_sys/services/location_service.dart';

class ProductionRegistrationScreen extends ConsumerStatefulWidget {
  const ProductionRegistrationScreen({super.key});

  @override
  ConsumerState<ProductionRegistrationScreen> createState() => _ProductionRegistrationScreenState();
}

class _ProductionRegistrationScreenState extends ConsumerState<ProductionRegistrationScreen> {
  // Controllers for the different screens in the flow
  final TextEditingController _densityController = TextEditingController();
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
  final TextEditingController _observationsController = TextEditingController();

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
  static const int _totalSteps = 8;

  // Scroll controller to reset position on step change
  final ScrollController _scrollController = ScrollController();

  // Selected producer and plot for default percentage values
  Producer? _selectedProducer;
  Plot? _selectedPlot;

  // Location data
  double? _locationLatitude;
  double? _locationLongitude;
  String? _locationText;

  // Density stored as local state to avoid ref.watch in build
  double _density = ProductionCalculator.sugarCaneDensity;
  bool _isAdminSistema = false;
  ProviderSubscription<double>? _densitySubscription;

  @override
  void initState() {
    super.initState();

    // Inject database from providers for offline support
    final db = ref.read(appDatabaseProvider);
    _batchCertService = BatchCertService(db: db);

    // Read initial values without watch (avoids build-scope conflicts)
    _density = ref.read(caneDensityProvider);
    _isAdminSistema = ref.read(currentUserProvider)?.isAdminSistema == true;

    // Role guard: productores cannot register production
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.isProductor == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home.path);
      });
    }

    // Initialize density controller with current density value
    _densityController.text = _density.toStringAsFixed(2);
    _densityController.addListener(() {
      final v = double.tryParse(_densityController.text.replaceAll(',', '.'));
      if (v != null && v > 0) {
        _density = v;
      }
    });

    // Listen for density changes using setState (safe from any context)
    _densitySubscription = ref.listenManual<double>(
      caneDensityProvider,
      (_, next) {
        if (mounted) {
          setState(() => _density = next);
          _densityController.text = next.toStringAsFixed(2);
        }
      },
      fireImmediately: false,
    );

    _loadCertificates();
    _plotController.addListener(_onPlotChanged);
  }

  void _onPlotChanged() {
    if (_plotController.text.isNotEmpty) {
      _loadSelectedProducerAndPlot();
    }
  }

  @override
  void dispose() {
    _densitySubscription?.close();
    _plotController.removeListener(_onPlotChanged);
    _scrollController.dispose();
    _densityController.dispose();
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
    _observationsController.dispose();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepProgressIndicator(
                  currentStep: _currentStep + 1,
                  totalSteps: _totalSteps,
                ),
                SizedBox(height: context.responsiveSpacing),
                AppCard(
                  padding: context.responsivePadding,
                  child: _buildCurrentStep(_density, _isAdminSistema),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(double density, bool isAdminSistema) {

    switch (_currentStep) {
      case 0:
        return ProducerSelectionStep(
          producerController: _producerController,
          plotController: _plotController,
          extractionPercentageController: _extractionPercentageController,
          cachazaPercentageController: _cachazaPercentageController,
          selectedProducer: _selectedProducer,
          selectedPlot: _selectedPlot,
          locationLatitude: _locationLatitude,
          locationLongitude: _locationLongitude,
          locationText: _locationText,
          onLocationChanged: (result) {
            setState(() {
              _locationLatitude = result.latitude;
              _locationLongitude = result.longitude;
            });
          },
          onLocationTextChanged: (text) {
            setState(() {
              _locationText = text.isNotEmpty ? text : null;
            });
          },
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
          density: density,
          densityController: isAdminSistema ? _densityController : null,
          onContinue: () => _validateResultsAndNextStep(),
          onBack: () => _previousStep(),
        );
      case 4:
        return SugarCaneDetailsStep(
          juiceQuantityController: _juiceQuantityController,
          panelaQuantityController: _panelaQuantityController,
          confitilloQuantityController: _confitilloQuantityController,
          extractionPercentageController: _extractionPercentageController,
          cachazaPercentageController: _cachazaPercentageController,
          density: density,
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
          density: density,
          locationLatitude: _locationLatitude,
          locationLongitude: _locationLongitude,
          locationText: _locationText,
          observationsController: _observationsController,
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
          locationLatitude: _locationLatitude,
          locationLongitude: _locationLongitude,
          locationText: _locationText,
          onLocationChanged: (result) {
            setState(() {
              _locationLatitude = result.latitude;
              _locationLongitude = result.longitude;
            });
          },
          onLocationTextChanged: (text) {
            setState(() {
              _locationText = text.isNotEmpty ? text : null;
            });
          },
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
    if (_currentStep == 3 && _isAdminSistema) {
      final v = double.tryParse(_densityController.text.replaceAll(',', '.'));
      if (v != null && v > 0) {
        ref.read(caneDensityProvider.notifier).update(v).catchError((_) {});
      }
    }
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

  void _validateResultsAndNextStep() {
    final juiceLiters = double.tryParse(_juiceQuantityController.text);
    final panelaKg = double.tryParse(_panelaQuantityController.text);
    final confitilloKg = double.tryParse(_confitilloQuantityController.text) ?? 0.0;

    if (juiceLiters == null || juiceLiters <= 0) {
      _showResultsError('Ingresa los litros de jugo (mayor a 0)');
      return;
    }
    if (panelaKg == null || panelaKg < 0) {
      _showResultsError('Ingresa los kg de panela (mayor o igual a 0)');
      return;
    }
    if (confitilloKg < 0) {
      _showResultsError('Los kg de confitillo no pueden ser negativos');
      return;
    }
    if (_confitilloQuantityController.text.isEmpty) {
      _confitilloQuantityController.text = '0';
    }
    if (panelaKg >= juiceLiters) {
      _showResultsError(
          'La panela (${panelaKg.toStringAsFixed(1)} kg) no puede pesar igual o más que los litros de jugo (${juiceLiters.toStringAsFixed(1)} L)');
      return;
    }

    _nextStep();
  }

  void _showResultsError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

}

class _StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Paso $currentStep de $totalSteps',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Theme.of(context).dividerColor,
          ),
        ),
      ],
    );
  }
}