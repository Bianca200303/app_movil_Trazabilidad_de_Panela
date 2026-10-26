import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart' show appInputContentPadding;

class DropdownOption<T> {
  final T value;
  final String label;

  DropdownOption({
    required this.value,
    required this.label,
  });
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hintText;
  final T? value;
  final List<DropdownOption<T>> options;
  final void Function(T?)? onChanged;
  final bool enabled;
  final bool isLoading;

  const AppDropdown({
    super.key,
    this.label,
    this.hintText,
    this.value,
    required this.options,
    this.onChanged,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: AppColors.inputBorder,
                width: AppDimensions.inputBorderWidth,
              ),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
          items: options.map((option) {
            return DropdownMenuItem<T>(
              value: option.value,
              child: Text(option.label),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
        ),
      ],
    );
  }
}