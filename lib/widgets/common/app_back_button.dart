import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.label = 'Regresar',
    this.isExpanded = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final actualBackgroundColor = backgroundColor ?? Colors.white;
    final actualForegroundColor = foregroundColor ?? AppColors.primary;
    final borderColor = backgroundColor ?? AppColors.primary;

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: actualBackgroundColor,
          foregroundColor: actualForegroundColor,
          elevation: 2,
          side: BorderSide(
            color: borderColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingButton,
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeight),
        ),
        icon: Icon(
          Icons.arrow_back,
          size: AppDimensions.iconMedium,
        ),
        label: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(
            color: actualForegroundColor,
          ),
        ),
      ),
    );
  }
}
