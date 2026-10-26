import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';

/// Reduce el tamaño de letra de toda la app en pantallas angostas o bajas
/// (ver ScreenUtils.getResponsiveFontScale). Va una sola vez, en el `builder`
/// de MaterialApp, para que ninguna pantalla tenga que hacerlo por su cuenta.
///
/// Respeta el tamaño de letra elegido en la configuración del celular: el
/// factor se aplica encima de ese ajuste, no lo reemplaza.
class ResponsiveTextScale extends StatelessWidget {
  const ResponsiveTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final factor = ScreenUtils.getResponsiveFontScale(context);
    if (factor == 1.0) return child;

    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: _FactorTextScaler(mediaQuery.textScaler, factor),
      ),
      child: child,
    );
  }
}

/// Aplica [factor] sobre el escalado del sistema, conservando su curva (en
/// Android 14+ el escalado del sistema no es lineal).
///
/// Los títulos se reducen más que el texto normal: un título de 36 px no
/// cabe en un celular angosto aunque se achique en la misma proporción que
/// el cuerpo. Por encima de [_headingFrom] solo se conserva [_headingKeep]
/// del excedente.
class _FactorTextScaler extends TextScaler {
  const _FactorTextScaler(this.base, this.factor);

  static const _headingFrom = 20.0;
  static const _headingKeep = 0.4;

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) {
    var size = fontSize * factor;
    if (size > _headingFrom) {
      size = _headingFrom + (size - _headingFrom) * _headingKeep;
    }
    return base.scale(size);
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _FactorTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}
