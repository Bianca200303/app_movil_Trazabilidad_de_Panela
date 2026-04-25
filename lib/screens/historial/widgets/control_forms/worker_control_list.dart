import 'package:flutter/material.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/worker_control_service.dart';

String _fmtKg(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

const _criteriaLabels = [
  'Uniforme completo', 'Sin maquillaje', 'Uñas cortas y limpias',
  'Uñas sin esmalte', 'Manos limpias', 'Sin joyas ni perfume',
  'Cabello cubierto', 'Sin barba', 'Sin heridas o cortes',
];

List<String> _failedCriteria(WorkerEvaluation w) {
  final values = [
    w.uniformComplete, w.noMakeup, w.nailsShortClean, w.nailsNoPolish,
    w.handsClean, w.noJewelry, w.hairCovered, w.noBeard, w.noWounds,
  ];
  return [for (int i = 0; i < values.length; i++) if (!values[i]) _criteriaLabels[i]];
}

// ── Batch group ──────────────────────────────────────────────────────────────

class _BatchGroup {
  final String batchId;
  final String producerName;
  final String? processDate;
  final String? moduleName;
  final double? panelaKg;
  final double? confitilloKg;
  final List<WorkerControl> controls;

  _BatchGroup({
    required this.batchId,
    required this.producerName,
    this.processDate,
    this.moduleName,
    this.panelaKg,
    this.confitilloKg,
    required this.controls,
  });

  int get totalWorkers => controls.fold(0, (s, c) => s + c.workersList.length);
  bool get isFullyCompliant => controls.every((c) => c.isFullyCompliant);
}

// ── List widget ───────────────────────────────────────────────────────────────

class WorkerControlList extends StatefulWidget {
  const WorkerControlList({required this.service, required this.getAllowedDnis, super.key});
  final WorkerControlService service;
  final Future<Set<String>?> Function() getAllowedDnis;

  @override
  State<WorkerControlList> createState() => _WorkerControlListState();
}

class _WorkerControlListState extends State<WorkerControlList> {
  late DateTime _from;
  late DateTime _to;
  bool _isLoading = false;
  String? _error;
  List<_BatchGroup> _groups = [];
  final Set<String> _expanded = {};

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
      final rawData = await widget.service.getWorkerControlsForHistorialByRange(
        AppConfig.current.id, _from, _to,
      );
      final allowedDnis = await widget.getAllowedDnis();

      final filtered = allowedDnis != null
          ? rawData.where((e) => allowedDnis.contains(e['producer_dni'])).toList()
          : rawData;

      // Group by production_batch_id
      final map = <String, _BatchGroup>{};
      for (final entry in filtered) {
        final control = entry['control'] as WorkerControl;
        final batchId = control.productionBatchId;
        if (!map.containsKey(batchId)) {
          map[batchId] = _BatchGroup(
            batchId: batchId,
            producerName: (entry['producer_name'] as String?) ?? '—',
            processDate: entry['process_date'] as String?,
            moduleName: entry['module_name'] as String?,
            panelaKg: (entry['panela_kg'] as num?)?.toDouble(),
            confitilloKg: (entry['confitillo_kg'] as num?)?.toDouble(),
            controls: [],
          );
        }
        map[batchId]!.controls.add(control);
      }

      setState(() { _groups = map.values.toList(); _isLoading = false; });
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
              '${_groups.length} lote${_groups.length != 1 ? 's' : ''} evaluado${_groups.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando controles de personal...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_groups.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Text('No hay controles en este período.', style: AppTextStyles.captionText, textAlign: TextAlign.center),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _groups.map((g) => _BatchCard(
              group: g,
              isExpanded: _expanded.contains(g.batchId),
              onToggle: () => setState(() {
                _expanded.contains(g.batchId) ? _expanded.remove(g.batchId) : _expanded.add(g.batchId);
              }),
            )).toList(),
          ),
      ],
    );
  }
}

// ── Card por lote ─────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.group, required this.isExpanded, required this.onToggle});
  final _BatchGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final allOk = group.isFullyCompliant;
    final badgeColor = allOk ? AppColors.success : Colors.orange[700]!;
    final bgColor = allOk ? Colors.green[50]! : Colors.orange[50]!;
    final processDate = group.processDate != null
        ? AppDateUtils.formatDDMMYYYY(DateTime.parse(group.processDate!))
        : null;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(allOk ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: badgeColor, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          group.moduleName != null
                              ? '${group.producerName}  ·  ${group.moduleName}'
                              : group.producerName,
                          style: AppTextStyles.fieldLabel.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            if (processDate != null) processDate,
                            if (group.panelaKg != null)
                              'Panela: ${_fmtKg(group.panelaKg!)} kg'
                              '${group.confitilloKg != null && group.confitilloKg! > 0 ? ' · Conf: ${_fmtKg(group.confitilloKg!)} kg' : ''}',
                          ].join('  ·  '),
                          style: AppTextStyles.captionText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${group.controls.length} área${group.controls.length != 1 ? 's' : ''}  ·  ${group.totalWorkers} trabajador${group.totalWorkers != 1 ? 'es' : ''}',
                          style: AppTextStyles.captionText.copyWith(
                              color: badgeColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Detalle expandible
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: group.controls.map((c) => _AreaSection(control: c)).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sección por área ──────────────────────────────────────────────────────────

class _AreaSection extends StatelessWidget {
  const _AreaSection({required this.control});
  final WorkerControl control;

  @override
  Widget build(BuildContext context) {
    final areaOk = control.isFullyCompliant;
    final color = areaOk ? AppColors.success : Colors.orange[700]!;

    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(areaOk ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(control.workArea.displayName,
                    style: AppTextStyles.fieldLabel.copyWith(fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${control.compliancePercentage.toStringAsFixed(0)}%  ${control.complianceCount}/${control.totalCriteria}',
                  style: AppTextStyles.captionText.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (control.workersList.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...control.workersList.map((w) => _WorkerRow(worker: w)),
          ],
          if (control.observations?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            HistorialInfoRow(label: 'Obs:', value: control.observations!),
          ],
        ],
      ),
    );
  }
}

// ── Fila de trabajador ────────────────────────────────────────────────────────

class _WorkerRow extends StatelessWidget {
  const _WorkerRow({required this.worker});
  final WorkerEvaluation worker;

  @override
  Widget build(BuildContext context) {
    final count = worker.complianceCount;
    const total = 9;
    final isOk = count == total;
    final color = isOk ? AppColors.success : Colors.orange[700]!;
    final failed = isOk ? <String>[] : _failedCriteria(worker);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isOk ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(worker.workerName,
                    style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count/$total',
                    style: AppTextStyles.captionText.copyWith(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (failed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(failed.join(' · '),
                  style: TextStyle(fontSize: 11, color: Colors.orange[800])),
            ),
        ],
      ),
    );
  }
}
