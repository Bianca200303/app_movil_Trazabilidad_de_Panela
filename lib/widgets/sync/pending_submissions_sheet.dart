import 'package:flutter/material.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/database/app_database.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/services/production_batch_service.dart';
import 'package:panela_sys/services/sync/pending_submissions_service.dart';
import 'package:panela_sys/services/sync/submissions/submission_registry.dart';
import 'package:panela_sys/widgets/widgets.dart';

/// Lista de lotes de producción y controles guardados en el celular que
/// todavía no se enviaron.
///
/// Muestra el motivo de los que el servidor rechazó y permite descartarlos:
/// sin esto, un registro rechazado quedaría para siempre pendiente y
/// bloquearía el cierre de sesión.
class PendingSubmissionsSheet extends StatefulWidget {
  const PendingSubmissionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PendingSubmissionsSheet(),
    );
  }

  @override
  State<PendingSubmissionsSheet> createState() => _PendingSubmissionsSheetState();
}

class _PendingSubmissionsSheetState extends State<PendingSubmissionsSheet> {
  final _db = AppDatabase();
  late Future<_PendingData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _loadAll();
  }

  Future<_PendingData> _loadAll() async {
    final batches = await _db.productionBatchesDao.getPending(AppConfig.current.id);
    final controls = <PendingSubmissionLocal>[];
    for (final kind in submissionHandlers.keys) {
      controls.addAll(await _db.pendingSubmissionsDao.getByKind(kind, AppConfig.current.id));
    }
    controls.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _PendingData(batches, controls);
  }

  Future<void> _discard(PendingSubmissionLocal row) async {
    final confirmed = await _confirmDiscard(
      title: 'Descartar registro',
      message: 'El registro se eliminará del celular y no se enviará. '
          'Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;
    await PendingSubmissionsService(db: _db).discard(row.id);
    if (mounted) setState(_reload);
  }

  Future<void> _discardBatch(ProductionBatchLocal batch) async {
    final dependents = await _db.pendingSubmissionsDao.getByProductionBatchLocalId(batch.id);
    if (!mounted) return;
    final alsoControls = dependents.isEmpty
        ? ''
        : ' También se eliminarán ${dependents.length} control(es) registrados sobre este lote.';
    final confirmed = await _confirmDiscard(
      title: 'Descartar lote',
      message: 'El lote ${batch.batchCode} se eliminará del celular y no se enviará.'
          '$alsoControls Esta acción no se puede deshacer.',
    );
    if (!confirmed) return;
    await ProductionBatchService(db: _db).discardUnsentBatch(batch.id);
    if (mounted) setState(_reload);
  }

  Future<bool> _confirmDiscard({required String title, required String message}) =>
      AppConfirmDialog.show(
        context,
        title: title,
        message: message,
        confirmLabel: 'Descartar',
        destructive: true,
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<_PendingData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Registros sin enviar', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  'Se envían solos al volver la señal. Los que tienen error fueron '
                  'rechazados por el servidor y se pueden descartar.',
                  style: AppTextStyles.captionText,
                ),
                const SizedBox(height: 12),
                if (data.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('No hay registros pendientes.', style: AppTextStyles.bodyText),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (data.batches.isNotEmpty) ...[
                          _sectionLabel('Lotes de producción'),
                          for (final batch in data.batches) _buildBatchRow(batch),
                        ],
                        if (data.controls.isNotEmpty) ...[
                          _sectionLabel('Controles'),
                          for (final row in data.controls) _buildRow(row),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(text, style: AppTextStyles.fieldLabel),
      );

  Widget _buildBatchRow(ProductionBatchLocal batch) {
    final rejected = batch.syncError != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        rejected ? Icons.error_outline : Icons.schedule,
        color: rejected ? AppColors.error : AppColors.warning,
      ),
      title: Text('Lote ${batch.batchCode}', style: AppTextStyles.bodyText),
      subtitle: Text(
        rejected
            ? 'Rechazado: ${batch.syncError}'
            : 'Producción del ${AppDateUtils.formatDDMMYYYY(batch.processDate)}',
        style: AppTextStyles.captionText.copyWith(color: rejected ? AppColors.error : null),
      ),
      trailing: rejected
          ? TextButton(
              onPressed: () => _discardBatch(batch),
              child: const Text('Descartar', style: TextStyle(color: AppColors.error)),
            )
          : null,
    );
  }

  Widget _buildRow(PendingSubmissionLocal row) {
    final label = submissionHandlers[row.kind]?.label ?? row.kind;
    final rejected = row.lastError != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        rejected ? Icons.error_outline : Icons.schedule,
        color: rejected ? AppColors.error : AppColors.warning,
      ),
      title: Text(label, style: AppTextStyles.bodyText),
      subtitle: Text(
        rejected
            ? 'Rechazado: ${row.lastError}'
            : 'Guardado el ${AppDateUtils.formatDDMMYYYY(row.createdAt)}',
        style: AppTextStyles.captionText.copyWith(color: rejected ? AppColors.error : null),
      ),
      trailing: rejected
          ? TextButton(
              onPressed: () => _discard(row),
              child: const Text('Descartar', style: TextStyle(color: AppColors.error)),
            )
          : null,
    );
  }
}

class _PendingData {
  final List<ProductionBatchLocal> batches;
  final List<PendingSubmissionLocal> controls;
  const _PendingData(this.batches, this.controls);

  bool get isEmpty => batches.isEmpty && controls.isEmpty;
}
