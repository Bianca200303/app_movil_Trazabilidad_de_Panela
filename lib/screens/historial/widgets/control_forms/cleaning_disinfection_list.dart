import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/cleaning_disinfection.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_expandable_card.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/cleaning_disinfection_service.dart';

Color _cleaningTypeColor(CleaningType type) {
  switch (type) {
    case CleaningType.daily:
      return const Color(0xFF1565C0);
    case CleaningType.general:
      return const Color(0xFFE65100);
    case CleaningType.deep:
      return const Color(0xFF6A1B9A);
  }
}

class CleaningDisinfectionList extends StatefulWidget {
  const CleaningDisinfectionList({
    required this.service,
    this.allowedModuleIds,
    super.key,
  });

  final CleaningDisinfectionService service;
  final Set<String>? allowedModuleIds;

  @override
  State<CleaningDisinfectionList> createState() =>
      _CleaningDisinfectionListState();
}

class _CleaningDisinfectionListState extends State<CleaningDisinfectionList> {
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
      final records = await widget.service.getCleaningRecords(
        fromDate: _from,
        toDate: _to,
      );
      final formattedData = <Map<String, dynamic>>[];
      for (final record in records) {
        final items = await widget.service.getItemsByRecordId(record.id);
        final itemsByArea = <String, List<CleaningDisinfectionItem>>{};
        for (final item in items) {
          itemsByArea.putIfAbsent(item.areaCode, () => []).add(item);
        }
        formattedData.add({
          'id': record.id,
          'coop_module_id': record.coopModuleId,
          'cleaning_date': record.cleaningDate,
          'formatted_date': AppDateUtils.formatDDMMYYYY(record.cleaningDate),
          'module_name': record.moduleName ?? 'Módulo desconocido',
          'cleaning_types': record.cleaningTypes,
          'has_observations': record.generalObservations != null && record.generalObservations!.isNotEmpty,
          'general_observations': record.generalObservations,
          'items_by_area': itemsByArea,
          'total_items': items.length,
          'registered_by': record.createdByName,
        });
      }
      var result = formattedData;
      if (widget.allowedModuleIds != null) {
        result = result
            .where((i) => widget.allowedModuleIds!.contains(i['coop_module_id']))
            .toList();
      }
      setState(() { _items = result; _isLoading = false; });
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
          const HistorialLoadingWidget(message: 'Cargando limpieza y desinfección...')
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
            children: _items.map((record) {
              final recordId = record['id'] as String;
              final isExpanded = _expandedRecords.contains(recordId);
              return _CleaningCard(
                data: record,
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

class _CleaningCard extends StatelessWidget {
  const _CleaningCard({required this.data, required this.isExpanded, required this.onToggle});
  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final moduleName = data['module_name'] as String;
    final formattedDate = data['formatted_date'] as String;
    final cleaningTypes = data['cleaning_types'] as List<CleaningType>;
    final hasObservations = data['has_observations'] as bool;
    final generalObservations = data['general_observations'] as String?;
    final itemsByArea = data['items_by_area'] as Map<String, List<CleaningDisinfectionItem>>;
    final totalItems = data['total_items'] as int;

    return HistorialExpandableCard(
      isExpanded: isExpanded,
      onToggle: onToggle,
      header: Row(
        children: [
          Icon(Icons.cleaning_services, color: AppColors.primary, size: 20),
          SizedBox(width: context.responsiveSpacing / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moduleName, style: AppTextStyles.cardTitle),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: cleaningTypes.map((t) {
                    final c = _cleaningTypeColor(t);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.getDisplayName(),
                        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                Text('Fecha de limpieza', style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary, fontSize: 11)),
                Text(formattedDate, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalItems',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          if (hasObservations)
            Padding(
              padding: EdgeInsets.only(left: context.responsiveSpacing / 2),
              child: const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasObservations && generalObservations != null) ...[
            Container(
              padding: context.responsivePadding,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[900]),
                    const SizedBox(width: 8),
                    Text('Observaciones Generales:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange[900])),
                  ]),
                  const SizedBox(height: 8),
                  Text(generalObservations,
                      style: TextStyle(fontSize: 12, color: Colors.orange[900])),
                ],
              ),
            ),
            SizedBox(height: context.responsiveSpacing),
          ],
          Text('Detalles de limpieza:', style: AppTextStyles.fieldLabel),
          SizedBox(height: context.responsiveSpacing / 2),
          ...itemsByArea.entries.map((entry) {
            final areaCode = entry.key;
            final items = entry.value;
            final areaName = CleaningAreas.getDisplayName(areaCode);
            final firstItem = items.first;
            final products = <String>[
              if (firstItem.usesChlorine) 'Cloro',
              if (firstItem.usesDetergent) 'Detergente',
              if (firstItem.usesOtherProduct) 'Otro',
            ];
            return Container(
              margin: EdgeInsets.only(bottom: context.responsiveSpacing),
              padding: context.responsivePadding,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.room_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(areaName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Text('${items.length} puntos',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.science_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(products.join(', '),
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  ...items.map((item) => Padding(
                    padding: EdgeInsets.only(
                      left: context.responsiveSpacing,
                      top: context.responsiveSpacing / 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.pointDescription,
                            style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            );
          }),
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
