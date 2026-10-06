import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_expandable_card.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_stat_chip.dart';
import 'package:panela_sys/services/environment_inspection_service.dart';

class EnvironmentInspectionList extends StatefulWidget {
  const EnvironmentInspectionList({
    required this.service,
    this.allowedModuleIds,
    super.key,
  });

  final EnvironmentInspectionService service;
  final Set<String>? allowedModuleIds;

  @override
  State<EnvironmentInspectionList> createState() =>
      _EnvironmentInspectionListState();
}

class _EnvironmentInspectionListState extends State<EnvironmentInspectionList> {
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
      final raw = await widget.service.getInspectionsWithModuleDetails(
        fromDate: _from,
        toDate: _to,
      );
      var items = raw.map((item) {
        final inspection = EnvironmentInspection.fromJson(item);
        final moduleData = item['coop_module'] as Map<String, dynamic>?;
        final regUser = item['registered_by_user'] as Map<String, dynamic>?;
        return {
          'id': inspection.id,
          'coop_module_id': inspection.coopModuleId,
          'module_name': moduleData?['name'] ?? 'Módulo desconocido',
          'inspection_date': inspection.formattedDate,
          'is_compliant': inspection.isFullyCompliant,
          'total_items': inspection.totalItems,
          'compliant_items': inspection.compliantItems,
          'non_compliant_items': inspection.nonCompliantItems,
          'compliance_percentage': inspection.compliancePercentage,
          'area_compliance': inspection.getAreaComplianceMap(),
          'non_compliant_by_area': inspection.getNonCompliantCountByArea(),
          'registered_by': regUser != null ? '${regUser['first_name']} ${regUser['last_name']}' : null,
        };
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
              '${_items.length} inspección${_items.length != 1 ? 'es' : ''} encontrada${_items.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando inspecciones de ambiente...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Text('No hay inspecciones en este período.',
                  style: AppTextStyles.captionText, textAlign: TextAlign.center),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _items.map((inspection) {
              final recordId = inspection['id'] as String;
              final isExpanded = _expandedRecords.contains(recordId);
              return _EnvironmentInspectionCard(
                data: inspection,
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

class _EnvironmentInspectionCard extends StatelessWidget {
  const _EnvironmentInspectionCard({required this.data, required this.isExpanded, required this.onToggle});
  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final compliancePercentage = data['compliance_percentage'] as double;
    final totalItems = data['total_items'] as int;
    final compliantItems = data['compliant_items'] as int;
    final nonCompliantItems = data['non_compliant_items'] as int;
    final moduleName = data['module_name'] as String;
    final inspectionDate = data['inspection_date'] as String;

    final Color backgroundColor;
    final Color badgeColor;
    if (compliancePercentage == 100) {
      backgroundColor = Colors.green[50]!;
      badgeColor = AppColors.success;
    } else {
      backgroundColor = Colors.orange[50]!;
      badgeColor = Colors.orange[700]!;
    }

    return HistorialExpandableCard(
      isExpanded: isExpanded,
      onToggle: onToggle,
      backgroundColor: backgroundColor,
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor),
            ),
            child: Text(
              '${compliancePercentage.toStringAsFixed(0)}%',
              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SizedBox(width: context.responsiveSpacing / 2),
          Expanded(child: Text(moduleName, style: AppTextStyles.cardTitle)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Fecha de inspección',
                style: AppTextStyles.captionText.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
              Text(
                inspectionDate,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumen de ítems', style: AppTextStyles.fieldLabel),
                SizedBox(height: context.responsiveSpacing / 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HistorialStatChip(label: 'Total', value: totalItems.toString(), color: AppColors.textPrimary),
                    HistorialStatChip(label: 'Conformes', value: compliantItems.toString(), color: AppColors.success),
                    HistorialStatChip(label: 'No conformes', value: nonCompliantItems.toString(), color: AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          if (nonCompliantItems > 0) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[900], size: 16),
                  SizedBox(width: context.responsiveSpacing / 4),
                  Expanded(
                    child: Text(
                      '$nonCompliantItems ítems requieren acciones correctivas',
                      style: TextStyle(color: Colors.orange[900], fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
