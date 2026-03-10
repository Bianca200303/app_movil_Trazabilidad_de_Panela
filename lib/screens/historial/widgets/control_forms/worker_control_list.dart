import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';

/// Lista de controles de personal operario.
/// Muestra cumplimiento de higiene, área de trabajo y observaciones.
class WorkerControlList extends StatelessWidget {
  const WorkerControlList({
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
        message: 'Cargando controles de personal...',
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay controles de personal registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((control) {
        final isFullyCompliant = control['is_fully_compliant'] as bool;
        final compliancePercentage = control['compliance_percentage'] as double;
        final complianceCount = control['compliance_count'] as int;
        final workerName = control['worker_name'] as String;
        final workArea = control['work_area'] as String;
        final formattedDate = control['formatted_date'] as String;
        final observations = control['observations'] as String?;
        final totalCriteria = control['total_criteria'] as int;
        final Color backgroundColor;
        final Color badgeColor;
        if (isFullyCompliant) {
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
              // Header: estado + fecha
              Row(
                children: [
                  Icon(
                    isFullyCompliant
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: badgeColor,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      isFullyCompliant
                          ? 'CUMPLE TOTALMENTE'
                          : 'INCUMPLIMIENTOS',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(formattedDate, style: AppTextStyles.captionText),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Trabajador(es):', value: workerName),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Área:', value: workArea),
              SizedBox(height: context.responsiveSpacing / 2),

              // Resumen de cumplimiento
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSmall,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cumplimiento de Higiene',
                      style: AppTextStyles.fieldLabel,
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isFullyCompliant
                                  ? Icons.check_circle
                                  : Icons.warning,
                              size: 16,
                              color: isFullyCompliant
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$complianceCount / $totalCriteria criterios',
                              style: AppTextStyles.bodyText.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${compliancePercentage.toStringAsFixed(0)}%',
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isFullyCompliant
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Observaciones
              if (observations != null && observations.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusSmall,
                    ),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange[900],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Observaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        observations,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
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
