import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

enum AppButtonType {
  primary,
  secondary,
  @Deprecated('Use AppBackButton widget instead. This will be removed in a future version.')
  back,
  option,
  optionActive,
  exitType,
  destructive,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final Color? customColor;
  final bool isLoading;
  final bool isExpanded;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.customColor,
    this.isLoading = false,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    // En pantallas angostas los botones se compactan (menos relleno) para
    // que el texto no se corte ni obligue a más scroll.
    final compact = ScreenUtils.isSmallScreen(context);
    return SizedBox(
      width: isExpanded ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(compact),
        child: _buildButtonContent(compact),
      ),
    );
  }

  ButtonStyle _getButtonStyle(bool compact) {
    final mainPadding = EdgeInsets.symmetric(
      vertical: compact ? AppDimensions.paddingSmall + AppDimensions.paddingXSmall : AppDimensions.paddingButton,
      horizontal: compact ? AppDimensions.paddingMedium : AppDimensions.paddingLarge,
    );
    final optionPadding = EdgeInsets.symmetric(
      vertical: compact ? AppDimensions.paddingSmall + AppDimensions.paddingXSmall : AppDimensions.paddingMedium,
      horizontal: compact ? AppDimensions.paddingSmall + AppDimensions.paddingXSmall : AppDimensions.paddingMedium,
    );
    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: mainPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeight),
        );
      case AppButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: mainPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: BorderSide(
              color: AppColors.border,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeight),
        );
      case AppButtonType.back:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeightSmall),
        );
      case AppButtonType.option:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: optionPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            side: BorderSide(
              color: AppColors.border,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
        );
      case AppButtonType.optionActive:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: optionPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        );
      case AppButtonType.exitType:
        return ElevatedButton.styleFrom(
          backgroundColor: customColor ?? AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingSmall,
            horizontal: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        );
      case AppButtonType.destructive:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: mainPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          minimumSize: const Size(0, AppDimensions.buttonHeight),
        );
    }
  }

  Widget _buildButtonContent(bool compact) {
    if (isLoading) {
      return const SizedBox(
        height: AppDimensions.iconSmall,
        width: AppDimensions.iconSmall,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? AppDimensions.iconSmall : AppDimensions.iconMedium),
          SizedBox(width: compact ? AppDimensions.spacingSmall : AppDimensions.spacingMedium),
          Flexible(
            child: Text(
              text,
              style: _getTextStyle(),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: _getTextStyle(),
    );
  }

  TextStyle _getTextStyle() {
    switch (type) {
      case AppButtonType.primary:
      case AppButtonType.optionActive:
      case AppButtonType.destructive:
        return AppTextStyles.buttonText;
      case AppButtonType.secondary:
      case AppButtonType.option:
        return AppTextStyles.buttonText.copyWith(color: AppColors.textPrimary);
      case AppButtonType.back:
        return AppTextStyles.buttonText;
      case AppButtonType.exitType:
        return AppTextStyles.buttonText;
    }
  }
}