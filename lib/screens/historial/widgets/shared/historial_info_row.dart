import 'package:flutter/material.dart';

/// Fila de información etiqueta-valor usada en todas las cards del historial.
/// Muestra [label] en negrita con ancho fijo y [value] expandido a la derecha.
class HistorialInfoRow extends StatelessWidget {
  const HistorialInfoRow({
    required this.label,
    this.value,
    super.key,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
