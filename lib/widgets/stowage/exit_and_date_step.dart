import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/stowage/selectable_exit_card.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class ExitAndDateStep extends StatelessWidget {
  final String? selectedExitId;
  final List<Map<String, dynamic>> availableExits;
  final bool isLoadingExits;
  final TextEditingController inspectionDateController;
  final ValueChanged<String?> onExitChanged;
  final VoidCallback onDateTap;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ExitAndDateStep({
    super.key,
    required this.selectedExitId,
    required this.availableExits,
    required this.isLoadingExits,
    required this.inspectionDateController,
    required this.onExitChanged,
    required this.onDateTap,
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

        FormSection(
          subtitle: 'Selecciona primero la fecha de inspección',
          children: [
            SizedBox(height: context.responsiveSpacing),

            // Inspection date picker (prominente)
            AppTextField(
              controller: inspectionDateController,
              label: 'Fecha de inspección',
              readOnly: true,
              onTap: onDateTap,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: onDateTap,
              ),
            ),
          ],
        ),

        FormSection(
          title: 'Salidas registradas',
          subtitle: 'Selecciona la salida a inspeccionar',
          children: [
            SizedBox(height: context.responsiveSpacing),

            // Loading state
            if (isLoadingExits)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando salidas...'),
                  ],
                ),
              )

            // No exits message
            else if (availableExits.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(context.responsiveSpacing),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: context.responsiveSpacing),
                      Text(
                        'No hay salidas registradas para esta fecha',
                        style: AppTextStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )

            // Exit cards
            else
              ...availableExits.map((exitData) {
                final exitId = exitData['id'] as String;
                final isSelected = selectedExitId == exitId;

                return SelectableExitCard(
                  exitData: exitData,
                  isSelected: isSelected,
                  onTap: () {
                    // Toggle selection
                    onExitChanged(isSelected ? null : exitId);
                  },
                );
              }),
          ],
        ),

        // Continue button
        SizedBox(height: context.responsiveSpacing),
        AppButton(
          text: 'CONTINUAR',
          type: AppButtonType.primary,
          onPressed: selectedExitId != null ? onContinue : null,
        ),
      ],
    );
  }
}
