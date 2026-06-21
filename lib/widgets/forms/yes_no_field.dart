import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/font_size_config.dart';

/// Fila de campo con botones SI / NO (o labels personalizados).
/// Úsalo en cualquier formulario que reemplace un CheckboxListTile
/// o switch binario por una elección visual explícita.
class YesNoField extends StatelessWidget {
  const YesNoField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.yesLabel = 'SI',
    this.noLabel = 'NO',
  });

  final String? label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String yesLabel;
  final String noLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Row(
        children: [
          if (label != null) ...[
            Expanded(
              child: Text(
                label!,
                style: AppTextStyles.bodyText,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
          ],
          _YesNoButton(
            label: yesLabel,
            selected: value,
            color: AppColors.success,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: AppDimensions.spacingXSmall),
          _YesNoButton(
            label: noLabel,
            selected: !value,
            color: AppColors.error,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  const _YesNoButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppDimensions.buttonHeightSmall,
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2.0 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: FontSizeConfig.captionSize,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.textWhite : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
