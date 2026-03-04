import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/product_return.dart';
import 'package:panela_sys/services/product_return_service.dart';
import 'package:panela_sys/widgets/widgets.dart';

// ==================== ENUMS ====================
enum QuantityMode { bags, kilograms }

class ComplaintsReturnsRegistrationScreen extends StatefulWidget {
  const ComplaintsReturnsRegistrationScreen({super.key});

  @override
  State<ComplaintsReturnsRegistrationScreen> createState() =>
      _ComplaintsReturnsRegistrationScreenState();
}

class _ComplaintsReturnsRegistrationScreenState
    extends State<ComplaintsReturnsRegistrationScreen> {
  // ==================== SERVICES ====================
  final _productReturnService = ProductReturnService();

  // ==================== PRODUCTION DATE & BATCHES ====================
  DateTime _selectedProductionDate = DateTime.now();
  final _productionDateController = TextEditingController();
  bool _isLoadingBatches = false;
  String? _selectedBatchId;
  List<Map<String, dynamic>> _availableBatches = [];


  // ==================== RETURN DETAILS ====================
  final _clientNameController = TextEditingController();
  DateTime _returnDate = DateTime.now();
  final _returnDateController = TextEditingController();

  // ==================== QUANTITY MODE TOGGLE ====================
  QuantityMode _quantityMode = QuantityMode.bags;
  final _quantitySacksController = TextEditingController();
  final _quantityKgController = TextEditingController();

  // ==================== RETURN REASON & OBSERVATIONS ====================
  final _returnReasonController = TextEditingController();
  final _observationsController = TextEditingController();

  // ==================== UI STATE ====================
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _productionDateController.text =
        DateFormat('dd/MM/yyyy').format(_selectedProductionDate);
    _returnDateController.text =
        DateFormat('dd/MM/yyyy').format(_returnDate);
    _loadBatchesForDate();
  }

  @override
  void dispose() {
    _productionDateController.dispose();
    _returnDateController.dispose();
    _clientNameController.dispose();
    _quantitySacksController.dispose();
    _quantityKgController.dispose();
    _returnReasonController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // ==================== BATCH LOADING ====================

  Future<void> _loadBatchesForDate() async {
    setState(() => _isLoadingBatches = true);

    try {
      final batches =
          await _productReturnService.getBatchesByDate(_selectedProductionDate);

      setState(() {
        _availableBatches = batches;
        _selectedBatchId = null;
        _isLoadingBatches = false;
      });
    } catch (e) {
      setState(() => _isLoadingBatches = false);
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al cargar lotes: $e',
        );
      }
    }
  }

  // ==================== DATE PICKERS ====================

  Future<void> _pickProductionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedProductionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedProductionDate) {
      setState(() {
        _selectedProductionDate = picked;
        _productionDateController.text =
            DateFormat('dd/MM/yyyy').format(picked);
      });

      await _loadBatchesForDate();
    }
  }

  Future<void> _pickReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _returnDate) {
      setState(() {
        _returnDate = picked;
        _returnDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // ==================== QUANTITY MODE MANAGEMENT ====================

  void _onQuantityModeChanged(QuantityMode mode) {
    setState(() {
      _quantityMode = mode;
      if (mode == QuantityMode.bags) {
        _quantityKgController.clear();
      } else {
        _quantitySacksController.clear();
      }
    });
  }

  void _updateKgFromSacks() {
    final sacks = int.tryParse(_quantitySacksController.text) ?? 0;
    final kg = (sacks * 50.0).toStringAsFixed(2);
    setState(() {
      _quantityKgController.text = kg;
    });
  }

  double get _finalQuantityKg {
    if (_quantityMode == QuantityMode.bags) {
      final sacks = int.tryParse(_quantitySacksController.text) ?? 0;
      return sacks * 50.0;
    } else {
      return double.tryParse(_quantityKgController.text) ?? 0.0;
    }
  }

  int get _finalQuantitySacks {
    return _quantityMode == QuantityMode.bags
        ? (int.tryParse(_quantitySacksController.text) ?? 0)
        : 0;
  }

  // ==================== VALIDATION ====================

  String? _validateForm() {
    // Check production date batch selection
    if (_selectedBatchId == null || _selectedBatchId!.isEmpty) {
      return 'Por favor selecciona un lote de producción';
    }

    // Check client name
    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      return 'Por favor ingresa el nombre del cliente';
    }

    // Check quantity
    if (_finalQuantityKg <= 0) {
      return 'Por favor ingresa una cantidad válida (mayor a 0)';
    }

    // Check return reason
    final returnReason = _returnReasonController.text.trim();
    if (returnReason.isEmpty) {
      return 'Por favor ingresa la causa de la devolución';
    }

    return null;
  }

  // ==================== SUBMIT ====================

  Future<void> _submitForm() async {
    final validationError = _validateForm();
    if (validationError != null) {
      AppSnackBar.show(
        context,
        message: validationError,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = CreateProductReturnRequest(
        productionBatchId: _selectedBatchId!,
        clientName: _clientNameController.text.trim(),
        returnDate: _returnDate,
        quantityKg: _finalQuantityKg,
        quantitySacks: _finalQuantitySacks,
        returnReason: _returnReasonController.text.trim(),
        observations: _observationsController.text.trim().isNotEmpty
            ? _observationsController.text.trim()
            : null,
        cooperativeId: AppConfig.current.id,
      );

      await _productReturnService.createProductReturn(request);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Devolución registrada exitosamente',
        );
        context.go(AppRoutes.controlForms.path);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al registrar devolución: $e',
        );
      }
    }
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
              padding: context.responsivePadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Registrar devolución',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),

                  // ==================== SECTION 1: PRODUCTION DATE & BATCH ====================
                  Text(
                    'Lote de producción',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Production date picker
                  AppTextField(
                    label: 'Fecha de producción',
                    controller: _productionDateController,
                    readOnly: true,
                    onTap: _pickProductionDate,
                    suffixIcon: const Icon(Icons.calendar_today),
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  // Batch dropdown with loading state
                  if (_isLoadingBatches)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_availableBatches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'No hay lotes disponibles para esta fecha',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppDropdown<String>(
                          label: 'Lote de producción',
                          value: _selectedBatchId,
                          options: _availableBatches.map((batch) {
                            final producer = batch['producers'] as Map;
                            final producerName =
                                '${producer['first_name']} ${producer['last_name']}';
                            final label =
                                '$producerName (${batch['panela_kg']} kg)';
                            return DropdownOption<String>(
                              value: batch['id'] as String,
                              label: label,
                            );
                          }).toList(),
                          onChanged: (batchId) {
                            setState(() {
                              _selectedBatchId = batchId;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                      ],
                    ),

                  // Divider
                  const Divider(height: 32),

                  // ==================== SECTION 2: RETURN DETAILS ====================
                  Text(
                    'Información de la devolución',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Client name
                  AppTextField(
                    label: 'Cliente',
                    controller: _clientNameController,
                    hintText: 'Nombre del cliente que devuelve',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Return date picker
                  AppTextField(
                    label: 'Fecha de devolución',
                    controller: _returnDateController,
                    readOnly: true,
                    onTap: _pickReturnDate,
                    suffixIcon: const Icon(Icons.calendar_today),
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  // Quantity toggle
                  FormGroup(
                    children: [
                      Text(
                        'Cantidad devuelta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<QuantityMode>(
                              segments: [
                                ButtonSegment(
                                  value: QuantityMode.bags,
                                  label: Text('Sacos'),
                                ),
                                ButtonSegment(
                                  value: QuantityMode.kilograms,
                                  label: Text('Kilogramos'),
                                ),
                              ],
                              selected: <QuantityMode>{_quantityMode},
                              onSelectionChanged: (newSelection) {
                                _onQuantityModeChanged(newSelection.first);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_quantityMode == QuantityMode.bags)
                        AppTextField(
                          label: 'Sacos',
                          controller: _quantitySacksController,
                          keyboardType: TextInputType.number,
                          hintText: '0',
                          onChanged: (_) => _updateKgFromSacks(),
                          validator: (value) => null,
                        )
                      else
                        AppTextField(
                          label: 'Kilogramos',
                          controller: _quantityKgController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          hintText: '0.00',
                          validator: (value) => null,
                        ),
                      if (_quantityMode == QuantityMode.bags &&
                          _quantityKgController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Equivalente: ${_quantityKgController.text} kg',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Return reason
                  AppTextField(
                    label: 'Causa',
                    controller: _returnReasonController,
                    hintText: 'Motivo de la devolución',
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Observations
                  AppTextField(
                    label: 'Observaciones',
                    controller: _observationsController,
                    hintText: 'Notas adicionales (opcional)',
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // ==================== BUTTONS ====================
                  FormGroup(
                    children: [
                      if (context.shouldStackButtons)
                        // Vertical layout for small screens
                        Column(
                          children: [
                            AppButton(
                              text: 'Registrar devolución',
                              onPressed: _isSaving ? null : _submitForm,
                              isLoading: _isSaving,
                              type: AppButtonType.primary,
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              text: 'Cancelar',
                              onPressed: _isSaving
                                  ? null
                                  : () => context.go(AppRoutes.controlForms.path),
                              type: AppButtonType.secondary,
                            ),
                          ],
                        )
                      else
                        // Horizontal layout for larger screens
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Registrar devolución',
                                onPressed: _isSaving ? null : _submitForm,
                                isLoading: _isSaving,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                text: 'Cancelar',
                                onPressed: _isSaving
                                    ? null
                                    : () =>
                                        context.go(AppRoutes.controlForms.path),
                                type: AppButtonType.secondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
