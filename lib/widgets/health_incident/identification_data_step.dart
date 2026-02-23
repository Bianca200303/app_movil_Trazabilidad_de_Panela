import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:intl/intl.dart';

class IdentificationDataStep extends StatelessWidget {
  final List<CoopModule> availableModules;
  final String? selectedModuleId;
  final TextEditingController employeeNameController;
  final TextEditingController workAreaController;
  final TextEditingController registrationDateController;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final ValueChanged<String?> onModuleChanged;

  const IdentificationDataStep({
    super.key,
    required this.availableModules,
    required this.selectedModuleId,
    required this.employeeNameController,
    required this.workAreaController,
    required this.registrationDateController,
    required this.onNext,
    required this.onBack,
    required this.onModuleChanged,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: registrationDateController.text.isEmpty
          ? DateTime.now()
          : DateFormat('dd/MM/yyyy').parse(registrationDateController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      registrationDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  bool _validate() {
    return selectedModuleId != null &&
        selectedModuleId!.isNotEmpty &&
        employeeNameController.text.trim().isNotEmpty &&
        workAreaController.text.trim().isNotEmpty &&
        registrationDateController.text.trim().isNotEmpty;
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
            AppDropdown<String>(
              label: 'Módulo',
              value: selectedModuleId,
              options: availableModules
                  .map((module) => DropdownOption<String>(
                        value: module.id,
                        label: module.name,
                      ))
                  .toList(),
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
            AppTextField(
              label: 'Fecha de registro',
              controller: registrationDateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Selecciona la fecha de registro';
                }
                return null;
              },
              hintText: 'DD/MM/AAAA',
              suffixIcon: const Icon(Icons.calendar_today),
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
            if (registrationDateController.text.trim().isEmpty) {
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
