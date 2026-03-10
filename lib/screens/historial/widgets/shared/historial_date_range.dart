import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';

/// Mensaje informativo que muestra el rango de fechas de los datos mostrados.
class HistorialDateRangeMessage extends StatelessWidget {
  const HistorialDateRangeMessage({
    required this.startDate,
    required this.endDate,
    super.key,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final startDateStr = AppDateUtils.formatDDMMYYYY(startDate);
    final endDateStr = AppDateUtils.formatDDMMYYYY(endDate);

    return Container(
      padding: EdgeInsets.all(context.responsiveSpacing / 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.inputBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
          SizedBox(width: context.responsiveSpacing / 4),
          Flexible(
            child: Text(
              'Mostrando registros del $startDateStr al $endDateStr',
              style: AppTextStyles.captionText,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
