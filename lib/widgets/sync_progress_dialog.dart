import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/models/sync_models.dart';

/// Dialog showing synchronization progress
///
/// Displays current module being synced and progress bar.
/// Auto-closes when sync completes.
class SyncProgressDialog extends StatelessWidget {
  final Stream<SyncProgress> syncStream;

  const SyncProgressDialog({
    super.key,
    required this.syncStream,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<SyncProgress>(
          stream: syncStream,
          builder: (context, snapshot) {
            // Auto-close when done
            if (snapshot.connectionState == ConnectionState.done) {
              // Capture navigator before async gap
              final navigator = Navigator.of(context);
              Future.microtask(() {
                if (navigator.canPop()) {
                  navigator.pop();
                }
              });
            }

            final progress = snapshot.data;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading indicator
                const CircularProgressIndicator(),

                const SizedBox(height: 16),

                // Title
                Text(
                  'Subiendo datos...',
                  style: AppTextStyles.cardTitle,
                ),

                const SizedBox(height: 16),

                // Current module
                if (progress != null) ...[
                  Text(
                    progress.module,
                    style: AppTextStyles.bodyText,
                  ),

                  const SizedBox(height: 8),

                  // Progress text
                  Text(
                    '${progress.current} / ${progress.total}',
                    style: AppTextStyles.bodyTextSecondary,
                  ),

                  const SizedBox(height: 8),

                  // Progress bar
                  LinearProgressIndicator(
                    value: progress.progress,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
