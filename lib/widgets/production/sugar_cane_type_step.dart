import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/widgets/production/exclusive_radio_group.dart';
import 'package:panela_sys/widgets/production/binary_certificate_switch.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/models/batch_cert.dart';

class SugarCaneTypeStep extends StatelessWidget {
  final List<BatchCert> certificates;
  final Map<String, bool> selectedCertificates;
  final Function(String certId, bool selected) onSelectionChanged;
  final Function(String groupName, String certId) onExclusiveSelectionChanged;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const SugarCaneTypeStep({
    super.key,
    required this.certificates,
    required this.selectedCertificates,
    required this.onSelectionChanged,
    required this.onExclusiveSelectionChanged,
    this.isLoading = false,
    this.errorMessage,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      children: [
        ProductionStepHeader(
          title: 'Registro de producción',
          onBack: onBack,
        ),
        SizedBox(height: context.responsiveSpacing * 0.5),
        Text(
          'Datos de la caña de azúcar',
          style: AppTextStyles.sectionTitle,
        ),
        SizedBox(height: context.responsiveSpacing),
        Text(
          'Seleccione los certificados de la caña',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.5),
        ..._buildCertificateSelection(),
        SizedBox(height: context.responsiveSpacing * 1.5),
        AppButton(
          text: 'CONTINUAR',
          onPressed: onContinue,
        ),
      ],
    );
  }

  List<Widget> _buildCertificateSelection() {
    if (isLoading) {
      return [
        const Center(
          child: CircularProgressIndicator(),
        ),
      ];
    }

    if (errorMessage != null) {
      return [
        Center(
          child: Text(
            errorMessage!,
            style: AppTextStyles.bodyText.copyWith(
              color: Colors.red,
            ),
          ),
        ),
      ];
    }

    if (certificates.isEmpty) {
      return [
        Center(
          child: Text(
            'No hay certificados disponibles',
            style: AppTextStyles.bodyText,
          ),
        ),
      ];
    }

    // Group certificates by exclusion group ID
    final groupedCertificates = <String?, List<BatchCert>>{};
    for (final cert in certificates) {
      groupedCertificates.putIfAbsent(cert.exclusionGroupId, () => []).add(cert);
    }

    final widgets = <Widget>[];

    // Handle exclusive groups (with radio buttons)
    for (final entry in groupedCertificates.entries) {
      if (entry.key != null) { // Exclusion group exists
        final groupName = entry.key!;
        final groupCertificates = entry.value;

        // Find selected certificate in this group
        String? selectedInGroup;
        for (final cert in groupCertificates) {
          if (selectedCertificates[cert.id] == true) {
            selectedInGroup = cert.id;
            break;
          }
        }

        // Use display name from the first certificate's exclusion group
        final displayName = groupCertificates.first.exclusionGroup?.displayName ?? _getGroupLabel(groupName);

        // Use switch for binary groups (exactly 2 certificates), radio buttons for others
        if (groupCertificates.length == 2) {
          widgets.addAll([
            BinaryCertificateSwitch(
              groupName: groupName,
              certificates: groupCertificates,
              selectedCertId: selectedInGroup,
              onSelectionChanged: (certId) => onExclusiveSelectionChanged(groupName, certId),
              label: displayName,
            ),
            const SizedBox(height: 16),
          ]);
        } else {
          widgets.addAll([
            ExclusiveRadioGroup(
              groupName: groupName,
              certificates: groupCertificates,
              selectedCertId: selectedInGroup,
              onSelectionChanged: (certId) => onExclusiveSelectionChanged(groupName, certId),
              label: displayName,
            ),
            const SizedBox(height: 16),
          ]);
        }
      }
    }

    // Handle independent certificates (with checkboxes)
    final independentCertificates = groupedCertificates[null];
    if (independentCertificates != null && independentCertificates.isNotEmpty) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificados adicionales (opcionales)',
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...independentCertificates.map((cert) {
              final isSelected = selectedCertificates[cert.id] ?? false;
              return CheckboxListTile(
                title: Text(cert.name, style: AppTextStyles.bodyText),
                value: isSelected,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onChanged: (value) {
                  onSelectionChanged(cert.id, value ?? false);
                },
              );
            }),
          ],
        ),
      );
    }

    return widgets;
  }

  String _getGroupLabel(String groupName) {
    switch (groupName) {
      case 'production_type':
        return 'Tipo de producción';
      default:
        return 'Certificados';
    }
  }
}