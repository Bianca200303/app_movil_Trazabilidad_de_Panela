import 'package:flutter/material.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/services/environment_inspection_service.dart';
import 'package:panela_sys/widgets/common/app_back_button.dart';
import 'package:panela_sys/widgets/common/app_title.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/utils/date_utils.dart';

class ModuleAndDateStep extends StatefulWidget {
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

  final List<CoopModule> availableModules;
  final bool isLoadingModules;
  final String? selectedModuleId;
  final DateTime? selectedDate;
  final Function(String?) onModuleChanged;
  final Function(DateTime) onDateSelected;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final bool isChecking;

  @override
  State<ModuleAndDateStep> createState() => _ModuleAndDateStepState();
}

class _ModuleAndDateStepState extends State<ModuleAndDateStep> {
  final _service = EnvironmentInspectionService();
  bool _hadProduction = false;
  bool _isCheckingDate = false;

  @override
  void didUpdateWidget(ModuleAndDateStep old) {
    super.didUpdateWidget(old);
    if (old.selectedModuleId != widget.selectedModuleId) {
      setState(() { _hadProduction = false; });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      locale: const Locale('es'),
    );
    if (picked == null || !mounted) return;
    widget.onDateSelected(picked);
    if (widget.selectedModuleId == null) return;
    setState(() => _isCheckingDate = true);
    final hasProd = await _service.hasProductionOnDate(widget.selectedModuleId!, picked);
    if (mounted) setState(() { _hadProduction = hasProd; _isCheckingDate = false; });
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = widget.selectedModuleId != null &&
        widget.selectedDate != null &&
        !widget.isChecking &&
        !_isCheckingDate;

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
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else
              AppDropdown<String>(
                label: null,
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
            title: 'Fecha de inspección',
            subtitle: 'Selecciona cualquier fecha',
            children: [
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: Container(
                  padding: context.responsivePadding,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: AppColors.primary),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Expanded(
                        child: Text(
                          widget.selectedDate != null
                              ? AppDateUtils.formatDDMMYYYY(widget.selectedDate!)
                              : 'Selecciona una fecha',
                          style: AppTextStyles.bodyText.copyWith(
                            color: widget.selectedDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              if (_isCheckingDate) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                const Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))),
              ] else if (widget.selectedDate != null && _hadProduction) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.agriculture_outlined, size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Text(
                        'Día con producción registrada',
                        style: AppTextStyles.captionText.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
