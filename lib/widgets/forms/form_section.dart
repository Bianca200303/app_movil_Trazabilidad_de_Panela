import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class FormSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const FormSection({
    super.key,
    this.title,
    this.subtitle,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.sectionLabel,
            ),
            const SizedBox(height: AppDimensions.spacingSmall),
          ],
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: AppDimensions.spacingMedium),
          ],
          ...children,
        ],
      ),
    );
  }
}

class FormGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const FormGroup({
    super.key,
    required this.children,
    this.spacing = AppDimensions.spacingMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children
          .expand((widget) => [widget, SizedBox(height: spacing)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}