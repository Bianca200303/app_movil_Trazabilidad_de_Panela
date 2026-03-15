import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/production_calculator.dart';

class SugarCaneDetailsStep extends StatelessWidget {
  final TextEditingController juiceQuantityController;
  final TextEditingController panelaQuantityController;
  final TextEditingController confitilloQuantityController;
  final TextEditingController extractionPercentageController;
  final TextEditingController cachazaPercentageController;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final double density;

  const SugarCaneDetailsStep({
    super.key,
    required this.juiceQuantityController,
    required this.panelaQuantityController,
    required this.confitilloQuantityController,
    required this.extractionPercentageController,
    required this.cachazaPercentageController,
    required this.onContinue,
    required this.onBack,
    this.density = ProductionCalculator.sugarCaneDensity,
  });

  ProductionCalculations? get _calculations {
    final juiceLiters = double.tryParse(juiceQuantityController.text);
    final panelaKg = double.tryParse(panelaQuantityController.text);
    final confitilloKg = double.tryParse(confitilloQuantityController.text);
    final extractionPercentage = double.tryParse(extractionPercentageController.text);
    final cachazaPercentage = double.tryParse(cachazaPercentageController.text);

    if (juiceLiters == null || juiceLiters <= 0 ||
        panelaKg == null || panelaKg < 0 ||
        confitilloKg == null || confitilloKg < 0 ||
        extractionPercentage == null || extractionPercentage <= 0 ||
        cachazaPercentage == null || cachazaPercentage < 0) {
      return null;
    }

    return ProductionCalculator.calculateAll(
      juiceLiters: juiceLiters,
      panelaKg: panelaKg,
      confitilloKg: confitilloKg,
      extractionPercentage: extractionPercentage,
      cachazaPercentage: cachazaPercentage,
      density: density,
    );
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
          'Datos de la caña de azúcar',
          style: AppTextStyles.sectionTitle,
        ),
        SizedBox(height: context.responsiveSpacing),
        Text(
          'Datos ingresados',
          style: AppTextStyles.bodyText.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.responsiveSpacing),
        Text(
          'Cantidad de caña procesada*',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: Text(
            '${(_calculations?.caneKg ?? 0.0).toStringAsFixed(2)} kg',
            style: AppTextStyles.bodyText,
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        Text(
          'Cantidad de jugo obtenido*',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: Text(
            juiceQuantityController.text.isNotEmpty
                ? '${juiceQuantityController.text} L'
                : '0 L',
            style: AppTextStyles.bodyText,
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        Text(
          'Cantidad de panela producida*',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: Text(
            panelaQuantityController.text.isNotEmpty
                ? '${panelaQuantityController.text} kg'
                : '0 kg',
            style: AppTextStyles.bodyText,
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        Text(
          'Cantidad de confitillo producido*',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: Text(
            confitilloQuantityController.text.isNotEmpty
                ? '${confitilloQuantityController.text} kg'
                : '0 kg',
            style: AppTextStyles.bodyText,
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        Text(
          '% de extracción*',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: Text(
            extractionPercentageController.text.isNotEmpty
                ? '${extractionPercentageController.text}%'
                : '0%',
            style: AppTextStyles.bodyText,
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        Text(
          '% de cachaza*',
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: Text(
            cachazaPercentageController.text.isNotEmpty
                ? '${cachazaPercentageController.text}%'
                : '0%',
            style: AppTextStyles.bodyText,
          ),
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        Divider(color: AppColors.border, thickness: 1),
        SizedBox(height: context.responsiveSpacing),
        Text(
          'Cálculos automáticos',
          style: AppTextStyles.bodyText.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.responsiveSpacing),
        _buildCalculatedField(
          context,
          'Peso de jugo',
          '${(_calculations?.juiceWeightKg ?? 0.0).toStringAsFixed(2)} kg',
          'Jugo extraído × Densidad de caña (${density.toStringAsFixed(2)})',
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        _buildCalculatedField(
          context,
          'Bagazo',
          '${(_calculations?.bagazoKg ?? 0.0).toStringAsFixed(2)} kg',
          'Caña ingresada × (1 – % extracción / 100)',
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        _buildCalculatedField(
          context,
          'Cachaza',
          '${(_calculations?.cachazaKg ?? 0.0).toStringAsFixed(2)} kg',
          'Peso de jugo × (% cachaza / 100)',
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        _buildCalculatedField(
          context,
          'Rendimiento',
          '${(_calculations?.rendimientoPercentage ?? 0.0).toStringAsFixed(2)}%',
          '(Kg panela / Litros jugo) × 100',
        ),
        SizedBox(height: context.responsiveSpacing * 0.75),
        _buildCalculatedField(
          context,
          'Pérdida de agua',
          '${(_calculations?.perdidaAguaKg ?? 0.0).toStringAsFixed(2)} kg',
          'Peso jugo – Panela – Confitillo – Cachaza',
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
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
                'Nota importante:',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Si algún valor calculado no cuadra, puede volver al paso anterior para corregir los datos ingresados.',
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

  Widget _buildCalculatedField(
    BuildContext context,
    String label,
    String value,
    String formula,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyText,
        ),
        SizedBox(height: context.responsiveSpacing * 0.25),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: Colors.green.shade200),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formula,
                style: AppTextStyles.captionText.copyWith(
                  color: Colors.green.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}