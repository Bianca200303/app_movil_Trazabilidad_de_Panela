import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/supabase_paging.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Productores activos por módulo (para ubicarse entre muchos módulos).
  Map<String, int> _producerCounts = {};

  final _searchController = TextEditingController();

  /// A partir de cuántos módulos se muestra el buscador.
  static const _searchThreshold = 6;

  /// La lista se dibuja por tandas: con cientos de módulos, construir todas
  /// las filas de una vez hacía lenta la pantalla.
  static const _pageSize = 40;
  int _shown = _pageSize;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _shown = _pageSize));
    _loadModules();
    _loadProducerCounts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducerCounts() async {
    try {
      final rows = await fetchAllRows(() => Supabase.instance.client
          .from('producers')
          .select('id, coop_module_id')
          .eq('cooperative_id', AppConfig.current.id)
          .eq('is_active', true)
          .order('id'));
      final counts = <String, int>{};
      for (final row in rows) {
        final id = row['coop_module_id'] as String?;
        if (id != null) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (mounted) setState(() => _producerCounts = counts);
    } catch (_) {
      // Sin conexión: la lista se muestra igual, sin los conteos.
    }
  }

  List<CoopModule> get _visibleModules {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _modules;
    return _modules.where((m) => m.name.toLowerCase().contains(query)).toList();
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

  Widget _buildModulesList() {
    final visible = _visibleModules;
    final countsLoaded = _producerCounts.isNotEmpty;
    return FormGroup(
      children: [
        Column(
          children: [
            const AppTitle(title: 'Módulos existentes'),
            if (!_isLoading && _modules.isNotEmpty)
              Text(
                _modules.length == 1 ? '1 módulo' : '${_modules.length} módulos',
                style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
              ),
          ],
        ),
        if (_modules.length >= _searchThreshold)
          AppTextField(
            controller: _searchController,
            hintText: 'Buscar módulo',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Limpiar búsqueda',
                    onPressed: _searchController.clear,
                  ),
          ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_modules.isEmpty)
          Text('No hay módulos registrados.', style: AppTextStyles.bodyText)
        else if (visible.isEmpty)
          Text('Ningún módulo coincide con la búsqueda.', style: AppTextStyles.bodyText)
        else ...[
          AppEntityList(
            children: [
              for (final module in visible.take(_shown))
                _ModuleTile(
                  module: module,
                  producerCount: countsLoaded ? (_producerCounts[module.id] ?? 0) : null,
                  onEdit: () => _showEditDialog(module),
                ),
            ],
          ),
          if (visible.length > _shown)
            AppButton(
              text: 'Mostrar más (${visible.length - _shown} restantes)',
              type: AppButtonType.secondary,
              onPressed: () => setState(() => _shown += _pageSize),
            ),
        ],
      ],
    );
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
                          text: 'Crear módulo',
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
                  child: _buildModulesList(),
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
  final int? producerCount;
  final VoidCallback onEdit;

  const _ModuleTile({required this.module, required this.producerCount, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return AppEntityTile(
      title: module.name,
      icon: Icons.view_module_outlined,
      accent: AppColors.primary,
      subtitle: switch (producerCount) {
        null => null,
        0 => 'Sin productores',
        1 => '1 productor',
        final n => '$n productores',
      },
      onTap: onEdit,
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        color: AppColors.primary,
        tooltip: 'Editar',
        visualDensity: VisualDensity.compact,
        onPressed: onEdit,
      ),
    );
  }
}
