import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class ControlFormsMenuScreen extends ConsumerWidget {
  const ControlFormsMenuScreen({super.key});

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
    // Calculate enabled state for each form
    final features = AppConfig.current.features;

    final environmentEnabled = isOnline && features.enableEnvironmentInspection;
    final cleaningEnabled = isOnline && features.enableCleaningDisinfection;
    final chlorineEnabled = isOnline && features.enableChlorineControl;
    final pestEnabled = isOnline && features.enablePestControl;
    final healthEnabled = isOnline && features.enableHealthAccidentTracking;
    final stowageEnabled = isOnline && features.enableStowageTransportInspection;
    final complaintsEnabled = isOnline && features.enableComplaintsReturns;
    final workerEnabled = isOnline && features.enableWorkerControl;
    final maintenanceEnabled = isOnline && features.enableMaintenanceControl;
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Formularios de Control',
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
                  const AppTitle(
                    title: 'Selecciona el formulario',
                  ),

                  AppButton(
                    text: 'Inspección de ambientes, equipo y personal',
                    icon: Icons.business_outlined,
                    type: environmentEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: environmentEnabled
                        ? () => context.go(AppRoutes.environmentInspectionRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Limpieza y desinfección',
                    icon: Icons.cleaning_services_outlined,
                    type: cleaningEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: cleaningEnabled
                        ? () => context.go(AppRoutes.cleaningDisinfectionRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Control de cloro libre residual',
                    icon: Icons.water_drop_outlined,
                    type: chlorineEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: chlorineEnabled
                        ? () => context.go(AppRoutes.chlorineControlRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Control de plagas',
                    icon: Icons.bug_report_outlined,
                    type: pestEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: pestEnabled
                        ? () => context.go(AppRoutes.pestControlRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Seguimiento de enfermedades y accidentes',
                    icon: Icons.medical_services_outlined,
                    type: healthEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: healthEnabled
                        ? () => context.go(AppRoutes.healthAccidentTrackingRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Inspección de estiba y transporte',
                    icon: Icons.local_shipping_outlined,
                    type: stowageEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: stowageEnabled
                        ? () => context.go(AppRoutes.stowageTransportInspectionRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Quejas y devoluciones',
                    icon: Icons.feedback_outlined,
                    type: complaintsEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: complaintsEnabled
                        ? () => context.go(AppRoutes.complaintsReturnsRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Control de personal operario',
                    icon: Icons.badge_outlined,
                    type: workerEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: workerEnabled
                        ? () => context.go(AppRoutes.workerControlRegistration.path)
                        : null,
                  ),

                  AppButton(
                    text: 'Mantenimiento hornilla/maquinaria/equipos',
                    icon: Icons.build_outlined,
                    type: maintenanceEnabled ? AppButtonType.optionActive : AppButtonType.option,
                    onPressed: maintenanceEnabled
                        ? () => context.go(AppRoutes.maintenanceControlRegistration.path)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
