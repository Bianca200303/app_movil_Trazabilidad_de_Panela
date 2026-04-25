import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/pest_control_service.dart';

class PestControlList extends StatefulWidget {
  const PestControlList({
    required this.service,
    this.allowedModuleIds,
    super.key,
  });

  final PestControlService service;
  final Set<String>? allowedModuleIds;

  @override
  State<PestControlList> createState() => _PestControlListState();
}

class _PestControlListState extends State<PestControlList> {
  late DateTime _from;
  late DateTime _to;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    final (from, to) = historialPeriodoRange(HistorialPeriodo.esteMes);
    _from = from;
    _to = to;
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final controls = await widget.service.getPestControls(
        fromDate: _from,
        toDate: _to,
      );
      final futures = controls.map((control) async {
        final baitRecords = await widget.service.getBaitRecordsByControlId(control.id);
        final insectRecords = await widget.service.getInsectRecordsByControlId(control.id);
        return {
          'id': control.id,
          'coop_module_id': control.coopModuleId,
          'module_name': control.moduleName ?? 'Módulo desconocido',
          'control_date': control.formattedDate,
          'bait_records': baitRecords,
          'insect_records': insectRecords,
        };
      });
      var items = await Future.wait(futures);
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
          const HistorialLoadingWidget(message: 'Cargando controles de plagas...')
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
            children: _items.map((c) => _PestControlCard(data: c)).toList(),
          ),
      ],
    );
  }
}

class _PestControlCard extends StatelessWidget {
  const _PestControlCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final moduleName = data['module_name'] as String;
    final controlDate = data['control_date'] as String;
    final baitRecords = data['bait_records'] as List;
    final insectRecords = data['insect_records'] as List;

    final hasBaitData = baitRecords.isNotEmpty;
    final hasInsectData = insectRecords.isNotEmpty;
    final backgroundColor = (hasBaitData && hasInsectData)
        ? Colors.blue[50]!
        : (hasBaitData ? Colors.green[50]! : Colors.orange[50]!);

    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.inputBorder, width: AppDimensions.inputBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: AppColors.primary, size: 20),
              SizedBox(width: context.responsiveSpacing / 2),
              Expanded(
                child: Text('CONTROL DE PLAGAS',
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Fecha de producción', style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary, fontSize: 11)),
                  Text(controlDate, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          SizedBox(height: context.responsiveSpacing / 2),
          HistorialInfoRow(label: 'Módulo:', value: moduleName),
          SizedBox(height: context.responsiveSpacing / 2),
          if (hasBaitData) ...[
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.circle, size: 12, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text('Control de Cebos',
                        style: AppTextStyles.fieldLabel.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  SizedBox(height: context.responsiveSpacing / 4),
                  ...baitRecords.map((record) {
                    final totalStations = record.totalStations;
                    final stationsEaten = record.stationsWithBaitEaten;
                    final consumptionPercent = record.consumptionPercentage;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HistorialInfoRow(label: 'Producto:', value: record.productName),
                        HistorialInfoRow(label: 'Cantidad:', value: '${record.quantity} ${record.unit}'),
                        SizedBox(height: context.responsiveSpacing / 4),
                        Text(
                          'Estaciones: $totalStations ($stationsEaten comieron, ${consumptionPercent.toStringAsFixed(0)}%)',
                          style: AppTextStyles.bodyText.copyWith(fontSize: 13),
                        ),
                        if (record.baitObservations != null) ...[
                          SizedBox(height: context.responsiveSpacing / 4),
                          Text('Observaciones: ${record.baitObservations}',
                              style: AppTextStyles.bodyText.copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: context.responsiveSpacing / 2),
          ],
          if (hasInsectData) ...[
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.circle, size: 12, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text('Control de Insectos',
                        style: AppTextStyles.fieldLabel.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                  SizedBox(height: context.responsiveSpacing / 4),
                  ...insectRecords.map((record) {
                    final totalFlies = record.totalFlies;
                    final totalBees = record.totalBees;
                    final totalAnts = record.totalAnts;
                    final totalCockroaches = record.totalCockroaches;
                    final totalInsects = record.totalInsects;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HistorialInfoRow(label: 'Producto:', value: record.productName),
                        HistorialInfoRow(label: 'Cantidad:', value: '${record.quantity} ${record.unit}'),
                        SizedBox(height: context.responsiveSpacing / 4),
                        Text('Total de insectos: $totalInsects',
                            style: AppTextStyles.bodyText.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
                        if (totalFlies > 0) Text('  • Moscas: $totalFlies', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                        if (totalBees > 0) Text('  • Abejas: $totalBees', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                        if (totalAnts > 0) Text('  • Hormigas: $totalAnts', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                        if (totalCockroaches > 0) Text('  • Cucarachas: $totalCockroaches', style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
