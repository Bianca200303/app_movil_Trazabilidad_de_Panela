import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/widgets.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/routes.dart';

class UnderConstructionScreen extends StatelessWidget {
  final String screenName;
  
  const UnderConstructionScreen({
    super.key,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasTopLabel: true,
      topLabelText: screenName,
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
                children: [
                  const Icon(
                    Icons.construction,
                    size: 64,
                    color: AppColors.warning,
                  ),
                  Text(
                    'Pantalla en construcción',
                    style: AppTextStyles.sectionTitle,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Esta funcionalidad estará disponible pronto',
                    textAlign: TextAlign.center,
                  ),
                  AppBackButton(
                    label: 'Volver',
                    onPressed: () => context.go(AppRoutes.home.path),
                    isExpanded: true,
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
