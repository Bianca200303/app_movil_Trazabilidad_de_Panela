import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/widgets/widgets.dart';

class ModuleManagementScreen extends StatefulWidget {
  const ModuleManagementScreen({super.key});

  @override
  State<ModuleManagementScreen> createState() => _ModuleManagementScreenState();
}

class _ModuleManagementScreenState extends State<ModuleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CoopModulesService _service = CoopModulesService();

  bool _isLoading = false;
  bool _isSaving = false;
  List<CoopModule> _modules = [];
  int _nameFieldKey = 0;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoading = true);
    try {
      final modules = await _service.fetchFromSupabase();
      if (mounted) setState(() => _modules = modules);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al cargar módulos: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditDialog(CoopModule module) async {
    final editController = TextEditingController(text: module.name);
    final editFormKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar módulo'),
        content: Form(
          key: editFormKey,
          child: TextFormField(
            controller: editController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre del módulo'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese el nombre del módulo';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (!editFormKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              try {
                final updated = await _service.updateModule(
                  id: module.id,
                  name: editController.text,
                );
                if (mounted) {
                  setState(() {
                    final idx = _modules.indexWhere((m) => m.id == module.id);
                    if (idx != -1) {
                      _modules = List.from(_modules)..[idx] = updated;
                      _modules.sort((a, b) => a.name.compareTo(b.name));
                    }
                  });
                  AppSnackBar.show(
                    context,
                    message: 'Módulo actualizado exitosamente',
                    type: SnackBarType.success,
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppSnackBar.show(
                    context,
                    message: e.toString().replaceFirst('Exception: ', ''),
                    type: SnackBarType.error,
                  );
                }
              } finally {
                editController.dispose();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createModule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final module = await _service.createModule(name: _nameController.text);
      if (mounted) {
        FocusScope.of(context).unfocus();
        _nameController.clear();
        setState(() {
          _modules = [..._modules, module]..sort((a, b) => a.name.compareTo(b.name));
          _nameFieldKey++;
        });
        AppSnackBar.show(
          context,
          message: 'Módulo "${module.name}" creado exitosamente',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        AppSnackBar.show(
          context,
          message: msg,
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Gestión de módulos',
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
                // Form to create new module
                AppCard(
                  padding: context.responsivePadding,
                  child: Form(
                    key: _formKey,
                    child: FormGroup(
                      children: [
                        const AppTitle(title: 'Nuevo módulo'),
                        AppTextField(
                          key: ValueKey('module-name-$_nameFieldKey'),
                          label: 'Nombre del módulo',
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingrese el nombre del módulo';
                            }
                            return null;
                          },
                          enabled: !_isSaving,
                        ),
                        AppButton(
                          text: 'CREAR MÓDULO',
                          onPressed: _createModule,
                          isLoading: _isSaving,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: context.responsiveSpacing),

                // Existing modules list
                AppCard(
                  padding: context.responsivePadding,
                  child: FormGroup(
                    children: [
                      const AppTitle(title: 'Módulos existentes'),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_modules.isEmpty)
                        const Text('No hay módulos registrados.')
                      else
                        ..._modules.map((module) => _ModuleTile(
                              module: module,
                              onEdit: () => _showEditDialog(module),
                            )),
                    ],
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

class _ModuleTile extends StatelessWidget {
  final CoopModule module;
  final VoidCallback onEdit;

  const _ModuleTile({required this.module, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(module.name, style: AppTextStyles.bodyText),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.primary,
            tooltip: 'Editar',
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
