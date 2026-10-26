import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart' show appInputContentPadding;

/// Campo de búsqueda reutilizable con ícono de lupa y botón de limpiar.
/// Muestra el botón X automáticamente cuando hay texto.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.bodyText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.hintText,
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textPrimary,
              size: AppDimensions.iconMedium,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: AppDimensions.iconSmall,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.inputFill,
            contentPadding: appInputContentPadding(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.inputBorder,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(
                color: AppColors.inputBorderFocused,
                width: AppDimensions.inputFocusedBorderWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}
