import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';

/// Selector de módulo con búsqueda por escritura.
/// Reemplazo de [AppDropdown] para usuarios a cargo de muchos módulos,
/// donde desplazarse uno por uno en una lista larga es incómodo.
class ModuleSearchField extends StatefulWidget {
  const ModuleSearchField({
    super.key,
    required this.modules,
    required this.selectedModuleId,
    required this.onChanged,
    this.label,
    this.hintText = 'Buscar módulo...',
    this.enabled = true,
    this.isLoading = false,
  });

  final List<CoopModule> modules;
  final String? selectedModuleId;
  final ValueChanged<String?> onChanged;
  final String? label;
  final String hintText;
  final bool enabled;
  final bool isLoading;

  @override
  State<ModuleSearchField> createState() => _ModuleSearchFieldState();
}

class _ModuleSearchFieldState extends State<ModuleSearchField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _nameFor(widget.selectedModuleId));
  }

  @override
  void didUpdateWidget(ModuleSearchField old) {
    super.didUpdateWidget(old);
    final resolvedName = _nameFor(widget.selectedModuleId);
    if (resolvedName.isNotEmpty && _controller.text != resolvedName) {
      _controller.text = resolvedName;
    }
  }

  String _nameFor(String? moduleId) {
    if (moduleId == null) return '';
    for (final module in widget.modules) {
      if (module.id == moduleId) return module.name;
    }
    return '';
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.fieldLabel),
          const SizedBox(height: AppDimensions.spacingSmall),
        ],
        if (widget.isLoading)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          RawAutocomplete<CoopModule>(
            textEditingController: _controller,
            focusNode: _focusNode,
            displayStringForOption: (module) => module.name,
            optionsBuilder: (textValue) {
              final query = textValue.text.toLowerCase().trim();
              if (query.isEmpty) return widget.modules;
              return widget.modules
                  .where((module) => module.name.toLowerCase().contains(query))
                  .toList();
            },
            onSelected: (module) => widget.onChanged(module.id),
            fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
              return AppTextField(
                label: null,
                hintText: widget.hintText,
                controller: controller,
                focusNode: focusNode,
                enabled: widget.enabled,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              );
            },
            optionsViewBuilder: (ctx, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: options.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(AppDimensions.paddingMedium),
                            child: Text('Sin coincidencias'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final module = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                title: Text(module.name, style: AppTextStyles.bodyText),
                                onTap: () => onSelected(module),
                              );
                            },
                          ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
