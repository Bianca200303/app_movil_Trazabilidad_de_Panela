import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_scaffold.dart';
import 'package:panela_sys/widgets/common/app_card.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:go_router/go_router.dart';

enum RegistrationType {
  producer,
  production,
  kardexExit,
}

class SuccessRegistrationScreen extends StatelessWidget {
  final RegistrationType type;

  const SuccessRegistrationScreen({
    super.key, 
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final String registroText = _getRegistroText();

    return AppScaffold(
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
              padding: context.responsivePadding,
              child: FormGroup(
                spacing: context.responsiveSpacing,
                children: [
                  // Title
                  Text(
                    'Registro enviado',
                    style: AppTextStyles.mainTitle,
                    textAlign: TextAlign.center,
                  ),
                  
                  // Success icon
                  Icon(
                    Icons.check_circle_outline,
                    size: context.isVerySmallScreen ? 60 : 80,
                    color: AppColors.success,
                  ),
                  
                  // Buttons section
                  if (context.shouldStackButtons)
                    // Vertical layout for very small screens
                    Column(
                      children: [
                        AppButton(
                          text: 'Nuevo registro de $registroText',
                          onPressed: () => _navigateToNewRegistration(context),
                        ),
                        SizedBox(height: AppDimensions.spacingMedium),
                        AppButton(
                          text: 'Ir al inicio',
                          type: AppButtonType.secondary,
                          onPressed: () => context.go(AppRoutes.home.path),
                        ),
                      ],
                    )
                  else
                    // Horizontal layout for larger screens
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Nuevo registro de $registroText',
                            onPressed: () => _navigateToNewRegistration(context),
                          ),
                        ),
                        SizedBox(width: AppDimensions.spacingMedium),
                        Expanded(
                          child: AppButton(
                            text: 'Ir al inicio',
                            type: AppButtonType.secondary,
                            onPressed: () => context.go(AppRoutes.home.path),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getRegistroText() {
    switch (type) {
      case RegistrationType.producer:
        return 'productor';
      case RegistrationType.production:
        return 'producción';
      case RegistrationType.kardexExit:
        return 'salida';
    }
  }

  void _navigateToNewRegistration(BuildContext context) {
    // Capture router and navigator to avoid using BuildContext across async gaps
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);

    // First pop the success screen
    navigator.pop();

    // Navigate to home first to clear the router state, then to registration
    switch (type) {
      case RegistrationType.producer:
        router.go(AppRoutes.home.path);
        Future.delayed(const Duration(milliseconds: 100), () {
          router.push(AppRoutes.producerRegistration.path);
        });
        break;
      case RegistrationType.production:
        router.go(AppRoutes.home.path);
        Future.delayed(const Duration(milliseconds: 100), () {
          router.push(AppRoutes.productionRegistration.path);
        });
        break;
      case RegistrationType.kardexExit:
        router.go(AppRoutes.home.path);
        Future.delayed(const Duration(milliseconds: 100), () {
          router.push(AppRoutes.kardexExit.path);
        });
        break;
    }
  }
}
