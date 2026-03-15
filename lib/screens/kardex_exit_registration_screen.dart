import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panela_sys/screens/success_registration_screen.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
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

class KardexExitRegistrationScreen extends StatefulWidget {
  const KardexExitRegistrationScreen({super.key});

  @override
  State<KardexExitRegistrationScreen> createState() => _KardexExitRegistrationScreenState();
}

class _KardexExitRegistrationScreenState extends State<KardexExitRegistrationScreen> {
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

  // Exit type state (global for all lots)
  bool _isAutoconsumo = false;

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubmitting = false;

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

      final stockData = await _inventoryService.getAvailableStock();
      
      setState(() {
        _availableStock = stockData;
        _selectedStock = List.filled(stockData.length, false);
        _quantityControllers = stockData.map((stock) {
          final availableKg = (stock['available_kg'] as num).toDouble();
          final bags = (availableKg / 50).floor();

       final controller = TextEditingController(text: bags.toString());
          // ESTO ES LO NUEVO: Escucha cada vez que se teclea un número
          controller.addListener(() {
            if (mounted) setState(() {}); 
          });
          return controller;
        }).toList();
        _itemDocumentControllers = stockData.map((_) {
          return TextEditingController();
        }).toList();
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
    switch (_currentStep) {
      case 1:
        return _buildProducerSelection();
      case 2:
        return _buildAdjustQuantity();
      case 3:
        return _buildExitDocument();
      default:
        return _buildProducerSelection();
    }
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
          subtitle: 'Seleccione el tipo de salida y los lotes disponibles',
          children: [
            SizedBox(height: context.responsiveSpacing),
            // Exit type switch (global for all lots)
            _buildExitTypeSwitch(),
            SizedBox(height: AppDimensions.spacingLarge),
            for (int i = 0; i < _availableStock.length; i++) ...[
              _buildStockCheckbox(i),
              if (i < _availableStock.length - 1) SizedBox(height: context.responsiveSpacing),
            ],
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
    final availableKg = (stock['available_kg'] as num).toDouble();
    final availableBags = (availableKg / 50).floor();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        color: AppColors.surface,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMedium),
        child: CheckboxListTile(
          title: Text(
            '${producer['first_name']} ${producer['last_name']}',
            style: AppTextStyles.fieldLabel,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lote: ${batch['batch_code']}',
                style: AppTextStyles.bodyText,
              ),
              Text(
                'Disponible: $availableBags sacos  •  ${availableKg.toStringAsFixed(1)} kg',
                style: AppTextStyles.bodyText,
              ),
              Text(
                'Fecha de proceso: ${_formatDate(batch['process_date'])}',
                style: AppTextStyles.bodyText,
              ),
            ],
          ),
          value: _selectedStock[index],
          onChanged: (bool? value) {
            setState(() {
              _selectedStock[index] = value!;
              _updateControllerValue(index);
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildExitTypeSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tipo de salida',
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' *',
              style: AppTextStyles.bodyText.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            color: AppColors.surface,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Acopio',
                  style: AppTextStyles.bodyText.copyWith(
                    color: Colors.black,
                    fontWeight: _isAutoconsumo ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _isAutoconsumo,
                onChanged: (value) {
                  setState(() {
                    _isAutoconsumo = value;
                    // Update all controller values when switching exit type
                    for (int i = 0; i < _quantityControllers.length; i++) {
                      _updateControllerValue(i);
                    }
                  });
                },
                activeColor: AppColors.warning,
              ),
              Expanded(
                child: Text(
                  'Autoconsumo',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyText.copyWith(
                    color: Colors.black,
                    fontWeight: _isAutoconsumo ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
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

            Container(
              padding: EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // Un color de fondo distinto para resaltar
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RESUMEN DE SALIDA',
                      style: AppTextStyles.sectionLabel.copyWith(color: AppColors.primary),
                    ),
                    SizedBox(height: AppDimensions.spacingSmall),
                    if (_isAutoconsumo) ...[
                      Text(
                        'Total a enviar: ${_calculateTotalSalidaKg().toStringAsFixed(1)} kg',
                        style: AppTextStyles.bodyTextLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Total a enviar: ${_calculateTotalSalidaSacos()} sacos',
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

  void _updateControllerValue(int index) {
    if (index >= _quantityControllers.length || index >= _availableStock.length) return;

    final controller = _quantityControllers[index];
    final stock = _availableStock[index];
    final availableKg = (stock['available_kg'] as num).toDouble();

    if (_isAutoconsumo) {
      // For autoconsumo, use kg
      controller.text = availableKg.toStringAsFixed(1);
    } else {
      // For normal exit, use bags
      final availableBags = (availableKg / 50).floor();
      controller.text = availableBags.toString();
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
    }
    return true;
  }

  Widget _buildQuantityAdjustment(int index) {
    final stock = _availableStock[index];
    final batch = stock['production_batch'];
    final producer = batch['producer'];
    final availableKg = (stock['available_kg'] as num).toDouble();
    final availableBags = (availableKg / 50).floor();
    final controller = _quantityControllers[index];
    final documentController = _itemDocumentControllers[index];

    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${producer['first_name']} ${producer['last_name']}',
            style: AppTextStyles.fieldLabel,
          ),
          Text(
            'Lote: ${batch['batch_code']}',
            style: AppTextStyles.bodyText,
          ),
          SizedBox(height: AppDimensions.spacingSmall),
          Text(
            _isAutoconsumo
                ? 'Tipo: Autoconsumo (kilogramos)'
                : 'Tipo: Acopio por sacos (1 saco = 50kg)',
            style: AppTextStyles.bodyText.copyWith(
              color: _isAutoconsumo ? AppColors.warning : AppColors.success,
            ),
          ),
          Text(
            'Disponible: $availableBags sacos  •  ${availableKg.toStringAsFixed(1)} kg',
            style: AppTextStyles.bodyText,
          ),
          Text(
            'Fecha de proceso: ${_formatDate(batch['process_date'])}',
            style: AppTextStyles.bodyText,
          ),
          SizedBox(height: AppDimensions.spacingMedium),
          AppTextField(
            label: _isAutoconsumo ? 'Cantidad en kilogramos' : 'Cantidad en sacos',
            controller: controller,
            keyboardType: TextInputType.number,
            suffixText: _isAutoconsumo ? 'kg' : 'sacos',
          ),
          SizedBox(height: AppDimensions.spacingMedium),
          AppTextField(
            label: 'Comprobante de acopio',
            controller: documentController,
            hintText: 'Ej: RCP-001, FACT-123',
            suffixText: 'Opcional',
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
              label: 'Número de documento (opcional)',
              controller: _documentController,
              hintText: 'Ej: RCP-001, FACT-123',
            ),
            SizedBox(height: AppDimensions.spacingLarge),
            _buildContinueButton(() {
              _completeRegistration();
            }),
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
      context.go(AppRoutes.home.path);
    }
  }

  Future<void> _completeRegistration() async {
    if (_isSubmitting) return;
    
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
          bagsCount: _isAutoconsumo ? 0 : quantity.round(),
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

  Widget _buildContinueButton(VoidCallback onPressed) {
    return AppButton(
      text: 'CONTINUAR',
      type: AppButtonType.primary,
      onPressed: onPressed,
      isLoading: _isSubmitting,
    );
  }

}