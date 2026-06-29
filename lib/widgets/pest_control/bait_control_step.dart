import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/models/pest_control.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/pest_control/bait_station_list_item.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

/// Step widget for bait control (Step 1 of wizard)
class BaitControlStep extends StatefulWidget {
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final List<BaitStation> baitStations;
  final Function(List<BaitStation>) onBaitStationsChanged;
  final TextEditingController observationsController;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const BaitControlStep({
    super.key,
    required this.productController,
    required this.quantityController,
    required this.unitController,
    required this.baitStations,
    required this.onBaitStationsChanged,
    required this.observationsController,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<BaitControlStep> createState() => _BaitControlStepState();
}

class _BaitControlStepState extends State<BaitControlStep> {
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
    if (productText == 'Panela' || productText.isEmpty) {
      _selectedProduct = 'Panela';
      widget.productController.text = 'Panela';
    } else {
      _selectedProduct = _kCustom;
      _customProduct = true;
    }
    // Unit
    final unitText = widget.unitController.text;
    if (unitText == 'gr' || unitText == 'kg') {
      _selectedUnit = unitText;
    } else {
      _selectedUnit = unitText.isEmpty ? 'gr' : _kCustom;
      if (_selectedUnit == _kCustom) _customUnit = true;
      if (unitText.isEmpty) widget.unitController.text = 'gr';
    }
  }

  List<Widget> _buildBaitStationsList() {
    return widget.baitStations.asMap().entries.map((entry) {
      final index = entry.key;
      final station = entry.value;
      final isFirst = index == 0;

      return BaitStationListItem(
        key: ValueKey('station_${station.stationNumber}'),
        stationNumber: station.stationNumber,
        ate: station.ate,
        onAteChanged: (value) => _updateStation(index, value),
        onRemove: !isFirst ? () => _removeStation(index) : null,
      );
    }).toList();
  }

  void _addStation() {
    final nextNumber = widget.baitStations.length + 1;
    final newStation = BaitStation(stationNumber: nextNumber, ate: false);
    setState(() => widget.baitStations.add(newStation));
    widget.onBaitStationsChanged(widget.baitStations);
  }

  void _removeStation(int index) {
    setState(() {
      widget.baitStations.removeAt(index);
      for (int i = 0; i < widget.baitStations.length; i++) {
        widget.baitStations[i] = BaitStation(
          stationNumber: i + 1,
          ate: widget.baitStations[i].ate,
        );
      }
    });
    widget.onBaitStationsChanged(widget.baitStations);
  }

  void _updateStation(int index, bool ate) {
    setState(() {
      widget.baitStations[index] = BaitStation(
        stationNumber: widget.baitStations[index].stationNumber,
        ate: ate,
      );
    });
    widget.onBaitStationsChanged(widget.baitStations);
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      children: [
        AppBackButton(onPressed: widget.onBack, isExpanded: true),

        SizedBox(height: context.responsiveSpacing),

        const AppTitle(title: 'Control de Cebos'),

        SizedBox(height: context.responsiveSpacing),

        // ── Producto empleado ──
        if (!_customProduct)
          AppDropdown<String>(
            label: 'Producto empleado',
            value: _selectedProduct,
            options: [
              DropdownOption(value: 'Panela', label: 'Panela'),
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
                    _selectedProduct = 'Panela';
                    widget.productController.text = 'Panela';
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
                hintText: 'Ej: 04',
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
                              _selectedUnit = 'gr';
                              widget.unitController.text = 'gr';
                            });
                          },
                        ),
                      ],
                    )
                  : AppDropdown<String>(
                      label: 'Unidad',
                      value: _selectedUnit,
                      options: [
                        DropdownOption(value: 'gr', label: 'gr'),
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
          'Estaciones de cebo',
          style: AppTextStyles.sectionLabel,
        ),

        SizedBox(height: context.responsiveSpacing / 2),

        ..._buildBaitStationsList(),

        SizedBox(height: context.responsiveSpacing / 2),

        OutlinedButton.icon(
          onPressed: _addStation,
          icon: const Icon(Icons.add),
          label: const Text('Agregar estación'),
        ),

        SizedBox(height: context.responsiveSpacing),

        AppTextField(
          label: 'Observaciones generales (opcional)',
          controller: widget.observationsController,
          maxLines: 3,
          hintText: 'Observaciones para todas las estaciones...',
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
