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
import 'package:panela_sys/services/equipment_maintenance_service.dart';

class MaintenanceControlList extends StatefulWidget {
  const MaintenanceControlList({
    required this.service,
    this.allowedModuleIds,
    super.key,
  });

  final EquipmentMaintenanceService service;
  final Set<String>? allowedModuleIds;

  @override
  State<MaintenanceControlList> createState() => _MaintenanceControlListState();
}

class _MaintenanceControlListState extends State<MaintenanceControlList> {
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
      final records = await widget.service.getRecords(
        fromDate: _from,
        toDate: _to,
      );
      var items = records.map((record) => {
        'id': record.id,
        'coop_module_id': record.coopModuleId,
        'maintenance_date': record.formattedDate,
        'equipment_name': record.equipmentName,
        'maintenance_type': record.maintenanceTypeDisplayName,
        'maintenance_type_code': record.maintenanceType.code,
        'maintenance_cause': record.maintenanceCause,
        'materials_used': record.materialsUsed,
        'has_materials': record.hasMaterials,
        'duration_hours': record.formattedDuration,
        'responsible_person': record.responsiblePerson,
        'module_name': record.moduleName ?? 'Módulo desconocido',
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
              '${_items.length} registro${_items.length != 1 ? 's' : ''} encontrado${_items.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando registros de mantenimiento...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Text('No hay registros en este período.',
                  style: AppTextStyles.captionText, textAlign: TextAlign.center),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _items.map((m) {
              final recordId = m['id'] as String;
              final isExpanded = _expandedRecords.contains(recordId);
              return _MaintenanceCard(
                data: m,
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

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({required this.data, required this.isExpanded, required this.onToggle});
  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final maintenanceDate = data['maintenance_date'] as String;
    final equipmentName = data['equipment_name'] as String;
    final maintenanceType = data['maintenance_type'] as String;
    final maintenanceTypeCode = data['maintenance_type_code'] as String;
    final maintenanceCause = data['maintenance_cause'] as String;
    final materialsUsed = data['materials_used'] as String?;
    final hasMaterials = data['has_materials'] as bool;
    final durationHours = data['duration_hours'] as String;
    final responsiblePerson = data['responsible_person'] as String;
    final moduleName = data['module_name'] as String;

    final Color badgeColor = maintenanceTypeCode == 'P' ? AppColors.success : AppColors.warning;

    return HistorialExpandableCard(
      isExpanded: isExpanded,
      onToggle: onToggle,
      backgroundColor: AppColors.cardBackground,
      header: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moduleName, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Text(equipmentName, style: AppTextStyles.captionText.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  maintenanceType,
                  style: AppTextStyles.fieldLabel.copyWith(color: badgeColor, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(maintenanceDate, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HistorialInfoRow(label: 'Causa:', value: maintenanceCause),
          SizedBox(height: context.responsiveSpacing / 4),
          HistorialInfoRow(label: 'Duración:', value: durationHours),
          SizedBox(height: context.responsiveSpacing / 4),
          HistorialInfoRow(label: 'Responsable:', value: responsiblePerson),
          if (hasMaterials) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            Text('Materiales/Repuestos:', style: AppTextStyles.fieldLabel),
            SizedBox(height: context.responsiveSpacing / 4),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.inputBorder, width: 0.5),
              ),
              child: Text(materialsUsed ?? '', style: AppTextStyles.bodyText),
            ),
          ],
        ],
      ),
    );
  }
}
