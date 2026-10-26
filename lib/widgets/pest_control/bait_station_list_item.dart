import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/widgets/forms/yes_no_field.dart';

/// A list item widget for displaying a single bait station
///
/// Shows:
/// - Station number badge
/// - Ate/Didn't eat toggle
/// - Optional remove button
class BaitStationListItem extends StatelessWidget {
  final int stationNumber;
  final bool ate; // true = ate, false = didn't eat
  final Function(bool) onAteChanged;
  final VoidCallback? onRemove; // null = don't show remove button

  const BaitStationListItem({
    super.key,
    required this.stationNumber,
    required this.ate,
    required this.onAteChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing / 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.inputBorder,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      padding: context.responsivePadding,
      child: Row(
          children: [
            // Station number badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$stationNumber',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(width: context.responsiveSpacing / 2),

            Expanded(
              child: YesNoField(
                label: '¿Comió el cebo?',
                value: ate,
                onChanged: onAteChanged,
              ),
            ),

            // Remove button (only if onRemove is not null)
            if (onRemove != null) ...[
              SizedBox(width: context.responsiveSpacing / 2),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar estación',
                color: AppColors.error,
              ),
            ],
          ],
        ),
    );
  }
}
