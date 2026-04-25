import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

class SelectableExitCard extends StatelessWidget {
  final Map<String, dynamic> exitData;
  final bool isSelected;
  final bool alreadyInspected;
  final VoidCallback? onTap;

  const SelectableExitCard({
    super.key,
    required this.exitData,
    required this.isSelected,
    this.alreadyInspected = false,
    this.onTap,
  });

  String _formatExitDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    // ISO: 2026-04-22 or 2026-04-22T...
    final parts = s.split('T').first.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final exitCode = exitData['exit_code'] as String;
    final documentNumber = exitData['document_number'] as String?;
    final totalKg = (exitData['total_kg'] as num?)?.toDouble() ?? 0.0;
    final exitItems = (exitData['exit_items'] as List?) ?? [];
    final itemCount = exitItems.length;
    final exitDate = _formatExitDate(exitData['exit_date']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing),
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: alreadyInspected
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge ya inspeccionado
            if (alreadyInspected) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text('Ya inspeccionado',
                        style: AppTextStyles.captionText.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              SizedBox(height: context.responsiveSpacing / 2),
            ],

            // Fecha de salida
            if (exitDate.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fecha de salida:', style: AppTextStyles.fieldLabel),
                  Text(exitDate, style: AppTextStyles.bodyText),
                ],
              ),
              SizedBox(height: context.responsiveSpacing / 2),
            ],

            // Guía de remisión (si existe)
            if (documentNumber != null && documentNumber.isNotEmpty) ...[
              SizedBox(height: context.responsiveSpacing / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Guía de Remisión:',
                    style: AppTextStyles.fieldLabel,
                  ),
                  Flexible(
                    child: Text(
                      documentNumber,
                      style: AppTextStyles.bodyText,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: context.responsiveSpacing / 2),

            // Total kg y cantidad de lotes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: AppTextStyles.fieldLabel,
                ),
                Flexible(
                  child: Text(
                    '${totalKg.toStringAsFixed(2)} kg ($itemCount ${itemCount == 1 ? 'lote' : 'lotes'})',
                    style: AppTextStyles.bodyText,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),

            // Items (productores y sacos)
            if (exitItems.isNotEmpty) ...[
              SizedBox(height: context.responsiveSpacing),
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(
                    color: AppColors.inputBorder.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lotes incluidos:',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    ...exitItems.map((item) {
                      final batch = item['production_batch'] as Map<String, dynamic>?;
                      final producer = batch?['producer'] as Map<String, dynamic>?;
                      final producerName = producer != null
                          ? '${producer['first_name']} ${producer['last_name']}'
                          : 'N/A';

                      final bagsCount = item['bags_count'] != null ? (item['bags_count'] as num).toDouble() : 0.0;
                      final isAutoconsumo = item['is_autoconsumo'] as bool? ?? false;
                      final quantityKg = (item['quantity_kg'] as num?)?.toDouble() ?? 0.0;
                      final itemDoc = item['item_document_number'] as String?;

                      return Padding(
                        padding: EdgeInsets.only(bottom: context.responsiveSpacing / 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    producerName,
                                    style: AppTextStyles.bodyText.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    isAutoconsumo
                                        ? '${quantityKg.toStringAsFixed(2)} kg (autoconsumo)'
                                        : '$bagsCount ${bagsCount == 1 ? 'saco' : 'sacos'}',
                                    style: AppTextStyles.captionText,
                                  ),
                                  if (itemDoc != null && itemDoc.isNotEmpty)
                                    Text(
                                      'Comp: $itemDoc',
                                      style: AppTextStyles.captionText.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Indicador de selección
            if (isSelected) ...[
              SizedBox(height: context.responsiveSpacing / 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 4),
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
