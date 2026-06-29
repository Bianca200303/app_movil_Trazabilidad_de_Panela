import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/health_incident.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_expandable_card.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/health_incident_service.dart';

class HealthIncidentsList extends StatefulWidget {
  const HealthIncidentsList({
    required this.service,
    this.allowedModuleIds,
    super.key,
  });

  final HealthIncidentService service;
  final Set<String>? allowedModuleIds;

  @override
  State<HealthIncidentsList> createState() => _HealthIncidentsListState();
}

class _HealthIncidentsListState extends State<HealthIncidentsList> {
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
      final raw = await widget.service.getIncidentsWithModuleDetails(
        fromDate: _from,
        toDate: _to,
      );
      var items = raw.map((item) {
        final incident = HealthIncident.fromJson(item);
        final moduleData = item['coop_module'] as Map<String, dynamic>?;
        return {
          'id': incident.id,
          'coop_module_id': incident.coopModuleId,
          'module_name': moduleData?['name'] ?? 'Módulo desconocido',
          'employee_name': incident.employeeName,
          'registration_date': incident.formattedRegistrationDate,
          'work_area': incident.workArea,
          'symptoms_description': incident.symptomsDescription,
          'actions_taken': incident.actionsDisplayText,
          'return_date': incident.formattedReturnDate,
          'certificate_presented': incident.certificatePresentedText,
          'has_return_date': incident.returnDate != null,
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
              '${_items.length} incidente${_items.length != 1 ? 's' : ''} encontrado${_items.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando incidentes de salud...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Text('No hay incidentes en este período.',
                  style: AppTextStyles.captionText, textAlign: TextAlign.center),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _items.map((i) {
              final recordId = i['id'] as String;
              final isExpanded = _expandedRecords.contains(recordId);
              return _HealthIncidentCard(
                data: i,
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

class _HealthIncidentCard extends StatelessWidget {
  const _HealthIncidentCard({required this.data, required this.isExpanded, required this.onToggle});
  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final hasReturnDate = data['has_return_date'] as bool;
    final moduleName = data['module_name'] as String;
    final employeeName = data['employee_name'] as String;
    final registrationDate = data['registration_date'] as String;
    final workArea = data['work_area'] as String;
    final symptomsDescription = data['symptoms_description'] as String;
    final actionsTaken = data['actions_taken'] as String;
    final returnDate = data['return_date'] as String;
    final certificatePresented = data['certificate_presented'] as String;

    return HistorialExpandableCard(
      isExpanded: isExpanded,
      onToggle: onToggle,
      backgroundColor: hasReturnDate ? Colors.green[50] : Colors.orange[50],
      header: Row(
        children: [
          Icon(hasReturnDate ? Icons.check_circle : Icons.warning,
              color: hasReturnDate ? AppColors.success : AppColors.warning, size: 20),
          SizedBox(width: context.responsiveSpacing / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employeeName, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  hasReturnDate ? 'REINTEGRADO' : 'PENDIENTE',
                  style: AppTextStyles.captionText.copyWith(
                    color: hasReturnDate ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Fecha de producción', style: AppTextStyles.captionText.copyWith(color: AppColors.textPrimary, fontSize: 11)),
              Text(registrationDate, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HistorialInfoRow(label: 'Módulo:', value: moduleName),
          SizedBox(height: context.responsiveSpacing / 2),
          HistorialInfoRow(label: 'Área:', value: workArea),
          SizedBox(height: context.responsiveSpacing / 2),
          Container(
            padding: EdgeInsets.all(context.responsiveSpacing / 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Síntomas/Lesiones:', style: AppTextStyles.fieldLabel),
                SizedBox(height: context.responsiveSpacing / 4),
                Text(symptomsDescription, style: AppTextStyles.bodyText.copyWith(fontSize: 12)),
              ],
            ),
          ),
          SizedBox(height: context.responsiveSpacing / 2),
          HistorialInfoRow(label: 'Acciones:', value: actionsTaken),
          SizedBox(height: context.responsiveSpacing / 2),
          HistorialInfoRow(label: 'Certificado:', value: certificatePresented),
          if (hasReturnDate) ...[
            SizedBox(height: context.responsiveSpacing / 2),
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing / 2),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reintegración: $returnDate',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green[700]),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
