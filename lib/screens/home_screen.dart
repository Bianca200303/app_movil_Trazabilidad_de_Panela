import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/providers/current_user_provider.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/widgets/sync/sign_out_blocked_dialog.dart';
import 'package:panela_sys/widgets/sync/form_data_freshness_label.dart';
import 'package:panela_sys/widgets/sync/pending_records_link.dart';
import 'package:panela_sys/providers/form_data_refresh_provider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _restoreSessionIfNeeded();
      // Al abrir la app con la sesión ya iniciada: sube lo pendiente de
      // antes y pone al día los datos para trabajar sin señal (si hay
      // conexión y hace falta; tras subir se vuelven a actualizar solos).
      if (!mounted) return;
      ref.read(autoSyncStateProvider.notifier).syncIfPending();
      ref.read(formDataRefreshProvider.notifier).refreshIfStale();
    });
  }

  Future<void> _restoreSessionIfNeeded() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) return;

    final authService = AuthService();
    if (!authService.isAuthenticated) return;

    final restored = await authService.restoreCurrentUser();
    if (restored != null && mounted) {
      ref.read(currentUserProvider.notifier).state = restored;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final AuthService authService = AuthService();
      await authService.signOut();

      if (context.mounted) {
        context.go(AppRoutes.login.path);
      }
    } on PendingSyncBlocksSignOutException catch (e) {
      if (context.mounted) await showSignOutBlockedDialog(context, e);
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
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isAdminSistema = currentUser?.isAdminSistema ?? false;
    final isProductor = currentUser?.isProductor ?? false;

    return connectivityAsync.when(
      data: (isOnline) => _buildHomeContent(context, isOnline, isAdminSistema, isProductor),
      loading: () => _buildHomeContent(context, true, isAdminSistema, isProductor),
      error: (_, __) => _buildHomeContent(context, false, isAdminSistema, isProductor),
    );
  }

  Widget _buildHomeContent(BuildContext context, bool isOnline, bool isAdminSistema, bool isProductor) {
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
                          Image.asset(AppConfig.current.logoPath, height: 64),
                          const SizedBox(height: 12),
                          AppTitle(title: AppConfig.current.displayTitle),

                          if (!isProductor) ...[
                            AppButton(
                              text: 'Registrar producción',
                              icon: Icons.shopping_bag,
                              type: productionEnabled ? AppButtonType.optionActive : AppButtonType.option,
                              onPressed: productionEnabled
                                  ? () => context.go(AppRoutes.productionRegistration.path)
                                  : null,
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
                              text: 'Control BPM',
                              icon: Icons.assignment_turned_in_outlined,
                              type: AppButtonType.option,
                              onPressed: () => context.go(AppRoutes.controlFormsProduccion.path),
                            ),

                            AppButton(
                              text: 'Control HSS',
                              icon: Icons.assignment_outlined,
                              type: AppButtonType.option,
                              onPressed: () => context.go(AppRoutes.controlFormsModulo.path),
                            ),
                          ],

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
                            AppButton(
                              text: 'Trabajadores certificados',
                              icon: Icons.badge_outlined,
                              type: AppButtonType.option,
                              onPressed: () => context.go(AppRoutes.certifiedWorkersManagement.path),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (!isProductor) ...[
                    SizedBox(height: context.responsiveSpacing / 2),
                    const FormDataFreshnessLabel(),
                    const PendingRecordsLink(),
                  ],

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
