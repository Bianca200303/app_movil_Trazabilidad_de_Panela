import 'package:flutter/material.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/widgets/common/app_confirm_dialog.dart';
import 'package:panela_sys/widgets/sync/pending_submissions_sheet.dart';

/// Aviso cuando no se puede cerrar sesión por registros sin enviar
/// (ver AuthService.signOut). Permite abrir la lista de pendientes para
/// revisar o descartar los que el servidor rechazó.
Future<void> showSignOutBlockedDialog(
  BuildContext context,
  PendingSyncBlocksSignOutException error,
) async {
  final openList = await AppConfirmDialog.choose<bool>(
    context,
    title: 'No se puede cerrar sesión',
    message: error.toString(),
    icon: Icons.cloud_upload_outlined,
    actions: const [
      AppDialogAction('Entendido', false),
      AppDialogAction('Ver registros pendientes', true, style: AppDialogActionStyle.primary),
    ],
  );
  if (openList == true && context.mounted) {
    await PendingSubmissionsSheet.show(context);
  }
}
