import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? action,
    String? actionLabel,
  }) {
    final config = _getConfig(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              config.icon,
              color: config.iconColor,
              size: AppDimensions.iconSmall,
            ),
            const SizedBox(width: AppDimensions.spacingSmall),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyText.copyWith(
                  color: config.textColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: BorderSide(
            color: config.borderColor,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
        duration: duration,
        action: action != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: config.actionColor,
                onPressed: action,
              )
            : null,
      ),
    );
  }

  static _SnackBarConfig _getConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          backgroundColor: AppColors.successLight,
          borderColor: AppColors.success,
          textColor: AppColors.success,
          iconColor: AppColors.success,
          actionColor: AppColors.success,
          icon: Icons.check_circle_outline,
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          backgroundColor: AppColors.errorLight,
          borderColor: AppColors.error,
          textColor: AppColors.error,
          iconColor: AppColors.error,
          actionColor: AppColors.error,
          icon: Icons.error_outline,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          backgroundColor: AppColors.warningLight,
          borderColor: AppColors.warning,
          textColor: AppColors.warning,
          iconColor: AppColors.warning,
          actionColor: AppColors.warning,
          icon: Icons.warning_amber_outlined,
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          backgroundColor: AppColors.infoLight,
          borderColor: AppColors.info,
          textColor: AppColors.info,
          iconColor: AppColors.info,
          actionColor: AppColors.info,
          icon: Icons.info_outline,
        );
    }
  }
}

class _SnackBarConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;
  final Color actionColor;
  final IconData icon;

  _SnackBarConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
    required this.actionColor,
    required this.icon,
  });
}