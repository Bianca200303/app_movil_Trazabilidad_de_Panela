import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

class ProductionStepHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const ProductionStepHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBackButton(
          onPressed: onBack,
          isExpanded: false,
        ),
        SizedBox(height: context.responsiveSpacing),
        Text(
          title,
          style: AppTextStyles.mainTitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}