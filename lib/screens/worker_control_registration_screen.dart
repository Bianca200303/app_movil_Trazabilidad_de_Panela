import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/services/worker_control_service.dart';
import 'package:panela_sys/services/product_return_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/widgets/worker_evaluation_card.dart';

class WorkerControlRegistrationScreen extends StatefulWidget {
  const WorkerControlRegistrationScreen({super.key});

  @override
  State<WorkerControlRegistrationScreen> createState() =>
      _WorkerControlRegistrationScreenState();
}

class _WorkerControlRegistrationScreenState
    extends State<WorkerControlRegistrationScreen> {
  final _workerControlService = WorkerControlService();
  final _productReturnService = ProductReturnService();

  final _scrollController = ScrollController();
  final _workerFormKey = GlobalKey();

  int _currentStep = 0;
  bool _isSaving = false;

  // State Step 0
  DateTime _selectedDate = DateTime.now();
  String? _selectedBatchId;
  List<Map<String, dynamic>> _availableBatches = [];
  bool _isLoadingBatches = false;

  // State Step 1
  WorkArea? _selectedWorkArea;
  final _observationsController = TextEditingController();
  List<WorkerEvaluation> _addedWorkers = [];

  // Temporal worker state
  final _workerNameController = TextEditingController();
  bool _uniformComplete = true;
  bool _noMakeup = true;
  bool _nailsShortClean = true;
  bool _nailsNoPolish = true;
  bool _handsClean = true;
  bool _noJewelry = true;
  bool _hairCovered = true;
  bool _noBeard = true;
  bool _noWounds = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _workerNameController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  // =====================================================
  // Worker List Management
  // =====================================================

  bool _addWorker() {
    if (_workerNameController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Ingresa el nombre del trabajador primero',
        type: SnackBarType.error,
      );
      return false;
    }

    setState(() {
      _addedWorkers.add(
        WorkerEvaluation(
          workerName: _workerNameController.text.trim(),
          uniformComplete: _uniformComplete,
          noMakeup: _noMakeup,
          nailsShortClean: _nailsShortClean,
          nailsNoPolish: _nailsNoPolish,
          handsClean: _handsClean,
          noJewelry: _noJewelry,
          hairCovered: _hairCovered,
          noBeard: _noBeard,
          noWounds: _noWounds,
        ),
      );
      _resetTemporalWorkerState();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _workerFormKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });

    return true;
  }

  void _updateWorker(int index, WorkerEvaluation updatedWorker) {
    setState(() {
      _addedWorkers[index] = updatedWorker;
    });
  }

  void _removeWorker(int index) {
    setState(() {
      _addedWorkers.removeAt(index);
    });
  }

  void _resetTemporalWorkerState() {
    _workerNameController.clear();
    _uniformComplete = true;
    _noMakeup = true;
    _nailsShortClean = true;
    _nailsNoPolish = true;
    _handsClean = true;
    _noJewelry = true;
    _hairCovered = true;
    _noBeard = true;
    _noWounds = true;
  }

  // =====================================================
  // Validation and Submission logic
  // =====================================================

  /// Red de seguridad UX 2: Verifica si hay datos sin guardar
  Future<bool> _handlePendingWorkerData() async {
    if (_workerNameController.text.trim().isEmpty)
      return true; // No hay pendientes

    final bool? shouldAdd = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Trabajador sin añadir'),
        content: Text(
          'Tienes a "${_workerNameController.text.trim()}" a medio registrar. ¿Deseas añadirlo a la lista antes de guardar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Descartar y Guardar',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Añadir y Guardar'),
          ),
        ],
      ),
    );

    if (shouldAdd == null) return false; // El usuario canceló la operación
    if (shouldAdd) return _addWorker();

    _resetTemporalWorkerState(); // Descartar los datos temporales
    return true;
  }

  Future<void> _submitForm() async {
    if (_selectedWorkArea == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona el área de trabajo',
        type: SnackBarType.error,
      );
      return;
    }

    // Ejecuta la red de seguridad
    final canProceed = await _handlePendingWorkerData();
    if (!canProceed) return;

    if (_addedWorkers.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Debes añadir al menos un trabajador a la lista',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = CreateWorkerControlRequest(
        productionBatchId: _selectedBatchId!,
        workArea: _selectedWorkArea!,
        observations: _observationsController.text.trim().isEmpty
            ? null
            : _observationsController.text.trim(),
        cooperativeId: AppConfig.current.id,
        workers: _addedWorkers,
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
      if (mounted)
        AppSnackBar.show(
          context,
          message: 'Error al guardar: $e',
          type: SnackBarType.error,
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // =====================================================
  // Data Loading and Navigation (Standard logic)
  // =====================================================

  Future<void> _loadBatches() async {
    setState(() => _isLoadingBatches = true);
    try {
      final batches = await _productReturnService.getBatchesByDate(
        _selectedDate,
      );
      setState(() {
        _availableBatches = batches;
        _isLoadingBatches = false;
        _selectedBatchId = null;
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

  void _nextStep() {
    if (_currentStep == 0 && _selectedBatchId == null) {
      AppSnackBar.show(
        context,
        message: 'Selecciona un lote de producción',
        type: SnackBarType.error,
      );
      return;
    }
    setState(() {
      if (_currentStep < 1) _currentStep++;
    });
  }

  void _previousStep() {
    if (_currentStep == 0) {
      context.go(AppRoutes.controlForms.path);
    } else {
      setState(() => _currentStep--);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadBatches();
    }
  }

  // =====================================================
  // UI Building
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Control de Personal Operario',
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: context.responsiveHorizontalPadding.copyWith(
            top: context.responsivePadding.top,
            bottom: context.responsivePadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.responsiveCardWidth),
            child: _currentStep == 0 ? _buildStep0() : _buildStep1(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          AppBackButton(onPressed: _previousStep, isExpanded: true),
          SizedBox(height: context.responsiveSpacing),
          const AppTitle(title: 'Seleccionar Lote de Producción'),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Fecha de producción',
            controller: TextEditingController(
              text: DateFormat('dd/MM/yyyy').format(_selectedDate),
            ),
            readOnly: true,
            onTap: _selectDate,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          if (_isLoadingBatches)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_availableBatches.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'No hay lotes para esta fecha',
                style: AppTextStyles.bodyText,
              ),
            )
          else
            AppDropdown<String>(
              label: 'Lote de Producción',
              value: _selectedBatchId,
              options: _availableBatches.map((batch) {
                final producer = batch['producers'] as Map<String, dynamic>;
                return DropdownOption(
                  value: batch['id'] as String,
                  label:
                      '${producer['first_name']} ${producer['last_name']} (${batch['panela_kg']} kg)',
                );
              }).toList(),
              onChanged: (id) => setState(() => _selectedBatchId = id),
            ),
          const SizedBox(height: 24),
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

  Widget _buildStep1() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          AppBackButton(onPressed: _previousStep, isExpanded: true),
          SizedBox(height: context.responsiveSpacing),

          const AppTitle(title: 'Detalles del Grupo'),
          const SizedBox(height: 16),

          AppDropdown<WorkArea>(
            label: 'Área de Trabajo',
            value: _selectedWorkArea,
            options: WorkArea.values
                .map((a) => DropdownOption(value: a, label: a.displayName))
                .toList(),
            onChanged: (area) => setState(() => _selectedWorkArea = area),
          ),

          const Divider(height: 48),

          // Renderización de la lista de trabajadores con las nuevas tarjetas desplegables
          if (_addedWorkers.isNotEmpty) ...[
            Text(
              'Trabajadores añadidos (${_addedWorkers.length}):',
              style: AppTextStyles.fieldLabel,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addedWorkers.length,
              itemBuilder: (context, index) {
                return WorkerEvaluationCard(
                  worker: _addedWorkers[index],
                  onUpdate: (updatedWorker) =>
                      _updateWorker(index, updatedWorker),
                  onDelete: () => _removeWorker(index),
                );
              },
            ),
            const Divider(height: 48),
          ],

          // Formulario de ingreso encapsulado visualmente
          Container(
            key: _workerFormKey,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _addedWorkers.isEmpty
                      ? 'Añadir primer trabajador:'
                      : 'Añadir otro trabajador:',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nombre del Trabajador',
                  controller: _workerNameController,
                  hintText: 'Ej: Juan García',
                ),
                const SizedBox(height: 16),
                Text(
                  'Cumplimiento de Higiene y Seguridad:',
                  style: AppTextStyles.fieldLabel,
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  title: const Text('Uso de uniforme completo'),
                  value: _uniformComplete,
                  onChanged: (c) =>
                      setState(() => _uniformComplete = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Rostro sin maquillaje'),
                  value: _noMakeup,
                  onChanged: (c) => setState(() => _noMakeup = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Uñas cortas limpias'),
                  value: _nailsShortClean,
                  onChanged: (c) =>
                      setState(() => _nailsShortClean = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Uñas no esmaltadas'),
                  value: _nailsNoPolish,
                  onChanged: (c) => setState(() => _nailsNoPolish = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Manos limpias'),
                  value: _handsClean,
                  onChanged: (c) => setState(() => _handsClean = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Sin joyas ni perfume'),
                  value: _noJewelry,
                  onChanged: (c) => setState(() => _noJewelry = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Cabello corto o recogido'),
                  value: _hairCovered,
                  onChanged: (c) => setState(() => _hairCovered = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Sin barba'),
                  value: _noBeard,
                  onChanged: (c) => setState(() => _noBeard = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Ausencia de heridas y cortes'),
                  value: _noWounds,
                  onChanged: (c) => setState(() => _noWounds = c ?? true),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _addWorker,
                  icon: const Icon(Icons.person_add),
                  label: const Text('AGREGAR ESTA PERSONA'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 48),

          AppTextField(
            label: 'Observaciones generales del turno (opcional)',
            controller: _observationsController,
            maxLines: 3,
          ),

          const SizedBox(height: 24),
          AppButton(
            text: _isSaving ? 'Guardando...' : 'GUARDAR REGISTRO FINAL',
            type: AppButtonType.primary,
            onPressed: _isSaving ? null : _submitForm,
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}
