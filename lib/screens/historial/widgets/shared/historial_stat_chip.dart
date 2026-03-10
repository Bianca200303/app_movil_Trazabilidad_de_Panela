import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

/// Chip de estadística: muestra un valor numérico grande con una etiqueta debajo.
/// Usado en el resumen de items de inspección de ambientes.
class HistorialStatChip extends StatelessWidget {
  const HistorialStatChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
