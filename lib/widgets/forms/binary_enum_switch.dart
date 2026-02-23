import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

/// Generic option for binary enum switch
class BinaryOption<T> {
  final T value;
  final String label;
  final bool isDefault;

  const BinaryOption({
    required this.value,
    required this.label,
    this.isDefault = false,
  });
}

/// A switch widget for selecting between two enum options
/// Similar to BinaryCertificateSwitch but works with any enum type
class BinaryEnumSwitch<T> extends StatelessWidget {
  final String groupName;
  final List<BinaryOption<T>> options;
  final T? selectedValue;
  final Function(T value) onChanged;
  final String? label;

  const BinaryEnumSwitch({
    super.key,
    required this.groupName,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Validate that we have exactly 2 options
    if (options.length != 2) {
      // Fallback to radio buttons if not exactly 2 options
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
          ],
          ...options.map((option) {
            return RadioListTile<T>(
              title: Text(option.label, style: AppTextStyles.bodyText),
              value: option.value,
              groupValue: selectedValue,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );
          }),
        ],
      );
    }

    // Sort options: default first, alternate second
    final sortedOptions = List<BinaryOption<T>>.from(options);
    sortedOptions.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });

    final defaultOption = sortedOptions[0];
    final alternateOption = sortedOptions[1];

    // Check if default option is selected
    final isDefaultSelected = selectedValue == defaultOption.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current state label only
              Expanded(
                child: Text(
                  isDefaultSelected ? defaultOption.label : alternateOption.label,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Switch
              Switch(
                value: isDefaultSelected,
                onChanged: (value) {
                  onChanged(value ? defaultOption.value : alternateOption.value);
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
