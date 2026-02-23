import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

/// Step widget for insect control (Step 2 of wizard)
///
/// Manages a SINGLE insect record with:
/// - Product information (name, quantity, unit)
/// - Insect counts (flies, bees, ants, cockroaches)
/// - Area and observations
/// - Navigation buttons
class InsectControlStep extends StatelessWidget {
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController fliesController;
  final TextEditingController beesController;
  final TextEditingController antsController;
  final TextEditingController cockroachesController;
  final TextEditingController areaController;
  final TextEditingController observationsController;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const InsectControlStep({
    super.key,
    required this.productController,
    required this.quantityController,
    required this.unitController,
    required this.fliesController,
    required this.beesController,
    required this.antsController,
    required this.cockroachesController,
    required this.areaController,
    required this.observationsController,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      children: [
        // Back button
        AppBackButton(
          onPressed: onBack,
          isExpanded: true,
        ),

        SizedBox(height: context.responsiveSpacing),

        // Title
        const AppTitle(title: 'Control de Insectos'),

        SizedBox(height: context.responsiveSpacing),

        // Product information
        AppTextField(
          label: 'Producto empleado',
          controller: productController,
          hintText: 'Ej: Trampa luz',
        ),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'Cantidad',
                controller: quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                hintText: 'Cantidad',
              ),
            ),
            SizedBox(width: context.responsiveSpacing / 2),
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'Unidad',
                controller: unitController,
                hintText: 'Ej: láminas adhesivas',
              ),
            ),
          ],
        ),

        SizedBox(height: context.responsiveSpacing),

        // Insect counts section title
        Text(
          'Conteo de insectos',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        SizedBox(height: context.responsiveSpacing / 2),

        // Insect count fields in 2-column grid
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Moscas',
                controller: fliesController,
                keyboardType: TextInputType.number,
                hintText: '0',
              ),
            ),
            SizedBox(width: context.responsiveSpacing / 2),
            Expanded(
              child: AppTextField(
                label: 'Abejas',
                controller: beesController,
                keyboardType: TextInputType.number,
                hintText: '0',
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Hormigas',
                controller: antsController,
                keyboardType: TextInputType.number,
                hintText: '0',
              ),
            ),
            SizedBox(width: context.responsiveSpacing / 2),
            Expanded(
              child: AppTextField(
                label: 'Cucarachas',
                controller: cockroachesController,
                keyboardType: TextInputType.number,
                hintText: '0',
              ),
            ),
          ],
        ),

        SizedBox(height: context.responsiveSpacing),

        // Area field (required)
        AppTextField(
          label: 'Área/Zona',
          controller: areaController,
          hintText: 'Ej: TT - TEA',
        ),

        // Observations (optional)
        AppTextField(
          label: 'Observaciones (opcional)',
          controller: observationsController,
          maxLines: 3,
          hintText: 'Notas sobre el control de insectos...',
        ),

        SizedBox(height: context.responsiveSpacing * 1.5),

        // Continue button
        AppButton(
          text: 'Continuar',
          type: AppButtonType.primary,
          onPressed: onContinue,
          isExpanded: true,
        ),
      ],
    );
  }
}
