import 'package:flutter/material.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';

class ModuleAndDateStep extends StatelessWidget {
  final List<CoopModule> availableModules;
  final bool isLoadingModules;
  final String? selectedModuleId;
  final TextEditingController inspectionDateController;
  final Function(String?) onModuleChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ModuleAndDateStep({
    super.key,
    required this.availableModules,
    required this.isLoadingModules,
    required this.selectedModuleId,
    required this.inspectionDateController,
    required this.onModuleChanged,
    required this.onContinue,
    required this.onBack,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: AppDateUtils.parseDDMMYYYY(inspectionDateController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      inspectionDateController.text = AppDateUtils.formatDDMMYYYY(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBackButton(onPressed: onBack),
        SizedBox(height: context.responsiveSpacing),
        const AppTitle(title: 'Datos de la inspección'),
        SizedBox(height: context.responsiveSpacing),
        FormSection(
          title: 'Módulo y fecha',
          subtitle: 'Selecciona el módulo a inspeccionar y la fecha',
          children: [
            if (isLoadingModules)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              AppDropdown<String>(
                label: 'Módulo',
                value: selectedModuleId,
                options: availableModules
                    .map((module) => DropdownOption(
                          value: module.id,
                          label: module.name,
                        ))
                    .toList(),
                onChanged: onModuleChanged,
                hintText: 'Selecciona un módulo',
              ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Fecha de inspección',
              controller: inspectionDateController,
              readOnly: true,
              hintText: 'DD/MM/AAAA',
              onTap: () => _selectDate(context),
            ),
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
