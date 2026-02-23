import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/widgets/common/floating_sync_button.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  final bool hasTopLabel;
  final String? topLabelText;
  final VoidCallback? onBack;
  final bool showBackButton;
  final bool showSyncStatus;
  final VoidCallback? onSyncPressed;

  const AppScaffold({
    super.key,
    required this.child,
    this.hasTopLabel = false,
    this.topLabelText,
    this.onBack,
    this.showBackButton = false,
    this.showSyncStatus = true,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sync status banner/button (transversal - appears on all screens)
            if (showSyncStatus)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingMedium,
                  AppDimensions.paddingMedium,
                  AppDimensions.paddingMedium,
                  0,
                ),
                child: FloatingSyncButton(
                  onSyncPressed: onSyncPressed,
                  readOnly: onSyncPressed == null,
                ),
              ),
            if (hasTopLabel && topLabelText != null)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    topLabelText!,
                    style: AppTextStyles.topLabel,
                  ),
                ),
              ),
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: AppBackButton(
                  onPressed: onBack,
                  isExpanded: false,
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

}