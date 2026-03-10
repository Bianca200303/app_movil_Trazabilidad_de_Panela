import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/common/app_button.dart';

/// Widget de error genérico para secciones del historial.
/// Muestra el mensaje de error y un botón de reintentar opcional.
class HistorialErrorWidget extends StatelessWidget {
  const HistorialErrorWidget({
    required this.error,
    this.onRetry,
    super.key,
  });

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          SizedBox(height: context.responsiveSpacing),
          Text('Error al cargar datos', style: AppTextStyles.fieldLabel),
          SizedBox(height: context.responsiveSpacing / 2),
          Text(
            error,
            style: AppTextStyles.bodyTextSecondary,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: context.responsiveSpacing),
            AppButton(text: 'Reintentar', onPressed: onRetry!),
          ],
        ],
      ),
    );
  }
}
