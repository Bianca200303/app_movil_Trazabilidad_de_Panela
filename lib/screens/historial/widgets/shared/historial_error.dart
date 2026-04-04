import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/common/app_button.dart';

/// Widget de error genérico para secciones del historial.
/// Detecta automáticamente errores de red y muestra un mensaje limpio.
class HistorialErrorWidget extends StatelessWidget {
  const HistorialErrorWidget({
    required this.error,
    this.onRetry,
    super.key,
  });

  final String error;
  final VoidCallback? onRetry;

  static bool _isNetworkError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('no address associated') ||
        lower.contains('timeout') ||
        lower.contains('oserror');
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = _isNetworkError(error);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
            size: 48,
            color: isNetwork ? AppColors.textSecondary : AppColors.error,
          ),
          SizedBox(height: context.responsiveSpacing),
          Text(
            isNetwork ? 'Sin conexión' : 'Error al cargar datos',
            style: AppTextStyles.fieldLabel,
          ),
          if (!isNetwork) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            Text(
              error,
              style: AppTextStyles.bodyTextSecondary,
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: context.responsiveSpacing),
            AppButton(text: 'Reintentar', onPressed: onRetry!),
          ],
        ],
      ),
    );
  }
}
