import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class VehicleChecklistStep extends StatelessWidget {
  final bool hasSpareTire;
  final bool hasValidSoat;
  final bool hasTechnicalReview;
  final bool hasFirstAidKit;
  final bool hasFireExtinguisher;
  final bool hasGps;
  final bool hasCleaningSupplies;
  final bool floorsClean;
  final bool wallsClean;
  final bool ceilingsClean;
  final bool noStrangeOdors;
  final bool tarpClean;
  final bool palletsClean;
  final ValueChanged<bool> onSpareTireChanged;
  final ValueChanged<bool> onValidSoatChanged;
  final ValueChanged<bool> onTechnicalReviewChanged;
  final ValueChanged<bool> onFirstAidKitChanged;
  final ValueChanged<bool> onFireExtinguisherChanged;
  final ValueChanged<bool> onGpsChanged;
  final ValueChanged<bool> onCleaningSuppliesChanged;
  final ValueChanged<bool> onFloorsCleanChanged;
  final ValueChanged<bool> onWallsCleanChanged;
  final ValueChanged<bool> onCeilingsCleanChanged;
  final ValueChanged<bool> onNoStrangeOdorsChanged;
  final ValueChanged<bool> onTarpCleanChanged;
  final ValueChanged<bool> onPalletsCleanChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const VehicleChecklistStep({
    super.key,
    required this.hasSpareTire,
    required this.hasValidSoat,
    required this.hasTechnicalReview,
    required this.hasFirstAidKit,
    required this.hasFireExtinguisher,
    required this.hasGps,
    required this.hasCleaningSupplies,
    required this.floorsClean,
    required this.wallsClean,
    required this.ceilingsClean,
    required this.noStrangeOdors,
    required this.tarpClean,
    required this.palletsClean,
    required this.onSpareTireChanged,
    required this.onValidSoatChanged,
    required this.onTechnicalReviewChanged,
    required this.onFirstAidKitChanged,
    required this.onFireExtinguisherChanged,
    required this.onGpsChanged,
    required this.onCleaningSuppliesChanged,
    required this.onFloorsCleanChanged,
    required this.onWallsCleanChanged,
    required this.onCeilingsCleanChanged,
    required this.onNoStrangeOdorsChanged,
    required this.onTarpCleanChanged,
    required this.onPalletsCleanChanged,
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

        const AppTitle(title: 'CHECKLIST DEL VEHÍCULO'),

        FormSection(
          title: 'Equipamiento de seguridad',
          subtitle: 'Marca los elementos presentes en el vehículo',
          children: [
            SizedBox(height: context.responsiveSpacing * 0.5),

            CheckboxListTile(
              title: Text('Neumático de repuesto', style: AppTextStyles.bodyText),
              value: hasSpareTire,
              onChanged: (value) => onSpareTireChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('SOAT vigente', style: AppTextStyles.bodyText),
              value: hasValidSoat,
              onChanged: (value) => onValidSoatChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Revisión técnica vigente', style: AppTextStyles.bodyText),
              value: hasTechnicalReview,
              onChanged: (value) => onTechnicalReviewChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Botiquín', style: AppTextStyles.bodyText),
              value: hasFirstAidKit,
              onChanged: (value) => onFirstAidKitChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Extintor', style: AppTextStyles.bodyText),
              value: hasFireExtinguisher,
              onChanged: (value) => onFireExtinguisherChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('GPS', style: AppTextStyles.bodyText),
              value: hasGps,
              onChanged: (value) => onGpsChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Implementos de limpieza', style: AppTextStyles.bodyText),
              value: hasCleaningSupplies,
              onChanged: (value) => onCleaningSuppliesChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),

        FormSection(
          title: 'Condiciones de limpieza',
          subtitle: 'Marca las condiciones de limpieza del vehículo',
          children: [
            SizedBox(height: context.responsiveSpacing * 0.5),

            CheckboxListTile(
              title: Text('Pisos limpios', style: AppTextStyles.bodyText),
              value: floorsClean,
              onChanged: (value) => onFloorsCleanChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Paredes limpias', style: AppTextStyles.bodyText),
              value: wallsClean,
              onChanged: (value) => onWallsCleanChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Techos limpios', style: AppTextStyles.bodyText),
              value: ceilingsClean,
              onChanged: (value) => onCeilingsCleanChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Sin olores extraños', style: AppTextStyles.bodyText),
              value: noStrangeOdors,
              onChanged: (value) => onNoStrangeOdorsChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Carpa limpia', style: AppTextStyles.bodyText),
              value: tarpClean,
              onChanged: (value) => onTarpCleanChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),

            CheckboxListTile(
              title: Text('Parihuelas limpias', style: AppTextStyles.bodyText),
              value: palletsClean,
              onChanged: (value) => onPalletsCleanChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
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
