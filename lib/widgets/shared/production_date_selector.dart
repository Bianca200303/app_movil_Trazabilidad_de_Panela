import 'package:flutter/material.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

/// Embeddable widget that shows period filter + production date cards.
/// Parent manages state: productionDates, isLoadingDates, selectedDate.
/// blocksAlreadyRecorded: true for forms with UNIQUE(module, date) constraint.
class ProductionDateSelector extends StatelessWidget {
  final List<ProductionDateGroup> productionDates;
  final bool isLoadingDates;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final void Function(DateTime from, DateTime to) onFilterChanged;
  final bool blocksAlreadyRecorded;

  const ProductionDateSelector({
    super.key,
    required this.productionDates,
    required this.isLoadingDates,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onFilterChanged,
    this.blocksAlreadyRecorded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistorialPeriodFilter(
          initial: HistorialPeriodo.esteMes,
          onChanged: onFilterChanged,
        ),
        const SizedBox(height: 16),
        if (isLoadingDates)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (productionDates.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Text(
              'No hay producciones registradas en este período',
              style: AppTextStyles.captionText
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...productionDates.map((group) {
            final isSelected = selectedDate != null &&
                selectedDate!.year == group.date.year &&
                selectedDate!.month == group.date.month &&
                selectedDate!.day == group.date.day;
            final isDisabled = blocksAlreadyRecorded && group.alreadyRecorded;
            return _ProductionDateCard(
              group: group,
              isSelected: isSelected,
              onTap: isDisabled ? null : () => onDateSelected(group.date),
            );
          }),
      ],
    );
  }
}

class _ProductionDateCard extends StatelessWidget {
  final ProductionDateGroup group;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ProductionDateCard({
    required this.group,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing / 2),
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade100
              : isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
            width: isSelected ? 2.0 : AppDimensions.inputBorderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (group.alreadyRecorded) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Ya registrado',
                      style: AppTextStyles.captionText.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsiveSpacing / 2),
            ],
            Row(
              children: [
                Expanded(
                  child: Text('Fecha de producción:', style: AppTextStyles.fieldLabel),
                ),
                Text(AppDateUtils.formatDDMMYYYY(group.date),
                    style: AppTextStyles.bodyText),
              ],
            ),
            SizedBox(height: context.responsiveSpacing / 2),
            Row(
              children: [
                Expanded(
                  child: Text('Lotes:', style: AppTextStyles.fieldLabel),
                ),
                Text(
                  '${group.batchCount} lote${group.batchCount != 1 ? 's' : ''}',
                  style: AppTextStyles.bodyText,
                ),
              ],
            ),
            if (group.totalPanelaKg > 0) ...[
              SizedBox(height: context.responsiveSpacing / 2),
              Row(
                children: [
                  Expanded(
                    child: Text('Total panela:', style: AppTextStyles.fieldLabel),
                  ),
                  Text('${group.totalPanelaKg.toStringAsFixed(1)} kg',
                      style: AppTextStyles.bodyText),
                ],
              ),
            ],
            if (isSelected) ...[
              SizedBox(height: context.responsiveSpacing / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'SELECCIONADO',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
