// =====================================================
// Worker Control Registration Screen
// 2-Step Wizard: Production Batch Selection → Worker Details
// =====================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/services/worker_control_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/services/product_return_service.dart';

class WorkerControlRegistrationScreen extends StatefulWidget {
  const WorkerControlRegistrationScreen({super.key});

  @override
  State<WorkerControlRegistrationScreen> createState() =>
      _WorkerControlRegistrationScreenState();
}

class _WorkerControlRegistrationScreenState
    extends State<WorkerControlRegistrationScreen> {
  // Services
  final _workerControlService = WorkerControlService();
  final _productReturnService = ProductReturnService();

  // Wizard state
  int _currentStep = 0;

  // Step 0: Production batch selection
  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchId;
  Map<String, dynamic>? _selectedBatch;
  List<Map<String, dynamic>> _availableBatches = [];
  bool _isLoadingBatches = false;


  // Step 1: Worker details
  final _workerNameController = TextEditingController();
  WorkArea? _selectedWorkArea;
  bool _uniformComplete = true;
  bool _noMakeup = true;
  bool _nailsShortClean = true;
  bool _nailsNoPolish = true;
  bool _handsClean = true;
  bool _noJewelry = true;
  bool _hairCovered = true;
  bool _noBeard = true;
  bool _noWounds = true;
  final _observationsController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // =====================================================
  // Data Loading
  // =====================================================

  Future<void> _loadBatches() async {
    setState(() => _isLoadingBatches = true);

    try {
      final batches = await _productReturnService.getBatchesByDate(_selectedDate);

      setState(() {
        _availableBatches = batches;
        _isLoadingBatches = false;
        // Reset batch selection when date changes
        _selectedBatchId = null;
        _selectedBatch = null;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al cargar lotes: $e',
          type: SnackBarType.error,
        );
        setState(() => _isLoadingBatches = false);
      }
    }
  }

  // =====================================================
  // Navigation
  // =====================================================

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep0()) {
      return;
    }

    setState(() {
      if (_currentStep < 1) {
        _currentStep++;
      }
    });
  }

  void _previousStep() {
    if (_currentStep == 0) {
      _showExitConfirmation();
    } else {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateStep0() {
    if (_selectedBatchId == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona un lote de producción',
        type: SnackBarType.error,
      );
      return false;
    }

    return true;
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar registro'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar? Se perderán todos los datos ingresados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.controlForms.path);
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Date Picker
  // =====================================================

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadBatches();
    }
  }

  // =====================================================
  // Submit
  // =====================================================

  Future<void> _submitForm() async {
    // Validate Step 1
    if (_workerNameController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ingresa el nombre del trabajador',
        type: SnackBarType.error,
      );
      return;
    }

    if (_selectedWorkArea == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona el área de trabajo',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = CreateWorkerControlRequest(
        productionBatchId: _selectedBatchId!,
        workerName: _workerNameController.text.trim(),
        workArea: _selectedWorkArea!,
        uniformComplete: _uniformComplete,
        noMakeup: _noMakeup,
        nailsShortClean: _nailsShortClean,
        nailsNoPolish: _nailsNoPolish,
        handsClean: _handsClean,
        noJewelry: _noJewelry,
        hairCovered: _hairCovered,
        noBeard: _noBeard,
        noWounds: _noWounds,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        cooperativeId: AppConfig.current.id,
      );

      await _workerControlService.createWorkerControl(request);

      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Control registrado exitosamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlForms.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al guardar: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // =====================================================
  // UI Rendering
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Control de Personal Operario',
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
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_currentStep == 0) {
      return _buildStep0();
    } else {
      return _buildStep1();
    }
  }

  // =====================================================
  // Step 0: Production Batch Selection
  // =====================================================

  Widget _buildStep0() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          // Back button
          AppBackButton(
            onPressed: () => context.go(AppRoutes.controlForms.path),
            isExpanded: true,
          ),
          SizedBox(height: context.responsiveSpacing),

          const AppTitle(title: 'Seleccionar Lote de Producción'),
          const SizedBox(height: 8),
          Text(
            'Elige la fecha y el lote de producción para registrar los controles',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Date picker
          AppTextField(
            label: 'Fecha de producción',
            controller: TextEditingController(
              text: DateFormat('dd/MM/yyyy').format(_selectedDate),
            ),
            readOnly: true,
            onTap: _selectDate,
            suffixIcon: const Icon(Icons.calendar_today),
          ),

          // Production batch dropdown
          if (_isLoadingBatches)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_availableBatches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay lotes de producción para esta fecha',
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            AppDropdown<String>(
              label: 'Lote de Producción',
              value: _selectedBatchId,
              options: _availableBatches
                  .map(
                    (batch) {
                      final producer = batch['producers'] as Map<String, dynamic>;
                      final producerName = '${producer['first_name']} ${producer['last_name']}';
                      final label = '$producerName (${batch['panela_kg']} kg)';
                      return DropdownOption(
                        value: batch['id'] as String,
                        label: label,
                      );
                    },
                  )
                  .toList(),
              onChanged: (batchId) {
                setState(() {
                  _selectedBatchId = batchId;
                  _selectedBatch = batchId != null
                      ? _availableBatches.firstWhere((b) => b['id'] == batchId)
                      : null;
                });
              },
            ),

          const SizedBox(height: 24),

          // Button
          AppButton(
            text: 'Continuar',
            type: AppButtonType.primary,
            onPressed: _availableBatches.isEmpty ? null : _nextStep,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Step 1: Worker Details
  // =====================================================

  Widget _buildStep1() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          // Back button
          AppBackButton(
            onPressed: _previousStep,
            isExpanded: true,
          ),
          SizedBox(height: context.responsiveSpacing),

          const AppTitle(title: 'Detalles del Trabajador'),
          const SizedBox(height: 8),
          Text(
            'Registra la información del trabajador y sus cumplimientos de higiene',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Worker name
          AppTextField(
            label: 'Nombre del Trabajador',
            controller: _workerNameController,
            hintText: 'Ej: Juan García',
          ),

          // Work area dropdown
          AppDropdown<WorkArea>(
            label: 'Área de Trabajo',
            value: _selectedWorkArea,
            options: WorkArea.values
                .map(
                  (area) => DropdownOption(
                    value: area,
                    label: area.displayName,
                  ),
                )
                .toList(),
            onChanged: (area) {
              setState(() {
                _selectedWorkArea = area;
              });
            },
          ),

          // Checkboxes header
          const SizedBox(height: 24),
          Text(
            'Cumplimiento de Higiene y Seguridad:',
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: 12),

          // Checkbox: Uniform
          CheckboxListTile(
            title: const Text('Uso de uniforme completo'),
            value: _uniformComplete,
            onChanged: (checked) {
              setState(() {
                _uniformComplete = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: Makeup
          CheckboxListTile(
            title: const Text('Rostro sin maquillaje'),
            value: _noMakeup,
            onChanged: (checked) {
              setState(() {
                _noMakeup = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: Nails short and clean
          CheckboxListTile(
            title: const Text('Uñas cortas limpias'),
            value: _nailsShortClean,
            onChanged: (checked) {
              setState(() {
                _nailsShortClean = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: Nails no polish
          CheckboxListTile(
            title: const Text('Uñas no esmaltadas'),
            value: _nailsNoPolish,
            onChanged: (checked) {
              setState(() {
                _nailsNoPolish = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: Hands clean
          CheckboxListTile(
            title: const Text('Manos limpias'),
            value: _handsClean,
            onChanged: (checked) {
              setState(() {
                _handsClean = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: No jewelry
          CheckboxListTile(
            title: const Text('Sin joyas, accesorios ni perfume'),
            value: _noJewelry,
            onChanged: (checked) {
              setState(() {
                _noJewelry = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: Hair covered
          CheckboxListTile(
            title: const Text('Cabello corto o recogido'),
            value: _hairCovered,
            onChanged: (checked) {
              setState(() {
                _hairCovered = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: No beard
          CheckboxListTile(
            title: const Text('Sin barba'),
            value: _noBeard,
            onChanged: (checked) {
              setState(() {
                _noBeard = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Checkbox: No wounds
          CheckboxListTile(
            title: const Text('Ausencia de heridas y cortes'),
            value: _noWounds,
            onChanged: (checked) {
              setState(() {
                _noWounds = checked ?? true;
              });
            },
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          // Observations
          const SizedBox(height: 24),
          AppTextField(
            label: 'Observaciones (opcional)',
            controller: _observationsController,
            maxLines: 4,
            hintText: 'Ej: Incumplimiento observado...',
          ),

          const SizedBox(height: 24),

          // Submit button
          AppButton(
            text: _isSaving ? 'Guardando...' : 'Guardar',
            type: AppButtonType.primary,
            onPressed: _isSaving ? null : _submitForm,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}
