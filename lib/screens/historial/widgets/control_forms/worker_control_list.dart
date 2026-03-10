import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/worker_control.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';

const _criteriaLabels = [
  'Uniforme completo',
  'Sin maquillaje',
  'Uñas cortas y limpias',
  'Uñas sin esmalte',
  'Manos limpias',
  'Sin joyas ni perfume',
  'Cabello cubierto',
  'Sin barba',
  'Sin heridas o cortes',
];

List<String> _failedCriteria(WorkerEvaluation w) {
  final values = [
    w.uniformComplete,
    w.noMakeup,
    w.nailsShortClean,
    w.nailsNoPolish,
    w.handsClean,
    w.noJewelry,
    w.hairCovered,
    w.noBeard,
    w.noWounds,
  ];
  return [
    for (int i = 0; i < values.length; i++)
      if (!values[i]) _criteriaLabels[i],
  ];
}

/// Lista de controles de personal operario.
class WorkerControlList extends StatelessWidget {
  const WorkerControlList({
    required this.isLoading,
    required this.error,
    required this.data,
    super.key,
  });

  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const HistorialLoadingWidget(
        message: 'Cargando controles de personal...',
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay controles de personal registrados',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data
          .map((control) => _WorkerControlCard(control: control))
          .toList(),
    );
  }
}

class _WorkerControlCard extends StatelessWidget {
  const _WorkerControlCard({required this.control});

  final Map<String, dynamic> control;

  @override
  Widget build(BuildContext context) {
    final isFullyCompliant = control['is_fully_compliant'] as bool;
    final compliancePercentage = control['compliance_percentage'] as double;
    final complianceCount = control['compliance_count'] as int;
    final totalCriteria = control['total_criteria'] as int;
    final workArea = control['work_area'] as String;
    final formattedDate = control['formatted_date'] as String;
    final observations = control['observations'] as String?;
    final workers = control['workers'] as List<WorkerEvaluation>? ?? [];
    final workerNameFallback = control['worker_name'] as String? ?? '';

    final badgeColor = isFullyCompliant ? AppColors.success : Colors.orange[700]!;
    final bgColor = isFullyCompliant ? Colors.green[50]! : Colors.orange[50]!;

    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isFullyCompliant
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: badgeColor,
                      size: 20,
                    ),
                    SizedBox(width: context.responsiveSpacing / 2),
                    Expanded(
                      child: Text(
                        isFullyCompliant ? 'CUMPLE TOTALMENTE' : 'INCUMPLIMIENTOS',
                        style: AppTextStyles.fieldLabel.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Porcentaje general
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${compliancePercentage.toStringAsFixed(0)}%  $complianceCount/$totalCriteria',
                        style: AppTextStyles.captionText.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing / 2),
                    Text(formattedDate, style: AppTextStyles.captionText),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing / 2),
                HistorialInfoRow(label: 'Área:', value: workArea),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // ── Trabajadores ─────────────────────────────────────────────────────
          Padding(
            padding: context.responsivePadding,
            child: workers.isNotEmpty
                ? _WorkersList(workers: workers)
                : _LegacyWorkerRow(name: workerNameFallback),
          ),

          // ── Observaciones ────────────────────────────────────────────────────
          if (observations != null && observations.isNotEmpty)
            _ObservationsBox(observations: observations),
        ],
      ),
    );
  }
}

/// Lista de trabajadores con estado individual (registros nuevos).
class _WorkersList extends StatelessWidget {
  const _WorkersList({required this.workers});

  final List<WorkerEvaluation> workers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${workers.length} ${workers.length == 1 ? 'trabajador evaluado' : 'trabajadores evaluados'}',
          style: AppTextStyles.fieldLabel,
        ),
        const SizedBox(height: 8),
        ...workers.map((w) => _WorkerRow(worker: w)),
      ],
    );
  }
}

/// Fila individual por trabajador.
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  worker.workerName,
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count/$total',
                  style: AppTextStyles.captionText.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (failed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 3),
              child: Text(
                failed.join(' · '),
                style: AppTextStyles.captionText.copyWith(
                  color: Colors.orange[800],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila de compatibilidad para registros antiguos (sin worker_control_items).
class _LegacyWorkerRow extends StatelessWidget {
  const _LegacyWorkerRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name, style: AppTextStyles.bodyText),
        ),
      ],
    );
  }
}

class _ObservationsBox extends StatelessWidget {
  const _ObservationsBox({required this.observations});

  final String observations;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.responsivePadding.left,
        0,
        context.responsivePadding.right,
        context.responsivePadding.bottom,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 15, color: Colors.orange[900]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              observations,
              style: TextStyle(fontSize: 12, color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }
}
