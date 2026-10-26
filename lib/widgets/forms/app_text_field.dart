import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final int? maxLength;
  final int? maxLines;
  final String? suffixText;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  /// Al presionar Enter / la acción del teclado.
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.onTap,
    this.maxLength,
    this.maxLines = 1,
    this.suffixText,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          maxLength: maxLength,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.inputFill : AppColors.surfaceVariant,
            hintText: hintText,
            helperText: helperText,
            hintStyle: AppTextStyles.hintText.copyWith(
              color: AppColors.placeholder,
            ),
            helperStyle: AppTextStyles.bodyTextSecondary.copyWith(
              color: AppColors.textSecondary,
            ),
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            suffixText: suffixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorder,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorder,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorderFocused,
                width: AppDimensions.inputFocusedBorderWidth,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorderError,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorderError,
                width: AppDimensions.inputFocusedBorderWidth,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.border,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            contentPadding: appInputContentPadding(context),
            errorStyle: AppTextStyles.bodyTextSecondary.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final bool enabled;

  const AppDropdownField({
    super.key,
    this.label,
    this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
        ],
        DropdownButtonFormField<T>(
          value: value,
          hint: hintText != null 
              ? Text(
                  hintText!,
                  style: AppTextStyles.hintText.copyWith(
                    color: AppColors.placeholder,
                  ),
                )
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.inputFill : AppColors.surfaceVariant,
            contentPadding: appInputContentPadding(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorder,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorder,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: BorderSide(
                color: AppColors.inputBorderFocused,
                width: AppDimensions.inputFocusedBorderWidth,
              ),
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
        ),
      ],
    );
  }
}

/// Relleno interior de los campos: más bajo en pantallas angostas para que
/// los formularios largos quepan con menos scroll.
EdgeInsets appInputContentPadding(BuildContext context) => EdgeInsets.symmetric(
      horizontal: ScreenUtils.isSmallScreen(context)
          ? AppDimensions.paddingSmall + AppDimensions.paddingXSmall
          : AppDimensions.paddingMedium,
      vertical: ScreenUtils.isSmallScreen(context)
          ? AppDimensions.paddingSmall + AppDimensions.paddingXSmall
          : AppDimensions.paddingMedium,
    );
