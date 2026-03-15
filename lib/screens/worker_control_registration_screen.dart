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
  final _workersListKey = GlobalKey();

  int _currentStep = 0;
  bool _isSaving = false;

  // State Step 0
  DateTime _selectedDate = DateTime.now();
  DateTime _calendarMonth = DateTime.now();
  Set<DateTime> _productionDates = {};
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
    _loadProductionDates();
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
      final ctx = _workersListKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.0,
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

  Future<void> _loadProductionDates() async {
    final dates = await _productReturnService.getProductionDates();
    if (mounted) setState(() => _productionDates = dates);
  }

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

  Widget _buildBatchSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lote de Producción', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        ..._availableBatches.map((batch) {
          final producer = batch['producers'] as Map<String, dynamic>;
          final isSelected = _selectedBatchId == batch['id'];
          final panelaKg = (batch['panela_kg'] as num?)?.toDouble() ?? 0.0;
          final confitilloKg =
              (batch['confitillo_kg'] as num?)?.toDouble() ?? 0.0;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedBatchId = batch['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.inputFill,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.inputBorder,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : AppColors.inputBorder,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${producer['first_name']} ${producer['last_name']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Panela: ${panelaKg % 1 == 0 ? panelaKg.toInt() : panelaKg} kg'
                          '${confitilloKg > 0 ? '  •  Confitillo: ${confitilloKg % 1 == 0 ? confitilloKg.toInt() : confitilloKg} kg' : ''}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInlineCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Lun, 7=Dom
    final canGoNext = _calendarMonth.year < now.year ||
        (_calendarMonth.year == now.year && _calendarMonth.month < now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado mes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _calendarMonth =
                    DateTime(_calendarMonth.year, _calendarMonth.month - 1);
              }),
            ),
            Text(
              DateFormat('MMMM yyyy', 'es').format(_calendarMonth),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoNext
                  ? () => setState(() {
                        _calendarMonth = DateTime(
                            _calendarMonth.year, _calendarMonth.month + 1);
                      })
                  : null,
            ),
          ],
        ),
        // Nombres de días
        Row(
          children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((d) {
            return Expanded(
              child: Center(
                child: Text(d,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // Cuadrícula de días
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemCount: (startWeekday - 1) + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday - 1) return const SizedBox();

            final day = index - (startWeekday - 1) + 1;
            final date =
                DateTime(_calendarMonth.year, _calendarMonth.month, day);
            final isFuture = date.isAfter(today);
            final isSelected = date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;
            final hasProduction = _productionDates.contains(date);

            Color? bgColor;
            Color textColor =
                isFuture ? Colors.grey.shade400 : Colors.black87;

            if (isSelected) {
              bgColor = AppColors.primary;
              textColor = Colors.white;
            } else if (hasProduction) {
              bgColor = AppColors.primary.withValues(alpha: 0.18);
              textColor = AppColors.primary;
            }

            return GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                      setState(() {
                        _selectedDate = date;
                        _selectedBatchId = null;
                      });
                      _loadBatches();
                    },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected || hasProduction
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Leyenda
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Text('Días con producción',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  // =====================================================
  // UI Building
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Control de personal operario',
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
          const AppTitle(title: 'Control de personal operario'),
          const SizedBox(height: 8),
          const SectionTitle(title: 'Seleccionar Lote de Producción'),
          const SizedBox(height: 24),
          _buildInlineCalendar(),
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
            _buildBatchSelector(),
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
              key: _workersListKey,
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
