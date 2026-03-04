import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/radio_group.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/stowage_transport_inspection.dart';

class BagConditionsStep extends StatelessWidget {
  final SackCondition sackCleanCondition;
  final SackCondition sackTiedCondition;
  final ValueChanged<SackCondition> onSackCleanConditionChanged;
  final ValueChanged<SackCondition> onSackTiedConditionChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const BagConditionsStep({
    super.key,
    required this.sackCleanCondition,
    required this.sackTiedCondition,
    required this.onSackCleanConditionChanged,
    required this.onSackTiedConditionChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return FormGroup(
      spacing: context.responsiveSpacing,
      children: [
        // Back button
        AppBackButton(
          onPressed: onBack,
          isExpanded: false,
        ),

        const AppTitle(title: 'CONDICIONES DE LOS SACOS'),

        FormSection(
          subtitle: 'Evalúa el estado de las Sacos de panela',
          children: [
            SizedBox(height: context.responsiveSpacing),

            AppRadioGroup<SackCondition>(
              label: 'Limpio y en buenas condiciones',
              options: SackCondition.values.map((condition) {
                return RadioOption(
                  value: condition,
                  label: condition.displayName,
                );
              }).toList(),
              groupValue: sackCleanCondition,
              onChanged: (value) {
                if (value != null) {
                  onSackCleanConditionChanged(value);
                }
              },
            ),

            SizedBox(height: context.responsiveSpacing),

            AppRadioGroup<SackCondition>(
              label: 'Amarrado/Cocido',
              options: SackCondition.values.map((condition) {
                return RadioOption(
                  value: condition,
                  label: condition.displayName,
                );
              }).toList(),
              groupValue: sackTiedCondition,
              onChanged: (value) {
                if (value != null) {
                  onSackTiedConditionChanged(value);
                }
              },
            ),
          ],
        ),

        // Continue button
        SizedBox(height: context.responsiveSpacing),
        AppButton(
          text: 'CONTINUAR',
          type: AppButtonType.primary,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
