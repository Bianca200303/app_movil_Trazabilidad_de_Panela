import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

/// Fila de una lista de personas o cosas (usuario, trabajador, productor):
/// avatar de color, nombre, línea de datos y etiquetas. Va dentro de una
/// tarjeta, sin borde propio, separada de las demás con [AppEntityList], para
/// no anidar tarjetas dentro de tarjetas.
class AppEntityTile extends StatelessWidget {
  const AppEntityTile({
    super.key,
    required this.title,
    required this.accent,
    this.icon,
    this.initials,
    this.subtitle,
    this.badges = const [],
    this.trailing,
    this.onTap,
    this.footer,
  }) : assert(icon != null || initials != null);

  final String title;
  /// Color del avatar (rol o estado), de la paleta de marca.
  final Color accent;
  final IconData? icon;
  final String? initials;
  final String? subtitle;
  final List<Widget> badges;
  final Widget? trailing;
  final VoidCallback? onTap;
  /// Contenido adicional debajo de los datos (p. ej. lista de parcelas).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall + 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.12),
              child: icon != null
                  ? Icon(icon, color: accent, size: 20)
                  : Text(
                      initials!,
                      style: AppTextStyles.captionText.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: AppDimensions.spacingSmall + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ],
                  if (footer != null) footer!,
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Columna de [AppEntityTile] separados por una línea fina.
class AppEntityList extends StatelessWidget {
  const AppEntityList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          children[i],
        ],
      ],
    );
  }
}

/// Iniciales para el avatar: primera letra del nombre y del apellido.
String entityInitials(String firstName, String lastName) {
  String first(String s) => s.trim().isEmpty ? '' : s.trim()[0];
  return '${first(firstName)}${first(lastName)}'.toUpperCase();
}
