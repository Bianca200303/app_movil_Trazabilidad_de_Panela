import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/worker_control_service.dart';
import 'package:panela_sys/services/product_return_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/widgets/worker_evaluation_card.dart';

// ── Modelo interno ────────────────────────────────────────────────────────────

class _AreaEntry {
  final String? existingId;
  final WorkArea workArea;
  final String? observations;
  final List<WorkerEvaluation> workers;

  _AreaEntry({
    this.existingId,
    required this.workArea,
    this.observations,
    required this.workers,
  });

  _AreaEntry copyWith({
    String? observations,
    List<WorkerEvaluation>? workers,
  }) =>
      _AreaEntry(
        existingId: existingId,
        workArea: workArea,
        observations: observations ?? this.observations,
        workers: workers ?? this.workers,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class WorkerControlRegistrationScreen extends ConsumerStatefulWidget {
  const WorkerControlRegistrationScreen({super.key});

  @override
  ConsumerState<WorkerControlRegistrationScreen> createState() =>
      _WorkerControlRegistrationScreenState();
}

class _WorkerControlRegistrationScreenState
    extends ConsumerState<WorkerControlRegistrationScreen> {
  final _workerControlService = WorkerControlService();
  final _productReturnService = ProductReturnService();
  final _scrollController = ScrollController();

  int _currentStep = 0;
  bool _isSaving = false;

  // ── Step 0 ──────────────────────────────────────────────────────────────────
  late DateTime _from;
  late DateTime _to;
  List<Map<String, dynamic>> _availableBatches = [];
  bool _isLoadingBatches = false;
  Map<String, List<WorkerControl>> _existingByBatch = {};

  String? _selectedBatchId;
  Map<String, dynamic>? _selectedBatch;

  // ── Step 1 — áreas ──────────────────────────────────────────────────────────
  List<_AreaEntry> _areaEntries = [];
  int? _editingIndex; // null = agregando nueva área

  // Form de área actual
  WorkArea? _formArea;
  final _formObsController = TextEditingController();

  // Workers del área actual
  List<WorkerEvaluation> _formWorkers = [];
  final _nameController = TextEditingController();
  bool _uniformComplete = true;
  bool _noMakeup = true;
  bool _nailsShortClean = true;
  bool _nailsNoPolish = true;
  bool _handsClean = true;
  bool _noJewelry = true;
  bool _hairCovered = true;
  bool _noBeard = true;
  bool _noWounds = true;

  // ── Init / Dispose ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final (from, to) = historialPeriodoRange(HistorialPeriodo.esteMes);
    _from = from;
    _to = to;
    _loadBatches();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _formObsController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  List<String>? get _moduleIds {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.hasModuleRestriction) return null;
    return user.moduleIds.isEmpty ? null : user.moduleIds;
  }

  Future<void> _loadBatches() async {
    setState(() { _isLoadingBatches = true; _selectedBatchId = null; _selectedBatch = null; });
    try {
      final batches = await _productReturnService.getBatchesByRange(
        _from, _to, moduleIds: _moduleIds,
      );
      final ids = batches.map((b) => b['id'] as String).toList();
      final existing = await _workerControlService.getControlsByBatchIds(
        AppConfig.current.id, ids,
      );
      setState(() {
        _availableBatches = batches;
        _existingByBatch = existing;
        _isLoadingBatches = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: 'Error al cargar lotes: $e', type: SnackBarType.error);
        setState(() => _isLoadingBatches = false);
      }
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _selectBatch(Map<String, dynamic> batch) {
    final id = batch['id'] as String;
    final existing = _existingByBatch[id] ?? [];
    setState(() {
      _selectedBatchId = id;
      _selectedBatch = batch;
      _areaEntries = existing.map((c) => _AreaEntry(
        existingId: c.id,
        workArea: c.workArea,
        observations: c.observations,
        workers: c.workersList,
      )).toList();
      _editingIndex = null;
      _resetForm();
    });
  }

  void _nextStep() {
    if (_selectedBatchId == null) {
      AppSnackBar.show(context, message: 'Selecciona un lote de producción', type: SnackBarType.error);
      return;
    }
    setState(() => _currentStep = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _previousStep() {
    if (_currentStep == 0) {
      context.go(AppRoutes.controlFormsProduccion.path);
    } else {
      setState(() { _currentStep = 0; _editingIndex = null; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
    }
  }

  // ── Worker form helpers ───────────────────────────────────────────────────────

  void _resetForm() {
    _formArea = null;
    _formObsController.clear();
    _formWorkers = [];
    _resetTempWorker();
  }

  void _resetTempWorker() {
    _nameController.clear();
    _uniformComplete = true; _noMakeup = true; _nailsShortClean = true;
    _nailsNoPolish = true; _handsClean = true; _noJewelry = true;
    _hairCovered = true; _noBeard = true; _noWounds = true;
  }

  void _loadAreaIntoForm(_AreaEntry entry, int index) {
    setState(() {
      _editingIndex = index;
      _formArea = entry.workArea;
      _formObsController.text = entry.observations ?? '';
      _formWorkers = List.from(entry.workers);
      _resetTempWorker();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(999999);
    });
  }

  bool _addTempWorker() {
    if (_nameController.text.trim().isEmpty) {
      AppSnackBar.show(context, message: 'Ingresa el nombre del trabajador', type: SnackBarType.error);
      return false;
    }
    setState(() {
      _formWorkers.add(WorkerEvaluation(
        workerName: _nameController.text.trim(),
        uniformComplete: _uniformComplete, noMakeup: _noMakeup,
        nailsShortClean: _nailsShortClean, nailsNoPolish: _nailsNoPolish,
        handsClean: _handsClean, noJewelry: _noJewelry,
        hairCovered: _hairCovered, noBeard: _noBeard, noWounds: _noWounds,
      ));
      _resetTempWorker();
    });
    return true;
  }

  Future<bool> _checkPendingWorker() async {
    if (_nameController.text.trim().isEmpty) return true;
    final add = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Trabajador sin añadir'),
        content: Text('Tienes a "${_nameController.text.trim()}" a medio registrar. ¿Añadirlo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Descartar', style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Añadir')),
        ],
      ),
    );
    if (add == null) return false;
    if (add) return _addTempWorker();
    _resetTempWorker();
    return true;
  }

  void _saveArea() async {
    if (_formArea == null) {
      AppSnackBar.show(context, message: 'Selecciona el área de trabajo', type: SnackBarType.error);
      return;
    }
    if (!await _checkPendingWorker()) return;
    if (_formWorkers.isEmpty) {
      AppSnackBar.show(context, message: 'Añade al menos un trabajador', type: SnackBarType.error);
      return;
    }

    final entry = _AreaEntry(
      existingId: _editingIndex != null ? _areaEntries[_editingIndex!].existingId : null,
      workArea: _formArea!,
      observations: _formObsController.text.trim().isEmpty ? null : _formObsController.text.trim(),
      workers: List.from(_formWorkers),
    );

    setState(() {
      if (_editingIndex != null) {
        _areaEntries[_editingIndex!] = entry;
      } else {
        _areaEntries.add(entry);
      }
      _editingIndex = null;
      _resetForm();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submitAll() async {
    if (_areaEntries.isEmpty) {
      AppSnackBar.show(context, message: 'Añade al menos un área evaluada', type: SnackBarType.error);
      return;
    }
    if (!await AppConfirmDialog.show(context)) return;
    setState(() => _isSaving = true);
    try {
      for (final entry in _areaEntries) {
        final req = CreateWorkerControlRequest(
          productionBatchId: _selectedBatchId!,
          workArea: entry.workArea,
          observations: entry.observations,
          cooperativeId: AppConfig.current.id,
          workers: entry.workers,
        );
        if (entry.existingId != null) {
          await _workerControlService.updateWorkerControlFull(entry.existingId!, req);
        } else {
          await _workerControlService.createWorkerControl(req);
        }
      }
      if (mounted) {
        AppSnackBar.show(context, message: 'Control registrado exitosamente', type: SnackBarType.success);
        context.go(AppRoutes.controlFormsProduccion.path);
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, message: 'Error al guardar: $e', type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

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

  // ── Step 0 ────────────────────────────────────────────────────────────────────

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
          HistorialPeriodFilter(
            initial: HistorialPeriodo.esteMes,
            onChanged: (from, to) { _from = from; _to = to; _loadBatches(); },
          ),
          const SizedBox(height: 16),
          if (_isLoadingBatches)
            const Center(child: CircularProgressIndicator())
          else if (_availableBatches.isEmpty)
            Text('No hay lotes para este período', style: AppTextStyles.bodyText)
          else
            _buildBatchList(),
          const SizedBox(height: 24),
          AppButton(
            text: 'Continuar',
            type: AppButtonType.primary,
            onPressed: _selectedBatchId != null ? _nextStep : null,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lote de Producción', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        ..._availableBatches.map((batch) {
          final id = batch['id'] as String;
          final isSelected = _selectedBatchId == id;
          final isEvaluated = _existingByBatch.containsKey(id);
          final producer = batch['producers'] as Map<String, dynamic>;
          final panelaKg = (batch['panela_kg'] as num?)?.toDouble() ?? 0.0;
          final confitilloKg = (batch['confitillo_kg'] as num?)?.toDouble() ?? 0.0;
          final processDateRaw = batch['process_date'] as String?;
          final processDate = processDateRaw != null
              ? AppDateUtils.formatDDMMYYYY(DateTime.parse(processDateRaw))
              : null;

          return GestureDetector(
            onTap: () => _selectBatch(batch),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : isEvaluated
                        ? Colors.green.withValues(alpha: 0.06)
                        : AppColors.inputFill,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isEvaluated
                          ? Colors.green.shade400
                          : AppColors.inputBorder,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        if (processDate != null)
                          Text(processDate, style: AppTextStyles.captionText),
                        const SizedBox(height: 2),
                        Text(
                          'Panela: ${panelaKg % 1 == 0 ? panelaKg.toInt() : panelaKg} kg'
                          '${confitilloKg > 0 ? '  •  Confitillo: ${confitilloKg % 1 == 0 ? confitilloKg.toInt() : confitilloKg} kg' : ''}',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  if (isEvaluated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade400),
                      ),
                      child: Text(
                        'Ya evaluado',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
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

  // ── Step 1 ────────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final batch = _selectedBatch;
    final producer = batch?['producers'] as Map<String, dynamic>?;
    final processDateRaw = batch?['process_date'] as String?;
    final processDate = processDateRaw != null
        ? AppDateUtils.formatDDMMYYYY(DateTime.parse(processDateRaw))
        : null;

    // Areas ya usadas (para deshabilitar en el selector cuando se agrega nueva)
    final usedAreas = _editingIndex != null
        ? _areaEntries
            .asMap()
            .entries
            .where((e) => e.key != _editingIndex)
            .map((e) => e.value.workArea)
            .toSet()
        : _areaEntries.map((e) => e.workArea).toSet();

    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          AppBackButton(onPressed: _previousStep, isExpanded: true),
          SizedBox(height: context.responsiveSpacing),

          // Banner lote fijo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producer != null
                            ? '${producer['first_name']} ${producer['last_name']}'
                            : 'Lote seleccionado',
                        style: AppTextStyles.fieldLabel.copyWith(color: AppColors.primary),
                      ),
                      if (processDate != null)
                        Text(processDate, style: AppTextStyles.captionText),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lista de áreas ya añadidas
          if (_areaEntries.isNotEmpty) ...[
            Text('Áreas evaluadas (${_areaEntries.length}):', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            ..._areaEntries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final isEditing = _editingIndex == idx;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isEditing
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : Colors.green.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEditing ? AppColors.primary : Colors.green.shade400,
                    width: isEditing ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.edit : Icons.check_circle,
                      size: 18,
                      color: isEditing ? AppColors.primary : Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.workArea.displayName,
                              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
                          Text('${entry.workers.length} trabajador${entry.workers.length != 1 ? 'es' : ''}',
                              style: AppTextStyles.captionText),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _loadAreaIntoForm(entry, idx),
                      child: Text(isEditing ? 'Editando...' : 'Editar',
                          style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ),
                    if (!isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () => setState(() => _areaEntries.removeAt(idx)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            }),
            const Divider(height: 32),
          ],

          // Formulario de área
          Text(
            _editingIndex != null ? 'Editando área:' : 'Nueva área:',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 12),

          AppDropdown<WorkArea>(
            label: 'Área de Trabajo',
            value: _formArea,
            options: WorkArea.values
                .where((a) => !usedAreas.contains(a))
                .map((a) => DropdownOption(value: a, label: a.displayName))
                .toList(),
            onChanged: (area) => setState(() => _formArea = area),
          ),

          const Divider(height: 32),

          // Workers del área
          if (_formWorkers.isNotEmpty) ...[
            Text('Trabajadores (${_formWorkers.length}):', style: AppTextStyles.fieldLabel),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _formWorkers.length,
              itemBuilder: (context, i) => WorkerEvaluationCard(
                worker: _formWorkers[i],
                onUpdate: (updated) => setState(() => _formWorkers[i] = updated),
                onDelete: () => setState(() => _formWorkers.removeAt(i)),
              ),
            ),
            const Divider(height: 32),
          ],

          // Formulario trabajador temporal
          Container(
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
                  _formWorkers.isEmpty ? 'Añadir primer trabajador:' : 'Añadir otro trabajador:',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Nombre del Trabajador',
                  controller: _nameController,
                  hintText: 'Ej: Juan García',
                ),
                const SizedBox(height: 16),
                Text('Cumplimiento de Higiene y Seguridad:', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 8),
                _check('Uso de uniforme completo', _uniformComplete, (v) => setState(() => _uniformComplete = v ?? true)),
                _check('Rostro sin maquillaje', _noMakeup, (v) => setState(() => _noMakeup = v ?? true)),
                _check('Uñas cortas limpias', _nailsShortClean, (v) => setState(() => _nailsShortClean = v ?? true)),
                _check('Uñas no esmaltadas', _nailsNoPolish, (v) => setState(() => _nailsNoPolish = v ?? true)),
                _check('Manos limpias', _handsClean, (v) => setState(() => _handsClean = v ?? true)),
                _check('Sin joyas ni perfume', _noJewelry, (v) => setState(() => _noJewelry = v ?? true)),
                _check('Cabello corto o recogido', _hairCovered, (v) => setState(() => _hairCovered = v ?? true)),
                _check('Sin barba', _noBeard, (v) => setState(() => _noBeard = v ?? true)),
                _check('Ausencia de heridas y cortes', _noWounds, (v) => setState(() => _noWounds = v ?? true)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _addTempWorker,
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

          const SizedBox(height: 16),
          AppTextField(
            label: 'Observaciones del área (opcional)',
            controller: _formObsController,
            maxLines: 2,
          ),

          const SizedBox(height: 16),
          AppButton(
            text: _editingIndex != null ? 'GUARDAR CAMBIOS DE ÁREA' : 'AÑADIR ÁREA',
            type: AppButtonType.secondary,
            onPressed: _saveArea,
            isExpanded: true,
          ),

          if (_areaEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppButton(
              text: _isSaving ? 'Guardando...' : 'REGISTRAR TODO',
              type: AppButtonType.primary,
              onPressed: _isSaving ? null : _submitAll,
              isExpanded: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool?> onChanged) =>
      CheckboxListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        dense: true,
        contentPadding: EdgeInsets.zero,
      );
}
