import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/widgets/widgets.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _supabase = Supabase.instance.client;

  // Create form
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _plotNameController = TextEditingController();
  final AuthService _authService = AuthService();
  late final ProducerService _producerService;
  late final PlotService _plotService;

  bool _isCreating = false;
  bool _obscurePassword = true;
  bool _useDniAsPassword = true;
  String _selectedCreateRole = 'productor';

  // Module selection for admin_modulo / tecnico_campo
  List<CoopModule> _modules = [];
  Set<String> _selectedModuleIds = {};
  bool _isLoadingModules = false;
  final _createModuleSearchController = TextEditingController();

  // Producer-specific state (used when role = productor)
  String? _selectedProductorModuleId;
  String _producerMemberStatus = 'SOCIO';
  final List<String> _createPlotNames = [];

  // Admin-also-producer state (optional, only when role = admin_modulo)
  bool _adminAlsoProducer = false;
  String _adminProducerMemberStatus = 'SOCIO';
  final List<String> _adminProducerPlotNames = [];
  final _adminPlotNameController = TextEditingController();

  // Users list
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;

  final List<DropdownOption<String>> _createRoleOptions = [
    DropdownOption<String>(label: 'Productor', value: 'productor'),
    DropdownOption<String>(label: 'Admin Módulo', value: 'admin_modulo'),
    DropdownOption<String>(label: 'Técnico de Campo', value: 'tecnico_campo'),
    DropdownOption<String>(label: 'Admin Sistema', value: 'admin_sistema'),
  ];

  final List<DropdownOption<String>> _allRoleOptions = [
    DropdownOption<String>(label: 'Productor', value: 'productor'),
    DropdownOption<String>(label: 'Admin Módulo', value: 'admin_modulo'),
    DropdownOption<String>(label: 'Técnico de Campo', value: 'tecnico_campo'),
    DropdownOption<String>(label: 'Admin Sistema', value: 'admin_sistema'),
  ];

  static const _roleLabels = {
    'productor': 'Productor',
    'admin_modulo': 'Admin Módulo',
    'tecnico_campo': 'Técnico de Campo',
    'admin_sistema': 'Admin Sistema',
  };

  @override
  void initState() {
    super.initState();
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _plotService = PlotService(db: db);
    _loadUsers();
    _loadModules();
  }

  @override
  void dispose() {
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _plotNameController.dispose();
    _adminPlotNameController.dispose();
    _createModuleSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoadingModules = true);
    try {
      final modules = await CoopModulesService().getModules();
      if (mounted) setState(() => _modules = modules);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingModules = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final data = await _supabase
          .from('users')
          .select('user_id, first_name, last_name, role')
          .eq('cooperative_id', AppConfig.current.id)
          .neq('is_support', true)
          .order('first_name', ascending: true);

      final modulesByUser = <String, List<String>>{};
      try {
        final assignments = await _supabase
            .from('user_module_assignments')
            .select('user_id, coop_module_id')
            .eq('cooperative_id', AppConfig.current.id);
        for (final a in assignments as List) {
          final uid = a['user_id'] as String;
          modulesByUser.putIfAbsent(uid, () => []).add(a['coop_module_id'] as String);
        }
      } catch (_) {}

      final users = (data as List).map((u) => {
        ...u as Map<String, dynamic>,
        'module_ids': modulesByUser[u['user_id']] ?? <String>[],
      }).toList();

      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, message: 'Error al cargar usuarios', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  void _addPlotToCreate() {
    final name = _plotNameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(context, message: 'Ingresa el nombre de la parcela', type: SnackBarType.error);
      return;
    }
    if (_createPlotNames.any((p) => p.toLowerCase() == name.toLowerCase())) {
      AppSnackBar.show(context, message: 'Ya existe una parcela con ese nombre', type: SnackBarType.error);
      return;
    }
    setState(() {
      _createPlotNames.add(name);
      _plotNameController.clear();
    });
  }

  void _addAdminPlot() {
    final name = _adminPlotNameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(context, message: 'Ingresa el nombre de la parcela', type: SnackBarType.error);
      return;
    }
    if (_adminProducerPlotNames.any((p) => p.toLowerCase() == name.toLowerCase())) {
      AppSnackBar.show(context, message: 'Ya existe una parcela con ese nombre', type: SnackBarType.error);
      return;
    }
    setState(() {
      _adminProducerPlotNames.add(name);
      _adminPlotNameController.clear();
    });
  }

  void _resetCreateForm() {
    _formKey.currentState?.reset();
    _dniController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _passwordController.clear();
    _plotNameController.clear();
    setState(() {
      _selectedCreateRole = 'productor';
      _selectedModuleIds = {};
      _selectedProductorModuleId = null;
      _producerMemberStatus = 'SOCIO';
      _createPlotNames.clear();
      _adminAlsoProducer = false;
      _adminProducerMemberStatus = 'SOCIO';
      _adminProducerPlotNames.clear();
      _adminPlotNameController.clear();
      _useDniAsPassword = true;
    });
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    final role = _selectedCreateRole;
    final dni = _dniController.text.trim();

    // Validaciones por rol
    if (role == 'admin_modulo') {
      if (_selectedModuleIds.isEmpty) {
        AppSnackBar.show(context, message: 'Seleccione el módulo asignado', type: SnackBarType.error);
        return;
      }
      if (_adminAlsoProducer && _adminProducerPlotNames.isEmpty) {
        AppSnackBar.show(context, message: 'Agregue al menos una parcela', type: SnackBarType.error);
        return;
      }
    }
    if (role == 'tecnico_campo') {
      if (_selectedModuleIds.isEmpty) {
        AppSnackBar.show(context, message: 'Seleccione al menos un módulo', type: SnackBarType.error);
        return;
      }
    }
    if (role == 'productor') {
      if (_selectedProductorModuleId == null) {
        AppSnackBar.show(context, message: 'Seleccione el módulo del productor', type: SnackBarType.error);
        return;
      }
      if (_createPlotNames.isEmpty) {
        AppSnackBar.show(context, message: 'Agregue al menos una parcela', type: SnackBarType.error);
        return;
      }
    }

    setState(() => _isCreating = true);
    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final password = _useDniAsPassword ? dni : _passwordController.text;

      await _authService.registerUser(
        dni: dni,
        firstName: firstName,
        lastName: lastName,
        password: password,
        role: role,
        moduleIds: (role == 'admin_modulo' || role == 'tecnico_campo')
            ? _selectedModuleIds.toList()
            : [],
      );

      if (role == 'productor') {
        final producer = await _producerService.createProducer(CreateProducerRequest(
          firstName: firstName,
          lastName: lastName,
          dni: dni,
          coopModuleId: _selectedProductorModuleId!,
          isMember: _producerMemberStatus == 'SOCIO',
        ));
        final plots = _createPlotNames.map((name) => PlotData(name: name)).toList();
        await _plotService.createMultiplePlots(producer.id, plots);
      }

      if (role == 'admin_modulo' && _adminAlsoProducer && _selectedModuleIds.isNotEmpty) {
        final producer = await _producerService.createProducer(CreateProducerRequest(
          firstName: firstName,
          lastName: lastName,
          dni: dni,
          coopModuleId: _selectedModuleIds.first,
          isMember: _adminProducerMemberStatus == 'SOCIO',
        ));
        final plots = _adminProducerPlotNames.map((name) => PlotData(name: name)).toList();
        await _plotService.createMultiplePlots(producer.id, plots);
      }

      if (mounted) {
        AppSnackBar.show(context, message: 'Usuario creado exitosamente', type: SnackBarType.success);
        _resetCreateForm();
        _loadUsers();
      }
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.show(context, message: e.message, type: SnackBarType.error);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchProducerRecord(String dni) async {
    return await _supabase
        .from('producers')
        .select('id, coop_module_id')
        .eq('dni', dni)
        .eq('cooperative_id', AppConfig.current.id)
        .maybeSingle();
  }

  Future<bool> _hasProducerRecord(String userId) async {
    final result = await _fetchProducerRecord(userId);
    return result != null;
  }

  Future<void> _updateProducerModule(String producerId, String newModuleId) async {
    try {
      await _supabase
          .from('producers')
          .update({'coop_module_id': newModuleId})
          .eq('id', producerId);
      if (mounted) {
        AppSnackBar.show(context, message: 'Módulo del productor actualizado', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al actualizar módulo: ${e.toString().replaceFirst('Exception: ', '')}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _createProducerRecord(
    Map<String, dynamic> user,
    String moduleId,
    String memberStatus,
    List<String> plotNames,
  ) async {
    try {
      final producer = await _producerService.createProducer(CreateProducerRequest(
        firstName: user['first_name'] as String,
        lastName: user['last_name'] as String,
        dni: user['user_id'] as String,
        coopModuleId: moduleId,
        isMember: memberStatus == 'SOCIO',
      ));
      final plots = plotNames.map((name) => PlotData(name: name)).toList();
      await _plotService.createMultiplePlots(producer.id, plots);
      if (mounted) {
        AppSnackBar.show(context, message: 'Datos de productor guardados', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al guardar datos de productor: ${e.toString().replaceFirst('Exception: ', '')}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _showProducerDataDialog(Map<String, dynamic> user) async {
    String? selectedModuleId;
    String memberStatus = 'SOCIO';
    final plotNames = <String>[];
    final plotCtrl = TextEditingController();
    final producerModuleSearchCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Datos de productor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['first_name']} ${user['last_name']}',
                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Módulo
                Text('Módulo *', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 6),
                if (_modules.isEmpty)
                  Text('No hay módulos disponibles',
                      style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary))
                else ...[
                  TextField(
                    controller: producerModuleSearchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar módulo...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 4),
                  ...(_modules.where((m) => m.name.toLowerCase()
                          .contains(producerModuleSearchCtrl.text.toLowerCase()))
                      .toList())
                      .map((m) => RadioListTile<String>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(m.name, style: AppTextStyles.bodyText),
                            value: m.id,
                            groupValue: selectedModuleId,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setDialogState(() => selectedModuleId = v),
                          )),
                ],
                const SizedBox(height: 16),

                // Condición
                Text('Condición', style: AppTextStyles.fieldLabel),
                Row(
                  children: ['SOCIO', 'NO SOCIO'].map((opt) => Expanded(
                    child: RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(opt, style: AppTextStyles.smallText),
                      value: opt,
                      groupValue: memberStatus,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setDialogState(() => memberStatus = v!),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Parcelas
                Text('Parcelas *', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plotCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nombre de parcela',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: () {
                        final name = plotCtrl.text.trim();
                        if (name.isEmpty) return;
                        if (plotNames.any((p) => p.toLowerCase() == name.toLowerCase())) return;
                        setDialogState(() {
                          plotNames.add(name);
                          plotCtrl.clear();
                        });
                      },
                    ),
                  ],
                ),
                if (plotNames.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...plotNames.map((name) => Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(name, style: AppTextStyles.bodyText)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setDialogState(() => plotNames.remove(name)),
                      ),
                    ],
                  )),
                ],
                if (plotNames.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Agrega al menos una parcela',
                        style: AppTextStyles.smallText.copyWith(color: AppColors.error)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                plotCtrl.dispose();
                producerModuleSearchCtrl.dispose();
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: (selectedModuleId == null || plotNames.isEmpty)
                  ? null
                  : () {
                      plotCtrl.dispose();
                      producerModuleSearchCtrl.dispose();
                      Navigator.of(ctx).pop();
                      _createProducerRecord(user, selectedModuleId!, memberStatus, plotNames);
                    },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditRoleDialog(Map<String, dynamic> user) async {
    String currentRole = user['role'] as String? ?? 'productor';
    String selectedRole = currentRole;
    final currentModuleIds = ((user['module_ids'] as List?) ?? []).cast<String>().toSet();
    Set<String> selectedModuleIds = Set.from(currentModuleIds);

    // Pre-fetch producer record for productor and admin_modulo (admin may also be a producer)
    Map<String, dynamic>? producerRecord;
    if (currentRole == 'productor' || currentRole == 'admin_modulo') {
      producerRecord = await _fetchProducerRecord(user['user_id'] as String);
    }
    String? selectedProducerModuleId = producerRecord?['coop_module_id'] as String?;
    final String? originalProducerModuleId = selectedProducerModuleId;
    bool adminWantsToBeProducer = false;

    if (!mounted) return;

    final editModuleSearchController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isAdminModulo = selectedRole == 'admin_modulo';
          final isTecnicoCampo = selectedRole == 'tecnico_campo';
          final isProductor = selectedRole == 'productor';
          final needsModules = isAdminModulo || isTecnicoCampo;
          final roleChanged = selectedRole != currentRole;
          final modulesChanged = needsModules &&
              (!selectedModuleIds.containsAll(currentModuleIds) ||
               !currentModuleIds.containsAll(selectedModuleIds));
          final producerModuleChanged = isProductor &&
              producerRecord != null &&
              selectedProducerModuleId != originalProducerModuleId;
          final hasChanges = roleChanged || modulesChanged || producerModuleChanged ||
              (isAdminModulo && adminWantsToBeProducer && producerRecord == null);
          final modulesValid = !needsModules || selectedModuleIds.isNotEmpty;
          final adminModuloValid = !isAdminModulo || selectedModuleIds.length == 1;

          return AlertDialog(
            title: const Text('Editar usuario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user['first_name']} ${user['last_name']}',
                      style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
                  Text('DNI: ${user['user_id']}',
                      style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  Text('Rol', style: AppTextStyles.fieldLabel),
                  const SizedBox(height: 4),
                  ..._allRoleOptions.map((option) => InkWell(
                        onTap: () => setDialogState(() => selectedRole = option.value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: option.value,
                                groupValue: selectedRole,
                                activeColor: AppColors.primary,
                                onChanged: (v) => setDialogState(() => selectedRole = v!),
                              ),
                              Text(option.label, style: AppTextStyles.bodyText),
                            ],
                          ),
                        ),
                      )),

                  // Módulos para admin_modulo / tecnico_campo
                  if (needsModules) ...[
                    const SizedBox(height: 16),
                    Text(
                      isAdminModulo ? 'Módulo asignado (solo 1)' : 'Módulos asignados',
                      style: AppTextStyles.fieldLabel,
                    ),
                    const SizedBox(height: 6),
                    if (_modules.isEmpty)
                      Text('No hay módulos disponibles',
                          style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary))
                    else ...[
                      TextField(
                        controller: editModuleSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar módulo...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 4),
                      ...(_modules.where((m) => m.name.toLowerCase()
                              .contains(editModuleSearchController.text.toLowerCase()))
                          .toList())
                          .map((m) => isAdminModulo
                          ? RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(m.name, style: AppTextStyles.bodyText),
                              value: m.id,
                              groupValue: selectedModuleIds.isEmpty ? null : selectedModuleIds.first,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setDialogState(() => selectedModuleIds = {v!}),
                            )
                          : CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(m.name, style: AppTextStyles.bodyText),
                              value: selectedModuleIds.contains(m.id),
                              activeColor: AppColors.primary,
                              onChanged: (checked) => setDialogState(() {
                                if (checked == true) {
                                  selectedModuleIds.add(m.id);
                                } else {
                                  selectedModuleIds.remove(m.id);
                                }
                              }),
                            )),
                    ], // cierre de else [...] del buscador
                    if (selectedModuleIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Seleccione al menos un módulo',
                            style: AppTextStyles.smallText.copyWith(color: AppColors.error)),
                      ),
                    if (isAdminModulo && selectedModuleIds.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('El administrador de módulo solo puede tener 1 módulo',
                            style: AppTextStyles.smallText.copyWith(color: AppColors.error)),
                      ),
                  ],

                  // Módulo para productor (si ya tiene registro)
                  if (isProductor && producerRecord != null) ...[
                    const SizedBox(height: 16),
                    Text('Módulo', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    if (_modules.isEmpty)
                      Text('No hay módulos disponibles',
                          style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary))
                    else ...[
                      TextField(
                        controller: editModuleSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Buscar módulo...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 4),
                      ...(_modules.where((m) => m.name.toLowerCase()
                              .contains(editModuleSearchController.text.toLowerCase()))
                          .toList())
                          .map((m) => RadioListTile<String>(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(m.name, style: AppTextStyles.bodyText),
                                value: m.id,
                                groupValue: selectedProducerModuleId,
                                activeColor: AppColors.primary,
                                onChanged: (v) => setDialogState(() => selectedProducerModuleId = v),
                              )),
                    ],
                  ],

                  // Productor para admin_modulo
                  if (isAdminModulo) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 4),
                    if (producerRecord != null)
                      Row(
                        children: [
                          const Icon(Icons.agriculture, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'También registrado como productor de este módulo',
                              style: AppTextStyles.smallText.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Checkbox(
                            value: adminWantsToBeProducer,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setDialogState(() => adminWantsToBeProducer = v ?? false),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Registrar también como productor de este módulo',
                              style: AppTextStyles.bodyText,
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: (!hasChanges || !modulesValid || !adminModuloValid)
                    ? null
                    : () async {
                        final userId = user['user_id'] as String;
                        final nav = Navigator.of(ctx);

                        if (selectedRole == 'productor') {
                          nav.pop();
                          if (roleChanged) await _updateRole(userId, selectedRole);
                          if (producerRecord != null) {
                            // Ya era productor: actualizar módulo si cambió
                            if (producerModuleChanged && selectedProducerModuleId != null && mounted) {
                              await _updateProducerModule(
                                producerRecord['id'] as String,
                                selectedProducerModuleId!,
                              );
                            }
                          } else {
                            // Cambió a productor: pedir datos faltantes
                            final hasRecord = await _hasProducerRecord(userId);
                            if (!hasRecord && mounted) {
                              await _showProducerDataDialog(user);
                            }
                          }
                          return;
                        }

                        nav.pop();
                        if (roleChanged) await _updateRole(userId, selectedRole);
                        if (modulesChanged) await _updateModuleAssignments(userId, selectedModuleIds.toList());
                        if (selectedRole == 'admin_modulo' && adminWantsToBeProducer && producerRecord == null && mounted) {
                          await _showProducerDataDialog(user);
                        }
                      },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    editModuleSearchController.dispose();
  }

  Future<void> _updateModuleAssignments(String userId, List<String> moduleIds) async {
    try {
      final cooperativeId = AppConfig.current.id;
      await _supabase
          .from('user_module_assignments')
          .delete()
          .eq('user_id', userId)
          .eq('cooperative_id', cooperativeId);

      if (moduleIds.isNotEmpty) {
        await _supabase.from('user_module_assignments').insert(
          moduleIds.map((id) => {
            'user_id': userId,
            'cooperative_id': cooperativeId,
            'coop_module_id': id,
          }).toList(),
        );
      }

      if (mounted) {
        setState(() {
          final idx = _users.indexWhere((u) => u['user_id'] == userId);
          if (idx != -1) _users[idx] = {..._users[idx], 'module_ids': moduleIds};
        });
        AppSnackBar.show(context, message: 'Módulos actualizados', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al actualizar módulos: ${e.toString().replaceFirst('Exception: ', '')}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      final response = await _supabase.functions.invoke(
        'update-user-role',
        body: {'userId': userId, 'newRole': newRole, 'cooperativeId': AppConfig.current.id},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) throw Exception(data!['error']);

      if (mounted) {
        setState(() {
          final idx = _users.indexWhere((u) => u['user_id'] == userId);
          if (idx != -1) _users[idx] = {..._users[idx], 'role': newRole};
        });
        AppSnackBar.show(context, message: 'Rol actualizado exitosamente', type: SnackBarType.success);
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

  String? _validateDNI(String? v) {
    if (v == null || v.isEmpty) return 'Ingrese el DNI';
    if (!RegExp(r'^\d{8}$').hasMatch(v)) return 'El DNI debe tener exactamente 8 dígitos';
    return null;
  }

  String? _validateName(String? v, String field) {
    if (v == null || v.isEmpty) return 'Ingrese $field';
    if (v.length < 2) return '$field debe tener al menos 2 caracteres';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingrese una contraseña';
    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserDni = ref.watch(currentUserProvider)?.dni;
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Gestión de usuarios',
      showBackButton: true,
      onBack: () => context.go(AppRoutes.home.path),
      child: SingleChildScrollView(
        padding: context.responsiveHorizontalPadding.copyWith(
          top: context.responsivePadding.top,
          bottom: context.responsivePadding.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.responsiveCardWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lista de usuarios
                AppCard(
                  padding: context.responsivePadding,
                  child: FormGroup(
                    children: [
                      const AppTitle(title: 'Usuarios registrados'),
                      if (_isLoadingUsers)
                        const Center(child: CircularProgressIndicator())
                      else if (_users.isEmpty)
                        const Text('No hay usuarios registrados.')
                      else
                        ..._users.map((user) {
                          final isSelf = user['user_id'] == currentUserDni;
                          final moduleIds = (user['module_ids'] as List).cast<String>();
                          final moduleNames = moduleIds
                              .map((id) => _modules
                                  .firstWhere((m) => m.id == id,
                                      orElse: () => CoopModule(id: id, name: id))
                                  .name)
                              .where((n) => n.isNotEmpty)
                              .join(', ');
                          return _UserTile(
                            user: user,
                            roleLabel: _roleLabels[user['role']] ?? user['role'],
                            moduleName: moduleNames.isNotEmpty ? moduleNames : null,
                            isSelf: isSelf,
                            onEdit: isSelf ? null : () => _showEditRoleDialog(user),
                          );
                        }),
                    ],
                  ),
                ),

                SizedBox(height: context.responsiveSpacing),

                // Formulario de creación
                AppCard(
                  padding: context.responsivePadding,
                  child: Form(
                    key: _formKey,
                    child: FormGroup(
                      children: [
                        const AppTitle(title: 'Crear nuevo usuario'),

                        // Rol (primero para adaptar el formulario)
                        AppDropdown<String>(
                          label: 'Rol',
                          options: _createRoleOptions,
                          value: _selectedCreateRole,
                          onChanged: _isCreating
                              ? null
                              : (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedCreateRole = v;
                                      _selectedModuleIds = {};
                                      _selectedProductorModuleId = null;
                                      _createPlotNames.clear();
                                    });
                                  }
                                },
                        ),

                        AppTextField(
                          label: 'DNI',
                          controller: _dniController,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          validator: _validateDNI,
                          enabled: !_isCreating,
                        ),
                        AppTextField(
                          label: 'Nombres',
                          controller: _firstNameController,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _validateName(v, 'el nombre'),
                          enabled: !_isCreating,
                        ),
                        AppTextField(
                          label: 'Apellidos',
                          controller: _lastNameController,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => _validateName(v, 'el apellido'),
                          enabled: !_isCreating,
                        ),

                        // Contraseña
                        Row(
                          children: [
                            Checkbox(
                              value: _useDniAsPassword,
                              activeColor: AppColors.primary,
                              onChanged: _isCreating
                                  ? null
                                  : (v) => setState(() {
                                        _useDniAsPassword = v ?? true;
                                        _passwordController.clear();
                                      }),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Usar DNI como contraseña',
                                style: AppTextStyles.bodyText,
                              ),
                            ),
                          ],
                        ),
                        if (!_useDniAsPassword) ...[
                          AppTextField(
                            label: 'Contraseña',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            enabled: !_isCreating,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ],

                        // Módulos — admin_modulo (radio) / tecnico_campo (checkbox)
                        if (_selectedCreateRole == 'admin_modulo' || _selectedCreateRole == 'tecnico_campo') ...[
                          if (_isLoadingModules)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            Text(
                              _selectedCreateRole == 'admin_modulo'
                                  ? 'Módulo asignado (solo 1) *'
                                  : 'Módulos asignados *',
                              style: AppTextStyles.fieldLabel,
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _createModuleSearchController,
                              decoration: const InputDecoration(
                                hintText: 'Buscar módulo...',
                                prefixIcon: Icon(Icons.search, size: 20),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 4),
                            ...(_modules.where((m) => m.name.toLowerCase()
                                    .contains(_createModuleSearchController.text.toLowerCase()))
                                .toList())
                                .map((m) => _selectedCreateRole == 'admin_modulo'
                                ? RadioListTile<String>(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(m.name, style: AppTextStyles.bodyText),
                                    value: m.id,
                                    groupValue: _selectedModuleIds.isEmpty ? null : _selectedModuleIds.first,
                                    activeColor: AppColors.primary,
                                    onChanged: _isCreating
                                        ? null
                                        : (v) => setState(() => _selectedModuleIds = {v!}),
                                  )
                                : CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(m.name, style: AppTextStyles.bodyText),
                                    value: _selectedModuleIds.contains(m.id),
                                    activeColor: AppColors.primary,
                                    onChanged: _isCreating
                                        ? null
                                        : (checked) => setState(() {
                                              if (checked == true) {
                                                _selectedModuleIds.add(m.id);
                                              } else {
                                                _selectedModuleIds.remove(m.id);
                                              }
                                            }),
                                  )),
                          ],
                        ],

                        // Sección productor opcional para admin_modulo
                        if (_selectedCreateRole == 'admin_modulo') ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Checkbox(
                                value: _adminAlsoProducer,
                                activeColor: AppColors.primary,
                                onChanged: _isCreating
                                    ? null
                                    : (v) => setState(() {
                                          _adminAlsoProducer = v ?? false;
                                          if (!_adminAlsoProducer) {
                                            _adminProducerPlotNames.clear();
                                            _adminPlotNameController.clear();
                                          }
                                        }),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'También es productor de este módulo',
                                  style: AppTextStyles.bodyText,
                                ),
                              ),
                            ],
                          ),
                          if (_adminAlsoProducer) ...[
                            const SizedBox(height: 4),
                            AppRadioGroup<String>(
                              label: 'Condición',
                              options: [
                                RadioOption(value: 'SOCIO', label: 'SOCIO'),
                                RadioOption(value: 'NO SOCIO', label: 'NO SOCIO'),
                              ],
                              groupValue: _adminProducerMemberStatus,
                              onChanged: _isCreating
                                  ? null
                                  : (v) => setState(() => _adminProducerMemberStatus = v ?? 'SOCIO'),
                            ),
                            Text('Parcelas *', style: AppTextStyles.fieldLabel),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: null,
                                    hintText: 'Nombre de parcela',
                                    controller: _adminPlotNameController,
                                    enabled: !_isCreating,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    onPressed: _isCreating ? null : _addAdminPlot,
                                  ),
                                ),
                              ],
                            ),
                            if (_adminProducerPlotNames.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ..._adminProducerPlotNames.map((name) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.circle, size: 6, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(name, style: AppTextStyles.bodyText)),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          color: AppColors.textSecondary,
                                          onPressed: _isCreating
                                              ? null
                                              : () => setState(() => _adminProducerPlotNames.remove(name)),
                                        ),
                                      ],
                                    ),
                                  )),
                            ] else ...[
                              const SizedBox(height: 4),
                              Text(
                                'Agrega al menos una parcela',
                                style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ],

                        // Campos específicos de productor
                        if (_selectedCreateRole == 'productor') ...[
                          // Módulo
                          if (_isLoadingModules)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            Text('Módulo *', style: AppTextStyles.fieldLabel),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _createModuleSearchController,
                              enabled: !_isCreating,
                              decoration: const InputDecoration(
                                hintText: 'Buscar módulo...',
                                prefixIcon: Icon(Icons.search, size: 20),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 4),
                            ...(_modules.where((m) => m.name.toLowerCase()
                                    .contains(_createModuleSearchController.text.toLowerCase()))
                                .toList())
                                .map((m) => RadioListTile<String>(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(m.name, style: AppTextStyles.bodyText),
                                      value: m.id,
                                      groupValue: _selectedProductorModuleId,
                                      activeColor: AppColors.primary,
                                      onChanged: _isCreating
                                          ? null
                                          : (v) => setState(() => _selectedProductorModuleId = v),
                                    )),
                          ],

                          // Condición
                          AppRadioGroup<String>(
                            label: 'Condición',
                            options: [
                              RadioOption(value: 'SOCIO', label: 'SOCIO'),
                              RadioOption(value: 'NO SOCIO', label: 'NO SOCIO'),
                            ],
                            groupValue: _producerMemberStatus,
                            onChanged: _isCreating
                                ? null
                                : (v) => setState(() => _producerMemberStatus = v ?? 'SOCIO'),
                          ),

                          // Parcelas
                          Text('Parcelas *', style: AppTextStyles.fieldLabel),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: null,
                                  hintText: 'Nombre de parcela',
                                  controller: _plotNameController,
                                  enabled: !_isCreating,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  onPressed: _isCreating ? null : _addPlotToCreate,
                                ),
                              ),
                            ],
                          ),
                          if (_createPlotNames.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ..._createPlotNames.map((name) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle, size: 6, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(name, style: AppTextStyles.bodyText)),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 16),
                                        color: AppColors.textSecondary,
                                        onPressed: _isCreating
                                            ? null
                                            : () => setState(() => _createPlotNames.remove(name)),
                                      ),
                                    ],
                                  ),
                                )),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              'Agrega al menos una parcela',
                              style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],

                        AppButton(
                          text: 'CREAR USUARIO',
                          onPressed: _isCreating ? null : _createUser,
                          isLoading: _isCreating,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final String roleLabel;
  final String? moduleName;
  final bool isSelf;
  final VoidCallback? onEdit;

  const _UserTile({
    required this.user,
    required this.roleLabel,
    this.moduleName,
    required this.isSelf,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${user['first_name']} ${user['last_name']}',
                        style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Text('(Tú)', style: AppTextStyles.smallText.copyWith(color: AppColors.primary)),
                    ],
                  ],
                ),
                Text(
                  [
                    'DNI: ${user['user_id']}',
                    roleLabel,
                    if (moduleName != null && moduleName!.isNotEmpty) moduleName!,
                  ].join('  •  '),
                  style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!isSelf)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.primary,
              tooltip: 'Editar',
              onPressed: onEdit,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
