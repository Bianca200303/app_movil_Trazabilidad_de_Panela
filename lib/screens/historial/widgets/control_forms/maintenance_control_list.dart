import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';

/// Lista de registros de mantenimiento de hornilla, maquinaria y equipos.
/// Distingue mantenimiento preventivo (verde) de correctivo (naranja).
class MaintenanceControlList extends StatelessWidget {
  const MaintenanceControlList({
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
        message: 'Cargando registros de mantenimiento...',
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
          'No hay registros de mantenimiento',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((maintenance) {
        final maintenanceDate = maintenance['maintenance_date'] as String;
        final equipmentName = maintenance['equipment_name'] as String;
        final maintenanceType = maintenance['maintenance_type'] as String;
        final maintenanceTypeCode = maintenance['maintenance_type_code'] as String;
        final maintenanceCause = maintenance['maintenance_cause'] as String;
        final materialsUsed = maintenance['materials_used'] as String?;
        final hasMaterials = maintenance['has_materials'] as bool;
        final durationHours = maintenance['duration_hours'] as String;
        final responsiblePerson = maintenance['responsible_person'] as String;
        final moduleName = maintenance['module_name'] as String;

        // Preventivo = verde, Correctivo = naranja
        final Color badgeColor = maintenanceTypeCode == 'P'
            ? AppColors.success
            : AppColors.warning;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
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
              // Header: fecha (izquierda) + badge tipo (derecha)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(maintenanceDate, style: AppTextStyles.cardTitle),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      maintenanceType,
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSpacing / 2),
              Divider(color: AppColors.inputBorder),
              SizedBox(height: context.responsiveSpacing / 2),

              HistorialInfoRow(label: 'Módulo:', value: moduleName),
              SizedBox(height: context.responsiveSpacing / 4),
              HistorialInfoRow(label: 'Equipo:', value: equipmentName),
              SizedBox(height: context.responsiveSpacing / 4),
              HistorialInfoRow(label: 'Causa:', value: maintenanceCause),
              SizedBox(height: context.responsiveSpacing / 4),
              HistorialInfoRow(label: 'Duración:', value: durationHours),
              SizedBox(height: context.responsiveSpacing / 4),
              HistorialInfoRow(label: 'Responsable:', value: responsiblePerson),

              // Materiales (si aplica)
              if (hasMaterials) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Text('Materiales/Repuestos:', style: AppTextStyles.fieldLabel),
                SizedBox(height: context.responsiveSpacing / 4),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.responsiveSpacing / 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                    border: Border.all(
                        color: AppColors.inputBorder, width: 0.5),
                  ),
                  child: Text(
                    materialsUsed ?? '',
                    style: AppTextStyles.bodyText,
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
