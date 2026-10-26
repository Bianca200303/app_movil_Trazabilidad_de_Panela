import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/providers/offline_provider.dart';

/// Floating sync button that appears at the top of the screen
///
/// States:
/// - OFFLINE: Shows warning banner "No connection - data will sync when connected"
/// - ONLINE + PENDING: Shows "Sync All" button (if not readOnly)
/// - ONLINE + NO PENDING: Shows nothing
/// - SYNCING: Shows disabled button with loading indicator
///
/// When [readOnly] is true, only shows offline banner without sync button.
///
/// The button uses global sync state from [autoSyncStateProvider] to:
/// - Disable button during both auto and manual sync
/// - Show unified sync status across all screens
/// - Prevent concurrent synchronizations
class FloatingSyncButton extends ConsumerWidget {
  final VoidCallback? onSyncPressed;
  final bool readOnly;

  const FloatingSyncButton({
    super.key,
    this.onSyncPressed,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch connectivity
    final connectivityAsync = ref.watch(connectivityProvider);

    // Watch pending count
    final pendingCountAsync = ref.watch(syncPendingCountProvider);

    // Watch global sync state
    final isSyncing = ref.watch(autoSyncStateProvider);

    return connectivityAsync.when(
      data: (isConnected) {
        return pendingCountAsync.when(
          data: (pendingCount) {
            // CASE 1: OFFLINE - Show warning banner (always visible)
            if (!isConnected) {
              return _buildOfflineBanner(context);
            }

            // CASE 2: ONLINE + PENDING - Show sync button (only if not readOnly)
            if (pendingCount > 0 && !readOnly) {
              return _buildSyncButton(context, pendingCount, isSyncing);
            }

            // CASE 3: ONLINE + NO PENDING or readOnly - Show nothing
            return const SizedBox.shrink();
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Build offline warning banner
  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.responsivePadding.left),
      decoration: BoxDecoration(
        color: AppColors.warningLight, // Light orange background
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.warning, // Orange border
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: AppColors.warning,
            size: 20,
          ),
          SizedBox(width: context.responsiveSpacing / 2),
          Expanded(
            child: Text(
              'Sin conexión - Los datos se subirán al conectarse',
              style: AppTextStyles.smallText.copyWith(
                color: AppColors.warningDark, // Dark orange text
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build sync button (online + pending items)
  Widget _buildSyncButton(BuildContext context, int pendingCount, bool isSyncing) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (isSyncing || onSyncPressed == null) ? null : onSyncPressed,
        icon: isSyncing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textWhite,
                  ),
                ),
              )
            : const Icon(Icons.sync, size: 20),
        label: Text(
          isSyncing
              ? 'Subiendo...'
              : 'Subir datos ($pendingCount)',
          style: AppTextStyles.buttonText,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsivePadding.left,
            vertical: context.responsivePadding.top * 0.75,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
