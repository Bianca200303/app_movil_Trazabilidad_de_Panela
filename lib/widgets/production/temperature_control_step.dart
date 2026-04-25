import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class TemperatureControlStep extends StatefulWidget {
  final List<double> temperatures;
  final Function(List<double>) onTemperaturesChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const TemperatureControlStep({
    super.key,
    required this.temperatures,
    required this.onTemperaturesChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<TemperatureControlStep> createState() => _TemperatureControlStepState();
}

class _TemperatureControlStepState extends State<TemperatureControlStep> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    final initial = widget.temperatures.isEmpty ? <double>[0.0] : widget.temperatures;
    _controllers = initial
        .map((temp) => TextEditingController(
              text: temp == 0.0 ? '' : temp.toString(),
            ))
        .toList();
    _focusNodes = List.generate(initial.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      children: [
        ProductionStepHeader(
          title: 'Registro de producción',
          onBack: widget.onBack,
        ),
        SizedBox(height: context.responsiveSpacing * 0.5),
        Text(
          'Control de temperatura en la paila punteadora',
          style: AppTextStyles.sectionTitle,
        ),
        SizedBox(height: context.responsiveSpacing),
        ..._buildTemperatureFields(),
        SizedBox(height: context.responsiveSpacing),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addTemperature,
                icon: const Icon(Icons.add),
                label: const Text('Agregar temperatura'),
              ),
            ),
          ],
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        AppButton(
          text: 'CONTINUAR',
          onPressed: widget.onContinue,
        ),
      ],
    );
  }

  List<Widget> _buildTemperatureFields() {
    final lastIndex = _controllers.length - 1;
    return _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      final isFirst = index == 0;
      final isLast = index == lastIndex;

      return Padding(
        padding: EdgeInsets.only(bottom: context.responsiveSpacing * 0.5),
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                focusNode: _focusNodes[index],
                textInputAction:
                    isLast ? TextInputAction.done : TextInputAction.next,
                label: 'Temperatura ${index + 1}',
                keyboardType: TextInputType.number,
                suffixText: '°C',
                onChanged: (value) => _updateTemperature(index, value),
              ),
            ),
            if (!isFirst) ...[
              SizedBox(width: context.responsiveSpacing * 0.5),
              IconButton(
                onPressed: () => _removeTemperature(index),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar temperatura',
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  void _addTemperature() {
    setState(() {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    });
    // Move cursor to the newly added field after the frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.last.requestFocus();
    });
    _notifyTemperaturesChanged();
  }

  void _removeTemperature(int index) {
    if (_controllers.length > 1) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
        _focusNodes[index].dispose();
        _focusNodes.removeAt(index);
      });
      _notifyTemperaturesChanged();
    }
  }

  void _updateTemperature(int index, String value) {
    _notifyTemperaturesChanged();
  }

  void _notifyTemperaturesChanged() {
    final temperatures = _controllers
        .map((c) => double.tryParse(c.text.trim().replaceAll(',', '.')))
        .where((v) => v != null && v > 0)
        .map((v) => v!)
        .toList();

    widget.onTemperaturesChanged(temperatures);
  }
}