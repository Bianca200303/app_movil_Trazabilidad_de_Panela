import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';

class DateSelectionStep extends StatefulWidget {
  final TextEditingController harvestDateController;
  final TextEditingController processingDateController;
  final List<DateTime> additionalHarvestDates;
  final ValueChanged<List<DateTime>> onAdditionalHarvestDatesChanged;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const DateSelectionStep({
    super.key,
    required this.harvestDateController,
    required this.processingDateController,
    required this.additionalHarvestDates,
    required this.onAdditionalHarvestDatesChanged,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<DateSelectionStep> createState() => _DateSelectionStepState();
}

class _DateSelectionStepState extends State<DateSelectionStep> {
  late List<TextEditingController> _additionalControllers;

  @override
  void initState() {
    super.initState();
    _fillSuggestedDates();
    widget.processingDateController.addListener(_onProcessingDateChanged);
    _additionalControllers = widget.additionalHarvestDates
        .map((date) => TextEditingController(text: AppDateUtils.formatDDMMYYYY(date)))
        .toList();
  }

  @override
  void dispose() {
    widget.processingDateController.removeListener(_onProcessingDateChanged);
    for (final controller in _additionalControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fillSuggestedDates() {
    // Only fill if fields are empty
    if (widget.harvestDateController.text.isEmpty && widget.processingDateController.text.isEmpty) {
      final now = DateTime.now();
      final harvestDate = now.subtract(const Duration(days: 2)); // 2 days ago
      final processDate = now; // Today

      setState(() {
        widget.harvestDateController.text = AppDateUtils.formatDDMMYYYY(harvestDate);
        widget.processingDateController.text = AppDateUtils.formatDDMMYYYY(processDate);
      });
    }
  }

  void _onProcessingDateChanged() {
    if (widget.processingDateController.text.isEmpty) return;

    final processDate = AppDateUtils.parseDDMMYYYY(widget.processingDateController.text);
    if (processDate != null) {
      final harvestDate = processDate.subtract(const Duration(days: 2));
      setState(() {
        widget.harvestDateController.text = AppDateUtils.formatDDMMYYYY(harvestDate);
      });
    }
  }

  bool get _canContinue {
    if (widget.harvestDateController.text.isEmpty ||
        widget.processingDateController.text.isEmpty) {
      return false;
    }
    if (_additionalControllers.any((c) => c.text.isEmpty)) {
      return false;
    }
    return _dateOrderError == null;
  }

  // Todas las fechas de corte (principal + adicionales) deben ser iguales o
  // anteriores a la fecha de proceso.
  String? get _dateOrderError {
    final process = AppDateUtils.parseDDMMYYYY(widget.processingDateController.text);
    if (process == null) return null;

    final harvest = AppDateUtils.parseDDMMYYYY(widget.harvestDateController.text);
    if (harvest != null && harvest.isAfter(process)) {
      return 'La fecha de corte no puede ser posterior a la fecha de proceso.';
    }

    for (final controller in _additionalControllers) {
      final date = AppDateUtils.parseDDMMYYYY(controller.text);
      if (date != null && date.isAfter(process)) {
        return 'La fecha de corte no puede ser posterior a la fecha de proceso.';
      }
    }
    return null;
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'PE'),
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        controller.text = AppDateUtils.formatDDMMYYYY(picked);
      });
      _notifyAdditionalHarvestDatesChanged();
    }
  }

  void _addAdditionalHarvestDate() {
    setState(() {
      _additionalControllers.add(TextEditingController());
    });
  }

  void _removeAdditionalHarvestDate(int index) {
    setState(() {
      _additionalControllers[index].dispose();
      _additionalControllers.removeAt(index);
    });
    _notifyAdditionalHarvestDatesChanged();
  }

  void _notifyAdditionalHarvestDatesChanged() {
    final dates = _additionalControllers
        .map((c) => AppDateUtils.parseDDMMYYYY(c.text))
        .where((d) => d != null)
        .map((d) => d!)
        .toList();
    widget.onAdditionalHarvestDatesChanged(dates);
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
          'Fechas',
          style: AppTextStyles.sectionTitle,
        ),
        SizedBox(height: context.responsiveSpacing),
        AppTextField(
          controller: widget.processingDateController,
          label: 'Seleccione la fecha de proceso',
          readOnly: true,
          onTap: () => _selectDate(widget.processingDateController),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(widget.processingDateController),
          ),
        ),
        SizedBox(height: context.responsiveSpacing),
        AppTextField(
          controller: widget.harvestDateController,
          label: 'Seleccione la fecha de corte',
          readOnly: true,
          onTap: () => _selectDate(widget.harvestDateController),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(widget.harvestDateController),
          ),
        ),
        ..._buildAdditionalHarvestDateFields(),
        SizedBox(height: context.responsiveSpacing * 0.5),
        OutlinedButton.icon(
          onPressed: _addAdditionalHarvestDate,
          icon: const Icon(Icons.add),
          label: const Text('Agregar otra fecha de corte'),
        ),
        if (_dateOrderError != null) ...[
          SizedBox(height: context.responsiveSpacing),
          Text(
            _dateOrderError!,
            style: AppTextStyles.bodyText.copyWith(color: AppColors.error),
          ),
        ],
        SizedBox(height: context.responsiveSpacing * 1.5),
        AppButton(
          text: 'CONTINUAR',
          onPressed: _canContinue ? widget.onContinue : null,
        ),
      ],
    );
  }

  List<Widget> _buildAdditionalHarvestDateFields() {
    return _additionalControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      return Padding(
        padding: EdgeInsets.only(top: context.responsiveSpacing),
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: controller,
                label: 'Fecha de corte adicional ${index + 1}',
                readOnly: true,
                onTap: () => _selectDate(controller),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(controller),
                ),
              ),
            ),
            SizedBox(width: context.responsiveSpacing * 0.5),
            IconButton(
              onPressed: () => _removeAdditionalHarvestDate(index),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar fecha de corte',
            ),
          ],
        ),
      );
    }).toList();
  }
}
