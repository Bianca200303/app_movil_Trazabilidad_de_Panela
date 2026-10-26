import 'package:flutter/material.dart';

/// Única fuente de color de la app. Ninguna pantalla ni widget debe usar
/// `Colors.*` ni `Color(0x...)` directo: para cambiar la paleta basta con
/// editar este archivo (el tema de main.dart también se arma desde aquí).
///
/// Cada color de estado tiene cuatro tonos con el mismo uso:
///   - `xLight`:  fondo suave (avisos, chips, tarjetas resaltadas)
///   - `xBorder`: borde o relleno intermedio
///   - `x`:       ícono, botón o indicador
///   - `xDark`:   texto sobre el fondo suave
class AppColors {
  AppColors._();

  // ── Marca: azul vivo y sobrio ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1F63C6);
  static const Color primaryLight = Color(0xFF4B8AE0);
  static const Color primaryDark = Color(0xFF154A99);
  static const Color primarySoft = Color(0xFFEBF2FC);
  static const Color primaryBorder = Color(0xFFBFD5F2);

  // ── Fondos ────────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F5F8);

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1F24);
  static const Color textSecondary = Color(0xFF4F5661);
  static const Color textTertiary = Color(0xFF6B7280);
  /// Texto e íconos sobre fondos de color (botones, encabezados).
  static const Color textWhite = Color(0xFFFFFFFF);

  // ── Elementos de interfaz ─────────────────────────────────────────────────
  static const Color cardBackground = surface;
  static const Color inputFill = surface;
  static const Color inputBorder = Color(0xFFC3C9D2);
  static const Color inputBorderFocused = primary;
  static const Color inputBorderError = error;
  static const Color border = Color(0xFFE1E5EB);
  static const Color borderFocused = primary;
  static const Color placeholder = Color(0xFF9AA1AC);

  // ── Estados ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E9B4A);
  static const Color successLight = Color(0xFFE7F5EB);
  static const Color successBorder = Color(0xFFA6D9B4);
  static const Color successDark = Color(0xFF1E6F33);

  static const Color warning = Color(0xFFF59300);
  static const Color warningLight = Color(0xFFFFF4E5);
  static const Color warningBorder = Color(0xFFFFCC80);
  static const Color warningDark = Color(0xFFB35C00);

  static const Color error = Color(0xFFE03C3C);
  static const Color errorLight = Color(0xFFFDECEC);
  static const Color errorBorder = Color(0xFFEF9A9A);
  static const Color errorDark = Color(0xFFB71C1C);

  static const Color info = primary;
  static const Color infoLight = primarySoft;
  static const Color infoBorder = primaryBorder;
  static const Color infoDark = primaryDark;

  // ── Categorías de datos ───────────────────────────────────────────────────
  static const Color cleaningDaily = primary;
  static const Color cleaningGeneral = warningDark;
  static const Color cleaningDeep = Color(0xFF6A1B9A);
  static const Color exitTypeNorandino = success;
  static const Color exitTypeAutoconsumo = Color(0xFF8D6E63);

  // ── Sombras y velos ───────────────────────────────────────────────────────
  /// Base de las sombras: se usa con opacidad (`shadow.withValues(alpha: …)`).
  static const Color shadow = Color(0xFF000000);
  /// Velo detrás de diálogos y hojas.
  static const Color scrim = Color(0x8A000000);

  // ── Alias heredados (se mantienen para no romper código existente) ────────
  static const Color successGreen = success;
  static const Color backButtonRed = error;
  static const Color backgroundBrown = Color(0xFF8B5A2B);

  static Color cardBackgroundTransparent = surface.withValues(alpha: 0.95);
  static Color labelTransparent = surface.withValues(alpha: 0.8);
}
