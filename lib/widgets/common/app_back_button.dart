import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/screen_utils.dart';
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
    final actualBackgroundColor = backgroundColor ?? AppColors.surface;
    final actualForegroundColor = foregroundColor ?? AppColors.primary;
    final borderColor = backgroundColor ?? AppColors.primary;
    // En pantallas angostas el botón se compacta para no robar ancho ni alto.
    final compact = ScreenUtils.isSmallScreen(context);

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () => context.pop(),
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
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppDimensions.paddingMedium : AppDimensions.paddingLarge,
            vertical: compact ? AppDimensions.paddingSmall : AppDimensions.paddingButton,
          ),
          minimumSize: Size(0, compact ? AppDimensions.buttonHeightSmall : AppDimensions.buttonHeight),
        ),
        icon: Icon(
          Icons.arrow_back,
          size: compact ? AppDimensions.iconSmall : AppDimensions.iconMedium,
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
