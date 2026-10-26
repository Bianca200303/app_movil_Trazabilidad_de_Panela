import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/widgets.dart';

class ActionsTakenStep extends StatelessWidget {
  final bool actionRest;
  final bool actionMedicalAttention;
  final bool actionRelocation;
  final bool actionMedication;
  final bool actionOther;
  final TextEditingController otherActionController;
  final ValueChanged<bool?> onActionRestChanged;
  final ValueChanged<bool?> onActionMedicalAttentionChanged;
  final ValueChanged<bool?> onActionRelocationChanged;
  final ValueChanged<bool?> onActionMedicationChanged;
  final ValueChanged<bool?> onActionOtherChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ActionsTakenStep({
    super.key,
    required this.actionRest,
    required this.actionMedicalAttention,
    required this.actionRelocation,
    required this.actionMedication,
    required this.actionOther,
    required this.otherActionController,
    required this.onActionRestChanged,
    required this.onActionMedicalAttentionChanged,
    required this.onActionRelocationChanged,
    required this.onActionMedicationChanged,
    required this.onActionOtherChanged,
    required this.onNext,
    required this.onBack,
  });

  bool _validate() {
    // At least one action must be selected
    final hasAction = actionRest ||
        actionMedicalAttention ||
        actionRelocation ||
        actionMedication ||
        actionOther;

    if (!hasAction) return false;

    // If "other" is selected, detail is required
    if (actionOther && otherActionController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBackButton(
          onPressed: onBack,
          isExpanded: false,
        ),
        SizedBox(height: context.responsiveSpacing),
        const AppTitle(
          title: 'Paso 3: Acciones Tomadas',
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        FormSection(
          subtitle: 'Selecciona las acciones que se tomaron (puedes elegir varias)',
          children: [
            CheckboxListTile(
              title: const Text('Descanso'),
              value: actionRest,
              onChanged: onActionRestChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Atención médica'),
              value: actionMedicalAttention,
              onChanged: onActionMedicalAttentionChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Reubicación'),
              value: actionRelocation,
              onChanged: onActionRelocationChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Medicación'),
              value: actionMedication,
              onChanged: onActionMedicationChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Otro'),
              value: actionOther,
              onChanged: onActionOtherChanged,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (actionOther) ...[
              SizedBox(height: context.responsiveSpacing),
              AppTextField(
                label: 'Especifica la otra acción',
                controller: otherActionController,
                validator: (value) {
                  if (actionOther && (value == null || value.trim().isEmpty)) {
                    return 'Especifica qué otra acción se tomó';
                  }
                  return null;
                },
                hintText: 'Ej: Fisioterapia, cambio de turno...',
              ),
            ],
          ],
        ),
        if (!_validate() && (actionRest || actionMedicalAttention || actionRelocation || actionMedication || actionOther))
          Padding(
            padding: EdgeInsets.only(top: context.responsiveSpacing),
            child: const Text(
              'Selecciona al menos una acción. Si eligió "Otro", especifica cuál.',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          )
        else if (!_validate())
          Padding(
            padding: EdgeInsets.only(top: context.responsiveSpacing),
            child: const Text(
              'Selecciona al menos una acción tomada',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        SizedBox(height: context.responsiveSpacing * 2),
        AppButton(
          onPressed: () {
            if (!_validate()) {
              final List<String> missingFields = [];

              final hasAction = actionRest ||
                  actionMedicalAttention ||
                  actionRelocation ||
                  actionMedication ||
                  actionOther;

              if (!hasAction) {
                missingFields.add('Selecciona al menos una acción');
              } else if (actionOther && otherActionController.text.trim().isEmpty) {
                missingFields.add('Especifica qué otra acción se tomó');
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Falta completar: ${missingFields.join(', ')}'),
                  backgroundColor: AppColors.error,
                ),
              );
              return;
            }
            onNext();
          },
          text: 'Continuar',
        ),
      ],
    );
  }
}
