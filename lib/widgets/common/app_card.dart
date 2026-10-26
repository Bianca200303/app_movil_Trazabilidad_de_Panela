import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hasBackButton;
  final VoidCallback? onBack;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.hasBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // En celulares el margen exterior es mínimo para no restarle ancho al
    // contenido (la pantalla ya suma su propio margen horizontal).
    final outerPadding = ScreenUtils.isSmallScreen(context)
        ? AppDimensions.paddingXSmall
        : ScreenUtils.isMobile(context)
            ? AppDimensions.paddingSmall
            : AppDimensions.paddingLarge;
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.cardMaxWidth,
            ),
            child: Card(
              color: AppColors.surface,
              elevation: AppDimensions.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                side: BorderSide(
                  color: AppColors.border,
                  width: AppDimensions.inputBorderWidth,
                ),
              ),
              child: Padding(
                padding: padding ?? ScreenUtils.getResponsivePadding(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasBackButton)
                      AppBackButton(
                        onPressed: onBack,
                        isExpanded: true,
                      ),
                    if (hasBackButton)
                      const SizedBox(height: AppDimensions.spacingMedium),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}