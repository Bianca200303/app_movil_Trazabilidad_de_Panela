import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/supabase_paging.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/services/producer_records_service.dart';
import 'package:panela_sys/core/offline/user_error_message.dart';
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
  /// Muestra el formulario "Nuevo usuario" en lugar de la lista.
  bool _showCreateForm = false;
  bool _obscurePassword = true;
  bool _useDniAsPassword = true;
  String _selectedCreateRole = 'productor';

  // Module selection for admin_modulo / tecnico_campo
  List<CoopModule> _modules = [];
  Set<String> _selectedModuleIds = {};
  bool _isLoadingModules = false;

  // Producer-specific state (used when role = productor)
  String? _selectedProductorModuleId;
  String _producerMemberStatus = 'SOCIO';
  final List<String> _createPlotNames = [];

  // Técnico o administrador de módulo que además es productor (opcional)
  bool _alsoProducer = false;
  String _alsoProducerMemberStatus = 'SOCIO';
  /// Módulo como productor del técnico (el administrador usa su módulo).
  String? _alsoProducerModuleId;
  final List<String> _alsoProducerPlotNames = [];
  final _alsoProducerPlotController = TextEditingController();

  // Users list
  List<Map<String, dynamic>> _users = [];
  /// Registros de productor por DNI: cualquier rol salvo el Administrador del
  /// sistema puede ser además productor (uno o más módulos).
  Map<String, List<ProducerRecord>> _producersByDni = {};
  final _producerRecordsService = ProducerRecordsService();
  bool _isLoadingUsers = false;
  /// Rol por el que se filtra la lista (null = todos).
  String? _roleFilter;
  /// Módulo por el que se filtra la lista (null = todos): asignado al
  /// usuario o donde figura como productor.
  String? _moduleFilter;
  final _userSearchController = TextEditingController();

  /// A partir de cuántos usuarios se muestra el buscador.
  static const _userSearchThreshold = 6;

  /// La lista se dibuja por tandas: con cientos de usuarios, construir todas
  /// las tarjetas de una vez hacía lenta la pantalla.
  static const _usersPageSize = 40;
  int _shownUsers = _usersPageSize;

  /// Presentación de cada rol en la lista (en este orden aparecen los
  /// filtros y las opciones de rol). Un solo tono neutro para todos: el rol
  /// se lee en el texto, no en el color.
  static const _roleStyles = {
    'admin_sistema': _RoleStyle(
      singular: 'Administrador del sistema',
      plural: 'Admin. sistema',
      short: 'Admin. sistema',
      description: 'Acceso total: usuarios, módulos y todos los registros.',
      icon: Icons.admin_panel_settings_outlined,
      color: AppColors.primaryDark,
      background: AppColors.surfaceVariant,
    ),
    'admin_modulo': _RoleStyle(
      singular: 'Administrador de módulo',
      plural: 'Admin. módulo',
      short: 'Admin. módulo',
      description: 'Administra un módulo: registros, productores y parcelas.',
      icon: Icons.supervisor_account_outlined,
      color: AppColors.primaryDark,
      background: AppColors.surfaceVariant,
    ),
    'tecnico_campo': _RoleStyle(
      singular: 'Técnico de campo',
      plural: 'Técnicos de campo',
      short: 'Técnico de campo',
      description: 'Registra producción y controles en sus módulos asignados.',
      icon: Icons.engineering_outlined,
      color: AppColors.primaryDark,
      background: AppColors.surfaceVariant,
    ),
    'productor': _RoleStyle(
      singular: 'Productor',
      plural: 'Productores',
      short: 'Productor',
      description: 'Consulta su propia producción y parcelas.',
      icon: Icons.agriculture_outlined,
      color: AppColors.primaryDark,
      background: AppColors.surfaceVariant,
    ),
  };

  Widget _buildRoleFilters() {
    int count(String? role) =>
        role == null ? _users.length : _users.where((u) => _matchesRole(u, role)).length;
    final chips = [
      _RoleFilterChip(
        label: 'Todos',
        count: count(null),
        icon: Icons.groups_outlined,
        selected: _roleFilter == null,
        onTap: () => setState(() {
          _roleFilter = null;
          _shownUsers = _usersPageSize;
        }),
      ),
      for (final entry in _roleStyles.entries)
        _RoleFilterChip(
          label: entry.value.plural,
          count: count(entry.key),
          icon: entry.value.icon,
          selected: _roleFilter == entry.key,
          onTap: () => setState(() {
            _roleFilter = _roleFilter == entry.key ? null : entry.key;
            _shownUsers = _usersPageSize;
          }),
        ),
    ];
    // Una sola fila deslizable: en pantallas angostas los filtros apilados
    // ocupaban media pantalla.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AppDimensions.spacingSmall),
            chips[i],
          ],
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, String? currentUserDni) {
    final isSelf = user['user_id'] == currentUserDni;
    final moduleIds = (user['module_ids'] as List).cast<String>();
    final moduleNames = moduleIds
        .map((id) => _modules
            .firstWhere((m) => m.id == id, orElse: () => CoopModule(id: id, name: id))
            .name)
        .where((n) => n.isNotEmpty)
        .join(', ');
    final style = _roleStyles[user['role']] ?? _RoleStyle.unknown(user['role'].toString());
    final onEdit = isSelf ? null : () => _showEditRoleDialog(user);
    return AppEntityTile(
      title: '${user['first_name']} ${user['last_name']}${isSelf ? ' (usted)' : ''}',
      initials: entityInitials(
        user['first_name']?.toString() ?? '',
        user['last_name']?.toString() ?? '',
      ),
      accent: style.color,
      subtitle: [
        'DNI ${user['user_id']}',
        if (moduleNames.isNotEmpty) moduleNames,
      ].join(' · '),
      badges: [
        AppBadge(text: style.singular, icon: style.icon, color: style.color, background: style.background),
        if (user['role'] != 'productor' && _isActiveProducer(user['user_id'] as String))
          const AppBadge(
            text: 'Productor',
            icon: Icons.agriculture_outlined,
            color: AppColors.primaryDark,
            background: AppColors.surfaceVariant,
          ),
      ],
      onTap: onEdit,
      trailing: onEdit == null
          ? null
          : const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Icon(Icons.chevron_right, color: AppColors.primary),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _plotService = PlotService(db: db);
    _userSearchController.addListener(() => setState(() => _shownUsers = _usersPageSize));
    _loadUsers();
    _loadModules();
  }

  void _selectCreateRole(String role) {
    setState(() {
      _selectedCreateRole = role;
      _selectedModuleIds = {};
      _selectedProductorModuleId = null;
      _createPlotNames.clear();
      _alsoProducer = false;
      _alsoProducerModuleId = null;
      _alsoProducerPlotNames.clear();
    });
  }

  /// Abre el formulario "Nuevo usuario"; si la lista está filtrada por un
  /// rol, el formulario queda con ese rol elegido.
  void _goToCreateForm() {
    final role = _roleFilter;
    if (role != null && role != _selectedCreateRole) _selectCreateRole(role);
    setState(() => _showCreateForm = true);
  }

  /// Vuelve a la lista descartando lo escrito en el formulario.
  void _closeCreateForm() {
    if (_isCreating) return;
    _resetCreateForm();
    setState(() => _showCreateForm = false);
  }

  /// Módulos del usuario: los asignados (admin. de módulo / técnico) y
  /// aquellos donde figura como productor.
  Set<String> _moduleIdsOf(Map<String, dynamic> user) => {
        ...(user['module_ids'] as List).cast<String>(),
        for (final r in _producerRecordsOf(user['user_id'] as String))
          if (r.isActive) r.moduleId,
      };

  /// Usuarios que pasan el filtro de rol, de módulo y la búsqueda (por
  /// nombre, DNI o nombre de módulo).
  List<Map<String, dynamic>> get _visibleUsers {
    final query = _userSearchController.text.trim().toLowerCase();
    final moduleNames = {for (final m in _modules) m.id: m.name.toLowerCase()};
    return _users.where((u) {
      if (_roleFilter != null && !_matchesRole(u, _roleFilter!)) return false;
      final moduleIds = _moduleIdsOf(u);
      if (_moduleFilter != null && !moduleIds.contains(_moduleFilter)) return false;
      if (query.isEmpty) return true;
      final name = '${u['first_name']} ${u['last_name']}'.toLowerCase();
      return name.contains(query) ||
          u['user_id'].toString().contains(query) ||
          moduleIds.any((id) => moduleNames[id]?.contains(query) ?? false);
    }).toList();
  }

  /// Hoja para elegir el módulo por el que se filtra la lista.
  Future<void> _pickModuleFilter() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          context.responsivePadding.left,
          0,
          context.responsivePadding.left,
          context.responsivePadding.bottom + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: FormGroup(
            children: [
              const _SheetHeader(
                icon: Icons.view_module_outlined,
                title: 'Filtrar por módulo',
                subtitle: 'Usuarios asignados al módulo o productores de él.',
              ),
              _ModulePicker(
                modules: _modules,
                selected: const {},
                multiple: false,
                onChanged: (ids) => Navigator.of(sheetContext).pop(ids.firstOrNull),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _moduleFilter = picked;
        _shownUsers = _usersPageSize;
      });
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _plotNameController.dispose();
    _alsoProducerPlotController.dispose();
    _userSearchController.dispose();
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
      // Por páginas: con más de 1000 filas Supabase cortaría la lista.
      final data = await fetchAllRows(() => _supabase
          .from('users')
          .select('user_id, first_name, last_name, role')
          .eq('cooperative_id', AppConfig.current.id)
          .neq('is_support', true)
          .order('first_name', ascending: true)
          .order('user_id'));

      final modulesByUser = <String, List<String>>{};
      try {
        final assignments = await fetchAllRows(() => _supabase
            .from('user_module_assignments')
            .select('user_id, coop_module_id')
            .eq('cooperative_id', AppConfig.current.id)
            .order('user_id')
            .order('coop_module_id'));
        for (final a in assignments) {
          final uid = a['user_id'] as String;
          modulesByUser.putIfAbsent(uid, () => []).add(a['coop_module_id'] as String);
        }
      } catch (_) {}

      final users = (data as List).map((u) => {
        ...u as Map<String, dynamic>,
        'module_ids': modulesByUser[u['user_id']] ?? <String>[],
      }).toList();

      var producersByDni = _producersByDni;
      try {
        producersByDni = await _producerRecordsService.fetchByDni();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _users = users;
          _producersByDni = producersByDni;
        });
      }
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
      AppSnackBar.show(context, message: 'Ingrese el nombre de la parcela', type: SnackBarType.error);
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

  void _addAlsoProducerPlot() {
    final name = _alsoProducerPlotController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(context, message: 'Ingrese el nombre de la parcela', type: SnackBarType.error);
      return;
    }
    if (_alsoProducerPlotNames.any((p) => p.toLowerCase() == name.toLowerCase())) {
      AppSnackBar.show(context, message: 'Ya existe una parcela con ese nombre', type: SnackBarType.error);
      return;
    }
    setState(() {
      _alsoProducerPlotNames.add(name);
      _alsoProducerPlotController.clear();
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
      _alsoProducer = false;
      _alsoProducerMemberStatus = 'SOCIO';
      _alsoProducerModuleId = null;
      _alsoProducerPlotNames.clear();
      _alsoProducerPlotController.clear();
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
    }
    if (role == 'tecnico_campo') {
      if (_selectedModuleIds.isEmpty) {
        AppSnackBar.show(context, message: 'Seleccione al menos un módulo', type: SnackBarType.error);
        return;
      }
      if (_alsoProducer && _alsoProducerModuleId == null) {
        AppSnackBar.show(context, message: 'Seleccione su módulo como productor', type: SnackBarType.error);
        return;
      }
    }
    final alsoProducer =
        (role == 'admin_modulo' || role == 'tecnico_campo') && _alsoProducer;
    if (alsoProducer && _alsoProducerPlotNames.isEmpty) {
      AppSnackBar.show(context, message: 'Agregue al menos una parcela', type: SnackBarType.error);
      return;
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

      if (alsoProducer) {
        final producer = await _producerService.createProducer(CreateProducerRequest(
          firstName: firstName,
          lastName: lastName,
          dni: dni,
          coopModuleId: role == 'admin_modulo' ? _selectedModuleIds.first : _alsoProducerModuleId!,
          isMember: _alsoProducerMemberStatus == 'SOCIO',
        ));
        final plots = _alsoProducerPlotNames.map((name) => PlotData(name: name)).toList();
        await _plotService.createMultiplePlots(producer.id, plots);
      }

      if (mounted) {
        AppSnackBar.show(context, message: 'Usuario creado exitosamente', type: SnackBarType.success);
        _resetCreateForm();
        setState(() => _showCreateForm = false);
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

  List<ProducerRecord> _producerRecordsOf(String dni) => _producersByDni[dni] ?? const [];

  bool _isActiveProducer(String dni) => _producerRecordsOf(dni).any((r) => r.isActive);

  /// Filtro de la lista: "Productores" incluye a técnicos y administradores
  /// de módulo que además son productores.
  bool _matchesRole(Map<String, dynamic> user, String role) {
    if (role == 'productor') {
      return user['role'] == 'productor' || _isActiveProducer(user['user_id'] as String);
    }
    return user['role'] == role;
  }

  /// Vuelve a leer los registros de productor (tras una acción en "Editar
  /// usuario") y devuelve los del DNI indicado.
  Future<List<ProducerRecord>> _reloadProducerRecords(String dni) async {
    try {
      final byDni = await _producerRecordsService.fetchByDni();
      if (mounted) setState(() => _producersByDni = byDni);
    } catch (_) {}
    return _producerRecordsOf(dni);
  }

  Future<_ProducerDataResult?> _openProducerDataSheet(
    Map<String, dynamic> user, {
    ProducerRecord? record,
  }) {
    // Al registrar en otro módulo no se ofrecen los módulos donde ya figura.
    final takenModuleIds = _producerRecordsOf(user['user_id'] as String)
        .where((r) => r.id != record?.id)
        .map((r) => r.moduleId)
        .toSet();
    return showModalBottomSheet<_ProducerDataResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXLarge)),
      ),
      builder: (_) => _ProducerDataSheet(
        user: user,
        modules: _modules.where((m) => !takenModuleIds.contains(m.id)).toList(),
        record: record,
      ),
    );
  }

  /// Registra al usuario como productor (en otro módulo si ya lo es).
  /// Devuelve false si se canceló o no se pudo guardar.
  Future<bool> _registerAsProducer(Map<String, dynamic> user) async {
    final result = await _openProducerDataSheet(user);
    if (result == null || !mounted) return false;
    return _createProducerRecord(user, result.moduleId, result.memberStatus, result.plotNames);
  }

  Future<bool> _createProducerRecord(
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
      return true;
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: userErrorMessage(e, action: 'No se pudieron guardar los datos de productor'),
          type: SnackBarType.error,
        );
      }
      return false;
    }
  }

  Future<void> _editProducerRecord(Map<String, dynamic> user, ProducerRecord record) async {
    final result = await _openProducerDataSheet(user, record: record);
    if (result == null || !mounted) return;
    try {
      await _producerRecordsService.update(
        record.id,
        moduleId: result.moduleId,
        isMember: result.memberStatus == 'SOCIO',
      );
      if (mounted) {
        AppSnackBar.show(context, message: 'Datos de productor actualizados', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: userErrorMessage(e, action: 'No se pudo guardar'),
          type: SnackBarType.error,
        );
      }
    }
  }

  /// Da de baja (con confirmación) o reactiva un registro de productor.
  Future<void> _toggleProducerRecord(ProducerRecord record) async {
    if (record.isActive) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: '¿Dar de baja como productor?',
        message: 'Dejará de aparecer al registrar producción en ese módulo. '
            'Sus lotes, parcelas y cupos se conservan. Puede reactivarlo después.',
        confirmLabel: 'Dar de baja',
        destructive: true,
      );
      if (!confirmed) return;
    }
    if (await _setProducerActive(record, !record.isActive) && mounted) {
      AppSnackBar.show(
        context,
        message: record.isActive ? 'Dado de baja como productor' : 'Productor reactivado',
        type: SnackBarType.success,
      );
    }
  }

  Future<void> _setProducerMember(ProducerRecord record, bool isMember) async {
    try {
      await _producerRecordsService.update(record.id, moduleId: record.moduleId, isMember: isMember);
      if (mounted) {
        AppSnackBar.show(
          context,
          message: isMember ? 'Marcado como socio' : 'Marcado como no socio',
          type: SnackBarType.success,
        );
      }
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

  Future<bool> _setProducerActive(ProducerRecord record, bool isActive) async {
    try {
      await _producerRecordsService.setActive(record.id, isActive);
      return true;
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: userErrorMessage(e, action: 'No se pudo guardar el cambio'),
          type: SnackBarType.error,
        );
      }
      return false;
    }
  }

  Future<void> _showEditRoleDialog(Map<String, dynamic> user) async {
    final userId = user['user_id'] as String;
    final currentModuleIds = ((user['module_ids'] as List?) ?? []).cast<String>().toSet();

    final result = await showModalBottomSheet<_EditUserResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXLarge)),
      ),
      builder: (_) => _EditUserSheet(
        user: user,
        modules: _modules,
        roleStyles: _roleStyles,
        currentModuleIds: currentModuleIds,
        producerRecords: _producerRecordsOf(userId),
        actions: _ProducerActions(
          register: () => _registerAsProducer(user),
          edit: (record) => _editProducerRecord(user, record),
          toggleActive: _toggleProducerRecord,
          setMember: _setProducerMember,
          reload: () => _reloadProducerRecords(userId),
        ),
      ),
    );
    if (result == null || !mounted) {
      // Las acciones de la sección "Productor" ya se guardaron.
      await _reloadProducerRecords(userId);
      return;
    }

    if (result.roleChanged) {
      final records = _producerRecordsOf(userId);
      if (result.role == 'productor' && !records.any((r) => r.isActive)) {
        // Un productor necesita un registro activo: se reactiva el que tenga
        // o se piden sus datos. Si se cancela, el rol no cambia.
        final inactive = records.where((r) => !r.isActive).firstOrNull;
        final ready = inactive != null
            ? await _setProducerActive(inactive, true)
            : await _registerAsProducer(user);
        if (!ready) {
          if (mounted) {
            AppSnackBar.show(
              context,
              message: 'El rol no se cambió: faltan los datos de productor',
              type: SnackBarType.error,
            );
          }
          await _reloadProducerRecords(userId);
          return;
        }
      }
      if (result.role == 'admin_sistema') {
        // El Administrador del sistema no puede ser productor.
        for (final record in records.where((r) => r.isActive)) {
          await _setProducerActive(record, false);
        }
      }
      await _updateRole(userId, result.role);
    }
    if (result.modulesChanged) await _updateModuleAssignments(userId, result.moduleIds.toList());
    await _reloadProducerRecords(userId);
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
    return PopScope(
      // En "Nuevo usuario", el botón atrás del sistema vuelve a la lista.
      canPop: !_showCreateForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeCreateForm();
      },
      child: AppScaffold(
        hasTopLabel: true,
        topLabelText: _showCreateForm ? 'Nuevo usuario' : 'Gestión de usuarios',
        showBackButton: true,
        onBack: _showCreateForm ? _closeCreateForm : () => context.go(AppRoutes.home.path),
        child: SingleChildScrollView(
          // Cada vista arranca desde arriba.
          key: ValueKey(_showCreateForm),
          padding: context.responsiveHorizontalPadding.copyWith(
            top: context.responsivePadding.top,
            bottom: context.responsivePadding.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.responsiveCardWidth),
              child: _showCreateForm ? _buildCreateForm() : _buildUsersList(currentUserDni),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(String? currentUserDni) {
    final visible = _visibleUsers;
    return _Panel(
      child: FormGroup(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Usuarios', style: AppTextStyles.cardTitle),
                    if (!_isLoadingUsers)
                      Text(
                        _users.length == 1 ? '1 usuario registrado' : '${_users.length} usuarios registrados',
                        style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              FilledButton.icon(
                onPressed: _goToCreateForm,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Nuevo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
              ),
            ],
          ),
          if (_users.length >= _userSearchThreshold)
            AppTextField(
              controller: _userSearchController,
              hintText: 'Buscar por nombre, DNI o módulo',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _userSearchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Limpiar búsqueda',
                      onPressed: _userSearchController.clear,
                    ),
            ),
          _buildRoleFilters(),
          if (_modules.length > 1)
            _FilterButton(
              icon: Icons.view_module_outlined,
              label: _moduleFilter == null
                  ? 'Todos los módulos'
                  : _modules
                          .where((m) => m.id == _moduleFilter)
                          .map((m) => m.name)
                          .firstOrNull ??
                      'Módulo',
              active: _moduleFilter != null,
              onTap: _pickModuleFilter,
              onClear: () => setState(() {
                _moduleFilter = null;
                _shownUsers = _usersPageSize;
              }),
            ),
          if (_isLoadingUsers)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingLarge),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_users.isEmpty)
            const _EmptyState(icon: Icons.group_outlined, text: 'Aún no hay usuarios registrados.')
          else if (visible.isEmpty)
            const _EmptyState(icon: Icons.search_off, text: 'Ningún usuario coincide con el filtro.')
          else ...[
            if (visible.length != _users.length)
              Text(
                visible.length == 1 ? '1 resultado' : '${visible.length} resultados',
                style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
              ),
            AppEntityList(
              children: [
                for (final user in visible.take(_shownUsers)) _buildUserTile(user, currentUserDni),
              ],
            ),
            if (visible.length > _shownUsers)
              AppButton(
                text: 'Mostrar más (${visible.length - _shownUsers} restantes)',
                type: AppButtonType.secondary,
                onPressed: () => setState(() => _shownUsers += _usersPageSize),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    final role = _selectedCreateRole;
    final needsModules = role == 'admin_modulo' || role == 'tecnico_campo';
    const gap = SizedBox(height: AppDimensions.spacingMedium);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Panel(
            title: 'Datos del usuario',
            icon: Icons.person_outline,
            child: FormGroup(
              children: [
                AppTextField(
                  label: 'DNI',
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 8,
                  validator: _validateDNI,
                  enabled: !_isCreating,
                ),
                AppTextField(
                  label: 'Nombres',
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => _validateName(v, 'el nombre'),
                  enabled: !_isCreating,
                ),
                AppTextField(
                  label: 'Apellidos',
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  validator: (v) => _validateName(v, 'el apellido'),
                  enabled: !_isCreating,
                ),
                _SwitchRow(
                  value: _useDniAsPassword,
                  title: 'Usar DNI como contraseña',
                  subtitle: 'Ingresará con su DNI como usuario y contraseña.',
                  enabled: !_isCreating,
                  onChanged: (v) => setState(() {
                    _useDniAsPassword = v;
                    _passwordController.clear();
                  }),
                ),
                if (!_useDniAsPassword)
                  AppTextField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    enabled: !_isCreating,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.primary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
              ],
            ),
          ),
          gap,
          _Panel(
            title: 'Rol',
            icon: Icons.badge_outlined,
            child: _RoleSelector(
              roleStyles: _roleStyles,
              selected: role,
              enabled: !_isCreating,
              onSelected: (r) {
                if (r != role) _selectCreateRole(r);
              },
            ),
          ),
          if (needsModules) ...[
            gap,
            _Panel(
              title: role == 'admin_modulo' ? 'Módulo asignado' : 'Módulos asignados',
              icon: Icons.view_module_outlined,
              subtitle: role == 'admin_modulo' ? 'Administra un solo módulo.' : 'Puede elegir varios.',
              child: _isLoadingModules
                  ? const Center(child: CircularProgressIndicator())
                  : _ModulePicker(
                      key: ValueKey('create-modules-$role'),
                      modules: _modules,
                      selected: _selectedModuleIds,
                      multiple: role == 'tecnico_campo',
                      onChanged: (ids) => setState(() => _selectedModuleIds = ids),
                    ),
            ),
          ],
          // El Administrador del sistema no puede ser productor.
          if (role != 'admin_sistema') ...[gap, _buildCreateProducerPanel()],
          gap,
          _SheetButtons(
            onCancel: _isCreating ? null : _closeCreateForm,
            onSave: _createUser,
            saveLabel: 'Crear usuario',
            isSaving: _isCreating,
          ),
        ],
      ),
    );
  }

  /// Datos de productor del formulario "Nuevo usuario": obligatorios para el
  /// rol Productor y opcionales ("También es productor") para técnicos y
  /// administradores de módulo.
  Widget _buildCreateProducerPanel() {
    final role = _selectedCreateRole;
    final isProductor = role == 'productor';
    final showFields = isProductor || _alsoProducer;
    final memberStatus = isProductor ? _producerMemberStatus : _alsoProducerMemberStatus;
    final plotNames = isProductor ? _createPlotNames : _alsoProducerPlotNames;

    return _Panel(
      title: isProductor ? 'Datos de productor' : 'Productor',
      icon: Icons.agriculture_outlined,
      subtitle: isProductor ? 'Módulo donde produce, condición y parcelas.' : null,
      child: FormGroup(
        children: [
          if (!isProductor)
            _SwitchRow(
              value: _alsoProducer,
              title: 'También es productor',
              subtitle: 'Tendrá parcelas y podrá registrar su propia producción.',
              enabled: !_isCreating,
              onChanged: (v) => setState(() {
                _alsoProducer = v;
                if (!v) {
                  _alsoProducerPlotNames.clear();
                  _alsoProducerPlotController.clear();
                  _alsoProducerModuleId = null;
                }
              }),
            ),
          if (showFields) ...[
            // El administrador de módulo produce en su propio módulo; el
            // técnico elige en cuál (puede no ser uno de los asignados).
            if (role == 'admin_modulo')
              const _Notice(text: 'Se registrará como productor en su módulo asignado.')
            else
              _SheetSection(
                title: 'Módulo donde produce',
                child: _isLoadingModules
                    ? const Center(child: CircularProgressIndicator())
                    : _ModulePicker(
                        key: ValueKey('create-producer-module-$role'),
                        modules: _modules,
                        selected: {
                          if (isProductor && _selectedProductorModuleId != null) _selectedProductorModuleId!,
                          if (!isProductor && _alsoProducerModuleId != null) _alsoProducerModuleId!,
                        },
                        multiple: false,
                        onChanged: (ids) => setState(() {
                          if (isProductor) {
                            _selectedProductorModuleId = ids.firstOrNull;
                          } else {
                            _alsoProducerModuleId = ids.firstOrNull;
                          }
                        }),
                      ),
              ),
            _SheetSection(
              title: 'Condición',
              child: _MembershipChips(
                value: memberStatus,
                onChanged: (v) => setState(() {
                  if (isProductor) {
                    _producerMemberStatus = v;
                  } else {
                    _alsoProducerMemberStatus = v;
                  }
                }),
              ),
            ),
            _SheetSection(
              title: 'Parcelas',
              child: _PlotNamesField(
                controller: isProductor ? _plotNameController : _alsoProducerPlotController,
                names: plotNames,
                enabled: !_isCreating,
                onAdd: isProductor ? _addPlotToCreate : _addAlsoProducerPlot,
                onRemove: (name) => setState(() => plotNames.remove(name)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleStyle {
  const _RoleStyle({
    required this.singular,
    required this.plural,
    required this.short,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
  });

  /// Rol que la app no conoce (no debería ocurrir): se muestra tal cual.
  const _RoleStyle.unknown(this.singular)
      : plural = singular,
        short = singular,
        description = '',
        icon = Icons.person_outline,
        color = AppColors.primary,
        background = AppColors.infoLight;

  final String singular;
  final String plural;
  /// Nombre corto para las opciones de rol.
  final String short;
  /// Qué puede hacer: se muestra bajo las opciones de rol.
  final String description;
  final IconData icon;
  final Color color;
  final Color background;
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.radiusXLarge);
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.textWhite : AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '$label  $count',
                style: AppTextStyles.captionText.copyWith(
                  color: selected ? AppColors.textWhite : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo que se eligió en la hoja "Editar usuario" para el rol y los módulos
/// asignados; la pantalla aplica esos cambios al guardar. Las acciones de la
/// sección "Productor" no pasan por aquí: se guardan al momento.
class _EditUserResult {
  const _EditUserResult({
    required this.role,
    required this.roleChanged,
    required this.moduleIds,
    required this.modulesChanged,
  });

  final String role;
  final bool roleChanged;
  final Set<String> moduleIds;
  final bool modulesChanged;
}

/// Acciones sobre los registros de productor del usuario que se edita. Las
/// ejecuta la pantalla (servicios y mensajes); la hoja solo las dispara y
/// luego recarga los registros con [reload].
class _ProducerActions {
  const _ProducerActions({
    required this.register,
    required this.edit,
    required this.toggleActive,
    required this.setMember,
    required this.reload,
  });

  final Future<bool> Function() register;
  final Future<void> Function(ProducerRecord record) edit;
  final Future<void> Function(ProducerRecord record) toggleActive;
  /// Cambia Socio / No socio directamente desde la tarjeta.
  final Future<void> Function(ProducerRecord record, bool isMember) setMember;
  final Future<List<ProducerRecord>> Function() reload;
}

enum _ProducerRecordAction { edit, plots, toggleActive }

class _EditUserSheet extends StatefulWidget {
  const _EditUserSheet({
    required this.user,
    required this.modules,
    required this.roleStyles,
    required this.currentModuleIds,
    required this.producerRecords,
    required this.actions,
  });

  final Map<String, dynamic> user;
  final List<CoopModule> modules;
  final Map<String, _RoleStyle> roleStyles;
  final Set<String> currentModuleIds;
  final List<ProducerRecord> producerRecords;
  final _ProducerActions actions;

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  late final String _currentRole = widget.user['role'] as String? ?? 'productor';
  late String _role = _currentRole;
  late Set<String> _moduleIds = {...widget.currentModuleIds};
  late List<ProducerRecord> _records = widget.producerRecords;
  bool _busy = false;

  String get _fullName => '${widget.user['first_name']} ${widget.user['last_name']}';
  bool get _isAdminModulo => _role == 'admin_modulo';
  bool get _needsModules => _isAdminModulo || _role == 'tecnico_campo';
  bool get _roleChanged => _role != _currentRole;
  bool get _modulesChanged =>
      _needsModules &&
      (!_moduleIds.containsAll(widget.currentModuleIds) ||
          !widget.currentModuleIds.containsAll(_moduleIds));
  bool get _modulesValid => !_needsModules || _moduleIds.isNotEmpty;
  bool get _adminModuloValid => !_isAdminModulo || _moduleIds.length == 1;
  bool get _canSave => (_roleChanged || _modulesChanged) && _modulesValid && _adminModuloValid;
  bool get _hasActiveRecord => _records.any((r) => r.isActive);

  String _moduleName(String id) =>
      widget.modules.firstWhere((m) => m.id == id, orElse: () => CoopModule(id: id, name: 'Módulo')).name;

  /// Ejecuta una acción de productor y recarga sus registros.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      final records = await widget.actions.reload();
      if (mounted) setState(() => _records = records);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRecordAction(_ProducerRecordAction action, ProducerRecord record) async {
    switch (action) {
      case _ProducerRecordAction.edit:
        await _run(() => widget.actions.edit(record));
      case _ProducerRecordAction.plots:
        await showProducerPlotsSheet(context, producerId: record.id, producerName: _fullName);
      case _ProducerRecordAction.toggleActive:
        final isLastActive = record.isActive && _records.where((r) => r.isActive).length == 1;
        if (_currentRole == 'productor' && _role == 'productor' && isLastActive) {
          AppSnackBar.show(
            context,
            message: 'Un productor debe tener al menos un registro activo. '
                'Para darlo de baja, cambie primero su rol.',
            type: SnackBarType.error,
          );
          return;
        }
        await _run(() => widget.actions.toggleActive(record));
    }
  }

  void _save() {
    Navigator.of(context).pop(_EditUserResult(
      role: _role,
      roleChanged: _roleChanged,
      moduleIds: _moduleIds,
      modulesChanged: _modulesChanged,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final currentStyle = widget.roleStyles[_currentRole] ?? _RoleStyle.unknown(_currentRole);
    final horizontal = context.responsivePadding.left;
    final hasChanges = _roleChanged || _modulesChanged;
    const gap = SizedBox(height: AppDimensions.spacingMedium);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, context.responsivePadding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              initials: entityInitials(
                widget.user['first_name']?.toString() ?? '',
                widget.user['last_name']?.toString() ?? '',
              ),
              title: _fullName,
              subtitle: 'DNI ${widget.user['user_id']}',
              caption: currentStyle.singular,
            ),
            gap,
            _Panel(
              title: 'Rol y módulos',
              icon: Icons.badge_outlined,
              subtitle: 'Se aplican al tocar "Guardar cambios".',
              child: FormGroup(
                children: [
                  _RoleSelector(
                    roleStyles: widget.roleStyles,
                    selected: _role,
                    onSelected: (r) => setState(() => _role = r),
                  ),
                  // Módulos para admin_modulo / tecnico_campo
                  if (_needsModules)
                    _SheetSection(
                      title: _isAdminModulo ? 'Módulo asignado (solo uno)' : 'Módulos asignados',
                      error: !_modulesValid
                          ? 'Seleccione al menos un módulo'
                          : !_adminModuloValid
                              ? 'El administrador de módulo solo puede tener un módulo'
                              : null,
                      child: _ModulePicker(
                        key: ValueKey('edit-modules-$_role'),
                        modules: widget.modules,
                        selected: _moduleIds,
                        multiple: !_isAdminModulo,
                        onChanged: (ids) => setState(() => _moduleIds = ids),
                      ),
                    ),
                  if (_roleChanged && _role == 'productor' && !_hasActiveRecord)
                    _Notice(
                      text: _records.isEmpty
                          ? 'Al guardar se le pedirán sus datos de productor.'
                          : 'Al guardar se reactivará su registro de productor.',
                    ),
                  // El Administrador del sistema no puede ser productor.
                  if (_role == 'admin_sistema' && _hasActiveRecord)
                    const _Notice(
                      text: 'El Administrador del sistema no puede ser productor. '
                          'Al guardar, sus registros de productor se darán de baja '
                          '(sus lotes y parcelas se conservan).',
                      warning: true,
                    ),
                ],
              ),
            ),
            if (_role != 'admin_sistema') ...[gap, _buildProducerSection()],
            gap,
            if (hasChanges)
              _SheetButtons(
                cancelLabel: 'Descartar',
                onCancel: () => Navigator.of(context).pop(),
                saveLabel: 'Guardar cambios',
                onSave: _canSave && !_busy ? _save : null,
              )
            else
              AppButton(
                text: 'Cerrar',
                type: AppButtonType.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }

  /// Condición de productor, independiente del rol. Sus acciones se guardan
  /// al momento (no esperan a "Guardar cambios").
  Widget _buildProducerSection() {
    return _Panel(
      title: 'Productor',
      icon: Icons.agriculture_outlined,
      subtitle: _busy ? 'Guardando...' : 'Estos cambios se guardan al instante.',
      trailing: _busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : _records.isEmpty
              ? null
              : _StatusDot(active: _hasActiveRecord),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_records.isEmpty) ...[
            Text(
              'Regístrelo como productor para asignarle parcelas y que '
              'pueda registrar su propia producción.',
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
            AppButton(
              text: 'Registrar como productor',
              icon: Icons.add,
              type: AppButtonType.secondary,
              onPressed: _busy ? null : () => _run(widget.actions.register),
            ),
          ] else ...[
            for (final (i, record) in _records.indexed) ...[
              if (i > 0) const SizedBox(height: AppDimensions.spacingSmall),
              _ProducerRecordCard(
                moduleName: _moduleName(record.moduleId),
                record: record,
                enabled: !_busy,
                onAction: (action) => _onRecordAction(action, record),
                onMemberChanged: (isMember) =>
                    _run(() => widget.actions.setMember(record, isMember)),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingXSmall),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : () => _run(widget.actions.register),
                icon: const Icon(Icons.add),
                label: const Text('Registrar en otro módulo'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aviso corto dentro de las hojas de edición.
class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall + AppDimensions.paddingXSmall),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningLight : AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warning ? Icons.warning_amber_rounded : Icons.info_outline, size: 18, color: color),
          const SizedBox(width: AppDimensions.spacingSmall),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Datos de un registro de productor: para registrarlo (con parcelas) o
/// para editar su módulo y condición ([plotNames] vacío).
class _ProducerDataResult {
  const _ProducerDataResult({
    required this.moduleId,
    required this.memberStatus,
    required this.plotNames,
  });

  final String moduleId;
  final String memberStatus;
  final List<String> plotNames;
}

class _ProducerDataSheet extends StatefulWidget {
  const _ProducerDataSheet({required this.user, required this.modules, this.record});

  final Map<String, dynamic> user;
  final List<CoopModule> modules;
  /// Registro a editar; null para registrar uno nuevo.
  final ProducerRecord? record;

  @override
  State<_ProducerDataSheet> createState() => _ProducerDataSheetState();
}

class _ProducerDataSheetState extends State<_ProducerDataSheet> {
  final _plotController = TextEditingController();
  final List<String> _plotNames = [];
  late String? _moduleId = widget.record?.moduleId;
  late String _memberStatus =
      (widget.record?.isMember ?? true) ? 'SOCIO' : 'NO SOCIO';

  bool get _isNew => widget.record == null;

  @override
  void dispose() {
    _plotController.dispose();
    super.dispose();
  }

  void _addPlot() {
    final name = _plotController.text.trim();
    if (name.isEmpty || _plotNames.any((p) => p.toLowerCase() == name.toLowerCase())) return;
    setState(() {
      _plotNames.add(name);
      _plotController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.responsivePadding.left;
    final canSave = _moduleId != null && (!_isNew || _plotNames.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, context.responsivePadding.bottom),
        child: FormGroup(
          children: [
            _SheetHeader(
              icon: Icons.agriculture_outlined,
              title: _isNew ? 'Registrar como productor' : 'Editar datos de productor',
              subtitle: '${widget.user['first_name']} ${widget.user['last_name']}',
            ),
            _SheetSection(
              title: 'Módulo donde produce',
              error: _moduleId == null ? 'Seleccione el módulo' : null,
              child: _ModulePicker(
                modules: widget.modules,
                selected: {if (_moduleId != null) _moduleId!},
                multiple: false,
                onChanged: (ids) => setState(() => _moduleId = ids.firstOrNull),
              ),
            ),
            _SheetSection(
              title: 'Condición',
              child: _MembershipChips(
                value: _memberStatus,
                onChanged: (v) => setState(() => _memberStatus = v),
              ),
            ),
            if (_isNew)
              _SheetSection(
                title: 'Parcelas',
                child: _PlotNamesField(
                  controller: _plotController,
                  names: _plotNames,
                  onAdd: _addPlot,
                  onRemove: (name) => setState(() => _plotNames.remove(name)),
                ),
              ),
            _SheetButtons(
              onCancel: () => Navigator.of(context).pop(),
              saveLabel: _isNew ? 'Registrar' : 'Guardar',
              onSave: canSave
                  ? () => Navigator.of(context).pop(_ProducerDataResult(
                        moduleId: _moduleId!,
                        memberStatus: _memberStatus,
                        plotNames: List.of(_plotNames),
                      ))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Condición del productor: Socio / No socio.
class _MembershipChips extends StatelessWidget {
  const _MembershipChips({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Segmented(
      options: const {'SOCIO': 'Socio', 'NO SOCIO': 'No socio'},
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Nombre de parcela + botón agregar, con las parcelas agregadas como
/// etiquetas que se pueden quitar.
class _PlotNamesField extends StatefulWidget {
  const _PlotNamesField({
    required this.controller,
    required this.names,
    required this.onAdd,
    required this.onRemove,
    this.enabled = true,
  });

  final TextEditingController controller;
  final List<String> names;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool enabled;

  @override
  State<_PlotNamesField> createState() => _PlotNamesFieldState();
}

class _PlotNamesFieldState extends State<_PlotNamesField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Agrega y deja el cursor en el campo para escribir la siguiente.
  void _add() {
    widget.onAdd();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          hintText: 'Nombre de la parcela',
          helperText: 'Escriba el nombre y presione Enter o +',
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(),
          enabled: widget.enabled,
          suffixIcon: IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            tooltip: 'Agregar parcela',
            onPressed: widget.enabled ? _add : null,
          ),
        ),
        if (widget.names.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingSmall),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in widget.names)
                InputChip(
                  label: Text(name),
                  labelStyle: AppTextStyles.captionText.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  deleteIconColor: AppColors.textPrimary,
                  onDeleted: widget.enabled ? () => widget.onRemove(name) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Interruptor con título y explicación; toda la fila es tocable.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.value,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final bool value;
  final String title;
  final String? subtitle;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXSmall),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Switch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    );
  }
}

/// Bloque blanco con borde fino y título: agrupa una parte del formulario.
/// No se anida dentro de otro [_Panel].
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  /// Ícono de referencia junto al título (siempre en el azul de la app).
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // En celulares angostos el relleno se reduce para no restar ancho.
    final padding = ScreenUtils.isSmallScreen(context)
        ? AppDimensions.paddingSmall + AppDimensions.paddingXSmall
        : AppDimensions.paddingMedium;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppDimensions.spacingSmall + 2),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title!, style: AppTextStyles.cardTitle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppDimensions.spacingSmall),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
          ],
          child,
        ],
      ),
    );
  }
}

/// Encabezado de las hojas: avatar (iniciales o ícono), nombre y datos.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    this.subtitle,
    this.initials,
    this.icon,
    this.caption,
  }) : assert(initials != null || icon != null);

  final String title;
  final String? subtitle;
  final String? initials;
  final IconData? icon;
  /// Texto corto bajo los datos (p. ej. el rol actual).
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.infoLight,
          child: icon != null
              ? Icon(icon, color: AppColors.primaryDark, size: 24)
              : Text(
                  initials!,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: AppDimensions.spacingSmall + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null || caption != null)
                Text(
                  [if (subtitle != null) subtitle!, if (caption != null) caption!].join(' · '),
                  style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Roles como lista de una columna: nombre y qué puede hacer. Se lee de un
/// vistazo y no se desborda en pantallas angostas.
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.roleStyles,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final Map<String, _RoleStyle> roleStyles;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.radiusMedium);
    final entries = roleStyles.entries.toList();
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, entry) in entries.indexed) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              Material(
                color: entry.key == selected ? AppColors.infoLight : AppColors.surface,
                child: InkWell(
                  onTap: enabled ? () => onSelected(entry.key) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          entry.key == selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppDimensions.spacingSmall),
                        Icon(entry.value.icon, size: 20, color: AppColors.primaryDark),
                        const SizedBox(width: AppDimensions.spacingSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value.singular,
                                style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (entry.value.description.isNotEmpty)
                                Text(
                                  entry.value.description,
                                  style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Control de dos opciones lado a lado (p. ej. Socio / No socio).
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// valor → texto
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.radiusMedium);
    final entries = options.entries.toList();
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Row(
          children: [
            for (final (i, entry) in entries.indexed) ...[
              if (i > 0) const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                child: Material(
                  color: entry.key == value ? AppColors.primary : AppColors.surface,
                  child: InkWell(
                    onTap: enabled && entry.key != value ? () => onChanged(entry.key) : null,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: entry.key == value ? AppColors.textWhite : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un registro de productor (un módulo): la condición se cambia ahí mismo y
/// las demás acciones están a la vista.
class _ProducerRecordCard extends StatelessWidget {
  const _ProducerRecordCard({
    required this.moduleName,
    required this.record,
    required this.enabled,
    required this.onAction,
    required this.onMemberChanged,
  });

  final String moduleName;
  final ProducerRecord record;
  final bool enabled;
  final ValueChanged<_ProducerRecordAction> onAction;
  final ValueChanged<bool> onMemberChanged;

  @override
  Widget build(BuildContext context) {
    final active = record.isActive;
    VoidCallback? action(_ProducerRecordAction a) => enabled ? () => onAction(a) : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  moduleName,
                  style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              _StatusDot(active: active),
            ],
          ),
          if (active) ...[
            const SizedBox(height: AppDimensions.spacingSmall),
            _Segmented(
              options: const {'SOCIO': 'Socio', 'NO SOCIO': 'No socio'},
              value: record.isMember ? 'SOCIO' : 'NO SOCIO',
              enabled: enabled,
              onChanged: (v) => onMemberChanged(v == 'SOCIO'),
            ),
          ] else
            Text(
              record.isMember ? 'Socio' : 'No socio',
              style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
            ),
          const SizedBox(height: AppDimensions.spacingXSmall),
          Wrap(
            spacing: AppDimensions.spacingXSmall,
            children: [
              if (active)
                _RecordActionButton(
                  icon: Icons.landscape_outlined,
                  label: 'Parcelas',
                  onPressed: action(_ProducerRecordAction.plots),
                ),
              _RecordActionButton(
                icon: Icons.swap_horiz,
                label: 'Cambiar módulo',
                onPressed: action(_ProducerRecordAction.edit),
              ),
              _RecordActionButton(
                icon: active ? Icons.block : Icons.restart_alt,
                label: active ? 'Dar de baja' : 'Reactivar',
                color: active ? AppColors.error : AppColors.primary,
                onPressed: action(_ProducerRecordAction.toggleActive),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Punto y texto de estado: verde activo, rojo dado de baja.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active, this.inactiveLabel = 'Dado de baja'});

  final bool active;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          active ? 'Activo' : inactiveLabel,
          style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RecordActionButton extends StatelessWidget {
  const _RecordActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: AppTextStyles.captionText.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Botón de filtro tipo "pastilla": muestra lo elegido y una X para quitarlo.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.onClear,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.radiusMedium);
    return Material(
      color: active ? AppColors.infoLight : AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 12),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: active ? AppColors.primary : AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.spacingSmall),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (active)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textPrimary,
                  tooltip: 'Quitar filtro',
                  onPressed: onClear,
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.expand_more, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado con ícono para listas vacías.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingLarge),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.primary),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(text, style: AppTextStyles.bodyText, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Bloque con título (y error opcional) dentro de las hojas de edición.
class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.child, this.error});

  final String title;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppDimensions.spacingSmall),
        child,
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: AppTextStyles.captionText.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}

/// Cancelar / Guardar, lado a lado (uno debajo del otro si no hay ancho).
class _SheetButtons extends StatelessWidget {
  const _SheetButtons({
    required this.onCancel,
    required this.onSave,
    this.cancelLabel = 'Cancelar',
    this.saveLabel = 'Guardar',
    this.isSaving = false,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final String cancelLabel;
  final String saveLabel;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final cancel = AppButton(text: cancelLabel, type: AppButtonType.secondary, onPressed: onCancel);
    final save = AppButton(text: saveLabel, onPressed: onSave, isLoading: isSaving);
    if (MediaQuery.sizeOf(context).width < 320) {
      return FormGroup(children: [save, cancel]);
    }
    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: AppDimensions.spacingSmall + 4),
        Expanded(child: save),
      ],
    );
  }
}

/// Lista de módulos con buscador, de selección única o múltiple. Pensada
/// para cooperativas con cientos de módulos: muestra como máximo
/// [_maxVisible] a la vez (el buscador encuentra el resto) y, en selección
/// múltiple, los elegidos quedan arriba como etiquetas que se pueden quitar.
class _ModulePicker extends StatefulWidget {
  const _ModulePicker({
    super.key,
    required this.modules,
    required this.selected,
    required this.multiple,
    required this.onChanged,
  });

  final List<CoopModule> modules;
  final Set<String> selected;
  final bool multiple;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_ModulePicker> createState() => _ModulePickerState();
}

class _ModulePickerState extends State<_ModulePicker> {
  /// A partir de cuántos módulos se muestra el buscador.
  static const _searchThreshold = 6;

  /// Cuántos módulos se dibujan como máximo: el resto se encuentra buscando.
  static const _maxVisible = 25;

  final _searchController = TextEditingController();

  /// Con algo ya elegido, la lista arranca cerrada y solo se ve el resumen
  /// con "Cambiar": la lista completa alargaba la hoja sin necesidad.
  late bool _expanded = widget.selected.isEmpty;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _nameOf(String id) =>
      widget.modules.where((m) => m.id == id).map((m) => m.name).firstOrNull ?? 'Módulo';

  void _toggle(String id) {
    if (!widget.multiple) {
      widget.onChanged({id});
      setState(() {
        _expanded = false;
        _searchController.clear();
      });
      return;
    }
    final next = {...widget.selected};
    if (!next.remove(id)) next.add(id);
    widget.onChanged(next);
  }

  /// "Norte" · "Norte, Sur y Centro" · "5 módulos: Norte, Sur, Centro y 2 más"
  String _summaryText() {
    final names = widget.selected.map(_nameOf).toList()..sort();
    if (names.isEmpty) return 'Módulo no disponible';
    if (names.length <= 3) return names.join(', ');
    return '${names.length} módulos: ${names.take(3).join(', ')} y ${names.length - 3} más';
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.view_module_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _summaryText(),
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _expanded = true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modules.isEmpty) {
      return Text('No hay módulos disponibles', style: AppTextStyles.bodyText);
    }
    if (!_expanded) return _buildSummary();

    final query = _searchController.text.trim().toLowerCase();
    final matches = widget.modules.where((m) => m.name.toLowerCase().contains(query)).toList();
    final visible = matches.take(_maxVisible).toList();
    final hidden = matches.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.multiple && widget.selected.isNotEmpty) ...[
          Text(
            widget.selected.length == 1 ? '1 seleccionado' : '${widget.selected.length} seleccionados',
            style: AppTextStyles.captionText.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final id in widget.selected)
                InputChip(
                  label: Text(_nameOf(id)),
                  labelStyle: AppTextStyles.captionText.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.infoLight,
                  side: BorderSide.none,
                  deleteIconColor: AppColors.primaryDark,
                  onDeleted: () => _toggle(id),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
        ],
        if (widget.modules.length >= _searchThreshold) ...[
          AppTextField(
            controller: _searchController,
            hintText: 'Buscar entre ${widget.modules.length} módulos',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Limpiar búsqueda',
                    onPressed: _searchController.clear,
                  ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
        ],
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                  child: Text(
                    'Ningún módulo coincide',
                    style: AppTextStyles.bodyText,
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  // Sin scroll propio: desplaza la hoja completa. Un scroll
                  // dentro de otro atrapaba el dedo en pantallas pequeñas.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, module) in visible.indexed) ...[
                      if (i > 0) const Divider(height: 1, color: AppColors.border),
                      _moduleRow(module),
                    ],
                  ],
                ),
        ),
        if (hidden > 0) ...[
          const SizedBox(height: 6),
          Text(
            'Se muestran ${visible.length} de ${matches.length}. '
            'Escriba en el buscador para encontrar los demás.',
            style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ],
    );
  }

  Widget _moduleRow(CoopModule module) {
    final isSelected = widget.selected.contains(module.id);
    return InkWell(
      onTap: () => _toggle(module.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              widget.multiple
                  ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                  : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                module.name,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
