import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';

/// Widget de carga genérico para secciones del historial.
/// Muestra un indicador circular y un mensaje configurable.
class HistorialLoadingWidget extends StatelessWidget {
  const HistorialLoadingWidget({
    this.message = 'Cargando datos...',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: context.responsiveSpacing),
          Text(message, style: AppTextStyles.bodyTextSecondary),
        ],
      ),
    );
  }
}
