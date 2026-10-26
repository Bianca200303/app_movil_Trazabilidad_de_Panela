import 'package:flutter/material.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/environment/inspection_item_widget.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

// Helper class to hold item data
class ItemChecklistData {
  String itemCode;
  String itemDescription;
  InspectionCondition condition;
  String correctiveActions;
  String observations;

  ItemChecklistData({
    required this.itemCode,
    required this.itemDescription,
    required this.condition,
    this.correctiveActions = '',
    this.observations = '',
  });
}

class AreaChecklistStep extends StatelessWidget {
  final String areaCode;
  final Map<String, ItemChecklistData> itemsData;
  final Function(String itemCode, ItemChecklistData updatedData)
      onItemChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const AreaChecklistStep({
    super.key,
    required this.areaCode,
    required this.itemsData,
    required this.onItemChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final areaDisplayName = EnvironmentInspectionAreas.getDisplayName(areaCode);
    final items = itemsData.values.toList();

    // Count non-compliant items
    final nonCompliantCount = items
        .where((item) => item.condition == InspectionCondition.nonCompliant)
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBackButton(onPressed: onBack),
        SizedBox(height: context.responsiveSpacing),
        AppTitle(title: areaDisplayName),
        SizedBox(height: context.responsiveSpacing),
        FormSection(
          title: 'Evaluación de ítems',
          subtitle:
              'Evalúa cada ítem como Conforme (C) o No Conforme (NC). Agrega acciones correctivas cuando sea NC.',
          children: items.map((item) {
            return InspectionItemWidget(
              key: ValueKey('${areaCode}_${item.itemCode}'),
              itemDescription: item.itemDescription,
              condition: item.condition,
              correctiveActions: item.correctiveActions,
              observations: item.observations,
              personnelNote: EnvironmentInspectionItemTemplates.getPersonnelNote(
                  item.itemCode),
              onConditionChanged: (newCondition) {
                item.condition = newCondition;
                onItemChanged(item.itemCode, item);
              },
              onCorrectiveActionsChanged: (newActions) {
                item.correctiveActions = newActions;
                onItemChanged(item.itemCode, item);
              },
              onObservationsChanged: (newObservations) {
                item.observations = newObservations;
                onItemChanged(item.itemCode, item);
              },
            );
          }).toList(),
        ),

        // Warning message if there are NC items
        if (nonCompliantCount > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warningDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$nonCompliantCount ítems marcados como No Conforme en esta área',
                    style: TextStyle(
                      color: AppColors.warningDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
