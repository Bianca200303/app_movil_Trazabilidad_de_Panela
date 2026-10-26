import 'package:flutter/material.dart';

/// Fila de información etiqueta-valor usada en todas las cards del historial.
/// Muestra [label] en negrita y [value] expandido a la derecha.
class HistorialInfoRow extends StatelessWidget {
  const HistorialInfoRow({required this.label, this.value, super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    // Etiqueta proporcional (40% del ancho, máx. 120): con un ancho fijo, en
    // pantallas angostas el valor quedaba aplastado en una columna mínima.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: (constraints.maxWidth * 0.4).clamp(0, 120).toDouble(),
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
      ),
    );
  }
}
