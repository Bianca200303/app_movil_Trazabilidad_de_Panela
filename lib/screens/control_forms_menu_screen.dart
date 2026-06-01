import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/app_config.dart';
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
                      type: isOnline && features.enableEnvironmentInspection
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableEnvironmentInspection
                          ? () => context.go(AppRoutes.environmentInspectionRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Limpieza y desinfección',
                      icon: Icons.cleaning_services_outlined,
                      type: isOnline && features.enableCleaningDisinfection
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableCleaningDisinfection
                          ? () => context.go(AppRoutes.cleaningDisinfectionRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Control de cloro libre residual',
                      icon: Icons.water_drop_outlined,
                      type: isOnline && features.enableChlorineControl
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableChlorineControl
                          ? () => context.go(AppRoutes.chlorineControlRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Control de plagas',
                      icon: Icons.bug_report_outlined,
                      type: isOnline && features.enablePestControl
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enablePestControl
                          ? () => context.go(AppRoutes.pestControlRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Seguimiento de enfermedades y accidentes',
                      icon: Icons.medical_services_outlined,
                      type: isOnline && features.enableHealthAccidentTracking
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableHealthAccidentTracking
                          ? () => context.go(AppRoutes.healthAccidentTrackingRegistration.path)
                          : null,
                    ),
                  ] else ...[
                    AppButton(
                      text: 'Inspección de estiba y transporte',
                      icon: Icons.local_shipping_outlined,
                      type: isOnline && features.enableStowageTransportInspection
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableStowageTransportInspection
                          ? () => context.go(AppRoutes.stowageTransportInspectionRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Quejas y devoluciones',
                      icon: Icons.feedback_outlined,
                      type: isOnline && features.enableComplaintsReturns
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableComplaintsReturns
                          ? () => context.go(AppRoutes.complaintsReturnsRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Control de personal operario',
                      icon: Icons.badge_outlined,
                      type: isOnline && features.enableWorkerControl
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableWorkerControl
                          ? () => context.go(AppRoutes.workerControlRegistration.path)
                          : null,
                    ),
                    AppButton(
                      text: 'Mantenimiento hornilla/maquinaria/equipos',
                      icon: Icons.build_outlined,
                      type: isOnline && features.enableMaintenanceControl
                          ? AppButtonType.optionActive
                          : AppButtonType.option,
                      onPressed: isOnline && features.enableMaintenanceControl
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
