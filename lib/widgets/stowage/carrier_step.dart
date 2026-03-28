import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/core/screen_utils.dart';

class CarrierStep extends StatelessWidget {
  final TextEditingController carrierNameController;
  final TextEditingController carrierRucController;
  final TextEditingController carrierLicenseController;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const CarrierStep({
    super.key,
    required this.carrierNameController,
    required this.carrierRucController,
    required this.carrierLicenseController,
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

        const AppTitle(title: 'DATOS DEL TRANSPORTISTA'),

        FormSection(
          subtitle: 'Ingresa la información del transportista',
          children: [
            SizedBox(height: context.responsiveSpacing),

            AppTextField(
              label: 'Nombre del transportista',
              controller: carrierNameController,
            ),

            SizedBox(height: context.responsiveSpacing),

            AppTextField(
              label: 'RUC',
              controller: carrierRucController,
              keyboardType: TextInputType.number,
              maxLength: 11,
            ),

            SizedBox(height: context.responsiveSpacing),

            AppTextField(
              label: 'Licencia de conducir',
              controller: carrierLicenseController,
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
