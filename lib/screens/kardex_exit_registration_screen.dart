import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/screens/success_registration_screen.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/unsaved_changes_guard.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_confirm_dialog.dart';
import 'package:panela_sys/widgets/common/step_progress_indicator.dart';
import 'package:panela_sys/widgets/common/app_search_field.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/font_size_config.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/services/inventory_service.dart';
import 'package:panela_sys/services/exit_registration_service.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/models/exit_registration.dart';
import 'package:panela_sys/models/exit_item.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/providers/current_user_provider.dart';

class KardexExitRegistrationScreen extends ConsumerStatefulWidget {
  const KardexExitRegistrationScreen({super.key});

  @override
  ConsumerState<KardexExitRegistrationScreen> createState() => _KardexExitRegistrationScreenState();
}

class _KardexExitRegistrationScreenState extends ConsumerState<KardexExitRegistrationScreen> {
  // Current step in the registration process (start at 1, no exit type selection)
  int _currentStep = 1;
  final _scrollController = ScrollController();
  
  // Services
  final InventoryService _inventoryService = InventoryService();
  final ExitRegistrationService _exitService = ExitRegistrationService();
  final AuthService _authService = AuthService();
  
  // Data state
  List<Map<String, dynamic>> _availableStock = [];
  List<bool> _selectedStock = [];
  List<TextEditingController> _quantityControllers = [];
  List<TextEditingController> _itemDocumentControllers = [];
  List<bool> _expandedItems = [];

  // Exit type state (global for all lots)
  bool _isAutoconsumo = false;

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Remission document number
  final TextEditingController _documentController = TextEditingController();

