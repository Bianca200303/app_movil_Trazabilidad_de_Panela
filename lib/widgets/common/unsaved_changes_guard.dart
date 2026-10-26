import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_confirm_dialog.dart';

/// Protege un formulario para que no se pierda lo ingresado al salir por
/// error.
///
/// Uso en la pantalla del formulario:
///
/// ```dart
/// bool get _hasUnsavedChanges => ...; // lo que el usuario llenó
///
/// void _leave() => UnsavedChangesGuard.leave(
///       context,
///       hasUnsavedChanges: _hasUnsavedChanges,
///       leave: () => context.go(AppRoutes.menu.path),
///     );
///
/// @override
/// Widget build(BuildContext context) => UnsavedChangesGuard(
///       onBack: _currentStep > 0 ? _previousStep : _leave,
///       child: AppScaffold(...), // y su botón "Regresar" llama a _leave
///     );
/// ```
///
/// - El botón/gesto "atrás" del celular hace lo mismo que el "Regresar" de
///   la pantalla ([onBack]) en vez de cerrar la app (las rutas se abren con
///   `context.go`, así que no hay pantalla anterior a la cual volver).
/// - [leave] pide confirmación solo si hay datos sin guardar.
/// - Navegar con `context.go` tras guardar no pasa por aquí: no pregunta.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.onBack,
    required this.child,
  });

  /// Qué hace el "atrás" del celular: volver al paso anterior o salir del
  /// formulario (con [leave]).
  final VoidCallback onBack;
  final Widget child;

  /// Sale del formulario con [leave], preguntando antes si
  /// [hasUnsavedChanges]. No hace nada si el usuario elige seguir editando.
  static Future<void> leave(
    BuildContext context, {
    required bool hasUnsavedChanges,
    required VoidCallback leave,
  }) async {
    if (hasUnsavedChanges &&
        !await AppConfirmDialog.confirmDiscardChanges(context)) {
      return;
    }
    if (context.mounted) leave();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: child,
    );
  }
}
