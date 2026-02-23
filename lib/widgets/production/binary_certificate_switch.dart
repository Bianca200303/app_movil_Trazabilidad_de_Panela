import 'package:flutter/material.dart';
import 'package:panela_sys/models/batch_cert.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class BinaryCertificateSwitch extends StatelessWidget {
  final String groupName;
  final List<BatchCert> certificates; // Should contain exactly 2 certificates
  final String? selectedCertId;
  final Function(String certId) onSelectionChanged;
  final String? label;

  const BinaryCertificateSwitch({
    super.key,
    required this.groupName,
    required this.certificates,
    this.selectedCertId,
    required this.onSelectionChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (certificates.length != 2) {
      // Fallback to radio buttons if not exactly 2 certificates
      return _buildRadioFallback();
    }

    // Sort certificates to ensure default is first
    final sortedCerts = [...certificates];
    sortedCerts.sort((a, b) => b.isDefault ? 1 : -1); // Default first

    final defaultCert = sortedCerts.first;
    final alternateCert = sortedCerts.last;

    // Switch is ON when default certificate is selected
    final isDefaultSelected = selectedCertId == defaultCert.id;

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
              Text(
                ' *',
                style: AppTextStyles.bodyText.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  alternateCert.name,
                  style: AppTextStyles.bodyTextSmall.copyWith(
                    color: isDefaultSelected ? Colors.grey.shade600 : Colors.black,
                    fontWeight: isDefaultSelected ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: isDefaultSelected,
                onChanged: (value) {
                  final targetCert = value ? defaultCert : alternateCert;
                  onSelectionChanged(targetCert.id);
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              Expanded(
                child: Text(
                  defaultCert.name,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyTextSmall.copyWith(
                    color: isDefaultSelected ? Colors.black : Colors.grey.shade600,
                    fontWeight: isDefaultSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioFallback() {
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
              Text(
                ' *',
                style: AppTextStyles.bodyText.copyWith(
                  color: Colors.red,
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