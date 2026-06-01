import 'package:flutter/material.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/common/app_button.dart';

/// Submenú de formularios de control (nivel 2 del historial).
/// Muestra los 9 tipos de formulario y los habilita según las features de la cooperativa.
/// Solo disponible cuando hay conectividad (el caller lo garantiza).
class HistorialControlSubmenu extends StatelessWidget {
  const HistorialControlSubmenu({
    required this.isOnline,
    required this.isModulo,
    required this.onFormTypeSelected,
    super.key,
  });

  final bool isOnline;
  final bool isModulo;

  /// Callback al seleccionar un tipo de formulario (índice 0-8).
  final void Function(int index) onFormTypeSelected;

  @override
  Widget build(BuildContext context) {
    final features = AppConfig.current.features;

    final moduloForms = [
      {
        'title': 'Inspección de ambientes, equipo y personal',
        'icon': Icons.business_outlined,
        'index': 0,
        'enabled': isOnline && features.enableEnvironmentInspection,
      },
      {
        'title': 'Limpieza y desinfección',
        'icon': Icons.cleaning_services_outlined,
        'index': 1,
        'enabled': isOnline && features.enableCleaningDisinfection,
      },
      {
        'title': 'Control de cloro libre residual',
        'icon': Icons.water_drop_outlined,
        'index': 2,
        'enabled': isOnline && features.enableChlorineControl,
      },
      {
        'title': 'Control de plagas',
        'icon': Icons.bug_report_outlined,
        'index': 3,
        'enabled': isOnline && features.enablePestControl,
      },
      {
        'title': 'Seguimiento de enfermedades y accidentes',
        'icon': Icons.medical_services_outlined,
        'index': 4,
        'enabled': isOnline && features.enableHealthAccidentTracking,
      },
    ];

    final produccionForms = [
      {
        'title': 'Inspección de estiba y transporte',
        'icon': Icons.local_shipping_outlined,
        'index': 5,
        'enabled': isOnline && features.enableStowageTransportInspection,
      },
      {
        'title': 'Quejas y devoluciones',
        'icon': Icons.feedback_outlined,
        'index': 6,
        'enabled': isOnline && features.enableComplaintsReturns,
      },
      {
        'title': 'Control de personal operario',
        'icon': Icons.badge_outlined,
        'index': 7,
        'enabled': isOnline && features.enableWorkerControl,
      },
      {
        'title': 'Mantenimiento hornilla/maquinaria/equipos',
        'icon': Icons.build_outlined,
        'index': 8,
        'enabled': isOnline && features.enableMaintenanceControl,
      },
    ];

    Widget buildFormButton(Map<String, Object> formType) {
      final isEnabled = formType['enabled'] as bool;
      final index = formType['index'] as int;
      return Padding(
        padding: EdgeInsets.only(bottom: context.responsiveSpacing),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            text: formType['title'] as String,
            icon: formType['icon'] as IconData,
            type: isEnabled ? AppButtonType.primary : AppButtonType.secondary,
            onPressed: isEnabled ? () => onFormTypeSelected(index) : null,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: (isModulo ? moduloForms : produccionForms)
          .map((f) => buildFormButton(f))
          .toList(),
    );
  }
}
