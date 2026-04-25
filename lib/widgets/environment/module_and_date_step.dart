import 'package:flutter/material.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/models/production_date_group.dart';
import 'package:panela_sys/services/environment_inspection_service.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/widgets/shared/production_date_selector.dart';
import 'package:panela_sys/core/screen_utils.dart';

class ModuleAndDateStep extends StatefulWidget {
  final List<CoopModule> availableModules;
  final bool isLoadingModules;
  final String? selectedModuleId;
  final DateTime? selectedDate;
  final Function(String?) onModuleChanged;
  final Function(DateTime) onDateSelected;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final bool isChecking;

  const ModuleAndDateStep({
    super.key,
    required this.availableModules,
    required this.isLoadingModules,
    required this.selectedModuleId,
    required this.selectedDate,
    required this.onModuleChanged,
    required this.onDateSelected,
    required this.onContinue,
    required this.onBack,
    this.isChecking = false,
  });

  @override
  State<ModuleAndDateStep> createState() => _ModuleAndDateStepState();
}

class _ModuleAndDateStepState extends State<ModuleAndDateStep> {
  final _service = EnvironmentInspectionService();

  late DateTime _filterFrom;
  late DateTime _filterTo;
  List<ProductionDateGroup> _productionDates = [];
  bool _isLoadingDates = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filterFrom = DateTime(now.year, now.month, now.day);
    _filterTo = now;
    if (widget.selectedModuleId != null) _loadDates();
  }

  @override
  void didUpdateWidget(ModuleAndDateStep old) {
    super.didUpdateWidget(old);
    if (old.selectedModuleId != widget.selectedModuleId) {
      setState(() => _productionDates = []);
      if (widget.selectedModuleId != null) _loadDates();
    }
  }

  Future<void> _loadDates() async {
    if (widget.selectedModuleId == null) return;
    setState(() => _isLoadingDates = true);
    try {
      final groups = await _service.getProductionDateGroups(
        widget.selectedModuleId!,
        _filterFrom,
        _filterTo,
      );
      if (mounted) {
        setState(() {
          _productionDates = groups;
          _isLoadingDates = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = widget.selectedModuleId != null &&
        widget.selectedDate != null &&
        !widget.isChecking;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBackButton(onPressed: widget.onBack),
        SizedBox(height: context.responsiveSpacing),
        const AppTitle(title: 'Datos de la inspección'),
        SizedBox(height: context.responsiveSpacing),
        FormSection(
          title: 'Módulo',
          children: [
            if (widget.isLoadingModules)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              AppDropdown<String>(
                label: 'Módulo',
                value: widget.selectedModuleId,
                options: widget.availableModules
                    .map((m) => DropdownOption(value: m.id, label: m.name))
                    .toList(),
                onChanged: widget.onModuleChanged,
                hintText: 'Selecciona un módulo',
              ),
          ],
        ),
        if (widget.selectedModuleId != null) ...[
          SizedBox(height: context.responsiveSpacing),
          FormSection(
            title: 'Fecha de producción',
            subtitle: 'Selecciona el día que quieres inspeccionar',
            children: [
              ProductionDateSelector(
                productionDates: _productionDates,
                isLoadingDates: _isLoadingDates,
                selectedDate: widget.selectedDate,
                onDateSelected: widget.onDateSelected,
                blocksAlreadyRecorded: true,
                onFilterChanged: (from, to) {
                  setState(() {
                    _filterFrom = from;
                    _filterTo = to;
                    _productionDates = [];
                  });
                  _loadDates();
                },
              ),
            ],
          ),
        ],
        SizedBox(height: context.responsiveSpacing),
        AppButton(
          text: widget.isChecking ? 'VERIFICANDO...' : 'CONTINUAR',
          type: AppButtonType.primary,
          onPressed: canContinue ? widget.onContinue : null,
        ),
      ],
    );
  }
}
