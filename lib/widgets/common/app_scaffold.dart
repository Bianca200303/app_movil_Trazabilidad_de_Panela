import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/screen_utils.dart';
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
    final showTopLabel = hasTopLabel && topLabelText != null;
    final gutter = ScreenUtils.isSmallScreen(context)
        ? AppDimensions.paddingSmall + AppDimensions.paddingXSmall
        : AppDimensions.paddingMedium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sync status banner/button (transversal - appears on all screens)
            if (showSyncStatus)
              Padding(
                // Medio margen: si no hay aviso de sincronización, este espacio
                // queda vacío sobre la cabecera.
                padding: EdgeInsets.fromLTRB(gutter, gutter / 2, gutter, 0),
                child: FloatingSyncButton(
                  onSyncPressed: onSyncPressed,
                  readOnly: onSyncPressed == null,
                ),
              ),
            // Título y "Regresar" comparten una sola fila: apilados ocupaban
            // casi un tercio de la altura en celulares pequeños.
            if (showTopLabel || showBackButton)
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, gutter / 2, gutter, gutter / 2),
                child: Row(
                  children: [
                    if (showBackButton)
                      // Con título al lado, en pantallas pequeñas basta la
                      // flecha: el botón con texto le quitaba medio ancho.
                      showTopLabel && ScreenUtils.isSmallScreen(context)
                          ? IconButton(
                              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                              tooltip: 'Regresar',
                              icon: const Icon(Icons.arrow_back),
                              color: AppColors.primary,
                              style: IconButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                ),
                              ),
                            )
                          : AppBackButton(
                              onPressed: onBack,
                              isExpanded: false,
                            ),
                    if (showBackButton && showTopLabel)
                      SizedBox(width: gutter),
                    if (showTopLabel)
                      Expanded(
                        child: Text(
                          topLabelText!,
                          style: AppTextStyles.topLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

}