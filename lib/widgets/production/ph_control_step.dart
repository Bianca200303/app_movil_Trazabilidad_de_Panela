import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

class PhControlStep extends StatefulWidget {
  final TextEditingController initialPHController;
  final TextEditingController regulatorQuantityController;
  final TextEditingController regulatorUnitController;
  final TextEditingController finalPHController;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const PhControlStep({
    super.key,
    required this.initialPHController,
    required this.regulatorQuantityController,
    required this.regulatorUnitController,
    required this.finalPHController,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<PhControlStep> createState() => _PhControlStepState();
}

class _PhControlStepState extends State<PhControlStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _validatePH(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }
    
    final double? ph = double.tryParse(value);
    if (ph == null) {
      return 'Ingrese un número válido';
    }
    
    if (ph < 0 || ph > 14) {
      return 'El pH debe estar entre 0 y 14';
    }
    
    return null;
  }

  String? _validateRegulatorQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }

    final double? quantity = double.tryParse(value);
    if (quantity == null) {
      return 'Ingrese un número válido';
    }

    if (quantity < 0) {
      return 'La cantidad no puede ser negativa';
    }

    return null;
  }

  String? _validateRegulatorUnit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Seleccione una unidad';
    }
    return null;
  }

  void _handleContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FormSection(
        children: [
          ProductionStepHeader(
            title: 'Registro de producción',
            onBack: widget.onBack,
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),
          Text(
            'Control de pH',
            style: AppTextStyles.sectionTitle,
          ),
          SizedBox(height: context.responsiveSpacing),
          AppTextField(
            controller: widget.initialPHController,
            label: 'Ingrese el pH inicial del jugo',
            helperText: 'Rango válido: 0.0 - 14.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validatePH,
          ),
          SizedBox(height: context.responsiveSpacing),
          AppTextField(
            controller: widget.regulatorQuantityController,
            label: 'Ingrese la cantidad de regulador de pH utilizado',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validateRegulatorQuantity,
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),
          FormField<String>(
            initialValue: widget.regulatorUnitController.text.isEmpty ? null : widget.regulatorUnitController.text,
            validator: _validateRegulatorUnit,
            onSaved: (value) {
              if (value != null) {
                widget.regulatorUnitController.text = value;
              }
            },
            builder: (FormFieldState<String> state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: context.responsiveSpacing * 0.5,
                    children: ['gr', 'mL', 'L'].map((unit) {
                      final isSelected = widget.regulatorUnitController.text == unit;
                      return FilterChip(
                        label: Text(unit),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            widget.regulatorUnitController.text = selected ? unit : '';
                            state.didChange(selected ? unit : null);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (state.hasError)
                    Padding(
                      padding: EdgeInsets.only(top: context.responsiveSpacing * 0.25),
                      child: Text(
                        state.errorText ?? '',
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(height: context.responsiveSpacing),
          AppTextField(
            controller: widget.finalPHController,
            label: 'Ingrese el pH final del jugo',
            helperText: 'Rango válido: 0.0 - 14.0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: _validatePH,
          ),
          SizedBox(height: context.responsiveSpacing * 1.5),
          AppButton(
            text: 'CONTINUAR',
            onPressed: _handleContinue,
          ),
        ],
      ),
    );
  }
}