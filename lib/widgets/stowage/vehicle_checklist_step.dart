import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/yes_no_field.dart';
import 'package:panela_sys/core/screen_utils.dart';

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
        AppBackButton(onPressed: onBack, isExpanded: false),

        const AppTitle(title: 'CHECKLIST DEL VEHÍCULO'),

        FormSection(
          title: 'Equipamiento de seguridad',
          subtitle: 'Indica si el vehículo cuenta con cada elemento',
          children: [
            YesNoField(label: 'Neumático de repuesto',    value: hasSpareTire,       onChanged: onSpareTireChanged),
            YesNoField(label: 'SOAT vigente',             value: hasValidSoat,        onChanged: onValidSoatChanged),
            YesNoField(label: 'Revisión técnica vigente', value: hasTechnicalReview,  onChanged: onTechnicalReviewChanged),
            YesNoField(label: 'Botiquín',                 value: hasFirstAidKit,      onChanged: onFirstAidKitChanged),
            YesNoField(label: 'Extintor',                 value: hasFireExtinguisher, onChanged: onFireExtinguisherChanged),
            YesNoField(label: 'GPS',                      value: hasGps,              onChanged: onGpsChanged),
            YesNoField(label: 'Implementos de limpieza',  value: hasCleaningSupplies, onChanged: onCleaningSuppliesChanged),
          ],
        ),

        FormSection(
          title: 'Condiciones de limpieza',
          subtitle: 'Indica el estado de limpieza del vehículo',
          children: [
            YesNoField(label: 'Pisos limpios',      value: floorsClean,    onChanged: onFloorsCleanChanged),
            YesNoField(label: 'Paredes limpias',    value: wallsClean,     onChanged: onWallsCleanChanged),
            YesNoField(label: 'Techos limpios',     value: ceilingsClean,  onChanged: onCeilingsCleanChanged),
            YesNoField(label: 'Sin olores extraños',value: noStrangeOdors, onChanged: onNoStrangeOdorsChanged),
            YesNoField(label: 'Carpa limpia',       value: tarpClean,      onChanged: onTarpCleanChanged),
            YesNoField(label: 'Parihuelas limpias', value: palletsClean,   onChanged: onPalletsCleanChanged),
          ],
        ),

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
