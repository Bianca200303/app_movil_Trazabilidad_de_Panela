import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/models/user_model.dart';
import 'package:panela_sys/services/user_service.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/widgets/sync/sign_out_blocked_dialog.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final users = await _userService.getAllUsers();
      if (kDebugMode) {
        debugPrint('Users loaded: ${users.length} users');
      }
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar usuarios: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lista de Usuarios',
              style: AppTextStyles.sectionTitle,
            ),
            Text(
              AppConfig.current.name,
              style: AppTextStyles.captionText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout_outlined,
              size: AppDimensions.iconMedium,
              color: AppColors.textSecondary,
            ),
            onPressed: () async {
              try {
                await authService.signOut();
              } on PendingSyncBlocksSignOutException catch (e) {
                if (context.mounted) await showSignOutBlockedDialog(context, e);
                return;
              }
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppDimensions.iconXLarge,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppDimensions.spacingMedium),
                        Text(
                          _error!,
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacingLarge),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                          margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.error,
                                size: AppDimensions.iconSmall,
                              ),
                              const SizedBox(width: AppDimensions.spacingSmall),
                              Expanded(
                                child: Text(
                                  'Error al cargar los datos',
                                  style: AppTextStyles.bodyTextSecondary.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingLarge,
                              vertical: AppDimensions.paddingMedium,
                            ),
                          ),
                          child: Text(
                            'Reintentar',
                            style: AppTextStyles.buttonText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: AppDimensions.iconXLarge,
                                color: AppColors.info,
                              ),
                              const SizedBox(height: AppDimensions.spacingMedium),
                              Text(
                                'No hay usuarios disponibles',
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: AppColors.info,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppDimensions.spacingSmall),
                              Text(
                                'Los usuarios registrados aparecerán aquí',
                                style: AppTextStyles.bodyText.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.background,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        itemCount: _users.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.spacingSmall),
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                              border: Border.all(
                                color: AppColors.border,
                                width: AppDimensions.inputBorderWidth,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingMedium,
                                vertical: AppDimensions.paddingSmall,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    user.firstName[0].toUpperCase(),
                                    style: AppTextStyles.bodyTextLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                user.fullName,
                                style: AppTextStyles.bodyText.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'DNI: ${user.userId}',
                                style: AppTextStyles.bodyTextSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        tooltip: 'Actualizar lista',
        child: Icon(
          Icons.refresh,
          size: AppDimensions.iconMedium,
        ),
      ),
    );
  }
}