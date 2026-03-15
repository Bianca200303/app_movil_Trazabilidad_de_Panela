import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

/// Step widget for insect control (Step 2 of wizard)
class InsectControlStep extends StatefulWidget {
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
  State<InsectControlStep> createState() => _InsectControlStepState();
}

class _InsectControlStepState extends State<InsectControlStep> {
  static const _kCustom = '__custom__';

  late String _selectedProduct;
  bool _customProduct = false;

  late String _selectedUnit;
  bool _customUnit = false;

  @override
  void initState() {
    super.initState();
    // Product
    final productText = widget.productController.text;
    if (productText == 'Trampa de Luz' || productText.isEmpty) {
      _selectedProduct = 'Trampa de Luz';
      widget.productController.text = 'Trampa de Luz';
    } else {
      _selectedProduct = _kCustom;
      _customProduct = true;
    }
    // Unit
    final unitText = widget.unitController.text;
    if (unitText == 'lámina' || unitText == 'kg') {
      _selectedUnit = unitText;
    } else if (unitText.isEmpty) {
      _selectedUnit = 'lámina';
      widget.unitController.text = 'lámina';
    } else {
      _selectedUnit = _kCustom;
      _customUnit = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      children: [
        AppBackButton(onPressed: widget.onBack, isExpanded: true),

        SizedBox(height: context.responsiveSpacing),

        const AppTitle(title: 'Control de Insectos'),

        SizedBox(height: context.responsiveSpacing),

        // ── Producto empleado ──
        if (!_customProduct)
          AppDropdown<String>(
            label: 'Producto empleado',
            value: _selectedProduct,
            options: [
              DropdownOption(value: 'Trampa de Luz', label: 'Trampa de Luz'),
              DropdownOption(value: _kCustom, label: 'Escribir otro...'),
            ],
            onChanged: (val) {
              if (val == _kCustom) {
                setState(() {
                  _customProduct = true;
                  widget.productController.clear();
                });
              } else if (val != null) {
                setState(() {
                  _selectedProduct = val;
                  widget.productController.text = val;
                });
              }
            },
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Producto empleado',
                  controller: widget.productController,
                  hintText: 'Escribe el producto...',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.list_outlined),
                tooltip: 'Volver a opciones',
                onPressed: () {
                  setState(() {
                    _customProduct = false;
                    _selectedProduct = 'Trampa de Luz';
                    widget.productController.text = 'Trampa de Luz';
                  });
                },
              ),
            ],
          ),

        // ── Cantidad + Unidad ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'Cantidad',
                controller: widget.quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                hintText: 'Cantidad',
              ),
            ),
            SizedBox(width: context.responsiveSpacing / 2),
            Expanded(
              flex: 2,
              child: _customUnit
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Unidad',
                            controller: widget.unitController,
                            hintText: 'Ej: unidades',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.list_outlined),
                          tooltip: 'Volver a opciones',
                          onPressed: () {
                            setState(() {
                              _customUnit = false;
                              _selectedUnit = 'lámina';
                              widget.unitController.text = 'lámina';
                            });
                          },
                        ),
                      ],
                    )
                  : AppDropdown<String>(
                      label: 'Unidad',
                      value: _selectedUnit,
                      options: [
                        DropdownOption(value: 'lámina', label: 'lámina'),
                        DropdownOption(value: 'kg', label: 'kg'),
                        DropdownOption(value: _kCustom, label: 'Otro...'),
                      ],
                      onChanged: (val) {
                        if (val == _kCustom) {
                          setState(() {
                            _customUnit = true;
                            widget.unitController.clear();
                          });
                        } else if (val != null) {
                          setState(() {
                            _selectedUnit = val;
                            widget.unitController.text = val;
                          });
                        }
                      },
                    ),
            ),
          ],
        ),

        SizedBox(height: context.responsiveSpacing),

        Text(
          'Conteo de insectos',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        SizedBox(height: context.responsiveSpacing / 2),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Moscas',
                controller: widget.fliesController,
                keyboardType: TextInputType.number,
                hintText: '0',
              ),
            ),
            SizedBox(width: context.responsiveSpacing / 2),
            Expanded(
              child: AppTextField(
                label: 'Abejas',
                controller: widget.beesController,
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
                controller: widget.antsController,
                keyboardType: TextInputType.number,
                hintText: '0',
              ),
            ),
            SizedBox(width: context.responsiveSpacing / 2),
            Expanded(
              child: AppTextField(
                label: 'Cucarachas',
                controller: widget.cockroachesController,
                keyboardType: TextInputType.number,
                hintText: '0',
              ),
            ),
          ],
        ),

        SizedBox(height: context.responsiveSpacing),

        AppTextField(
          label: 'Área/Zona',
          controller: widget.areaController,
          hintText: 'Ej: TT - TEA',
        ),

        AppTextField(
          label: 'Observaciones (opcional)',
          controller: widget.observationsController,
          maxLines: 3,
          hintText: 'Notas sobre el control de insectos...',
        ),

        SizedBox(height: context.responsiveSpacing * 1.5),

        AppButton(
          text: 'Continuar',
          type: AppButtonType.primary,
          onPressed: widget.onContinue,
          isExpanded: true,
        ),
      ],
    );
  }
}
