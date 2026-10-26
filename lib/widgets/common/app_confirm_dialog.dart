import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

/// Color e ícono del aviso: [warning] para confirmar o advertir, [danger]
/// cuando se pierden datos o se incumple algo, [info] para preguntas neutras.
enum AppDialogTone { warning, danger, info }

/// Cómo se ve cada botón del aviso.
enum AppDialogActionStyle { secondary, primary, destructive }

/// Un botón del aviso: al tocarlo, el aviso se cierra devolviendo [value].
class AppDialogAction<T> {
  const AppDialogAction(
    this.label,
    this.value, {
    this.style = AppDialogActionStyle.secondary,
  });

  final String label;
  final T value;
  final AppDialogActionStyle style;
}

/// Aviso de la app (círculo con ícono, título, mensaje y botones). Todos los
/// avisos deben pasar por aquí para verse iguales.
///
/// - [show]: confirmar/cancelar, devuelve true si confirma. Sin parámetros es
///   el "¿Confirmar registro?" de siempre.
/// - [choose]: varias opciones; devuelve el valor de la elegida, o null si se
///   cierra con el botón atrás.
/// - [confirmDiscardChanges]: "¿Salir sin guardar?".
///
/// Se adapta al tamaño de pantalla: en celulares pequeños reduce márgenes e
/// ícono, el contenido se desplaza si no entra, y los botones se apilan
/// cuando no caben uno al lado del otro.
class AppConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    String title = '¿Confirmar registro?',
    String message =
        'Una vez guardado, este registro no podrá ser modificado ni eliminado.',
    String cancelLabel = 'Cancelar',
    String confirmLabel = 'Confirmar',
    bool destructive = false,
    AppDialogTone? tone,
    IconData? icon,
  }) async {
    final result = await choose<bool>(
      context,
      title: title,
      message: message,
      tone: tone ?? (destructive ? AppDialogTone.danger : AppDialogTone.warning),
      icon: icon,
      actions: [
        AppDialogAction(cancelLabel, false),
        AppDialogAction(
          confirmLabel,
          true,
          style: destructive
              ? AppDialogActionStyle.destructive
              : AppDialogActionStyle.primary,
        ),
      ],
    );
    return result ?? false;
  }

  /// "¿Salir sin guardar?" al dejar un formulario con datos sin guardar.
  static Future<bool> confirmDiscardChanges(BuildContext context) => show(
    context,
    title: '¿Salir sin guardar?',
    message: 'Se perderán los datos que ingresó en este formulario.',
    cancelLabel: 'Seguir editando',
    confirmLabel: 'Salir',
    destructive: true,
  );

  /// Aviso con las opciones de [actions] (en ese orden). [details] va debajo
  /// del mensaje, para listas u otro contenido extra.
  static Future<T?> choose<T>(
    BuildContext context, {
    required String title,
    String? message,
    Widget? details,
    required List<AppDialogAction<T>> actions,
    AppDialogTone tone = AppDialogTone.warning,
    IconData? icon,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.scrim,
      builder: (ctx) => _AppDialog<T>(
        title: title,
        message: message,
        details: details,
        actions: actions,
        tone: tone,
        icon: icon,
      ),
    );
  }
}

class _AppDialog<T> extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.message,
    required this.details,
    required this.actions,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String? message;
  final Widget? details;
  final List<AppDialogAction<T>> actions;
  final AppDialogTone tone;
  final IconData? icon;

  static const _buttonTextStyle =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const _buttonGap = 12.0;
  static const _buttonHorizontalPadding = 16.0;

  (Color, Color, IconData) get _toneStyle => switch (tone) {
    AppDialogTone.warning => (
      AppColors.warning,
      AppColors.warningLight,
      Icons.warning_amber_rounded,
    ),
    AppDialogTone.danger => (
      AppColors.error,
      AppColors.errorLight,
      Icons.error_outline_rounded,
    ),
    AppDialogTone.info => (
      AppColors.primary,
      AppColors.infoLight,
      Icons.info_outline_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 360;
    final (color, background, defaultIcon) = _toneStyle;
    final iconSize = compact ? 56.0 : 72.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 32,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 20 : 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Si no entra (pantalla baja o lista larga), se desplaza el
              // contenido y los botones quedan siempre visibles.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon ?? defaultIcon,
                          size: iconSize * 0.58,
                          color: color,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (details != null) ...[
                        const SizedBox(height: 12),
                        details!,
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 20 : 28),
              LayoutBuilder(
                builder: (context, constraints) => _shouldStack(
                  context,
                  constraints.maxWidth,
                )
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Apilados: la acción principal arriba.
                          for (final (i, a) in actions.reversed.indexed) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _button(context, a),
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          for (final (i, a) in actions.indexed) ...[
                            if (i > 0) const SizedBox(width: _buttonGap),
                            Expanded(child: _button(context, a)),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Apila los botones si alguno no entra en una línea con el ancho que le
  /// toca en fila (depende del texto, la pantalla y el tamaño de letra).
  bool _shouldStack(BuildContext context, double width) {
    if (actions.length > 2) return true;
    final perButton =
        (width - _buttonGap * (actions.length - 1)) / actions.length -
            _buttonHorizontalPadding * 2;
    final scaler = MediaQuery.textScalerOf(context);
    return actions.any((a) {
      final painter = TextPainter(
        text: TextSpan(text: a.label, style: _buttonTextStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      return painter.width > perButton;
    });
  }

  Widget _button(BuildContext context, AppDialogAction<T> action) {
    void onPressed() => Navigator.of(context).pop(action.value);
    const padding = EdgeInsets.symmetric(
      vertical: 14,
      horizontal: _buttonHorizontalPadding,
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    final label = Text(
      action.label,
      textAlign: TextAlign.center,
      style: _buttonTextStyle,
    );

    if (action.style == AppDialogActionStyle.secondary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: padding,
          shape: shape,
          side: const BorderSide(color: AppColors.inputBorder),
        ),
        child: label,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: action.style == AppDialogActionStyle.destructive
            ? AppColors.error
            : AppColors.primary,
        foregroundColor: AppColors.textWhite,
        padding: padding,
        shape: shape,
        elevation: 2,
      ),
      child: label,
    );
  }
}
