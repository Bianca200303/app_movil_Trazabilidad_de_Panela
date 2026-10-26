import 'package:flutter/material.dart';
import 'package:panela_sys/models/batch_cert.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

class ExclusiveRadioGroup extends StatelessWidget {
  final String groupName;
  final List<BatchCert> certificates;
  final String? selectedCertId;
  final Function(String certId) onSelectionChanged;
  final bool isRequired;
  final String? label;

  const ExclusiveRadioGroup({
    super.key,
    required this.groupName,
    required this.certificates,
    this.selectedCertId,
    required this.onSelectionChanged,
    this.isRequired = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (certificates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ...certificates.map((cert) => RadioListTile<String>(
          title: Text(cert.name, style: AppTextStyles.bodyText),
          value: cert.id,
          groupValue: selectedCertId,
          onChanged: (value) {
            if (value != null) {
              onSelectionChanged(value);
            }
          },
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        )),
      ],
    );
  }
}