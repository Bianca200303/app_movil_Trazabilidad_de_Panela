import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/core/screen_utils.dart';

class ObservationsStep extends StatelessWidget {
  final TextEditingController observationsController;
  final bool isSaving;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const ObservationsStep({
    super.key,
    required this.observationsController,
    required this.isSaving,
    required this.onSubmit,
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

        const AppTitle(title: 'OBSERVACIONES'),

        FormSection(
          subtitle: 'Agrega observaciones adicionales sobre la inspección (opcional)',
          children: [
            SizedBox(height: context.responsiveSpacing),

            AppTextField(
              label: 'Observaciones',
              controller: observationsController,
              maxLines: 4,
              hintText: 'Ingresa observaciones adicionales...',
            ),
          ],
        ),

        // Submit button
        SizedBox(height: context.responsiveSpacing),
        AppButton(
          text: isSaving ? 'GUARDANDO...' : 'ENVIAR INSPECCIÓN',
          type: AppButtonType.primary,
          onPressed: isSaving ? null : onSubmit,
        ),
      ],
    );
  }
}
