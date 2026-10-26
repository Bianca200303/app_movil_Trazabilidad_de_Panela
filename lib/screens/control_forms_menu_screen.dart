import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class ControlFormsMenuScreen extends ConsumerWidget {
  final bool isModulo;

  const ControlFormsMenuScreen({super.key, required this.isModulo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (isOnline) => _buildContent(context, isOnline),
      loading: () => _buildContent(context, true),
      error: (_, __) => _buildContent(context, false),
    );
  }

  Widget _buildContent(BuildContext context, bool isOnline) {
    final features = AppConfig.current.features;
    final offline = OfflineConfig.instance.features;
    // Un control se puede abrir si la cooperativa lo usa y, además, hay
    // señal o el control ya funciona sin conexión (bandeja de pendientes).
    bool available(bool enabledForCoop, bool worksOffline) =>
        enabledForCoop && (isOnline || worksOffline);

    final environmentEnabled = available(features.enableEnvironmentInspection, offline.environmentInspection);
    final cleaningEnabled = available(features.enableCleaningDisinfection, offline.cleaningDisinfection);
    final chlorineEnabled = available(features.enableChlorineControl, offline.chlorineControl);
    final pestEnabled = available(features.enablePestControl, offline.pestControl);
    final healthEnabled = available(features.enableHealthAccidentTracking, offline.healthIncidents);
    // Estiba depende de las salidas (kardex), que aún no funcionan sin señal.
    final stowageEnabled = available(features.enableStowageTransportInspection, false);
    final workerControlEnabled = available(features.enableWorkerControl, offline.workerControl);
    final maintenanceEnabled = available(features.enableMaintenanceControl, offline.maintenanceControl);

    return AppScaffold(
      hasTopLabel: true,
      topLabelText: isModulo
          ? 'Control HSS'
          : 'Control BPM',
      child: Center(
        child: SingleChildScrollView(
          padding: context.responsiveHorizontalPadding.copyWith(
            top: context.responsivePadding.top,
            bottom: context.responsivePadding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.responsiveCardWidth,
            ),
            child: AppCard(
              hasBackButton: true,
              onBack: () => context.go(AppRoutes.home.path),
              padding: context.responsivePadding,
              child: FormGroup(
                children: [
                  const AppTitle(title: 'Selecciona el formulario'),

                  if (isModulo) ...[
                    AppButton(
                      text: 'Inspección de ambientes, equipo y personal',
                      icon: Icons.business_outlined,
                      type: environmentEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: environmentEnabled
                          ? () => context.go(AppRoutes.environmentInspectionRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Limpieza y desinfección',
                      icon: Icons.cleaning_services_outlined,
                      type: cleaningEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: cleaningEnabled
                          ? () => context.go(AppRoutes.cleaningDisinfectionRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Control de cloro libre residual',
                      icon: Icons.water_drop_outlined,
                      type: chlorineEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: chlorineEnabled
                          ? () => context.go(AppRoutes.chlorineControlRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Control de plagas',
                      icon: Icons.bug_report_outlined,
                      type: pestEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: pestEnabled
                          ? () => context.go(AppRoutes.pestControlRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Seguimiento de enfermedades y accidentes',
                      icon: Icons.medical_services_outlined,
                      type: healthEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: healthEnabled
                          ? () => context.go(AppRoutes.healthAccidentTrackingRegistration.path)
                          : null,
                    ),
                  ] else ...[
                    // "Quejas y devoluciones" se sacó de acá (2026-08-03): el
                    // registro de una devolución ya se crea automático desde
                    // Calidad en la web al rechazar un lote, no hace falta
                    // cargarlo dos veces a mano. El historial sigue
                    // disponible en Historial > Quejas y devoluciones.
                    AppButton(
                      text: 'Inspección de estiba y transporte',
                      icon: Icons.local_shipping_outlined,
                      type: stowageEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: stowageEnabled
                          ? () => context.go(AppRoutes.stowageTransportInspectionRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Control de personal operario',
                      icon: Icons.badge_outlined,
                      type: workerControlEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: workerControlEnabled
                          ? () => context.go(AppRoutes.workerControlRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Mantenimiento hornilla/maquinaria/equipos',
                      icon: Icons.build_outlined,
                      type: maintenanceEnabled
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: maintenanceEnabled
                          ? () => context.go(AppRoutes.maintenanceControlRegistration.path)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
