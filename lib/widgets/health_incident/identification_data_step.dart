import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/widgets/widgets.dart';


class IdentificationDataStep extends StatelessWidget {
  final List<CoopModule> availableModules;
  final String? selectedModuleId;
  final TextEditingController employeeNameController;
  final TextEditingController workAreaController;
  final DateTime? registrationDate;
  final VoidCallback onDateTap;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final ValueChanged<String?> onModuleChanged;

  const IdentificationDataStep({
    super.key,
    required this.availableModules,
    required this.selectedModuleId,
    required this.employeeNameController,
    required this.workAreaController,
    required this.registrationDate,
    required this.onDateTap,
    required this.onNext,
    required this.onBack,
    required this.onModuleChanged,
  });

  bool _validate() {
    return selectedModuleId != null &&
        selectedModuleId!.isNotEmpty &&
        employeeNameController.text.trim().isNotEmpty &&
        workAreaController.text.trim().isNotEmpty &&
        registrationDate != null;
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
          title: 'Paso 1: Datos de Identificación',
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        FormSection(
          children: [
            ModuleSearchField(
              label: 'Módulo',
              modules: availableModules,
              selectedModuleId: selectedModuleId,
              onChanged: onModuleChanged,
            ),
            SizedBox(height: context.responsiveSpacing),
            AppTextField(
              label: 'Nombre del personal',
              controller: employeeNameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre del personal';
                }
                return null;
              },
              hintText: 'Ej: Juan Pérez',
            ),
            SizedBox(height: context.responsiveSpacing),
            AppTextField(
              label: 'Área de trabajo',
              controller: workAreaController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el área de trabajo';
                }
                return null;
              },
              hintText: 'Ej: Área de producción',
            ),
            SizedBox(height: context.responsiveSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha de registro', style: AppTextStyles.fieldLabel),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onDateTap,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMedium,
                      vertical: AppDimensions.paddingMedium,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            registrationDate != null
                                ? AppDateUtils.formatDDMMYYYY(registrationDate!)
                                : 'Selecciona una fecha',
                            style: AppTextStyles.bodyText.copyWith(
                              color: registrationDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: context.responsiveSpacing * 2),
        AppButton(
          onPressed: () {
            // Validar y mostrar mensaje específico de qué falta
            final List<String> missingFields = [];

            if (selectedModuleId == null || selectedModuleId!.isEmpty) {
              missingFields.add('Módulo');
            }
            if (employeeNameController.text.trim().isEmpty) {
              missingFields.add('Nombre del personal');
            }
            if (workAreaController.text.trim().isEmpty) {
              missingFields.add('Área de trabajo');
            }
            if (registrationDate == null) {
              missingFields.add('Fecha de registro');
            }

            if (missingFields.isNotEmpty) {
              final String message = missingFields.length == 1
                  ? 'Falta completar: ${missingFields[0]}'
                  : 'Faltan completar: ${missingFields.join(', ')}';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
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
