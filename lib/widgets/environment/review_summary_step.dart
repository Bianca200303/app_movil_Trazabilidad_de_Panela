import 'package:flutter/material.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/environment/area_checklist_step.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class ReviewSummaryStep extends StatelessWidget {
  final String moduleName;
  final String inspectionDate;
  final Map<String, Map<String, ItemChecklistData>> checklistData;
  final bool isSaving;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const ReviewSummaryStep({
    super.key,
    required this.moduleName,
    required this.inspectionDate,
    required this.checklistData,
    required this.isSaving,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    int totalItems = 0;
    int compliantItems = 0;
    int nonCompliantItems = 0;

    for (final areaData in checklistData.values) {
      for (final item in areaData.values) {
        totalItems++;
        if (item.condition == InspectionCondition.compliant) {
          compliantItems++;
        } else {
          nonCompliantItems++;
        }
      }
    }

    final compliancePercentage =
        totalItems > 0 ? (compliantItems / totalItems) * 100 : 0.0;
    final isFullyCompliant = nonCompliantItems == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBackButton(onPressed: isSaving ? () {} : onBack),
        SizedBox(height: context.responsiveSpacing),
        const AppTitle(title: 'Resumen de la inspección'),
        SizedBox(height: context.responsiveSpacing),

        // Basic info section
        FormSection(
          title: 'Información básica',
          children: [
            _buildInfoRow('Módulo:', moduleName),
            const SizedBox(height: 8),
            _buildInfoRow('Fecha:', inspectionDate),
          ],
        ),

        // Compliance summary
        FormSection(
          title: 'Resumen de cumplimiento',
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isFullyCompliant
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFullyCompliant
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isFullyCompliant
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        color: isFullyCompliant
                            ? AppColors.success
                            : Colors.orange.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${compliancePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isFullyCompliant
                              ? AppColors.success
                              : Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isFullyCompliant
                        ? 'Totalmente conforme'
                        : 'Requiere acciones correctivas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isFullyCompliant
                          ? AppColors.success
                          : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'Total',
                        totalItems.toString(),
                        AppColors.textPrimary,
                      ),
                      _buildStatColumn(
                        'Conformes',
                        compliantItems.toString(),
                        AppColors.success,
                      ),
                      _buildStatColumn(
                        'No conformes',
                        nonCompliantItems.toString(),
                        AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Area-by-area breakdown
        FormSection(
          title: 'Detalle por área',
          children: EnvironmentInspectionAreas.all.map((areaCode) {
            final areaData = checklistData[areaCode]!;
            final areaItems = areaData.values.toList();
            final areaCompliant = areaItems
                .where((item) => item.condition == InspectionCondition.compliant)
                .length;
            final areaNonCompliant = areaItems.length - areaCompliant;
            final isAreaCompliant = areaNonCompliant == 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAreaCompliant ? Icons.check_circle : Icons.cancel,
                      color: isAreaCompliant
                          ? AppColors.success
                          : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            EnvironmentInspectionAreas.getDisplayName(areaCode),
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$areaCompliant/${ areaItems.length} conformes',
                            style: AppTextStyles.bodyTextSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // Warning if not fully compliant
        if (!isFullyCompliant)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta inspección tiene $nonCompliantItems ítems no conformes. '
                    'Asegúrate de haber agregado las acciones correctivas necesarias.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: context.responsiveSpacing),

        // Submit button
        AppButton(
          text: isSaving ? 'GUARDANDO...' : 'GUARDAR INSPECCIÓN',
          type: AppButtonType.primary,
          onPressed: isSaving ? () {} : onSubmit,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.fieldLabel,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
