import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:intl/intl.dart';

class FollowupStep extends StatelessWidget {
  final TextEditingController returnDateController;
  final bool certificatePresented;
  final ValueChanged<bool> onCertificatePresentedChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FollowupStep({
    super.key,
    required this.returnDateController,
    required this.certificatePresented,
    required this.onCertificatePresentedChanged,
    required this.onNext,
    required this.onBack,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: returnDateController.text.isEmpty
          ? DateTime.now()
          : DateFormat('dd/MM/yyyy').parse(returnDateController.text),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      returnDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
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
          title: 'Paso 4: Seguimiento',
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        FormSection(
          subtitle:
              'Información de seguimiento (todos los campos son opcionales)',
          children: [
            AppTextField(
              label: 'Fecha de reingreso',
              controller: returnDateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              hintText: 'DD/MM/AAAA (Opcional)',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (returnDateController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        returnDateController.clear();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
            SizedBox(height: context.responsiveSpacing),
            SwitchListTile(
              title: const Text('¿Se presentó certificado médico de alta?'),
              subtitle: const Text(
                  'Indica si el empleado presentó un certificado médico'),
              value: certificatePresented,
              onChanged: onCertificatePresentedChanged,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        SizedBox(height: context.responsiveSpacing * 2),
        AppButton(
          onPressed: onNext,
          text: 'Continuar al resumen',
        ),
      ],
    );
  }
}
