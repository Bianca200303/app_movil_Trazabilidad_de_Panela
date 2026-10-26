import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/widgets.dart';

class IncidentDescriptionStep extends StatelessWidget {
  final TextEditingController symptomsController;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const IncidentDescriptionStep({
    super.key,
    required this.symptomsController,
    required this.onNext,
    required this.onBack,
  });

  bool _validate() {
    return symptomsController.text.trim().isNotEmpty;
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
          title: 'Paso 2: Descripción del Incidente',
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        FormSection(
          subtitle:
              'Describe los síntomas o lesiones que presenta el personal afectado',
          children: [
            AppTextField(
              label: '¿Cuáles son los síntomas o lesiones que presentan?',
              controller: symptomsController,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Describe los síntomas o lesiones';
                }
                return null;
              },
              hintText:
                  'Ej: Dolor de cabeza, mareos, corte en la mano izquierda...',
            ),
          ],
        ),
        SizedBox(height: context.responsiveSpacing * 2),
        AppButton(
          onPressed: () {
            if (!_validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Falta completar: Descripción de síntomas'),
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