  // Exit date
  final TextEditingController _exitDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailableStock();
    // Initialize exit date to today
    _exitDateController.text = AppDateUtils.formatDDMMYYYY(DateTime.now());
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers) {
      controller.dispose();
    }
    for (final controller in _itemDocumentControllers) {
      controller.dispose();
    }
    _searchController.dispose();
    _documentController.dispose();
    _exitDateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStock() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      var stockData = await _inventoryService.getAvailableStock();
      // Filter by assigned modules for adminModulo/tecnicoCampo
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && currentUser.hasModuleRestriction && currentUser.moduleIds.isNotEmpty) {
        stockData = stockData.where((item) {
          final producer = item['production_batch']?['producer'] as Map<String, dynamic>?;
          final coopModuleId = producer?['coop_module_id'] as String?;
          return coopModuleId != null && currentUser.moduleIds.contains(coopModuleId);
        }).toList();
      }

      setState(() {
        _availableStock = stockData;
        _selectedStock = List.filled(stockData.length, false);
        _quantityControllers = stockData.map((stock) {
          final availableKg = (stock['available_kg'] as num).toDouble();
          final controller = TextEditingController(text: _kgToBagsText(availableKg));
          // ESTO ES LO NUEVO: Escucha cada vez que se teclea un número
          controller.addListener(() {
            if (mounted) setState(() {}); 
          });
          return controller;
        }).toList();
        _itemDocumentControllers = stockData.map((_) {
          return TextEditingController();
        }).toList();
        _expandedItems = List.filled(stockData.length, false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Calcula el total de kilos que están saliendo
  double _calculateTotalSalidaKg() {
    double totalKg = 0;
    for (int i = 0; i < _selectedStock.length; i++) {
      if (_selectedStock[i]) {
        final text = _quantityControllers[i].text.trim();
        final quantity = double.tryParse(text) ?? 0;
        
        if (_isAutoconsumo) {
          totalKg += quantity; // Si es autoconsumo, ya está en kilos
        } else {
          totalKg += (quantity * 50); // Si es acopio, multiplicamos los sacos por 50kg
        }
      }
    }
    return totalKg;
  }

  // Calcula el total de sacos (solo útil si NO es autoconsumo)
  int _calculateTotalSalidaSacos() {
    int totalSacos = 0;
    for (int i = 0; i < _selectedStock.length; i++) {
      if (_selectedStock[i] && !_isAutoconsumo) {
        final text = _quantityControllers[i].text.trim();
        final quantity = int.tryParse(text) ?? 0;
        totalSacos += quantity;
      }
    }
    return totalSacos;
  }

  /// Hay datos ingresados que se perderían al salir (ver UnsavedChangesGuard).
  bool get _hasUnsavedChanges =>
      _currentStep > 1 || _selectedStock.contains(true) ||
      _documentController.text.trim().isNotEmpty;

  void _leave() => UnsavedChangesGuard.leave(
        context,
        hasUnsavedChanges: _hasUnsavedChanges,
        leave: () => context.go(AppRoutes.home.path),
      );

  @override
  Widget build(BuildContext context) => UnsavedChangesGuard(
        onBack: _handleBackNavigation,
        child: _buildForm(context),
      );

  Widget _buildForm(BuildContext context) {
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
              hasBackButton: true,
              onBack: _handleBackNavigation,
              padding: context.responsivePadding,
              child: _buildCurrentStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepProgressIndicator(currentStep: _currentStep, totalSteps: 3),
        SizedBox(height: AppDimensions.spacingMedium),
        switch (_currentStep) {
          1 => _buildProducerSelection(),
          2 => _buildAdjustQuantity(),
          3 => _buildExitDocument(),
          _ => _buildProducerSelection(),
        },
      ],
    );
  }


  // Convierte kg a texto de sacos con decimales si hay fracción (ej: 415 kg → "8.3")
  String _kgToBagsText(double availableKg) {
    final bags = availableKg / 50;
    if (bags % 1 == 0) return bags.toInt().toString();
    return bags.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _producerName(int index) {
    final producer = _availableStock[index]['production_batch']['producer'];
    return '${producer['first_name']} ${producer['last_name']}';
  }

  List<int> get _filteredIndices {
    if (_searchQuery.isEmpty) return List.generate(_availableStock.length, (i) => i);
    final query = _searchQuery.toLowerCase();
    return [
      for (int i = 0; i < _availableStock.length; i++)
        if (_producerName(i).toLowerCase().contains(query)) i,
    ];
  }

  Widget _buildProducerSelection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return FormGroup(
        spacing: context.responsiveSpacing,
        children: [
          const AppTitle(
            title: 'KARDEX',
            subtitle: 'Registro de Salida',
          ),
          Text(
            'Error: $_errorMessage',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          AppButton(
            text: 'Reintentar',
            type: AppButtonType.secondary,
            onPressed: _loadAvailableStock,
          ),
        ],
      );
    }

    if (_availableStock.isEmpty) {
      return FormGroup(
        spacing: context.responsiveSpacing,
        children: [
          const AppTitle(
            title: 'KARDEX',
            subtitle: 'Registro de Salida',
          ),
          Text(
            'No hay stock disponible para salidas',
            style: AppTextStyles.bodyText,
            textAlign: TextAlign.center,
          ),
          AppButton(
            text: 'Actualizar',
            type: AppButtonType.secondary,
            onPressed: _loadAvailableStock,
          ),
        ],
      );
    }

    return FormGroup(
      spacing: context.responsiveSpacing,
      children: [
        const AppTitle(
          title: 'REGISTRO DE SALIDA',
        ),
        FormSection(
          subtitle: 'Seleccione el tipo de salida y busque el lote del productor',
          children: [
            SizedBox(height: context.responsiveSpacing),
            _buildExitTypeSwitch(),
            SizedBox(height: AppDimensions.spacingLarge),
            AppSearchField(
              controller: _searchController,
              hintText: 'Buscar productor...',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            SizedBox(height: context.responsiveSpacing),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: context.screenSize.height * 0.45,
              ),
              child: _filteredIndices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingLarge),
                      child: Center(
                        child: Text(
                          'No se encontró ningún productor con ese nombre',
                          style: AppTextStyles.bodyText,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredIndices.length,
                      itemBuilder: (context, i) {
                        final originalIndex = _filteredIndices[i];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i < _filteredIndices.length - 1
                                ? context.responsiveSpacing
                                : 0,
                          ),
                          child: _buildStockCheckbox(originalIndex),
                        );
                      },
                    ),
            ),
            SizedBox(height: AppDimensions.spacingLarge),
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL DISPONIBLE',
                      style: AppTextStyles.sectionLabel,
                    ),
                    SizedBox(height: AppDimensions.spacingSmall),
                    Text(
                      '${_calculateTotalAvailableKg().toStringAsFixed(1)} kg (${_calculateTotalAvailableBags()} sacos)',
                      style: AppTextStyles.bodyTextLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppDimensions.spacingLarge),
            _buildContinueButton(() {
              if (_selectedStock.contains(true)) {
                setState(() {
                  _currentStep = 2;
                });
                _scrollController.jumpTo(0);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Seleccione al menos un lote')),
                );
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildStockCheckbox(int index) {
    final stock = _availableStock[index];
    final batch = stock['production_batch'];
    final producer = batch['producer'];
    final moduleName = producer['coop_modules']?['name'] as String?;
    final availableKg = (stock['available_kg'] as num).toDouble();
    final availableBags = (availableKg / 50).floor();
    final remainderKg = availableKg - (availableBags * 50.0);
    final isLowStock = availableKg < 50;
    final isExpanded = _expandedItems[index];

    const styleNormal = TextStyle(fontSize: FontSizeConfig.captionSize, color: AppColors.textPrimary);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isLowStock ? AppColors.warning : AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        color: AppColors.surface,
      ),
      child: Column(
        children: [
          // ── Header compacto: checkbox + nombre + módulo/kg ────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox zone
              InkWell(
                onTap: () => setState(() {
                  _selectedStock[index] = !_selectedStock[index];
                  _updateControllerValue(index);
                }),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusMedium),
                  bottomLeft: Radius.circular(AppDimensions.radiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                  child: Checkbox(
                    value: _selectedStock[index],
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedStock[index] = value!;
                        _updateControllerValue(index);
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
              ),
              // Nombre + expand zone
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _expandedItems[index] = !isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.paddingMedium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila 1: nombre + icono expand
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${producer['first_name']} ${producer['last_name']}',
                                style: const TextStyle(
                                  fontSize: FontSizeConfig.smallSize,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingXSmall),
                            Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingXSmall),
                        // Fila 2: fecha (flexible) + kg
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _formatDate(batch['process_date']),
                                style: styleNormal,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${availableKg.toStringAsFixed(1)} kg',
                              style: styleNormal,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Detalles desplegables ─────────────────────────────────
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusMedium),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingMedium,
                AppDimensions.paddingSmall,
                AppDimensions.paddingMedium,
                AppDimensions.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lote: ${batch['batch_code']}', style: styleNormal),
                  if (moduleName != null)
                    Text('Módulo: $moduleName', style: styleNormal),
                  Text(
                    remainderKg > 0.05
                        ? 'Disponible: $availableBags sacos + ${remainderKg.toStringAsFixed(1)} kg'
                        : 'Disponible: $availableBags sacos',
                    style: styleNormal,
                  ),
                  if (isLowStock) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: const Text(
                        'Stock bajo — menos de 1 saco',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: FontSizeConfig.captionSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExitTypeSwitch() {
    final buttonHeight = context.isVerySmallScreen
        ? AppDimensions.buttonHeight
        : AppDimensions.buttonHeightLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tipo de salida',
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              ' *',
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _ExitTypeButton(
                label: 'ACOPIO',
                icon: Icons.warehouse_outlined,
                isSelected: !_isAutoconsumo,
                selectedColor: AppColors.primary,
                height: buttonHeight,
                onTap: () => _handleExitTypeChange(false),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(
              child: _ExitTypeButton(
                label: 'AUTOCONSUMO',
                icon: Icons.store_outlined,
                isSelected: _isAutoconsumo,
                selectedColor: AppColors.warning,
                height: buttonHeight,
                onTap: () => _handleExitTypeChange(true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildAdjustQuantity() {
    return FormGroup(
      spacing: context.responsiveSpacing,
      children: [
        const AppTitle(
          title: 'KARDEX',
          subtitle: 'Registro de Salida',
        ),
        FormSection(
          title: 'Ajuste',
          subtitle: 'Ajuste la cantidad de salida según corresponda',
          children: [
            SizedBox(height: context.responsiveSpacing),
            for (int i = 0; i < _selectedStock.length; i++)
              if (_selectedStock[i]) ...[
                _buildQuantityAdjustment(i),
                SizedBox(height: context.responsiveSpacing),
              ],
            Builder(builder: (_) {
              final remaining = _calculateRemainingKg();
              final remainingBags = (remaining / 50).floor();
              final isOver = remaining < 0;
              final remainingColor = isOver ? AppColors.error : AppColors.success;
              return Container(
                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: IntrinsicHeight(
                  child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('DISPONIBLE', style: AppTextStyles.sectionLabel.copyWith(color: AppColors.textPrimary)),
                          SizedBox(height: AppDimensions.spacingSmall),
                          Text(
                            '${_calculateTotalAvailableKg().toStringAsFixed(1)} kg\n(${_calculateTotalAvailableBags()} sacos)',
                            style: AppTextStyles.bodyTextLarge.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, color: AppColors.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text('RESTANTE', style: AppTextStyles.sectionLabel.copyWith(color: remainingColor)),
                          SizedBox(height: AppDimensions.spacingSmall),
                          Text(
                            isOver
                                ? 'Excedido\n${remaining.abs().toStringAsFixed(1)} kg'
                                : '${remaining.toStringAsFixed(1)} kg\n($remainingBags sacos)',
                            style: AppTextStyles.bodyTextLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: remainingColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  ),
                ),
              );
            }),

            Container(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESUMEN DE SALIDA',
                    style: AppTextStyles.sectionLabel.copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: AppDimensions.spacingSmall),
                  // Desglose por lote
                  ...List.generate(_selectedStock.length, (i) {
                    if (!_selectedStock[i]) return const SizedBox.shrink();
                    final s = _availableStock[i];
                    final b = s['production_batch'];
                    final p = b['producer'];
                    final qty = double.tryParse(_quantityControllers[i].text.trim()) ?? 0;
                    final kg = _isAutoconsumo ? qty : qty * 50;
                    final sacosStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${p['first_name']} ${p['last_name']}',
                              style: AppTextStyles.bodyText,
                            ),
                          ),
                          Text(
                            _isAutoconsumo
                                ? '${kg.toStringAsFixed(1)} kg'
                                : '$sacosStr sacos\n(${kg.toStringAsFixed(1)} kg)',
                            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  SizedBox(height: AppDimensions.spacingSmall),
                  Center(
                    child: Column(
                      children: [
                        if (_isAutoconsumo) ...[
                          Text(
                            'Total: ${_calculateTotalSalidaKg().toStringAsFixed(1)} kg',
                            style: AppTextStyles.bodyTextLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Total: ${(_calculateTotalSalidaKg() / 50).toStringAsFixed(1)} sacos',
                            style: AppTextStyles.bodyTextLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Equivalente a: ${_calculateTotalSalidaKg().toStringAsFixed(1)} kg',
                            style: AppTextStyles.bodyText,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.spacingLarge),
            _buildContinueButton(() {
              if (_validateQuantities()) {
                setState(() {
                  _currentStep = 3;
                });
                _scrollController.jumpTo(0);
              }
            }),
          ],
        ),
      ],
    );
  }

  Future<void> _handleExitTypeChange(bool newValue) async {
    if (_selectedStock.contains(true)) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: '¿Cambiar tipo de salida?',
        message: 'Las cantidades ingresadas se recalcularán según el nuevo modo. '
            '¿Desea continuar?',
        confirmLabel: 'Continuar',
      );
      if (!confirmed) return;
    }
    setState(() {
      _isAutoconsumo = newValue;
      for (int i = 0; i < _quantityControllers.length; i++) {
        _updateControllerValue(i);
      }
    });
  }

  void _updateControllerValue(int index) {
    if (index >= _quantityControllers.length || index >= _availableStock.length) return;

    final controller = _quantityControllers[index];
    final stock = _availableStock[index];
    final availableKg = (stock['available_kg'] as num).toDouble();

    if (_isAutoconsumo) {
      controller.text = availableKg.toStringAsFixed(1);
    } else {
      controller.text = _kgToBagsText(availableKg);
    }
  }

  double _calculateTotalAvailableKg() {
    double total = 0;
    for (int i = 0; i < _availableStock.length; i++) {
      total += (_availableStock[i]['available_kg'] as num).toDouble();
    }
    return total;
  }

  int _calculateTotalAvailableBags() {
    return (_calculateTotalAvailableKg() / 50).floor();
  }

  double _calculateRemainingKg() {
    double selectedAvailable = 0;
    for (int i = 0; i < _availableStock.length; i++) {
      if (_selectedStock[i]) {
        selectedAvailable += (_availableStock[i]['available_kg'] as num).toDouble();
      }
    }
    return selectedAvailable - _calculateTotalSalidaKg();
  }

  bool _validateQuantities() {
    for (int i = 0; i < _selectedStock.length; i++) {
      if (!_selectedStock[i]) continue;

      final controller = _quantityControllers[i];
      final stock = _availableStock[i];
      final availableKg = (stock['available_kg'] as num).toDouble();

      final quantityText = controller.text.trim();
      if (quantityText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese todas las cantidades')),
        );
        return false;
      }

      final quantity = double.tryParse(quantityText);
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese cantidades válidas')),
        );
        return false;
      }

      // Validate against available stock
      final requestedKg = _isAutoconsumo ? quantity : quantity * 50;
      if (requestedKg > availableKg) {
        final batch = stock['production_batch'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cantidad excede stock disponible para lote ${batch['batch_code']}. '
              'Disponible: ${availableKg.toStringAsFixed(1)} kg'
            ),
          ),
        );
        return false;
      }

      // Comprobante de acopio obligatorio, salvo en autoconsumo (no suele
      // existir un comprobante físico ya que no hay venta a un tercero).
      if (!_isAutoconsumo && _itemDocumentControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrese el comprobante de acopio para todos los lotes')),
        );
        return false;
      }
    }
    return true;
  }

  Widget _buildQuantityAdjustment(int index) {
    final stock = _availableStock[index];
    final batch = stock['production_batch'];
    final producer = batch['producer'];
    final moduleName = producer['coop_modules']?['name'] as String?;
    final availableKg = (stock['available_kg'] as num).toDouble();
    final availableBags = (availableKg / 50).floor();
    final remainderKg = availableKg - (availableBags * 50.0);
    final controller = _quantityControllers[index];
    final documentController = _itemDocumentControllers[index];
    final isExpanded = _expandedItems[index];

    final currentQty = double.tryParse(controller.text.trim()) ?? 0;
    final requestedKg = _isAutoconsumo ? currentQty : currentQty * 50;
    final isOverLimit = currentQty > 0 && requestedKg > availableKg;

    const styleNormal = TextStyle(fontSize: FontSizeConfig.captionSize, color: AppColors.textPrimary);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isOverLimit ? AppColors.error : AppColors.textPrimary, width: isOverLimit ? 1.0 : 1.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: nombre + módulo/kg (siempre visible) ─────────
          InkWell(
            onTap: () => setState(() => _expandedItems[index] = !isExpanded),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusMedium),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: nombre + icono expand
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${producer['first_name']} ${producer['last_name']}',
                          style: const TextStyle(
                            fontSize: FontSizeConfig.smallSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingXSmall),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXSmall),
                  // Fila 2: fecha (flexible) + kg
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatDate(batch['process_date']),
                          style: styleNormal,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const Spacer(),
                      Text('${availableKg.toStringAsFixed(1)} kg disp.', style: styleNormal),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Detalles desplegables (van ENCIMA de los inputs) ─────
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border.symmetric(horizontal: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lote: ${batch['batch_code']}', style: styleNormal),
                  if (moduleName != null)
                    Text('Módulo: $moduleName', style: styleNormal),
                  Text(
                    remainderKg > 0.05
                        ? 'Disponible: $availableBags sacos + ${remainderKg.toStringAsFixed(1)} kg'
                        : 'Disponible: $availableBags sacos',
                    style: styleNormal,
                  ),
                ],
              ),
            ),

          // ── Inputs: cantidad + equivale + comprobante (siempre) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingMedium,
              0,
              AppDimensions.paddingMedium,
              AppDimensions.paddingMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: AppDimensions.spacingMedium),
                AppTextField(
                  label: _isAutoconsumo ? 'Cantidad en kilogramos' : 'Cantidad en sacos',
                  controller: controller,
                  keyboardType: TextInputType.number,
                  suffixText: _isAutoconsumo ? 'kg' : 'sacos',
                  hintText: _isAutoconsumo ? 'Ej: 25.5' : 'Ej: 5',
                ),
                if (!_isAutoconsumo && currentQty > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                      vertical: AppDimensions.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: isOverLimit ? AppColors.errorLight : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(
                        color: isOverLimit ? AppColors.error : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOverLimit ? Icons.warning_amber_rounded : Icons.scale_outlined,
                          color: isOverLimit ? AppColors.error : AppColors.primary,
                          size: AppDimensions.iconMedium,
                        ),
                        const SizedBox(width: AppDimensions.spacingSmall),
                        Expanded(
                          child: Text(
                            'Equivale a ${(currentQty * 50).toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: isOverLimit ? AppColors.error : AppColors.textPrimary,
                              fontSize: FontSizeConfig.smallSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!_isAutoconsumo && availableKg % 50 != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Incluye fracción: máximo ${_kgToBagsText(availableKg)} sacos (${availableKg.toStringAsFixed(1)} kg)',
                      style: const TextStyle(color: AppColors.warning, fontSize: FontSizeConfig.captionSize),
                    ),
                  ),
                if (isOverLimit)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Excede el stock disponible (${availableKg.toStringAsFixed(1)} kg)',
                      style: const TextStyle(color: AppColors.error, fontSize: FontSizeConfig.captionSize),
                    ),
                  ),
                const SizedBox(height: AppDimensions.spacingMedium),
                AppTextField(
                  label: 'Comprobante de acopio',
                  controller: documentController,
                  hintText: 'Ej: RCP-001, FACT-123',
                  suffixText: _isAutoconsumo ? 'Opcional' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExitDocument() {
    return FormGroup(
      spacing: context.responsiveSpacing,
      children: [
        const AppTitle(
          title: 'KARDEX',
          subtitle: 'Registro de Salida',
        ),
        FormSection(
          title: 'Documento de salida',
          subtitle: 'Ingrese el documento que acredite la salida (N° de guía de remisión)',
          children: [
            SizedBox(height: context.responsiveSpacing),
            AppTextField(
              label: 'Fecha de salida',
              controller: _exitDateController,
              readOnly: true,
              onTap: _selectExitDate,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectExitDate,
              ),
            ),
            SizedBox(height: context.responsiveSpacing),
            AppTextField(
              label: 'Guía de remisión (opcional)',
              controller: _documentController,
              hintText: 'Ej: 001-0042',
            ),
            SizedBox(height: AppDimensions.spacingLarge),
            _buildContinueButton(
              _completeRegistration,
              text: 'REGISTRAR SALIDA',
            ),
          ],
        ),
      ],
    );
  }

  void _handleBackNavigation() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _scrollController.jumpTo(0);
    } else {
      _leave();
    }
  }

  Future<void> _completeRegistration() async {
    if (_isSubmitting) return;
    if (!await AppConfirmDialog.show(context)) return;

    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Get current user's DNI
      final userDNI = await _authService.getCurrentUserDNI();
      if (userDNI == null) {
        throw Exception('No se pudo obtener el DNI del usuario actual');
      }
      
      // Parse selected exit date
      final selectedDate = AppDateUtils.parseDDMMYYYY(_exitDateController.text);
      if (selectedDate == null) {
        throw Exception('Fecha de salida inválida');
      }

      // Create exit registration request
      final exitRequest = CreateExitRegistrationRequest(
        documentNumber: _documentController.text.trim().isEmpty ? null : _documentController.text.trim(),
        exitDate: selectedDate,
        destination: AppConfig.current.code,
        cooperativeId: AppConfig.current.id,
        createdBy: userDNI,
      );
      
      // Create exit items
      final List<CreateExitItemRequest> itemRequests = [];
      for (int i = 0; i < _selectedStock.length; i++) {
        if (!_selectedStock[i]) continue;

        final stock = _availableStock[i];
        final batch = stock['production_batch'];
        final controller = _quantityControllers[i];
        final documentController = _itemDocumentControllers[i];
        final quantity = double.parse(controller.text.trim());
        final quantityKg = _isAutoconsumo ? quantity : quantity * 50;

        itemRequests.add(CreateExitItemRequest(
          exitRegistrationId: '', // Will be set by the service
          productionBatchId: batch['id'],
          quantityKg: quantityKg,
          isAutoconsumo: _isAutoconsumo,
          bagsCount: _isAutoconsumo ? 0.0 : quantityKg / 50,
          itemDocumentNumber: documentController.text.trim().isEmpty
              ? null
              : documentController.text.trim(),
          cooperativeId: stock['cooperative_id'],
        ));
      }
      
      // Create the exit registration with items
      await _exitService.createExitRegistrationWithItems(exitRequest, itemRequests);
      
      if (kDebugMode) {
        debugPrint('Exit registration completed: ${itemRequests.length} items');
        for (var item in itemRequests) {
          debugPrint('- Batch ${item.productionBatchId}: ${item.quantityKg} kg (autoconsumo: ${item.isAutoconsumo})');
        }
      }
      
      // Show success message and navigate to success screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro de salida completado con éxito')),
        );
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => const SuccessRegistrationScreen(type: RegistrationType.kardexExit)
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar salida: $e'),
            backgroundColor: AppColors.error,
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


  Future<void> _selectExitDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'PE'),
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _exitDateController.text = AppDateUtils.formatDDMMYYYY(picked);
      });
    }
  }

  Widget _buildContinueButton(VoidCallback onPressed, {String text = 'CONTINUAR'}) {
    return AppButton(
      text: text,
      type: AppButtonType.primary,
      onPressed: onPressed,
      isLoading: _isSubmitting,
    );
  }
}

class _ExitTypeButton extends StatelessWidget {
  const _ExitTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.height,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.surface,
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.border,
            width: isSelected ? 2.0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppDimensions.iconSmall,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              Text(
                label,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                  fontSize: FontSizeConfig.captionSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}