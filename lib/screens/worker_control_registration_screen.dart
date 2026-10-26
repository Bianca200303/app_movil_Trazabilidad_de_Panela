import 'package:panela_sys/core/offline/user_error_message.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/worker_control_service.dart';
import 'package:panela_sys/services/recent_batches_service.dart';
import 'package:panela_sys/services/sync/pending_submissions_service.dart';
import 'package:panela_sys/services/sync/submissions/submission_kinds.dart';
import 'package:panela_sys/core/database/app_database.dart';
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
  final _recentBatchesService = RecentBatchesService();
  final _pendingSubmissionsDao = AppDatabase().pendingSubmissionsDao;
  final _coopModulesService = CoopModulesService();
  final _scrollController = ScrollController();

  int _currentStep = 0;
  bool _isSaving = false;

  // ── Step 0 ──────────────────────────────────────────────────────────────────
  late DateTime _from;
  late DateTime _to;
  List<Map<String, dynamic>> _availableBatches = [];
  bool _isLoadingBatches = false;
  Map<String, List<WorkerControl>> _existingByBatch = {};
  // Sin señal no se pueden traer las áreas ya enviadas de cada lote: se
  // avisa para no registrar dos veces la misma área.
  bool _existingUnavailable = false;
  // Áreas de este lote guardadas en el celular y aún no enviadas.
  int _pendingAreasForBatch = 0;

  // Filtro por módulo
  List<CoopModule> _assignedModules = [];
  bool _isLoadingModules = false;
  String? _selectedModuleId;

  String? _selectedBatchId;
  Map<String, dynamic>? _selectedBatch;

  // ── Step 1 — áreas ──────────────────────────────────────────────────────────
  List<_AreaEntry> _areaEntries = [];
  int? _editingIndex; // null = agregando nueva área

  // Form de área actual
  WorkArea? _formArea;
  final _formObsController = TextEditingController();

  // Búsqueda de lotes
  final _batchSearchController = TextEditingController();

  // Workers del área actual
  List<WorkerEvaluation> _formWorkers = [];
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
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
    _loadModules();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _formObsController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    _batchSearchController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  List<String>? get _moduleIds {
    final user = ref.read(currentUserProvider);
    if (user == null || !user.hasModuleRestriction) return null;
    return user.moduleIds.isEmpty ? null : user.moduleIds;
  }

  List<Map<String, dynamic>> get _moduleBatches {
    if (_selectedModuleId == null) return _availableBatches;
    return _availableBatches.where((b) {
      final producer = b['producers'] as Map<String, dynamic>;
      return (producer['coop_module_id'] as String?) == _selectedModuleId;
    }).toList();
  }

  Future<void> _loadModules() async {
    final user = ref.read(currentUserProvider);
    if (user == null) { _loadBatches(); return; }

    setState(() => _isLoadingModules = true);
    try {
      final all = await _coopModulesService.getModules();
      final assigned = user.hasModuleRestriction && user.moduleIds.isNotEmpty
          ? all.where((m) => user.moduleIds.contains(m.id)).toList()
          : all;
      if (!mounted) return;
      setState(() {
        _assignedModules = assigned;
        _isLoadingModules = false;
        if (assigned.length == 1) _selectedModuleId = assigned.first.id;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingModules = false);
    }
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() { _isLoadingBatches = true; _selectedBatchId = null; _selectedBatch = null; _batchSearchController.clear(); });
    try {
      // Con o sin señal: servidor (o su copia local de 30 días) + lotes
      // creados en este celular aún sin enviar.
      final batches = await _recentBatchesService.getBatches(
        _from, _to, moduleIds: _moduleIds,
      );
      final remoteIds = batches
          .where((b) => RecentBatchesService.localBatchIdOf(b) == null)
          .map((b) => b['id'] as String)
          .toList();

      var existing = <String, List<WorkerControl>>{};
      var existingUnavailable = false;
      try {
        existing = await _workerControlService.getControlsByBatchIds(
          AppConfig.current.id, remoteIds,
        );
      } catch (_) {
        existingUnavailable = true;
      }

      if (!mounted) return;
      setState(() {
        _availableBatches = batches;
        _existingByBatch = existing;
        _existingUnavailable = existingUnavailable;
        _isLoadingBatches = false;
      });
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: userErrorMessage(e, action: 'No se pudieron cargar los lotes'), type: SnackBarType.error);
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
      _batchSearchController.clear();
      _areaEntries = existing.map((c) => _AreaEntry(
        existingId: c.id,
        workArea: c.workArea,
        observations: c.observations,
        workers: c.workersList,
      )).toList();
      _editingIndex = null;
      _pendingAreasForBatch = 0;
      _resetForm();
    });
    _loadPendingAreas(batch);
  }

  Future<void> _loadPendingAreas(Map<String, dynamic> batch) async {
    final localId = RecentBatchesService.localBatchIdOf(batch);
    final remoteId = localId == null ? batch['id'] as String : null;
    final pending = await _pendingSubmissionsDao.getByKind(
      SubmissionKinds.workerControl,
      AppConfig.current.id,
    );
    final count = pending.where((p) {
      if (localId != null) return p.productionBatchLocalId == localId;
      return (jsonDecode(p.payload) as Map<String, dynamic>)['production_batch_id'] == remoteId;
    }).length;
    if (mounted && _selectedBatch == batch) setState(() => _pendingAreasForBatch = count);
  }

  void _clearBatchSelection() {
    setState(() {
      _selectedBatchId = null;
      _selectedBatch = null;
      _areaEntries = [];
      _batchSearchController.clear();
      _resetForm();
    });
  }

  /// Módulo del productor del lote: de ahí salen los trabajadores sugeridos.
  String? get _batchModuleId =>
      (_selectedBatch?['producers'] as Map<String, dynamic>?)?['coop_module_id'] as String?;

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedBatchId == null) {
        AppSnackBar.show(context, message: 'Selecciona un lote de producción', type: SnackBarType.error);
        return;
      }
      setState(() => _currentStep = _areaEntries.isNotEmpty ? 3 : 1);
    } else if (_currentStep == 1) {
      if (_formArea == null) {
        AppSnackBar.show(context, message: 'Selecciona el área de trabajo', type: SnackBarType.error);
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      _saveAreaAndContinue();
      return;
    }
    _scrollToTop();
  }

  void _previousStep() {
    if (_currentStep == 0) {
      _leave();
    } else if (_currentStep == 1) {
      setState(() { _currentStep = 0; _editingIndex = null; _resetForm(); });
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 1);
    }
    _scrollToTop();
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
      _currentStep = 1;
      _resetTempWorker();
    });
    _scrollToTop();
  }

  /// Nombre del trabajador que se está llenando (elegido de la lista o
  /// escrito a mano), o null si el campo está vacío.
  String? get _pendingWorkerName {
    final name = _nameController.text.trim();
    return name.isEmpty ? null : name;
  }

  bool _addTempWorker() {
    final name = _pendingWorkerName;
    if (name == null) {
      AppSnackBar.show(context, message: 'Elija o escriba el nombre del trabajador', type: SnackBarType.error);
      return false;
    }
    setState(() {
      _formWorkers.add(WorkerEvaluation(
        workerName: name,
        uniformComplete: _uniformComplete, noMakeup: _noMakeup,
        nailsShortClean: _nailsShortClean, nailsNoPolish: _nailsNoPolish,
        handsClean: _handsClean, noJewelry: _noJewelry,
        hairCovered: _hairCovered, noBeard: _noBeard, noWounds: _noWounds,
      ));
      _resetTempWorker();
    });
    _nameFocusNode.unfocus();
    return true;
  }

  Future<bool> _checkPendingWorker() async {
    final pendingName = _pendingWorkerName;
    if (pendingName == null) return true;
    final add = await AppConfirmDialog.choose<bool>(
      context,
      title: 'Trabajador sin añadir',
      message: 'Tiene a "$pendingName" a medio registrar. ¿Desea añadirlo?',
      actions: const [
        AppDialogAction('Descartar', false),
        AppDialogAction('Añadir', true, style: AppDialogActionStyle.primary),
      ],
    );
    if (add == null) return false;
    if (add) return _addTempWorker();
    _resetTempWorker();
    return true;
  }

  Future<void> _saveAreaAndContinue() async {
    if (!await _checkPendingWorker() || !mounted) return;
    if (_formWorkers.isEmpty) {
      AppSnackBar.show(context, message: 'Añada al menos un trabajador', type: SnackBarType.error);
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
      _currentStep = 3;
    });
    _scrollToTop();
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submitAll() async {
    if (_areaEntries.isEmpty) {
      AppSnackBar.show(context, message: 'Añade al menos un área evaluada', type: SnackBarType.error);
      return;
    }
    if (!await AppConfirmDialog.show(context)) return;
    setState(() => _isSaving = true);
    final localBatchId = RecentBatchesService.localBatchIdOf(_selectedBatch!);
    var anyQueued = false;
    // Áreas nuevas ya guardadas en esta pasada: si una posterior falla, se
    // quitan de la lista para que reintentar no las registre dos veces.
    final savedNew = <_AreaEntry>{};
    try {
      for (final entry in List.of(_areaEntries)) {
        if (entry.existingId != null) {
          // Editar un área ya enviada requiere señal (solo se cargan con señal).
          await _workerControlService.updateWorkerControlFull(
            entry.existingId!,
            CreateWorkerControlRequest(
              productionBatchId: _selectedBatchId!,
              workArea: entry.workArea,
              observations: entry.observations,
              cooperativeId: AppConfig.current.id,
              workers: entry.workers,
            ),
          );
        } else {
          final outcome = await _workerControlService.submitNewControl(
            productionBatchId: localBatchId == null ? _selectedBatchId : null,
            productionBatchLocalId: localBatchId,
            workArea: entry.workArea,
            observations: entry.observations,
            workers: entry.workers,
          );
          if (outcome == SubmissionOutcome.queued) anyQueued = true;
          savedNew.add(entry);
        }
      }
      if (mounted) {
        AppSnackBar.show(
          context,
          message: anyQueued
              ? 'Control guardado en el celular. Se enviará cuando haya conexión.'
              : 'Control registrado exitosamente',
          type: SnackBarType.success,
        );
        context.go(AppRoutes.controlFormsProduccion.path);
      }
    } catch (e) {
      if (!mounted) return;
      if (savedNew.isNotEmpty) {
        setState(() => _areaEntries.removeWhere(savedNew.contains));
      }
      AppSnackBar.show(
        context,
        message: savedNew.isEmpty
            ? userErrorMessage(e, action: 'No se pudo guardar')
            : userErrorMessage(e, action: 'Se guardaron ${savedNew.length} área(s); las demás no'),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  /// Hay datos ingresados que se perderían al salir (ver UnsavedChangesGuard).
  bool get _hasUnsavedChanges =>
      _currentStep > 0 || _selectedBatchId != null || _areaEntries.isNotEmpty;

  void _leave() => UnsavedChangesGuard.leave(
        context,
        hasUnsavedChanges: _hasUnsavedChanges,
        leave: () => context.go(AppRoutes.controlFormsProduccion.path),
      );

  @override
  Widget build(BuildContext context) => UnsavedChangesGuard(
        onBack: _previousStep,
        child: _buildForm(context),
      );

  Widget _buildForm(BuildContext context) {
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
            child: switch (_currentStep) {
              0 => _buildStep0(),
              1 => _buildStep1(),
              2 => _buildStep2(),
              _ => _buildStep3(),
            },
          ),
        ),
      ),
    );
  }

  // ── Shared: banner lote ───────────────────────────────────────────────────────

  Widget _buildLoteBanner() {
    final batch = _selectedBatch;
    final producer = batch?['producers'] as Map<String, dynamic>?;
    final processDateRaw = batch?['process_date'] as String?;
    final processDate = processDateRaw != null
        ? AppDateUtils.formatDDMMYYYY(DateTime.parse(processDateRaw))
        : null;
    final isLocalBatch = batch != null && RecentBatchesService.localBatchIdOf(batch) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLoteCard(producer, processDate),
        if (isLocalBatch)
          _buildNotice('Lote registrado en este celular y aún no enviado. El control '
              'se enviará después del lote.'),
        if (_existingUnavailable && !isLocalBatch)
          _buildNotice('Sin conexión: no se muestran las áreas ya enviadas de este '
              'lote. Evite registrar dos veces la misma área.'),
        if (_pendingAreasForBatch > 0)
          _buildNotice('Este lote tiene $_pendingAreasForBatch área(s) guardadas en '
              'el celular, pendientes de envío.'),
      ],
    );
  }

  Widget _buildNotice(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.captionText)),
        ],
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic>? producer, String? processDate) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textWhite),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('LOTE DE PRODUCCIÓN',
                      style: TextStyle(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producer != null
                      ? '${producer['first_name']} ${producer['last_name']}'
                      : 'Lote seleccionado',
                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                ),
                if (processDate != null) ...[
                  const SizedBox(height: 2),
                  Text('Fecha: $processDate', style: AppTextStyles.captionText),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Seleccionar lote ──────────────────────────────────────────────────

  Widget _buildStep0() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          AppBackButton(onPressed: _previousStep, isExpanded: false),
          SizedBox(height: context.responsiveSpacing),
          const _StepIndicatorBar(currentStep: 0),
          SizedBox(height: context.responsiveSpacing),
          HistorialPeriodFilter(
            initial: HistorialPeriodo.esteMes,
            onChanged: (from, to) { _from = from; _to = to; _loadBatches(); },
          ),
          if (_assignedModules.isNotEmpty) ...[
            const SizedBox(height: 16),
            SearchableDropdownField<CoopModule>(
              label: 'Módulo',
              items: _assignedModules,
              selectedValue: _assignedModules.where((m) => m.id == _selectedModuleId).firstOrNull,
              labelFor: (m) => m.name,
              hintText: 'Seleccionar módulo...',
              isLoading: _isLoadingModules,
              onChanged: (module) {
                setState(() {
                  _selectedModuleId = module?.id;
                  _selectedBatchId = null;
                  _selectedBatch = null;
                  _areaEntries = [];
                  _batchSearchController.clear();
                  _resetForm();
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          if (_isLoadingBatches)
            const Center(child: CircularProgressIndicator())
          else if (_moduleBatches.isEmpty)
            Text('No hay lotes para este período', style: AppTextStyles.bodyText)
          else
            _buildBatchList(),
          const SizedBox(height: 24),
          AppButton(
            text: 'CONTINUAR',
            type: AppButtonType.primary,
            onPressed: _selectedBatchId != null ? _nextStep : null,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchList() {
    // Lote ya seleccionado → tarjeta compacta con "Cambiar"
    if (_selectedBatchId != null && _selectedBatch != null) {
      final batch = _selectedBatch!;
      final producer = batch['producers'] as Map<String, dynamic>;
      final processDateRaw = batch['process_date'] as String?;
      final processDate = processDateRaw != null
          ? AppDateUtils.formatDDMMYYYY(DateTime.parse(processDateRaw))
          : null;
      final panelaKg = (batch['panela_kg'] as num?)?.toDouble() ?? 0.0;
      final confitilloKg = (batch['confitillo_kg'] as num?)?.toDouble() ?? 0.0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${producer['first_name']} ${producer['last_name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  if (processDate != null)
                    Text(processDate, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  Text(
                    'Panela: ${panelaKg % 1 == 0 ? panelaKg.toInt() : panelaKg} kg'
                    '${confitilloKg > 0 ? '  •  Confitillo: ${confitilloKg % 1 == 0 ? confitilloKg.toInt() : confitilloKg} kg' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _clearBatchSelection,
              child: Text('Cambiar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Sin selección → buscador + lista acotada
    final query = _batchSearchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _moduleBatches
        : _moduleBatches.where((b) {
            final producer = b['producers'] as Map<String, dynamic>;
            final name = '${producer['first_name']} ${producer['last_name']}'.toLowerCase();
            return name.contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lote de Producción', style: AppTextStyles.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          controller: _batchSearchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre de productor',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _batchSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _batchSearchController.clear()),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${filtered.length} lote${filtered.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: filtered.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No se encontraron lotes',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    final batch = filtered[i];
                    final id = batch['id'] as String;
                    final isEvaluated = _existingByBatch.containsKey(id);
                    final producer = batch['producers'] as Map<String, dynamic>;
                    final panelaKg = (batch['panela_kg'] as num?)?.toDouble() ?? 0.0;
                    final confitilloKg = (batch['confitillo_kg'] as num?)?.toDouble() ?? 0.0;
                    final processDateRaw = batch['process_date'] as String?;
                    final processDate = processDateRaw != null
                        ? AppDateUtils.formatDDMMYYYY(DateTime.parse(processDateRaw))
                        : null;

                    return InkWell(
                      onTap: () => _selectBatch(batch),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${producer['first_name']} ${producer['last_name']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  if (processDate != null)
                                    Text(processDate, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                  Text(
                                    'Panela: ${panelaKg % 1 == 0 ? panelaKg.toInt() : panelaKg} kg'
                                    '${confitilloKg > 0 ? '  •  Confitillo: ${confitilloKg % 1 == 0 ? confitilloKg.toInt() : confitilloKg} kg' : ''}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            if (isEvaluated)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.successBorder),
                                ),
                                child: Text(
                                  'Evaluado',
                                  style: TextStyle(fontSize: 10, color: AppColors.successDark, fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Step 1: Seleccionar área ──────────────────────────────────────────────────

  Widget _buildStep1() {
    final usedAreas = _editingIndex != null
        ? _areaEntries.asMap().entries
            .where((e) => e.key != _editingIndex)
            .map((e) => e.value.workArea).toSet()
        : _areaEntries.map((e) => e.workArea).toSet();

    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          AppBackButton(onPressed: _previousStep, isExpanded: false),
          SizedBox(height: context.responsiveSpacing),
          const _StepIndicatorBar(currentStep: 1),
          SizedBox(height: context.responsiveSpacing),
          _buildLoteBanner(),
          SizedBox(height: context.responsiveSpacing),
          if (_editingIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16, color: AppColors.warningDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Editando: ${_areaEntries[_editingIndex!].workArea.displayName}',
                        style: TextStyle(color: AppColors.warningDark, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          if (_editingIndex != null) SizedBox(height: context.responsiveSpacing),
          Text('¿En qué área realizas el control?', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          SearchableDropdownField<WorkArea>(
            label: 'Área de Trabajo',
            items: WorkArea.values.where((a) => !usedAreas.contains(a)).toList(),
            selectedValue: _formArea,
            labelFor: (a) => a.displayName,
            hintText: 'Seleccionar área...',
            onChanged: (area) => setState(() => _formArea = area),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'CONTINUAR',
            type: AppButtonType.primary,
            onPressed: _formArea != null ? _nextStep : null,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Añadir trabajadores ───────────────────────────────────────────────

  Widget _buildStep2() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          AppBackButton(onPressed: _previousStep, isExpanded: false),
          SizedBox(height: context.responsiveSpacing),
          const _StepIndicatorBar(currentStep: 1),
          SizedBox(height: context.responsiveSpacing),
          _buildLoteBanner(),
          SizedBox(height: context.responsiveSpacing),

          // Área seleccionada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.work_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Área: ${_formArea?.displayName ?? ''}',
                      style: AppTextStyles.fieldLabel.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          SizedBox(height: context.responsiveSpacing),

          // Formulario trabajador (lista + form juntos)
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
                // Lista de trabajadores ya añadidos (dentro del mismo contenedor)
                if (_formWorkers.isNotEmpty) ...[
                  Text('Trabajadores añadidos (${_formWorkers.length}):', style: AppTextStyles.fieldLabel),
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
                  const Divider(height: 24),
                ],
                Text(
                  _formWorkers.isEmpty ? 'Añadir primer trabajador:' : 'Añadir otro trabajador:',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 16),
                // Sugiere los certificados del módulo; si la persona no está
                // en la lista, se escribe su nombre igual.
                CertifiedWorkerNameField(
                  moduleId: _batchModuleId,
                  controller: _nameController,
                  focusNode: _nameFocusNode,
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
            text: 'CONTINUAR',
            type: AppButtonType.primary,
            onPressed: _nextStep,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  // ── Step 3: Resumen ───────────────────────────────────────────────────────────

  Widget _buildStep3() {
    return AppCard(
      padding: context.responsivePadding,
      child: FormGroup(
        children: [
          const _StepIndicatorBar(currentStep: 2),
          SizedBox(height: context.responsiveSpacing),
          _buildLoteBanner(),
          SizedBox(height: context.responsiveSpacing),

          // Confirmación visual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Área guardada correctamente!',
                    style: TextStyle(color: AppColors.successDark, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.responsiveSpacing),

          Text('Áreas evaluadas (${_areaEntries.length}):', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          ..._areaEntries.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: AppColors.success),
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
                    child: Text('Editar', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: () => setState(() => _areaEntries.removeAt(idx)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              setState(() { _resetForm(); _currentStep = 1; });
              _scrollToTop();
            },
            icon: const Icon(Icons.add),
            label: const Text('AÑADIR OTRA ÁREA'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(color: AppColors.primary, width: 1.5),
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: _isSaving ? 'Guardando...' : 'REGISTRAR TODO',
            type: AppButtonType.primary,
            onPressed: _isSaving ? null : _submitAll,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 8),
          _YesNoButton(label: 'SI', selected: value, isYes: true, onTap: () => onChanged(true)),
          const SizedBox(width: 6),
          _YesNoButton(label: 'NO', selected: !value, isYes: false, onTap: () => onChanged(false)),
        ],
      ),
    );
  }
}

class _StepIndicatorBar extends StatelessWidget {
  final int currentStep;

  const _StepIndicatorBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepCircle(index: 0, currentStep: currentStep, label: 'Lote'),
        Expanded(child: _StepLine(done: currentStep > 0)),
        _StepCircle(index: 1, currentStep: currentStep, label: 'Área'),
        Expanded(child: _StepLine(done: currentStep > 1)),
        _StepCircle(index: 2, currentStep: currentStep, label: 'Registro'),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final int currentStep;
  final String label;

  const _StepCircle({required this.index, required this.currentStep, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDone = currentStep > index;
    final isActive = currentStep == index;
    final bgColor = (isDone || isActive) ? AppColors.primary : AppColors.border;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: AppColors.textWhite, size: 20)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.textWhite : AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;

  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 3,
        decoration: BoxDecoration(
          color: done ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isYes;
  final VoidCallback onTap;

  const _YesNoButton({
    required this.label,
    required this.selected,
    required this.isYes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isYes ? AppColors.success : AppColors.error;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.textWhite : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
