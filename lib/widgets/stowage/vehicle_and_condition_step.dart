import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/binary_enum_switch.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/stowage_transport_inspection.dart';

class VehicleAndConditionStep extends StatelessWidget {
  final TextEditingController vehicleBrandController;
  final TextEditingController vehiclePlateController;
  final VehicleCondition vehicleCondition;
  final ValueChanged<VehicleCondition> onConditionChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const VehicleAndConditionStep({
    super.key,
    required this.vehicleBrandController,
    required this.vehiclePlateController,
    required this.vehicleCondition,
    required this.onConditionChanged,
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

        const AppTitle(title: 'DATOS DEL VEHÍCULO'),

        FormSection(
          subtitle: 'Ingresa la información del vehículo',
          children: [
            SizedBox(height: context.responsiveSpacing),

            AppTextField(
              label: 'Marca del vehículo',
              controller: vehicleBrandController,
              maxLength: 20,
            ),

            SizedBox(height: context.responsiveSpacing),

            AppTextField(
              label: 'Placa del vehículo',
              controller: vehiclePlateController,
            ),
          ],
        ),

        FormSection(
          title: 'Estado de conservación',
          subtitle: 'Evalúa el estado general del vehículo',
          children: [
            SizedBox(height: context.responsiveSpacing),

            BinaryEnumSwitch<VehicleCondition>(
              groupName: 'vehicle_condition',
              options: [
                BinaryOption(
                  value: VehicleCondition.adequate,
                  label: VehicleCondition.adequate.displayName,
                  isDefault: true,
                ),
                BinaryOption(
                  value: VehicleCondition.deficient,
                  label: VehicleCondition.deficient.displayName,
                  isDefault: false,
                ),
              ],
              selectedValue: vehicleCondition,
              onChanged: onConditionChanged,
              label: 'Estado de conservación',
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
