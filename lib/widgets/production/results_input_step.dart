import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/production_calculator.dart';
import 'package:panela_sys/models/producer.dart';
import 'package:panela_sys/models/plot.dart';

class ResultsInputStep extends StatelessWidget {
  final TextEditingController juiceQuantityController;
  final TextEditingController panelaQuantityController;
  final TextEditingController confitilloQuantityController;
  final TextEditingController extractionPercentageController;
  final TextEditingController cachazaPercentageController;
  final Producer? selectedProducer;
  final Plot? selectedPlot;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const ResultsInputStep({
    super.key,
    required this.juiceQuantityController,
    required this.panelaQuantityController,
    required this.confitilloQuantityController,
    required this.extractionPercentageController,
    required this.cachazaPercentageController,
    this.selectedProducer,
    this.selectedPlot,
    required this.onContinue,
    required this.onBack,
  });

  String _getDefaultHintText(String fieldType) {
    if (fieldType == 'extraction') {
      // Priority: plot -> producer -> system
      if (selectedPlot?.defaultExtractionPercentage != null) {
        return 'Valor por defecto (parcela): ${selectedPlot!.defaultExtractionPercentage}%';
      } else if (selectedProducer != null) {
        return 'Valor por defecto (productor): ${selectedProducer!.defaultExtractionPercentage}%';
      } else {
        return 'Valor por defecto (sistema): 62.5%';
      }
    } else {
      // cachaza
      if (selectedPlot?.defaultCachazaPercentage != null) {
        return 'Valor por defecto (parcela): ${selectedPlot!.defaultCachazaPercentage}%';
      } else if (selectedProducer != null) {
        return 'Valor por defecto (productor): ${selectedProducer!.defaultCachazaPercentage}%';
      } else {
        return 'Valor por defecto (sistema): 2.5%';
      }
    }
  }

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
          'Resultados',
          style: AppTextStyles.sectionTitle,
        ),
        SizedBox(height: context.responsiveSpacing),
        AppTextField(
          controller: juiceQuantityController,
          label: 'Ingrese la cantidad de jugo obtenido (L)',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: context.responsiveSpacing),
        AppTextField(
          controller: panelaQuantityController,
          label: 'Ingrese la cantidad de panela producida (kg)',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: context.responsiveSpacing),
        AppTextField(
          controller: confitilloQuantityController,
          label: 'Ingrese la cantidad de confitillo producido (kg)',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: context.responsiveSpacing),
        Text(
          '% de extracción',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                extractionPercentageController.text.isNotEmpty
                    ? '${extractionPercentageController.text}%'
                    : '0%',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getDefaultHintText('extraction'),
                style: AppTextStyles.captionText.copyWith(
                  color: Colors.green.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        Text(
          '% de cachaza',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cachazaPercentageController.text.isNotEmpty
                    ? '${cachazaPercentageController.text}%'
                    : '0%',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getDefaultHintText('cachaza'),
                style: AppTextStyles.captionText.copyWith(
                  color: Colors.green.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.responsiveSpacing),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Constantes del proceso:',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Densidad de caña: ${ProductionCalculator.sugarCaneDensityDisplay}',
                style: AppTextStyles.bodyTextSecondary.copyWith(
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        AppButton(
          text: 'CONTINUAR',
          onPressed: onContinue,
        ),
      ],
    );
  }
}