import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/widgets/sync/pending_submissions_sheet.dart';

/// "N registros sin enviar · Ver" en la pantalla de inicio: deja ver qué
/// falta subir y, si el servidor rechazó algo, descartarlo. Sin pendientes
/// no ocupa espacio.
class PendingRecordsLink extends ConsumerWidget {
  const PendingRecordsLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(syncPendingCountProvider).valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();

    final text = count == 1 ? '1 registro sin enviar' : '$count registros sin enviar';
    return InkWell(
      onTap: () async {
        await PendingSubmissionsSheet.show(context);
        // Tras descartar, el contador se actualiza sin esperar al sondeo.
        ref.invalidate(syncPendingCountProvider);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 16, color: AppColors.warning),
            const SizedBox(width: 6),
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$text · '),
                  const TextSpan(
                    text: 'Ver',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ]),
                style: AppTextStyles.captionText.copyWith(color: AppColors.warning),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
