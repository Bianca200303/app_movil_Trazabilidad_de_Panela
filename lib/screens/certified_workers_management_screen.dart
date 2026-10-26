import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/offline/user_error_message.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/certified_worker.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/services/certified_workers_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/widgets/widgets.dart';

/// Lista de trabajadores certificados por módulo, mantenida desde el celular
/// por el Administrador del sistema (también se mantiene en la web, en
/// Catálogos). Alimenta las sugerencias de nombre de los formularios
/// (CertifiedWorkerNameField). Requiere conexión.
class CertifiedWorkersManagementScreen extends StatefulWidget {
  const CertifiedWorkersManagementScreen({super.key});

  @override
  State<CertifiedWorkersManagementScreen> createState() =>
      _CertifiedWorkersManagementScreenState();
}

class _CertifiedWorkersManagementScreenState
    extends State<CertifiedWorkersManagementScreen> {
  /// A partir de cuántos trabajadores se muestra el buscador.
  static const _searchThreshold = 6;

  final _workersService = CertifiedWorkersService();
  final _modulesService = CoopModulesService();
  final _searchController = TextEditingController();

  List<CoopModule> _modules = [];
  List<CertifiedWorker> _workers = [];
  String? _selectedModuleId;
  bool _isLoading = true;
  bool _showInactive = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _workers.isEmpty;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _modulesService.fetchFromSupabase(),
        _workersService.fetchAllForManagement(),
      ]);
      if (!mounted) return;
      final modules = results[0] as List<CoopModule>;
      setState(() {
        _modules = modules;
        _workers = results[1] as List<CertifiedWorker>;
        _selectedModuleId ??= modules.length == 1 ? modules.first.id : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = userErrorMessage(e, action: 'No se pudo cargar la lista');
        _isLoading = false;
      });
    }
  }

  void _selectModule(String? id) => setState(() {
        _selectedModuleId = id;
        _showInactive = false;
        _searchController.clear();
      });

  List<CertifiedWorker> get _moduleWorkers =>
      _workers.where((w) => w.coopModuleId == _selectedModuleId).toList();

  bool _matchesSearch(CertifiedWorker worker) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return worker.fullName.toLowerCase().contains(query) ||
        (worker.dni?.contains(query) ?? false);
  }

  Future<void> _openForm([CertifiedWorker? worker]) async {
    final moduleId = worker?.coopModuleId ?? _selectedModuleId;
    if (moduleId == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXLarge)),
      ),
      builder: (_) => _WorkerFormSheet(
        service: _workersService,
        moduleId: moduleId,
        worker: worker,
      ),
    );
    if (saved == true && mounted) {
      AppSnackBar.show(
        context,
        message: worker == null ? 'Trabajador agregado' : 'Trabajador actualizado',
        type: SnackBarType.success,
      );
      _load();
    }
  }

  Future<void> _toggleActive(CertifiedWorker worker) async {
    if (worker.isActive) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: '¿Dar de baja?',
        message: '${worker.fullName} dejará de aparecer en los formularios. '
            'Los controles ya registrados no cambian. Puede reactivarlo después.',
        confirmLabel: 'Dar de baja',
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await _workersService.setActive(worker.id, !worker.isActive);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: worker.isActive ? 'Trabajador dado de baja' : 'Trabajador reactivado',
        type: SnackBarType.success,
      );
      _load();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: userErrorMessage(e, action: 'No se pudo guardar el cambio'),
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Trabajadores certificados',
      showBackButton: true,
      onBack: () => context.go(AppRoutes.home.path),
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: context.responsiveHorizontalPadding.copyWith(
            bottom: context.responsivePadding.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.responsiveCardWidth),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return AppCard(
        child: _EmptyState(
          icon: Icons.cloud_off_outlined,
          color: AppColors.error,
          message: _loadError!,
          action: AppButton(
            text: 'Reintentar',
            icon: Icons.refresh,
            type: AppButtonType.secondary,
            onPressed: _load,
            isExpanded: false,
          ),
        ),
      );
    }

    final spacing = SizedBox(height: context.responsiveSpacing);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: FormGroup(
            children: [
              ModuleSearchField(
                label: 'Módulo',
                modules: _modules,
                selectedModuleId: _selectedModuleId,
                onChanged: _selectModule,
              ),
              if (_selectedModuleId != null)
                AppButton(
                  text: 'Nuevo trabajador',
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: () => _openForm(),
                ),
            ],
          ),
        ),
        spacing,
        if (_selectedModuleId == null)
          const AppCard(
            child: _EmptyState(
              icon: Icons.view_module_outlined,
              color: AppColors.primary,
              message: 'Elija un módulo para ver sus trabajadores certificados. '
                  'Aparecerán como sugerencia al llenar los formularios de ese módulo.',
            ),
          )
        else
          ..._buildWorkerSections(spacing),
      ],
    );
  }

  List<Widget> _buildWorkerSections(Widget spacing) {
    final workers = _moduleWorkers;
    final active = workers.where((w) => w.isActive).toList();
    final inactive = workers.where((w) => !w.isActive).toList();
    final visibleActive = active.where(_matchesSearch).toList();
    final visibleInactive = inactive.where(_matchesSearch).toList();

    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: 'Activos', count: active.length),
            if (workers.length >= _searchThreshold) ...[
              const SizedBox(height: AppDimensions.spacingSmall),
              AppTextField(
                controller: _searchController,
                hintText: 'Buscar por nombre o DNI',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Limpiar búsqueda',
                        onPressed: _searchController.clear,
                      ),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingSmall),
            if (active.isEmpty)
              const _EmptyState(
                icon: Icons.badge_outlined,
                color: AppColors.primary,
                message: 'Este módulo aún no tiene trabajadores certificados.',
              )
            else if (visibleActive.isEmpty)
              const _EmptyState(
                icon: Icons.search_off,
                color: AppColors.primary,
                message: 'Ningún trabajador activo coincide con la búsqueda.',
              )
            else
              AppEntityList(
                children: [
                  for (final w in visibleActive)
                    _WorkerTile(
                      worker: w,
                      onEdit: () => _openForm(w),
                      onToggleActive: () => _toggleActive(w),
                    ),
                ],
              ),
          ],
        ),
      ),
      if (inactive.isNotEmpty) ...[
        spacing,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                onTap: () => setState(() => _showInactive = !_showInactive),
                child: Row(
                  children: [
                    Expanded(
                      child: _SectionHeader(title: 'Dados de baja', count: inactive.length),
                    ),
                    Icon(
                      _showInactive ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              if (_showInactive) ...[
                const SizedBox(height: AppDimensions.spacingSmall),
                if (visibleInactive.isEmpty)
                  const _EmptyState(
                    icon: Icons.search_off,
                    color: AppColors.primary,
                    message: 'Ningún trabajador dado de baja coincide con la búsqueda.',
                  )
                else
                  AppEntityList(
                    children: [
                      for (final w in visibleInactive)
                        _WorkerTile(
                          worker: w,
                          onEdit: () => _openForm(w),
                          onToggleActive: () => _toggleActive(w),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ],
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(child: Text(title, style: AppTextStyles.cardTitle)),
        const SizedBox(width: AppDimensions.spacingSmall),
        AppBadge(
          text: '$count',
          color: AppColors.primary,
          background: AppColors.infoLight,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.color,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
      child: Column(
        children: [
          Icon(icon, size: AppDimensions.iconLarge, color: color),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(message, style: AppTextStyles.bodyText, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppDimensions.spacingMedium),
            action!,
          ],
        ],
      ),
    );
  }
}

enum _WorkerAction { edit, toggleActive }

class _WorkerTile extends StatelessWidget {
  const _WorkerTile({
    required this.worker,
    required this.onEdit,
    required this.onToggleActive,
  });

  final CertifiedWorker worker;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  Widget _certificationBadge() {
    final until = worker.certifiedUntil;
    if (until == null) {
      return const AppBadge(
        text: 'Sin vencimiento',
        icon: Icons.verified_outlined,
        color: AppColors.primary,
        background: AppColors.infoLight,
      );
    }
    if (worker.isExpired) {
      return AppBadge(
        text: 'Vencida el ${_formatIso(until)}',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        background: AppColors.warningLight,
      );
    }
    return AppBadge(
      text: 'Vigente hasta ${_formatIso(until)}',
      icon: Icons.verified_outlined,
      color: AppColors.success,
      background: AppColors.successLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppEntityTile(
      title: worker.fullName,
      initials: entityInitials(worker.firstName, worker.lastName),
      accent: worker.isActive ? AppColors.primary : AppColors.error,
      subtitle: [
        if (worker.position != null) worker.position!,
        if (worker.dni != null) 'DNI ${worker.dni}',
      ].join(' · '),
      badges: [
        if (worker.isActive)
          _certificationBadge()
        else
          const AppBadge(
            text: 'Dado de baja',
            icon: Icons.person_off_outlined,
            color: AppColors.error,
            background: AppColors.errorLight,
          ),
      ],
      onTap: onEdit,
      trailing: PopupMenuButton<_WorkerAction>(
        tooltip: 'Opciones',
        icon: const Icon(Icons.more_vert, color: AppColors.primary),
        onSelected: (action) => switch (action) {
          _WorkerAction.edit => onEdit(),
          _WorkerAction.toggleActive => onToggleActive(),
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: _WorkerAction.edit,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined, color: AppColors.primary),
              title: Text('Editar'),
            ),
          ),
          PopupMenuItem(
            value: _WorkerAction.toggleActive,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                worker.isActive ? Icons.person_off_outlined : Icons.person_add_alt_outlined,
                color: worker.isActive ? AppColors.error : AppColors.success,
              ),
              title: Text(worker.isActive ? 'Dar de baja' : 'Reactivar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 'YYYY-MM-DD' → 'DD/MM/YYYY'.
String _formatIso(String iso) {
  final date = DateTime.tryParse(iso);
  return date == null ? iso : AppDateUtils.formatDDMMYYYY(date);
}

/// Formulario para agregar o editar un trabajador (mismos datos y
/// validaciones que Catálogos en la web).
class _WorkerFormSheet extends StatefulWidget {
  const _WorkerFormSheet({
    required this.service,
    required this.moduleId,
    this.worker,
  });

  final CertifiedWorkersService service;
  final String moduleId;
  final CertifiedWorker? worker;

  @override
  State<_WorkerFormSheet> createState() => _WorkerFormSheetState();
}

class _WorkerFormSheetState extends State<_WorkerFormSheet> {
  /// Ancho desde el cual los campos cortos van de a dos por fila.
  static const _twoColumnWidth = 440.0;

  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(text: widget.worker?.firstName);
  late final _lastNameController = TextEditingController(text: widget.worker?.lastName);
  late final _dniController = TextEditingController(text: widget.worker?.dni);
  late final _positionController = TextEditingController(text: widget.worker?.position);
  late String? _certifiedUntil = widget.worker?.certifiedUntil;
  late final _certifiedUntilController = TextEditingController(
    text: _certifiedUntil == null ? '' : _formatIso(_certifiedUntil!),
  );
  bool _isSaving = false;

  void _setCertifiedUntil(String? iso) => setState(() {
        _certifiedUntil = iso;
        _certifiedUntilController.text = iso == null ? '' : _formatIso(iso);
      });

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dniController.dispose();
    _positionController.dispose();
    _certifiedUntilController.dispose();
    super.dispose();
  }

  Future<void> _pickCertifiedUntil() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_certifiedUntil ?? '') ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
      helpText: 'Certificado hasta',
    );
    if (picked != null) _setCertifiedUntil(AppDateUtils.dateToISO(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.service.save(
        id: widget.worker?.id,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        coopModuleId: widget.moduleId,
        dni: _dniController.text,
        position: _positionController.text,
        certifiedUntil: _certifiedUntil,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.show(
        context,
        message: userErrorMessage(e, action: 'No se pudo guardar'),
        type: SnackBarType.error,
      );
    }
  }

  String? _required(String? value, String field) =>
      (value == null || value.trim().isEmpty) ? 'Ingrese $field' : null;

  /// Dos campos lado a lado si hay ancho; si no, uno debajo del otro.
  Widget _pair(bool wide, Widget a, Widget b) {
    if (!wide) return FormGroup(children: [a, b]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: b),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.worker == null;
    final horizontal = context.responsivePadding.left;

    return Padding(
      // Sube el formulario por encima del teclado.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, context.responsivePadding.bottom),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _twoColumnWidth;
            return Form(
              key: _formKey,
              child: FormGroup(
                children: [
                  Row(
                    children: [
                      Icon(
                        isNew ? Icons.person_add_alt_1_outlined : Icons.edit_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Expanded(
                        child: Text(
                          isNew ? 'Nuevo trabajador' : 'Editar trabajador',
                          style: AppTextStyles.sectionTitle,
                        ),
                      ),
                    ],
                  ),
                  _pair(
                    wide,
                    AppTextField(
                      label: 'Nombres',
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'los nombres'),
                      enabled: !_isSaving,
                    ),
                    AppTextField(
                      label: 'Apellidos',
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _required(v, 'los apellidos'),
                      enabled: !_isSaving,
                    ),
                  ),
                  _pair(
                    wide,
                    AppTextField(
                      label: 'DNI (opcional)',
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (v) {
                        final dni = v?.trim() ?? '';
                        return dni.isEmpty || RegExp(r'^\d{8}$').hasMatch(dni)
                            ? null
                            : 'El DNI debe tener 8 dígitos';
                      },
                      enabled: !_isSaving,
                    ),
                    AppTextField(
                      label: 'Cargo (opcional)',
                      controller: _positionController,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSaving,
                    ),
                  ),
                  AppTextField(
                    label: 'Certificado hasta (opcional)',
                    controller: _certifiedUntilController,
                    readOnly: true,
                    onTap: _isSaving ? null : _pickCertifiedUntil,
                    hintText: 'Sin fecha de vencimiento',
                    prefixIcon: const Icon(Icons.event_outlined, color: AppColors.primary),
                    suffixIcon: _certifiedUntil == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Quitar fecha',
                            onPressed: _isSaving ? null : () => _setCertifiedUntil(null),
                          ),
                  ),
                  _pair(
                    constraints.maxWidth >= 320,
                    AppButton(
                      text: 'Cancelar',
                      type: AppButtonType.secondary,
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    ),
                    AppButton(
                      text: 'Guardar',
                      onPressed: _save,
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
