import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      final AuthService authService = AuthService();
      await authService.signOut();
      
      // Force navigation after logout with pushReplacement to clear history
      if (context.mounted) {
        context.go(AppRoutes.login.path);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          message: 'Error al cerrar sesión: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdminSistema = currentUser?.isAdminSistema ?? false;

    return connectivityAsync.when(
      data: (isOnline) => _buildHomeContent(context, isOnline, isAdminSistema),
      loading: () => _buildHomeContent(context, true, isAdminSistema),
      error: (_, __) => _buildHomeContent(context, false, isAdminSistema),
    );
  }

  Widget _buildHomeContent(BuildContext context, bool isOnline, bool isAdminSistema) {
    // Determine button enabled states based on connectivity + offline support
    final producersEnabled = isOnline || OfflineConfig.instance.features.producers;
    final productionEnabled = isOnline || OfflineConfig.instance.features.production;
    final exitsEnabled = isOnline || OfflineConfig.instance.features.exits;

    return AppScaffold(
      hasTopLabel: true,
      topLabelText: 'Inicio',
      child: Padding(
        padding: context.responsiveHorizontalPadding,
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: context.responsivePadding,
                      child: FormGroup(
                        children: [
                          const AppTitle(title: 'UDEP Captura'),

                          AppButton(
                            text: 'Registrar productor',
                            icon: Icons.person,
                            type: producersEnabled ? AppButtonType.optionActive : AppButtonType.option,
                            onPressed: producersEnabled
                                ? () => context.go(AppRoutes.producerRegistration.path)
                                : null,
                          ),

                          AppButton(
                            text: 'Registrar producción',
                            icon: Icons.shopping_bag,
                            type: productionEnabled ? AppButtonType.optionActive : AppButtonType.option,
                            onPressed: productionEnabled
                                ? () => context.go(AppRoutes.productionRegistration.path)
                                : null,
                          ),

                          AppButton(
                            text: 'Formularios de control',
                            icon: Icons.assignment_outlined,
                            type: AppButtonType.option,
                            onPressed: () => context.go(AppRoutes.controlForms.path),
                          ),


                             AppButton(
                            text: 'Registro de salida',
                            icon: Icons.signpost,
                            type: exitsEnabled ? AppButtonType.optionActive : AppButtonType.option,
                            onPressed: exitsEnabled
                                ? () => context.go(AppRoutes.kardexExit.path)
                                : null,
                          ),


                          AppButton(
                            text: 'Historial de registros',
                            icon: Icons.history,
                            type: AppButtonType.option,
                            onPressed: () => context.go(AppRoutes.historial.path),
                          ),

                          if (isAdminSistema) ...[
                            AppButton(
                              text: 'Gestión de usuarios',
                              icon: Icons.manage_accounts_outlined,
                              type: AppButtonType.option,
                              onPressed: () => context.go(AppRoutes.userManagement.path),
                            ),
                            AppButton(
                              text: 'Gestión de módulos',
                              icon: Icons.view_module_outlined,
                              type: AppButtonType.option,
                              onPressed: () => context.go(AppRoutes.moduleManagement.path),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Show logout button only when online
                  if (isOnline) ...[
                    SizedBox(height: context.responsiveSpacing),

                    Padding(
                      padding: EdgeInsets.only(bottom: context.responsivePadding.bottom),
                      child: AppButton(
                        text: 'Cerrar sesión',
                        icon: Icons.logout_outlined,
                        type: AppButtonType.destructive,
                        onPressed: () => _signOut(context),
                        isExpanded: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}