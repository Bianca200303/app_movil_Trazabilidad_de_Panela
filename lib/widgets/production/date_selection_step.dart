import 'package:flutter/material.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/production/production_step_header.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';

class DateSelectionStep extends StatefulWidget {
  final TextEditingController harvestDateController;
  final TextEditingController processingDateController;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const DateSelectionStep({
    super.key,
    required this.harvestDateController,
    required this.processingDateController,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<DateSelectionStep> createState() => _DateSelectionStepState();
}

class _DateSelectionStepState extends State<DateSelectionStep> {
  @override
  void initState() {
    super.initState();
    _fillSuggestedDates();
    widget.processingDateController.addListener(_onProcessingDateChanged);
  }

  @override
  void dispose() {
    widget.processingDateController.removeListener(_onProcessingDateChanged);
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
    return widget.harvestDateController.text.isNotEmpty &&
           widget.processingDateController.text.isNotEmpty;
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
    }
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
          controller: widget.harvestDateController,
          label: 'Seleccione la fecha de corte',
          readOnly: true,
          onTap: () => _selectDate(widget.harvestDateController),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(widget.harvestDateController),
          ),
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
        SizedBox(height: context.responsiveSpacing * 1.5),
        AppButton(
          text: 'CONTINUAR',
          onPressed: _canContinue ? widget.onContinue : null,
        ),
      ],
    );
  }
}