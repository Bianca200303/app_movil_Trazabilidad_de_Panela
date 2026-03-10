import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';

/// Lista de incidentes de salud y accidentes.
/// Muestra estado (reintegrado / pendiente), datos del empleado, síntomas y acciones.
class HealthIncidentsList extends StatelessWidget {
  const HealthIncidentsList({
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
        message: 'Cargando incidentes de salud...',
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
          'No hay incidentes de salud registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((incident) {
        final hasReturnDate = incident['has_return_date'] as bool;
        final moduleName = incident['module_name'] as String;
        final employeeName = incident['employee_name'] as String;
        final registrationDate = incident['registration_date'] as String;
        final workArea = incident['work_area'] as String;
        final symptomsDescription = incident['symptoms_description'] as String;
        final actionsTaken = incident['actions_taken'] as String;
        final returnDate = incident['return_date'] as String;
        final certificatePresented = incident['certificate_presented'] as String;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: hasReturnDate ? Colors.green[50] : Colors.orange[50],
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
                    hasReturnDate ? Icons.check_circle : Icons.warning,
                    color: hasReturnDate ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                  SizedBox(width: context.responsiveSpacing / 2),
                  Expanded(
                    child: Text(
                      hasReturnDate ? 'REINTEGRADO' : 'PENDIENTE',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: hasReturnDate ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(registrationDate, style: AppTextStyles.captionText),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Empleado:', value: employeeName),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Módulo:', value: moduleName),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Área:', value: workArea),
              SizedBox(height: context.responsiveSpacing / 2),

              // Síntomas
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing / 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Síntomas/Lesiones:', style: AppTextStyles.fieldLabel),
                    SizedBox(height: context.responsiveSpacing / 4),
                    Text(
                      symptomsDescription,
                      style: AppTextStyles.bodyText.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Acciones:', value: actionsTaken),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(label: 'Certificado:', value: certificatePresented),

              // Fecha de reintegración
              if (hasReturnDate) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reintegración: $returnDate',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green[700],
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
