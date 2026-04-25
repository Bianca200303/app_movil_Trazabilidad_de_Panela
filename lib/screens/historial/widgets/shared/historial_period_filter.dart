import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';

enum HistorialPeriodo { hoy, esteMes, rango }

/// Devuelve el rango (from, to) para un período dado.
(DateTime, DateTime) historialPeriodoRange(
  HistorialPeriodo periodo, {
  DateTime? customFrom,
  DateTime? customTo,
}) {
  final now = DateTime.now();
  switch (periodo) {
    case HistorialPeriodo.hoy:
      return (DateTime(now.year, now.month, now.day), now);
    case HistorialPeriodo.esteMes:
      return (DateTime(now.year, now.month, 1), now);
    case HistorialPeriodo.rango:
      return (
        customFrom ?? DateTime(now.year, now.month, 1),
        customTo ?? now,
      );
  }
}

/// Widget de filtro de período reutilizable.
/// Chips: Hoy / Este mes / Rango.
/// Cuando es Rango muestra dos date pickers.
/// Llama [onChanged] cada vez que el período o las fechas cambian.
class HistorialPeriodFilter extends StatefulWidget {
  const HistorialPeriodFilter({
    required this.onChanged,
    this.initial = HistorialPeriodo.esteMes,
    super.key,
  });

  final void Function(DateTime from, DateTime to) onChanged;
  final HistorialPeriodo initial;

  @override
  State<HistorialPeriodFilter> createState() => _HistorialPeriodFilterState();
}

class _HistorialPeriodFilterState extends State<HistorialPeriodFilter> {
  late HistorialPeriodo _periodo;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    _periodo = widget.initial;
  }

  void _notify() {
    final (from, to) = historialPeriodoRange(
      _periodo,
      customFrom: _customFrom,
      customTo: _customTo,
    );
    widget.onChanged(from, to);
  }

  void _select(HistorialPeriodo p) {
    setState(() => _periodo = p);
    _notify();
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_customFrom ?? now) : (_customTo ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _customFrom = picked; else _customTo = picked;
      });
      _notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: HistorialPeriodo.values.map((p) {
              final labels = {
                HistorialPeriodo.hoy:     'Hoy',
                HistorialPeriodo.esteMes: 'Este mes',
                HistorialPeriodo.rango:   'Rango',
              };
              final isSelected = _periodo == p;
              return GestureDetector(
                onTap: () => _select(p),
                child: Container(
                  margin: EdgeInsets.only(right: context.responsiveSpacing / 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.inputBorder,
                    ),
                  ),
                  child: Text(
                    labels[p]!,
                    style: AppTextStyles.captionText.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_periodo == HistorialPeriodo.rango) ...[
          SizedBox(height: context.responsiveSpacing / 2),
          Row(
            children: [
              Expanded(child: _DateButton(label: 'Desde', date: _customFrom, onTap: () => _pickDate(true))),
              SizedBox(width: context.responsiveSpacing / 2),
              Expanded(child: _DateButton(label: 'Hasta', date: _customTo,   onTap: () => _pickDate(false))),
            ],
          ),
        ],
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          color: AppColors.surfaceVariant,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null ? AppDateUtils.formatDDMMYYYY(date!) : label,
                style: AppTextStyles.captionText.copyWith(
                  color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
