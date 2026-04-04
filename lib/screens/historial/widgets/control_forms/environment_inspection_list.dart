import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_stat_chip.dart';

/// Lista de inspecciones de ambientes, equipos y personal.
/// Muestra porcentaje de cumplimiento, módulo, resumen de ítems y áreas no conformes.
class EnvironmentInspectionList extends StatelessWidget {
  const EnvironmentInspectionList({
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
        message: 'Cargando inspecciones de ambiente...',
      );
    }

    if (error != null) {
      return HistorialErrorWidget(error: error!);
    }

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay inspecciones de ambiente registradas',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((inspection) {
        final compliancePercentage = inspection['compliance_percentage'] as double;
        final totalItems = inspection['total_items'] as int;
        final compliantItems = inspection['compliant_items'] as int;
        final nonCompliantItems = inspection['non_compliant_items'] as int;
        final moduleName = inspection['module_name'] as String;
        final inspectionDate = inspection['inspection_date'] as String;

        // Color según porcentaje de cumplimiento
        final Color backgroundColor;
        final Color badgeColor;
        if (compliancePercentage == 100) {
          backgroundColor = Colors.green[50]!;
          badgeColor = AppColors.success;
        } else {
          backgroundColor = Colors.orange[50]!;
          badgeColor = Colors.orange[700]!;
        }

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: backgroundColor,
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
              // Header: badge de cumplimiento + fecha
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      '${compliancePercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(inspectionDate, style: AppTextStyles.captionText),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Módulo:', value: moduleName),
              SizedBox(height: context.responsiveSpacing / 2),

              // Resumen de ítems
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen de ítems', style: AppTextStyles.fieldLabel),
                    SizedBox(height: context.responsiveSpacing / 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HistorialStatChip(
                          label: 'Total',
                          value: totalItems.toString(),
                          color: AppColors.textPrimary,
                        ),
                        HistorialStatChip(
                          label: 'Conformes',
                          value: compliantItems.toString(),
                          color: AppColors.success,
                        ),
                        HistorialStatChip(
                          label: 'No conformes',
                          value: nonCompliantItems.toString(),
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Aviso de ítems no conformes
              if (nonCompliantItems > 0) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[900], size: 16),
                      SizedBox(width: context.responsiveSpacing / 4),
                      Expanded(
                        child: Text(
                          '$nonCompliantItems ítems requieren acciones correctivas',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
