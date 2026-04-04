import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';

/// Lista de controles de cloro libre residual.
/// Muestra estado (en rango / fuera de rango), mediciones M1/M2, acciones correctivas y observaciones.
class ChlorineControlList extends StatelessWidget {
  const ChlorineControlList({
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
        message: 'Cargando controles de cloro...',
      );
    }

    if (error != null) {
      return HistorialErrorWidget(error: error!);
    }

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay controles de cloro registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((control) {
        final bothSafe = control['both_safe'] as bool;
        final requiresAction = control['requires_action'] as bool;
        final moduleName = control['module_name'] as String;
        final controlDate = control['control_date'] as String;
        final controlTime = control['control_time'] as String;
        final m1 = control['m1'] as double;
        final m2 = control['m2'] as double;
        final isM1Safe = control['is_m1_safe'] as bool;
        final isM2Safe = control['is_m2_safe'] as bool;
        final safetyWarning = control['safety_warning'] as String?;
        final correctiveActions = control['corrective_actions'] as String?;
        final observations = control['observations'] as String?;
        final responsiblePerson = control['responsible_person'] as String;

        final Color backgroundColor;
        final Color badgeColor;
        if (bothSafe) {
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
              // Header: estado + fecha/hora
              Row(
                children: [
                  Icon(
                    bothSafe ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: badgeColor,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      bothSafe ? 'EN RANGO SEGURO' : 'FUERA DE RANGO',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$controlDate $controlTime',
                    style: AppTextStyles.captionText,
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Módulo:', value: moduleName),
              SizedBox(height: context.responsiveSpacing / 2),

              // Mediciones
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mediciones (ppm)', style: AppTextStyles.fieldLabel),
                    SizedBox(height: context.responsiveSpacing / 4),

                    // M1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isM1Safe ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: isM1Safe ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'M1 - Sanitización:',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          m1.toStringAsFixed(2),
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isM1Safe ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsiveSpacing / 4),

                    // M2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isM2Safe ? Icons.check_circle : Icons.warning,
                              size: 16,
                              color: isM2Safe ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'M2 - Proceso:',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          m2.toStringAsFixed(2),
                          style: AppTextStyles.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isM2Safe ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsiveSpacing / 4),
                    Text(
                      'Rango seguro: 0.5 - 2.0 ppm',
                      style: AppTextStyles.captionText.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Advertencia de seguridad (si está fuera de rango)
              if (requiresAction && safetyWarning != null) ...[
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
                          safetyWarning,
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

              // Acciones correctivas
              if (correctiveActions != null && correctiveActions.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.build, size: 16, color: Colors.blue[900]),
                          const SizedBox(width: 8),
                          Text(
                            'Acciones correctivas:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        correctiveActions,
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
              ],

              // Observaciones
              if (observations != null && observations.isNotEmpty) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Observaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        observations,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Responsable:', value: responsiblePerson),
            ],
          ),
        );
      }).toList(),
    );
  }
}
