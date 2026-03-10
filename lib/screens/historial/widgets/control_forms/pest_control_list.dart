import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/widgets/common/app_button.dart';

/// Lista de controles de plagas.
/// Muestra registros de cebos e insectos por módulo.
class PestControlList extends StatelessWidget {
  const PestControlList({
    required this.isLoading,
    required this.error,
    required this.data,
    required this.onRetry,
    super.key,
  });

  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const HistorialLoadingWidget(
        message: 'Cargando controles de plagas...',
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButton(text: 'Reintentar', onPressed: onRetry),
          ],
        ),
      );
    }

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay controles de plagas registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((control) {
        final moduleName = control['module_name'] as String;
        final controlDate = control['control_date'] as String;
        final baitRecords = control['bait_records'] as List;
        final insectRecords = control['insect_records'] as List;

        final hasBaitData = baitRecords.isNotEmpty;
        final hasInsectData = insectRecords.isNotEmpty;

        final backgroundColor = (hasBaitData && hasInsectData)
            ? Colors.blue[50]!
            : (hasBaitData ? Colors.green[50]! : Colors.orange[50]!);

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
              // Header
              Row(
                children: [
                  Icon(Icons.bug_report, color: AppColors.primary, size: 20),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      'CONTROL DE PLAGAS',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(controlDate, style: AppTextStyles.captionText),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Módulo:', value: moduleName),
              SizedBox(height: context.responsiveSpacing / 2),

              // Sección de cebos
              if (hasBaitData) ...[
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Control de Cebos',
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      ...baitRecords.map((record) {
                        final totalStations = record.totalStations;
                        final stationsEaten = record.stationsWithBaitEaten;
                        final consumptionPercent = record.consumptionPercentage;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HistorialInfoRow(
                                label: 'Producto:', value: record.productName),
                            HistorialInfoRow(
                                label: 'Cantidad:',
                                value: '${record.quantity} ${record.unit}'),
                            SizedBox(height: context.responsiveSpacing / 4),
                            Text(
                              'Estaciones: $totalStations ($stationsEaten comieron, '
                              '${consumptionPercent.toStringAsFixed(0)}%)',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                            ),
                            if (record.baitObservations != null) ...[
                              SizedBox(height: context.responsiveSpacing / 4),
                              Text(
                                'Observaciones: ${record.baitObservations}',
                                style: AppTextStyles.bodyText.copyWith(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: context.responsiveSpacing / 2),
              ],

              // Sección de insectos
              if (hasInsectData) ...[
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Control de Insectos',
                            style: AppTextStyles.fieldLabel.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsiveSpacing / 4),
                      ...insectRecords.map((record) {
                        final totalFlies = record.totalFlies;
                        final totalBees = record.totalBees;
                        final totalAnts = record.totalAnts;
                        final totalCockroaches = record.totalCockroaches;
                        final totalInsects = record.totalInsects;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HistorialInfoRow(
                                label: 'Producto:', value: record.productName),
                            HistorialInfoRow(
                                label: 'Cantidad:',
                                value: '${record.quantity} ${record.unit}'),
                            SizedBox(height: context.responsiveSpacing / 4),
                            Text(
                              'Total de insectos: $totalInsects',
                              style: AppTextStyles.bodyText.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (totalFlies > 0)
                              Text('  • Moscas: $totalFlies',
                                  style: AppTextStyles.bodyText
                                      .copyWith(fontSize: 12)),
                            if (totalBees > 0)
                              Text('  • Abejas: $totalBees',
                                  style: AppTextStyles.bodyText
                                      .copyWith(fontSize: 12)),
                            if (totalAnts > 0)
                              Text('  • Hormigas: $totalAnts',
                                  style: AppTextStyles.bodyText
                                      .copyWith(fontSize: 12)),
                            if (totalCockroaches > 0)
                              Text('  • Cucarachas: $totalCockroaches',
                                  style: AppTextStyles.bodyText
                                      .copyWith(fontSize: 12)),
                          ],
                        );
                      }),
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
