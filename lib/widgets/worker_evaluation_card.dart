import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/widgets/forms/yes_no_field.dart';

/// Componente que representa un trabajador añadido.
/// Utiliza un ExpansionTile para permitir la edición in situ.
class WorkerEvaluationCard extends StatelessWidget {
  const WorkerEvaluationCard({
    super.key,
    required this.worker,
    required this.onUpdate,
    required this.onDelete,
  });

  final WorkerEvaluation worker;
  final ValueChanged<WorkerEvaluation> onUpdate;
  final VoidCallback onDelete;

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
        subtitle: const Text(
          'Toca para ver o editar detalles',
          style: TextStyle(color: Colors.black87, fontSize: 12),
        ),
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
          YesNoField(label: 'Uso de uniforme completo',    value: worker.uniformComplete,  onChanged: (v) => onUpdate(worker.copyWith(uniformComplete: v))),
          YesNoField(label: 'Rostro sin maquillaje',       value: worker.noMakeup,         onChanged: (v) => onUpdate(worker.copyWith(noMakeup: v))),
          YesNoField(label: 'Uñas cortas limpias',         value: worker.nailsShortClean,  onChanged: (v) => onUpdate(worker.copyWith(nailsShortClean: v))),
          YesNoField(label: 'Uñas no esmaltadas',          value: worker.nailsNoPolish,    onChanged: (v) => onUpdate(worker.copyWith(nailsNoPolish: v))),
          YesNoField(label: 'Manos limpias',               value: worker.handsClean,       onChanged: (v) => onUpdate(worker.copyWith(handsClean: v))),
          YesNoField(label: 'Sin joyas ni perfume',        value: worker.noJewelry,        onChanged: (v) => onUpdate(worker.copyWith(noJewelry: v))),
          YesNoField(label: 'Cabello corto o recogido',    value: worker.hairCovered,      onChanged: (v) => onUpdate(worker.copyWith(hairCovered: v))),
          YesNoField(label: 'Sin barba',                   value: worker.noBeard,          onChanged: (v) => onUpdate(worker.copyWith(noBeard: v))),
          YesNoField(label: 'Ausencia de heridas y cortes',value: worker.noWounds,         onChanged: (v) => onUpdate(worker.copyWith(noWounds: v))),
        ],
      ),
    );
  }
}
