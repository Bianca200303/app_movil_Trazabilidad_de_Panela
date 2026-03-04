import 'package:flutter/material.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

/// Componente que representa un trabajador añadido.
/// Utiliza un ExpansionTile para permitir la edicion in situ (Mejora UX 1).
class WorkerEvaluationCard extends StatelessWidget {
  final WorkerEvaluation worker;
  final ValueChanged<WorkerEvaluation> onUpdate;
  final VoidCallback onDelete;

  const WorkerEvaluationCard({
    super.key,
    required this.worker,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          worker.workerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Toca para ver o editar detalles'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Eliminar trabajador',
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text('Modificar cumplimiento:', style: AppTextStyles.bodyText),
          const SizedBox(height: 8),
          _buildEditToggle('Uso de uniforme completo', worker.uniformComplete, (v) => onUpdate(worker.copyWith(uniformComplete: v))),
          _buildEditToggle('Rostro sin maquillaje', worker.noMakeup, (v) => onUpdate(worker.copyWith(noMakeup: v))),
          _buildEditToggle('Uñas cortas limpias', worker.nailsShortClean, (v) => onUpdate(worker.copyWith(nailsShortClean: v))),
          _buildEditToggle('Uñas no esmaltadas', worker.nailsNoPolish, (v) => onUpdate(worker.copyWith(nailsNoPolish: v))),
          _buildEditToggle('Manos limpias', worker.handsClean, (v) => onUpdate(worker.copyWith(handsClean: v))),
          _buildEditToggle('Sin joyas ni perfume', worker.noJewelry, (v) => onUpdate(worker.copyWith(noJewelry: v))),
          _buildEditToggle('Cabello corto o recogido', worker.hairCovered, (v) => onUpdate(worker.copyWith(hairCovered: v))),
          _buildEditToggle('Sin barba', worker.noBeard, (v) => onUpdate(worker.copyWith(noBeard: v))),
          _buildEditToggle('Ausencia de heridas y cortes', worker.noWounds, (v) => onUpdate(worker.copyWith(noWounds: v))),
        ],
      ),
    );
  }

  Widget _buildEditToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.green.shade700,
    );
  }
}