import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class RadioOption<T> {
  final T value;
  final String label;

  RadioOption({required this.value, required this.label});
}

class AppRadioGroup<T> extends StatelessWidget {
  final String? label;
  final List<RadioOption<T>> options;
  final T? groupValue;
  final void Function(T?) onChanged;

  const AppRadioGroup({
    super.key,
    this.label,
    required this.options,
    this.groupValue,
    required this.onChanged,
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
        ...options.map((option) => Row(
          children: [
            Radio<T>(
              value: option.value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            Text(
              option.label,
              style: AppTextStyles.bodyTextLarge,
            ),
          ],
        )),
      ],
    );
  }
}

class AppCheckboxGroup extends StatelessWidget {
  final String? label;
  final List<CheckboxOption> options;

  const AppCheckboxGroup({
    super.key,
    this.label,
    required this.options,
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
          const SizedBox(height: AppDimensions.spacingMedium),
        ],
        ...options.map((option) => CheckboxListTile(
          title: Text(option.label),
          value: option.value,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: option.onChanged,
        )),
      ],
    );
  }
}

class CheckboxOption {
  final String label;
  final bool value;
  final void Function(bool?) onChanged;

  CheckboxOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });
}