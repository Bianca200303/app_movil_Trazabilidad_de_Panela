import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/stowage/selectable_exit_card.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

class ExitAndDateStep extends StatelessWidget {
  final String? selectedExitId;
  final List<Map<String, dynamic>> availableExits;
  final Set<String> inspectedExitIds;
  final bool isLoadingExits;
  final TextEditingController inspectionDateController;
  final void Function(DateTime start, DateTime end) onRangeChanged;
  final ValueChanged<String?> onExitChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ExitAndDateStep({
    super.key,
    required this.selectedExitId,
    required this.availableExits,
    required this.inspectedExitIds,
    required this.isLoadingExits,
    required this.inspectionDateController,
    required this.onRangeChanged,
    required this.onExitChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return FormGroup(
      spacing: context.responsiveSpacing,
      children: [
        AppBackButton(onPressed: onBack, isExpanded: false),

        FormSection(
          title: 'Buscar salidas',
          children: [
            SizedBox(height: context.responsiveSpacing * 0.5),
            HistorialPeriodFilter(
              initial: HistorialPeriodo.esteMes,
              onChanged: onRangeChanged,
            ),
          ],
        ),

        FormSection(
          title: 'Salidas registradas',
          subtitle: 'Toca la salida que quieres inspeccionar',
          children: [
            SizedBox(height: context.responsiveSpacing),
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
            else if (availableExits.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(context.responsiveSpacing),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: AppColors.textTertiary),
                      SizedBox(height: context.responsiveSpacing),
                      Text(
                        'No hay salidas en este período',
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...availableExits.map((exitData) {
                final exitId = exitData['id'] as String;
                final isSelected = selectedExitId == exitId;
                final alreadyInspected = inspectedExitIds.contains(exitId);
                return SelectableExitCard(
                  exitData: exitData,
                  isSelected: isSelected,
                  alreadyInspected: alreadyInspected,
                  onTap: () => onExitChanged(isSelected ? null : exitId),
                );
              }),
          ],
        ),

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
