import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/providers/producer_prefill_provider.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
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
  final AuthService _authService = AuthService();
  bool _isCreating = false;
  bool _obscurePassword = true;

  // Module selection (for admin_modulo creation)
  List<CoopModule> _modules = [];
  Set<String> _selectedModuleIds = {};
  bool _isLoadingModules = false;

  // Users list
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;
  String _selectedCreateRole = 'admin_modulo';

  // Productor role excluded from creation — producers are created via the producer registration form
  final List<DropdownOption<String>> _createRoleOptions = [
    DropdownOption<String>(label: 'Admin Módulo', value: 'admin_modulo'),
    DropdownOption<String>(label: 'Admin Sistema', value: 'admin_sistema'),
  ];

  // All roles available for role changes on existing users
  final List<DropdownOption<String>> _allRoleOptions = [
    DropdownOption<String>(label: 'Productor', value: 'productor'),
    DropdownOption<String>(label: 'Admin Módulo', value: 'admin_modulo'),
    DropdownOption<String>(label: 'Admin Sistema', value: 'admin_sistema'),
  ];

  static const _roleLabels = {
    'productor': 'Productor',
    'admin_modulo': 'Admin Módulo',
    'admin_sistema': 'Admin Sistema',
  };

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoadingModules = true);
    try {
      final modules = await CoopModulesService().getModules();
      if (mounted) setState(() => _modules = modules);
    } catch (_) {
      // Non-critical, modules just won't show in dropdown
    } finally {
      if (mounted) setState(() => _isLoadingModules = false);
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final data = await _supabase
          .from('users')
          .select('user_id, first_name, last_name, role')
          .eq('cooperative_id', AppConfig.current.id)
          .order('first_name', ascending: true);

      // Fetch module assignments for all users (table may not exist yet)
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
      } catch (_) {
        // Table doesn't exist yet — ignore, users will show without module info
      }

      final users = (data as List).map((u) {
        return {
          ...u as Map<String, dynamic>,
          'module_ids': modulesByUser[u['user_id']] ?? <String>[],
        };
      }).toList();

      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Error al cargar usuarios', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    // Require at least one module for admin_modulo
    if (_selectedCreateRole == 'admin_modulo' && _selectedModuleIds.isEmpty) {
      AppSnackBar.show(context,
          message: 'Seleccione al menos un módulo asignado', type: SnackBarType.error);
      return;
    }
    setState(() => _isCreating = true);
    try {
      await _authService.registerUser(
        dni: _dniController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        role: _selectedCreateRole,
        moduleIds: _selectedCreateRole == 'admin_modulo' ? _selectedModuleIds.toList() : [],
      );
      if (mounted) {
        AppSnackBar.show(context,
            message: 'Usuario creado exitosamente', type: SnackBarType.success);
        _formKey.currentState!.reset();
        _dniController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _passwordController.clear();
        setState(() {
          _selectedCreateRole = 'admin_modulo';
          _selectedModuleIds.clear();
        });
        _loadUsers();
      }
    } on AuthException catch (e) {
      if (mounted) AppSnackBar.show(context, message: e.message, type: SnackBarType.error);
    } catch (e) {
      if (mounted) AppSnackBar.show(context,
          message: e.toString().replaceFirst('Exception: ', ''), type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<bool> _hasProducerRecord(String userId) async {
    final result = await _supabase
        .from('producers')
        .select('id')
        .eq('dni', userId)
        .eq('cooperative_id', AppConfig.current.id)
        .maybeSingle();
    return result != null;
  }

  Future<void> _showEditRoleDialog(Map<String, dynamic> user) async {
    String currentRole = user['role'] as String? ?? 'productor';
    String selectedRole = currentRole;
    final fullName = '${user['first_name']} ${user['last_name']}';
    final currentModuleIds = ((user['module_ids'] as List?) ?? []).cast<String>().toSet();
    Set<String> selectedModuleIds = Set.from(currentModuleIds);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isAdminModulo = selectedRole == 'admin_modulo';
          final roleChanged = selectedRole != currentRole;
          final modulesChanged = isAdminModulo &&
              (!selectedModuleIds.containsAll(currentModuleIds) ||
               !currentModuleIds.containsAll(selectedModuleIds));
          final hasChanges = roleChanged || modulesChanged;
          final modulesValid = !isAdminModulo || selectedModuleIds.isNotEmpty;

          return AlertDialog(
            title: Text('Editar usuario'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600)),
                  Text('DNI: ${user['user_id']}', style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary)),
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
                  if (isAdminModulo) ...[
                    const SizedBox(height: 16),
                    Text('Módulos asignados', style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 6),
                    if (_modules.isEmpty)
                      Text('No hay módulos disponibles',
                          style: AppTextStyles.smallText.copyWith(color: AppColors.textSecondary))
                    else
                      ..._modules.map((m) => CheckboxListTile(
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
                    if (selectedModuleIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Seleccione al menos un módulo',
                            style: AppTextStyles.smallText.copyWith(color: AppColors.error)),
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
                onPressed: (!hasChanges || !modulesValid)
                    ? null
                    : () async {
                        final userId = user['user_id'] as String;
                        final nav = Navigator.of(ctx);
                        if (selectedRole == 'productor') {
                          final hasRecord = await _hasProducerRecord(userId);
                          if (!hasRecord) {
                            nav.pop();
                            if (mounted) {
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Registro incompleto'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_add_alt_1,
                                          size: 48, color: AppColors.primary),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Para asignar el rol de Productor, '
                                        'primero debes registrar los datos de '
                                        '${user['first_name']} ${user['last_name']} '
                                        '(módulo, parcelas, etc.).',
                                        style: AppTextStyles.bodyText,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.app_registration),
                                      label: const Text('Ir al formulario'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        ref.read(producerPreFillProvider.notifier).state =
                                            ProducerPreFill(
                                          dni: userId,
                                          firstName: user['first_name'] as String,
                                          lastName: user['last_name'] as String,
                                        );
                                        context.go(AppRoutes.producerRegistration.path);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                            return;
                          }
                        }
                        nav.pop();
                        if (roleChanged) await _updateRole(userId, selectedRole);
                        if (modulesChanged) {
                          await _updateModuleAssignments(userId, selectedModuleIds.toList());
                        }
                      },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateModuleAssignments(String userId, List<String> moduleIds) async {
    try {
      final cooperativeId = AppConfig.current.id;
      // Replace all assignments: delete then insert
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
        AppSnackBar.show(context,
            message: 'Módulos actualizados', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context,
          message: 'Error al actualizar módulos: ${e.toString().replaceFirst('Exception: ', '')}',
          type: SnackBarType.error);
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      final response = await _supabase.functions.invoke(
        'update-user-role',
        body: {
          'userId': userId,
          'newRole': newRole,
          'cooperativeId': AppConfig.current.id,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      if (data?['error'] != null) throw Exception(data!['error']);

      if (mounted) {
        setState(() {
          final idx = _users.indexWhere((u) => u['user_id'] == userId);
          if (idx != -1) _users[idx] = {..._users[idx], 'role': newRole};
        });
        AppSnackBar.show(context,
            message: 'Rol actualizado exitosamente', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context,
          message: e.toString().replaceFirst('Exception: ', ''),
          type: SnackBarType.error);
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
                // Users list
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

                // Create user form
                AppCard(
                  padding: context.responsivePadding,
                  child: Form(
                    key: _formKey,
                    child: FormGroup(
                      children: [
                        const AppTitle(title: 'Crear nuevo usuario'),
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
                                    });
                                  }
                                },
                        ),
                        if (_selectedCreateRole == 'admin_modulo') ...[
                          if (_isLoadingModules)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            Text('Módulos asignados', style: AppTextStyles.fieldLabel),
                            const SizedBox(height: 6),
                            ..._modules.map((m) => CheckboxListTile(
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
                        AppButton(
                          text: 'CREAR USUARIO',
                          onPressed: _createUser,
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
              tooltip: 'Cambiar rol',
              onPressed: onEdit,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
