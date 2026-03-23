import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/screens/success_registration_screen.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
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
import 'package:panela_sys/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/providers/producer_prefill_provider.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/widgets/common/app_snackbar.dart';

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
  final TextEditingController _moduleSearchController = TextEditingController();
  final FocusNode _moduleFocusNode = FocusNode();

  // Services will be injected with AppDatabase from providers
  late final ProducerService _producerService;
  late final PlotService _plotService;
  late final CoopModulesService _modulesService;
  final AuthService _authService = AuthService();
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

    // Pre-fill data if coming from user management
    final preFill = ref.read(producerPreFillProvider);
    if (preFill != null) {
      _dniController.text = preFill.dni;
      _namesController.text = preFill.firstName;
      _surnamesController.text = preFill.lastName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(producerPreFillProvider.notifier).state = null;
      });
    }

    // Listen to DNI changes to load plot code preview
    _dniController.addListener(_onDniChanged);
  }

  Future<void> _loadModules() async {
    try {
      final modules = await _modulesService.fetchFromSupabase();
      final currentUser = ref.read(currentUserProvider);
      // For adminModulo/tecnicoCampo, filter modules to only their assigned ones
      final filteredModules = (currentUser?.hasModuleRestriction == true && currentUser!.moduleIds.isNotEmpty)
          ? modules.where((m) => currentUser.moduleIds.contains(m.id)).toList()
          : modules;
      setState(() {
        _modules = filteredModules;
        _isLoadingModules = false;
        // If user has exactly one module, pre-select and lock it
        if (currentUser?.hasModuleRestriction == true && filteredModules.length == 1) {
          _selectedModuleId = filteredModules.first.id;
          _moduleSearchController.text = filteredModules.first.name;
        }
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

  Future<void> _createModuleInline(String name) async {
    try {
      final module = await _modulesService.createModule(name: name);
      if (mounted) {
        setState(() {
          _modules = [..._modules, module]..sort((a, b) => a.name.compareTo(b.name));
          _selectedModuleId = module.id;
          _moduleSearchController.text = module.name;
          if (AppConfig.current.features.useAppagropCode &&
              _appagropCodeController.text.trim().isEmpty) {
            _appagropCodeController.text = module.name;
          }
        });
        AppSnackBar.show(
          context,
          message: 'Módulo "${module.name}" creado',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: SnackBarType.error,
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

  Future<void> _editPlot(int index) async {
    final plot = _plots[index];

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _PlotNameEditDialog(plot: plot),
    );

    if (newName == null || !mounted) return; // Cancelled

    // Validate: required name
    if (AppConfig.current.features.requirePlotNames && newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre de la parcela es requerido'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate: duplicate name (excluding current plot)
    if (newName.isNotEmpty) {
      final duplicate = _plots.asMap().entries.any(
        (e) =>
            e.key != index &&
            e.value.name.toLowerCase() == newName.toLowerCase(),
      );
      if (duplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya existe una parcela con ese nombre'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _plots[index] = PlotData(name: newName, code: plot.code);
    });
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

      // Create user account for the producer (password = DNI)
      try {
        await _authService.registerUser(
          dni: _dniController.text.trim(),
          firstName: _namesController.text.trim(),
          lastName: _surnamesController.text.trim(),
          password: _dniController.text.trim(),
          role: 'productor',
        );
      } catch (_) {
        // User already exists — update their role to 'productor' via Edge Function
        try {
          await Supabase.instance.client.functions.invoke(
            'update-user-role',
            body: {
              'userId': _dniController.text.trim(),
              'newRole': 'productor',
              'cooperativeId': AppConfig.current.id,
            },
          );
        } catch (_) {
          // Non-critical — producer record was created successfully
        }
      }

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

  Widget _buildPlotChip(PlotData plot, int index) {
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
        mainAxisSize:
            context.isSmallScreen ? MainAxisSize.max : MainAxisSize.min,
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
                    fontStyle: plot.name.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
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
          SizedBox(width: context.responsiveSpacing / 2),
          // Edit button
          GestureDetector(
            onTap: () => _editPlot(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.edit_outlined,
                size: context.isSmallScreen ? 20 : 16,
                color: AppColors.textWhite,
              ),
            ),
          ),
          SizedBox(width: context.responsiveSpacing / 2),
          // Remove button
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
    _moduleSearchController.dispose();
    _moduleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final hasLockedModule = (currentUser?.hasModuleRestriction ?? false) && (currentUser?.moduleIds.length == 1);
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
                  if (_isLoadingModules)
                    const Center(child: CircularProgressIndicator())
                  else if (hasLockedModule && _selectedModuleId != null)
                    // AdminModulo: show locked module, no change allowed
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Módulo', style: AppTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _modules.firstWhere((m) => m.id == _selectedModuleId, orElse: () => CoopModule(id: '', name: _selectedModuleId!)).name,
                                style: AppTextStyles.bodyText,
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
                        Text('Módulo', style: AppTextStyles.fieldLabel),
                        const SizedBox(height: 6),
                        RawAutocomplete<CoopModule>(
                          textEditingController: _moduleSearchController,
                          focusNode: _moduleFocusNode,
                          displayStringForOption: (m) => m.name,
                          optionsBuilder: (textValue) {
                            final query = textValue.text.toLowerCase().trim();
                            if (query.isEmpty) return _modules;
                            final filtered = _modules
                                .where((m) => m.name.toLowerCase().contains(query))
                                .toList();
                            final hasExact = filtered.any(
                              (m) => m.name.toLowerCase() == query,
                            );
                            if (!hasExact && query.isNotEmpty) {
                              filtered.add(CoopModule(id: '__create__', name: textValue.text.trim()));
                            }
                            return filtered;
                          },
                          onSelected: (module) {
                            if (module.id == '__create__') {
                              _moduleSearchController.clear();
                              _createModuleInline(module.name);
                            } else {
                              setState(() {
                                _selectedModuleId = module.id;
                                _moduleSearchController.text = module.name;
                                if (AppConfig.current.features.useAppagropCode &&
                                    _appagropCodeController.text.trim().isEmpty) {
                                  _appagropCodeController.text = module.name;
                                }
                              });
                            }
                          },
                          fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                            return AppTextField(
                              label: null,
                              hintText: 'Buscar o crear módulo...',
                              controller: controller,
                              focusNode: focusNode,
                            );
                          },
                          optionsViewBuilder: (ctx, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 220),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final module = options.elementAt(index);
                                      final isCreate = module.id == '__create__';
                                      return ListTile(
                                        leading: Icon(
                                          isCreate ? Icons.add_circle_outline : Icons.circle,
                                          size: isCreate ? 20 : 8,
                                          color: AppColors.primary,
                                        ),
                                        title: Text(
                                          isCreate
                                              ? 'Crear módulo "${module.name}"'
                                              : module.name,
                                          style: AppTextStyles.bodyText.copyWith(
                                            color: isCreate ? AppColors.primary : null,
                                            fontWeight: isCreate ? FontWeight.w600 : null,
                                          ),
                                        ),
                                        onTap: () => onSelected(module),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_selectedModuleId != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '✓ ${_modules.firstWhere((m) => m.id == _selectedModuleId, orElse: () => CoopModule(id: '', name: '')).name}',
                            style: AppTextStyles.smallText.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ],
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
                                  children: _plots.asMap().entries.map((e) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: context.responsiveSpacing,
                                      ),
                                      child: _buildPlotChip(e.value, e.key),
                                    );
                                  }).toList(),
                                )
                              : Wrap(
                                  spacing: context.responsiveSpacing,
                                  runSpacing: context.responsiveSpacing,
                                  children: _plots.asMap().entries.map((e) {
                                    return _buildPlotChip(e.value, e.key);
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

/// Dialog para editar el nombre de una parcela.
///
/// Gestiona su propio [TextEditingController] en [initState]/[dispose]
/// para evitar el error de dependencias al cerrar el dialog.
class _PlotNameEditDialog extends StatefulWidget {
  const _PlotNameEditDialog({required this.plot});

  final PlotData plot;

  @override
  State<_PlotNameEditDialog> createState() => _PlotNameEditDialogState();
}

class _PlotNameEditDialogState extends State<_PlotNameEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.plot.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar parcela'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Código aprox: ${widget.plot.code}',
            style: AppTextStyles.smallText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Nombre de parcela',
            hintText: AppConfig.current.features.requirePlotNames
                ? 'Nombre de parcela (requerido)'
                : 'Nombre de parcela (opcional)',
            controller: _controller,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}
