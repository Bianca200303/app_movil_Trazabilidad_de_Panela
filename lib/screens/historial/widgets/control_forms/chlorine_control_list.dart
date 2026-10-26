import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_expandable_card.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/chlorine_residual_control_service.dart';

class ChlorineControlList extends StatefulWidget {
  const ChlorineControlList({
    required this.service,
    this.allowedModuleIds,
    super.key,
  });

  final ChlorineResidualControlService service;
  final Set<String>? allowedModuleIds;

  @override
  State<ChlorineControlList> createState() => _ChlorineControlListState();
}

class _ChlorineControlListState extends State<ChlorineControlList> {
  late DateTime _from;
  late DateTime _to;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _expandedRecords = {};

  @override
  void initState() {
    super.initState();
    final (from, to) = historialPeriodoRange(HistorialPeriodo.esteMes);
    _from = from;
    _to = to;
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; _expandedRecords.clear(); });
    try {
      final controls = await widget.service.getControls(
        fromDate: _from,
        toDate: _to,
      );
      var items = controls.map((control) => {
        'id': control.id,
        'coop_module_id': control.coopModuleId,
        'module_name': control.moduleName ?? 'Módulo desconocido',
        'control_date': control.formattedDate,
        'control_time': control.formattedTime,
        'm1': control.measurementPoint1,
        'm2': control.measurementPoint2,
        'is_m1_safe': control.isM1InSafeRange,
        'is_m2_safe': control.isM2InSafeRange,
        'both_safe': control.areBothInSafeRange,
        'requires_action': control.requiresCorrectiveAction,
        'safety_warning': control.safetyWarningMessage,
        'corrective_actions': control.correctiveActions,
        'observations': control.observations,
        'responsible_person': control.responsiblePerson,
        'registered_by': control.registeredByName,
      }).toList();
      if (widget.allowedModuleIds != null) {
        items = items
            .where((i) => widget.allowedModuleIds!.contains(i['coop_module_id']))
            .toList();
      }
      setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistorialPeriodFilter(
          onChanged: (from, to) { _from = from; _to = to; _load(); },
        ),
        SizedBox(height: context.responsiveSpacing),
        if (!_isLoading && _error == null)
          Padding(
            padding: EdgeInsets.only(bottom: context.responsiveSpacing / 2),
            child: Text(
              '${_items.length} control${_items.length != 1 ? 'es' : ''} encontrado${_items.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando controles de cloro...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Text('No hay controles en este período.',
                  style: AppTextStyles.captionText, textAlign: TextAlign.center),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _items.map((c) {
              final recordId = c['id'] as String;
              final isExpanded = _expandedRecords.contains(recordId);
              return _ChlorineCard(
                data: c,
                isExpanded: isExpanded,
                onToggle: () => setState(() {
                  isExpanded ? _expandedRecords.remove(recordId) : _expandedRecords.add(recordId);
                }),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ChlorineCard extends StatelessWidget {
  const _ChlorineCard({required this.data, required this.isExpanded, required this.onToggle});
  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final bothSafe = data['both_safe'] as bool;
    final requiresAction = data['requires_action'] as bool;
    final moduleName = data['module_name'] as String;
    final controlDate = data['control_date'] as String;
    final controlTime = data['control_time'] as String;
    final m1 = data['m1'] as double;
    final m2 = data['m2'] as double;
    final isM1Safe = data['is_m1_safe'] as bool;
    final isM2Safe = data['is_m2_safe'] as bool;
    final safetyWarning = data['safety_warning'] as String?;
    final correctiveActions = data['corrective_actions'] as String?;
    final observations = data['observations'] as String?;
    final responsiblePerson = data['responsible_person'] as String;

    final Color backgroundColor = bothSafe ? AppColors.successLight : AppColors.warningLight;
    final Color badgeColor = bothSafe ? AppColors.success : AppColors.warningDark;

    return HistorialExpandableCard(
      isExpanded: isExpanded,
      onToggle: onToggle,
      backgroundColor: backgroundColor,
      // Todo apilado en una sola columna: en pantallas angostas o con letra
      // grande, una columna fija de fecha a la derecha aplastaba el nombre.
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(bothSafe ? Icons.check_circle : Icons.warning_amber_rounded, color: badgeColor, size: 20),
          SizedBox(width: context.responsiveSpacing / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moduleName, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  bothSafe ? 'EN RANGO SEGURO' : 'FUERA DE RANGO',
                  style: AppTextStyles.captionText.copyWith(color: badgeColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Fecha de producción: '),
                    TextSpan(
                      text: '$controlDate $controlTime',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ]),
                  style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsiveSpacing / 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mediciones (ppm)', style: AppTextStyles.fieldLabel),
                SizedBox(height: context.responsiveSpacing / 4),
                _MeasurementRow(label: 'M1 - Sanitización:', value: m1, isSafe: isM1Safe),
                SizedBox(height: context.responsiveSpacing / 4),
                _MeasurementRow(label: 'M2 - Proceso:', value: m2, isSafe: isM2Safe),
                SizedBox(height: context.responsiveSpacing / 4),
                Text('Rango seguro: 0.5 - 2.0 ppm',
                    style: AppTextStyles.captionText.copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          if (requiresAction && safetyWarning != null) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber, color: AppColors.warningDark, size: 16),
                SizedBox(width: context.responsiveSpacing / 4),
                Expanded(child: Text(safetyWarning,
                    style: TextStyle(color: AppColors.warningDark, fontSize: 12, fontWeight: FontWeight.w500))),
              ]),
            ),
          ],
          if (correctiveActions != null && correctiveActions.isNotEmpty) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.infoBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.build, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text('Acciones correctivas:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                  ]),
                  const SizedBox(height: 8),
                  Text(correctiveActions, style: TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                ],
              ),
            ),
          ],
          if (observations != null && observations.isNotEmpty) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.notes, size: 16, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text('Observaciones:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                  ]),
                  const SizedBox(height: 8),
                  Text(observations, style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
          SizedBox(height: context.responsiveSpacing / 2),
          HistorialInfoRow(label: 'Responsable:', value: responsiblePerson),
          if ((data['registered_by'] as String?)?.isNotEmpty ?? false) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            const Divider(height: 1),
            SizedBox(height: context.responsiveSpacing / 2),
            HistorialInfoRow(label: 'Registrado por:', value: data['registered_by'] as String),
          ],
        ],
      ),
    );
  }
}

/// Medición con ícono de estado: la etiqueta ocupa el espacio libre (y baja
/// de línea si hace falta) para que el valor nunca se salga de la tarjeta.
class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.label, required this.value, required this.isSafe});
  final String label;
  final double value;
  final bool isSafe;

  @override
  Widget build(BuildContext context) {
    final color = isSafe ? AppColors.success : AppColors.warning;
    return Row(
      children: [
        Icon(isSafe ? Icons.check_circle : Icons.warning, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyText.copyWith(fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Text(
          value.toStringAsFixed(2),
          style: AppTextStyles.bodyText.copyWith(
            fontSize: 13, fontWeight: FontWeight.w600, color: color,
          ),
        ),
      ],
    );
  }
}
