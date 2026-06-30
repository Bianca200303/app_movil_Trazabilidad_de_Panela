import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';

/// Selector con búsqueda por escritura, visualmente idéntico a [ModuleSearchField].
/// Acepta cualquier tipo [T] mediante [labelFor].
class SearchableDropdownField<T extends Object> extends StatefulWidget {
  const SearchableDropdownField({
    super.key,
    required this.items,
    required this.labelFor,
    required this.onChanged,
    this.selectedValue,
    this.label,
    this.hintText = 'Buscar...',
    this.enabled = true,
    this.isLoading = false,
  });

  final List<T> items;
  final String Function(T) labelFor;
  final ValueChanged<T?> onChanged;
  final T? selectedValue;
  final String? label;
  final String hintText;
  final bool enabled;
  final bool isLoading;

  @override
  State<SearchableDropdownField<T>> createState() =>
      _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T extends Object>
    extends State<SearchableDropdownField<T>> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _labelFor(widget.selectedValue));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SearchableDropdownField<T> old) {
    super.didUpdateWidget(old);
    final label = _labelFor(widget.selectedValue);
    if (_controller.text != label) _controller.text = label;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _labelFor(T? value) => value == null ? '' : widget.labelFor(value);

  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    // Al perder foco: restaurar el texto al valor seleccionado actual.
    final expected = _labelFor(widget.selectedValue);
    if (_controller.text != expected) _controller.text = expected;
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          RawAutocomplete<T>(
            textEditingController: _controller,
            focusNode: _focusNode,
            displayStringForOption: widget.labelFor,
            optionsBuilder: (textValue) {
              final query = textValue.text.toLowerCase().trim();
              if (query.isEmpty) return widget.items;
              return widget.items
                  .where((item) =>
                      widget.labelFor(item).toLowerCase().contains(query))
                  .toList();
            },
            onSelected: widget.onChanged,
            fieldViewBuilder: (ctx, controller, focusNode, _) => AppTextField(
              label: null,
              hintText: widget.hintText,
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            ),
            optionsViewBuilder: (ctx, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: options.isEmpty
                      ? const Padding(
                          padding:
                              EdgeInsets.all(AppDimensions.paddingMedium),
                          child: Text('Sin coincidencias'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final item = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(widget.labelFor(item),
                                  style: AppTextStyles.bodyText),
                              onTap: () => onSelected(item),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
