import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';

/// Lista de inspecciones de estiba y transporte.
/// Muestra conformidad, guía de remisión, condición del vehículo, sacos y lotes inspeccionados.
class StowageInspectionList extends StatelessWidget {
  const StowageInspectionList({
    required this.isLoading,
    required this.error,
    required this.data,
    super.key,
  });

  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const HistorialLoadingWidget(
        message: 'Cargando inspecciones...',
      );
    }

    if (error != null) {
      return HistorialErrorWidget(error: error!);
    }

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay inspecciones registradas',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((inspection) {
        final isCompliant = inspection['is_compliant'] as bool;
        final documentNumber = inspection['document_number'] as String?;
        final exitItems = (inspection['exit_items'] as List?) ?? [];
        final vehicleCondition = inspection['vehicle_condition'] as String;
        final sackCleanCondition = inspection['sack_clean_condition'] as String;
        final sackTiedCondition = inspection['sack_tied_condition'] as String;
        final observations = inspection['observations'] as String?;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: isCompliant ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.inputBorder,
              width: AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: conformidad + fecha
              Row(
                children: [
                  Icon(
                    isCompliant ? Icons.check_circle : Icons.warning,
                    color: isCompliant ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      isCompliant ? 'CONFORME' : 'NO CONFORME',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: isCompliant ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    inspection['inspection_date'] as String,
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),

              if (documentNumber != null && documentNumber.isNotEmpty)
                HistorialInfoRow(label: 'Guía de Remisión:', value: documentNumber),

              if (documentNumber != null && documentNumber.isNotEmpty)
                SizedBox(height: context.responsiveSpacing / 2),

              HistorialInfoRow(
                  label: 'Condición del vehículo:', value: vehicleCondition),

              // Condiciones de sacos
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
                      'Condiciones de sacos:',
                      style: AppTextStyles.fieldLabel.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(
                        label: 'Limpieza:', value: sackCleanCondition),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(
                        label: 'Amarrado:', value: sackTiedCondition),
                  ],
                ),
              ),

              // Lista de lotes inspeccionados
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
                        'Lotes inspeccionados:',
                        style: AppTextStyles.fieldLabel.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      ...exitItems.map((item) {
                        final batch =
                            item['production_batch'] as Map<String, dynamic>?;
                        final producer =
                            batch?['producer'] as Map<String, dynamic>?;
                        final producerName = producer != null
                            ? '${producer['first_name']} ${producer['last_name']}'
                            : 'N/A';

                        final bagsCount = item['bags_count'] != null ? (item['bags_count'] as num).toDouble() : 0.0;
                        final isAutoconsumo =
                            item['is_autoconsumo'] as bool? ?? false;
                        final quantityKg =
                            (item['quantity_kg'] as num?)?.toDouble() ?? 0.0;
                        final itemDoc =
                            item['item_document_number'] as String?;

                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: context.responsiveSpacing / 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style:
                                    AppTextStyles.bodyText.copyWith(fontSize: 12),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$producerName - ${isAutoconsumo ? '${quantityKg.toStringAsFixed(2)} kg' : '$bagsCount ${bagsCount == 1 ? 'saco' : 'sacos'}'}',
                                      style: AppTextStyles.bodyText.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
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

              // Observaciones
              if (observations != null && observations.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.blue[700]),
                          SizedBox(width: context.responsiveSpacing / 4),
                          Text(
                            'Observaciones:',
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      Text(
                        observations,
                        style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(
                  label: 'Transportista:',
                  value: inspection['carrier_name'] as String),
              HistorialInfoRow(
                  label: 'Vehículo:',
                  value: inspection['vehicle_plate'] as String),
            ],
          ),
        );
      }).toList(),
    );
  }
}
