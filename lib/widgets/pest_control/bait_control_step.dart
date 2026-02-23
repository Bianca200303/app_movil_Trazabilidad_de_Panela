import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/pest_control.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/pest_control/bait_station_list_item.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';

/// Step widget for bait control (Step 1 of wizard)
///
/// Manages:
/// - Product information (name, quantity, unit)
/// - Dynamic list of bait stations
/// - General observations for all stations
/// - Navigation buttons
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
  /// Build dynamic list of bait stations
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

  /// Add a new bait station
  void _addStation() {
    final nextNumber = widget.baitStations.length + 1;
    final newStation = BaitStation(stationNumber: nextNumber, ate: false);

    setState(() {
      widget.baitStations.add(newStation);
    });

    widget.onBaitStationsChanged(widget.baitStations);
  }

  /// Remove a bait station at index
  void _removeStation(int index) {
    setState(() {
      widget.baitStations.removeAt(index);

      // Renumber stations to maintain sequential order
      for (int i = 0; i < widget.baitStations.length; i++) {
        widget.baitStations[i] = BaitStation(
          stationNumber: i + 1,
          ate: widget.baitStations[i].ate,
        );
      }
    });

    widget.onBaitStationsChanged(widget.baitStations);
  }

  /// Update station ate status
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
        // Back button
        AppBackButton(
          onPressed: widget.onBack,
          isExpanded: true,
        ),

        SizedBox(height: context.responsiveSpacing),

        // Title
        const AppTitle(title: 'Control de Cebos'),

        SizedBox(height: context.responsiveSpacing),

        // Product information
        AppTextField(
          label: 'Producto empleado',
          controller: widget.productController,
          hintText: 'Ej: Panela',
        ),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'Cantidad',
                controller: widget.quantityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hintText: 'Ej: 04',
              ),
            ),
            SizedBox(width: context.responsiveSpacing / 2),
            Expanded(
              flex: 1,
              child: AppTextField(
                label: 'Unidad',
                controller: widget.unitController,
                hintText: 'Ej: gr',
              ),
            ),
          ],
        ),

        SizedBox(height: context.responsiveSpacing),

        // Bait stations section title
        Text(
          'Estaciones de cebo',
          style: Theme.of(context).textTheme.titleMedium,
        ),

        SizedBox(height: context.responsiveSpacing / 2),

        // List of bait stations
        ..._buildBaitStationsList(),

        SizedBox(height: context.responsiveSpacing / 2),

        // Add station button
        OutlinedButton.icon(
          onPressed: _addStation,
          icon: const Icon(Icons.add),
          label: const Text('Agregar estación'),
        ),

        SizedBox(height: context.responsiveSpacing),

        // General observations
        AppTextField(
          label: 'Observaciones generales (opcional)',
          controller: widget.observationsController,
          maxLines: 3,
          hintText: 'Observaciones para todas las estaciones...',
        ),

        SizedBox(height: context.responsiveSpacing * 1.5),

        // Continue button
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
