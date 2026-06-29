import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/screen_utils.dart';

/// Card de historial colapsable: [header] siempre visible, [body] solo
/// cuando [isExpanded] es true. Evita que listas largas se vuelvan una
/// pared de texto — el usuario expande solo lo que necesita revisar.
class HistorialExpandableCard extends StatelessWidget {
  const HistorialExpandableCard({
    required this.header,
    required this.body,
    required this.isExpanded,
    required this.onToggle,
    this.backgroundColor,
    super.key,
  });

  final Widget header;
  final Widget body;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.inputBorder, width: AppDimensions.inputBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Padding(
              padding: context.responsivePadding,
              child: Row(
                children: [
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.primary, size: 24),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(child: header),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: context.responsivePadding,
              child: body,
            ),
          ],
        ],
      ),
    );
  }
}
