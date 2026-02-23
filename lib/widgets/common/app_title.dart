import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class AppTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  const AppTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.mainTitle,
          textAlign: textAlign,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            subtitle!,
            style: AppTextStyles.bodyText,
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.sectionTitle,
          textAlign: textAlign,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            subtitle!,
            style: AppTextStyles.bodyText,
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}

class CardTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextAlign textAlign;

  const CardTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTextStyles.cardTitle,
          textAlign: textAlign,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            subtitle!,
            style: AppTextStyles.bodyText,
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}