import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/screens/success_registration_screen.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/radio_group.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/providers/offline_provider.dart';

class ProducerRegistrationScreen extends ConsumerStatefulWidget {
  const ProducerRegistrationScreen({super.key});

  @override
  ConsumerState<ProducerRegistrationScreen> createState() =>
      _ProducerRegistrationScreenState();
}

class _ProducerRegistrationScreenState
    extends ConsumerState<ProducerRegistrationScreen> {
  final TextEditingController _namesController = TextEditingController();
  final TextEditingController _surnamesController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _appagropCodeController = TextEditingController();

  // Services will be injected with AppDatabase from providers
  late final ProducerService _producerService;
  late final PlotService _plotService;
  late final CoopModulesService _modulesService;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _plotNameController = TextEditingController();

  String _memberStatus = "SOCIO";
  String? _selectedModuleId;
  List<CoopModule> _modules = [];
  final List<PlotData> _plots = [];
  bool _isLoadingModules = true;
  bool _isSubmitting = false;
  String? _nextPlotCodeBase;  // Stores only the number part, e.g. "1", "2"
  bool _isLoadingCode = false;
  String? _currentProducerDni;  // Stores current DNI for code generation
  
  @override
  void initState() {
    super.initState();

    // Inject AppDatabase from providers into services
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _plotService = PlotService(db: db);
    _modulesService = CoopModulesService(db: db);

    _loadModules();

    // Listen to DNI changes to load plot code preview
    _dniController.addListener(_onDniChanged);
  }

  Future<void> _loadModules() async {
    try {
      final modules = await _modulesService.getModules();
      setState(() {
        _modules = modules;
        _isLoadingModules = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingModules = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar módulos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDniChanged() {
    final dni = _dniController.text.trim();

    // Only load preview if DNI is valid (8 digits numeric)
    if (dni.length == 8 && RegExp(r'^[0-9]+$').hasMatch(dni)) {
      if (_currentProducerDni != dni) {
        _currentProducerDni = dni;
        _loadNextPlotCodeForDni(dni);
      }
    } else {
      // Reset if DNI is invalid
      if (_currentProducerDni != null) {
        setState(() {
          _currentProducerDni = null;
          _nextPlotCodeBase = null;
          _plots.clear();  // Clear plots when DNI changes
        });
      }
    }
  }

  Future<void> _loadNextPlotCodeForDni(String dni) async {
    setState(() {
      _isLoadingCode = true;
    });

    try {
      // We need to create a temporary producer to get the code preview
      // Since the producer doesn't exist yet, we'll use a different approach:
      // Simply default to 1 for new producers
      setState(() {
        _nextPlotCodeBase = '1';
        _isLoadingCode = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCode = false;
      });
      // Don't show error for code preview
    }
  }

  // Helper method to generate full plot code with DNI
  String _buildPlotCode(int offset) {
    final dni = _currentProducerDni;
    final codeBase = _nextPlotCodeBase;

    if (dni == null || codeBase == null) {
      return '???-?';
    }

    final baseNum = int.tryParse(codeBase) ?? 1;
    final codeNum = baseNum + offset;
    return '$dni-$codeNum';
  }

  void _addPlot() {
    final plotName = _plotNameController.text.trim();

    // Check if DNI is valid before allowing plots
    if (_currentProducerDni == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un DNI válido primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if plot names are required for this cooperative
    if (AppConfig.current.features.requirePlotNames && plotName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el nombre de la parcela'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for duplicate name only if name is not empty
    if (plotName.isNotEmpty) {
      final existingPlot = _plots.firstWhere(
        (plot) => plot.name.toLowerCase() == plotName.toLowerCase(),
        orElse: () => PlotData(name: ''),
      );

      if (existingPlot.name.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya agregaste una parcela con este nombre'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Calculate the expected code for this plot (for preview purposes)
    final expectedCode = _buildPlotCode(_plots.length);

    setState(() {
      _plots.add(PlotData(name: plotName.isEmpty ? '' : plotName, code: expectedCode));
      _plotNameController.clear();
    });
  }

  void _removePlot(PlotData plot) {
    setState(() {
      _plots.remove(plot);
    });
    
    // Recalculate preview codes for remaining plots
    _recalculatePreviewCodes();
  }

  void _recalculatePreviewCodes() {
    for (int i = 0; i < _plots.length; i++) {
      final expectedCode = _buildPlotCode(i);
      _plots[i] = PlotData(name: _plots[i].name, code: expectedCode);
    }

    setState(() {});
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedModuleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un módulo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_plots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una parcela'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate APPAGROP code if required for this cooperative
    if (AppConfig.current.features.useAppagropCode &&
        _appagropCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('APPAGROP es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create producer first
      final producerRequest = CreateProducerRequest(
        firstName: _namesController.text.trim(),
        lastName: _surnamesController.text.trim(),
        dni: _dniController.text.trim(),
        coopModuleId: _selectedModuleId!,
        isMember: _memberStatus == 'SOCIO',
        appagropCode: AppConfig.current.features.useAppagropCode
            ? _appagropCodeController.text.trim().isNotEmpty
                ? _appagropCodeController.text.trim()
                : null
            : null,
      );

      final producer = await _producerService.createProducer(producerRequest);

      // Create plots for the producer (only with names, codes auto-generated)
      final plotsForCreation = _plots.map((plot) => PlotData(name: plot.name)).toList();
      await _plotService.createMultiplePlots(producer.id, plotsForCreation);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SuccessRegistrationScreen(
              type: RegistrationType.producer,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  String? _validateDNI(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'DNI es requerido';
    }
    if (value.trim().length != 8) {
      return 'DNI debe tener 8 dígitos';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return 'DNI solo debe contener números';
    }
    return null;
  }

  Widget _buildPlotChip(PlotData plot) {
    return Container(
      width: context.isSmallScreen ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: context.responsivePadding.left,
        vertical: context.responsivePadding.top / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: context.isSmallScreen ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Expanded(
            flex: context.isSmallScreen ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plot.name.isEmpty ? 'Parcela sin nombre' : plot.name,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                    fontStyle: plot.name.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                Text(
                  'Código aprox: ${plot.code}',
                  style: AppTextStyles.smallText.copyWith(
                    color: AppColors.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.responsiveSpacing),
          GestureDetector(
            onTap: () => _removePlot(plot),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: context.isSmallScreen ? 20 : 16,
                color: AppColors.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _namesController.dispose();
    _surnamesController.dispose();
    _dniController.dispose();
    _appagropCodeController.dispose();
    _plotNameController.dispose();
    super.dispose();
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
              hasBackButton: true,
              onBack: () => context.go(AppRoutes.home.path),
              padding: context.responsivePadding,
              child: Form(
                key: _formKey,
                child: FormGroup(
                  spacing: context.responsiveSpacing,
                  children: [
                  // Title
                  Text(
                    'Registrar productor',
                    style: AppTextStyles.mainTitle,
                    textAlign: TextAlign.center,
                  ),
                  
                    // Names field
                    AppTextField(
                      label: 'Nombres',
                      controller: _namesController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => _validateRequired(value, 'Nombres'),
                    ),
                    
                    // Surnames field
                    AppTextField(
                      label: 'Apellidos',
                      controller: _surnamesController,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => _validateRequired(value, 'Apellidos'),
                    ),
                    
                    // DNI field
                    AppTextField(
                      label: 'Número de DNI',
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      validator: _validateDNI,
                    ),
                  
                  // Module field
                  AppDropdown<String>(
                    label: 'Módulo',
                    hintText: 'Selecciona un módulo',
                    value: _selectedModuleId,
                    isLoading: _isLoadingModules,
                    options: _modules.map((module) {
                      return DropdownOption<String>(
                        value: module.id,
                        label: module.name,
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedModuleId = value;

                        // Auto-complete APPAGROP code if empty and feature is enabled
                        if (AppConfig.current.features.useAppagropCode &&
                            _appagropCodeController.text.trim().isEmpty &&
                            value != null) {
                          final selectedModule = _modules.firstWhere(
                            (module) => module.id == value,
                            orElse: () => _modules.first,
                          );
                          _appagropCodeController.text = selectedModule.name;
                        }
                      });
                    },
                  ),

                  // APPAGROP code field (only for cooperatives that use it)
                  if (AppConfig.current.features.useAppagropCode)
                    AppTextField(
                      label: 'APPAGROP',
                      controller: _appagropCodeController,
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) => _validateRequired(value, 'APPAGROP'),
                    ),
                  
                  
                  // Condition field (Radio buttons)
                  AppRadioGroup<String>(
                    label: 'Condición',
                    options: [
                      RadioOption(value: 'SOCIO', label: 'SOCIO'),
                      RadioOption(value: 'NO SOCIO', label: 'NO SOCIO'),
                    ],
                    groupValue: _memberStatus,
                    onChanged: (value) {
                      setState(() {
                        _memberStatus = value ?? 'SOCIO';
                      });
                    },
                  ),
                  
                  
                  // Parcelas section
                  Text(
                    'Parcelas',
                    style: AppTextStyles.fieldLabel,
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall),
                  
                  // Code preview info
                  Container(
                    padding: EdgeInsets.all(context.responsivePadding.left),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(
                        color: AppColors.inputBorder,
                        width: AppDimensions.inputBorderWidth,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: context.responsiveSpacing / 2),
                        Expanded(
                          child: Text(
                            _isLoadingCode
                                ? 'Cargando próximo código...'
                                : _currentProducerDni != null && _nextPlotCodeBase != null
                                    ? 'Próximo código: ${_buildPlotCode(_plots.length)}'
                                    : 'Ingresa DNI para ver código',
                            style: AppTextStyles.smallText.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: context.responsiveSpacing),
                  
                  // Plot input field with add button (simplified)
                  context.shouldStackButtons
                      ? Column(
                          children: [
                            AppTextField(
                              label: null,
                              hintText: AppConfig.current.features.requirePlotNames
                                  ? 'Nombre de parcela (ej: Parcela Norte)'
                                  : 'Nombre de parcela (opcional)',
                              controller: _plotNameController,
                            ),
                            SizedBox(height: context.responsiveSpacing),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: 'AGREGAR PARCELA',
                                onPressed: _addPlot,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: null,
                                hintText: AppConfig.current.features.requirePlotNames
                                    ? 'Nombre de parcela (ej: Parcela Norte)'
                                    : 'Nombre de parcela (opcional)',
                                controller: _plotNameController,
                              ),
                            ),
                            SizedBox(width: context.responsiveSpacing),
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  color: AppColors.textWhite,
                                ),
                                onPressed: _addPlot,
                              ),
                            ),
                          ],
                        ),
                  
                  // Plot list
                  if (_plots.isNotEmpty) ...[
                    SizedBox(height: context.responsiveSpacing),
                    Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Parcelas agregadas:',
                            style: AppTextStyles.fieldLabel,
                          ),
                          SizedBox(height: context.responsiveSpacing),
                          context.isSmallScreen
                              ? Column(
                                  children: _plots.map((plot) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: context.responsiveSpacing,
                                      ),
                                      child: _buildPlotChip(plot),
                                    );
                                  }).toList(),
                                )
                              : Wrap(
                                  spacing: context.responsiveSpacing,
                                  runSpacing: context.responsiveSpacing,
                                  children: _plots.map((plot) {
                                    return _buildPlotChip(plot);
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ],
                  
                    // Register button
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: _isSubmitting ? 'REGISTRANDO...' : 'REGISTRAR',
                        onPressed: _isSubmitting ? null : _submitForm,
                      ),
                    ),
                ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
