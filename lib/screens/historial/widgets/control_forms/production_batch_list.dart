import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/production_batch_service.dart';

class ProductionBatchList extends StatefulWidget {
  const ProductionBatchList({
    required this.service,
    required this.getAllowedDnis,
    super.key,
  });

  final ProductionBatchService service;
  final Future<Set<String>?> Function() getAllowedDnis;

  @override
  State<ProductionBatchList> createState() => _ProductionBatchListState();
}

class _ProductionBatchListState extends State<ProductionBatchList> {
  late DateTime _from;
  late DateTime _to;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _batches = [];
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
      final from = _from;
      final to = _to;
      var data = await widget.service.getProductionBatchesForHistorial(from: from, to: to);
      final allowedDnis = await widget.getAllowedDnis();
      if (allowedDnis != null) {
        data = data.where((b) => allowedDnis.contains(b['dni_productor'])).toList();
      }
      final formatted = data.map((b) {
        final fp = b['fecha_proceso'];
        final fc = b['fecha_cosecha'];
        final fr = b['fecha_registro'];
        return {
          ...b,
          'fecha_proceso': fp is DateTime ? AppDateUtils.formatDDMMYYYY(fp) : fp,
          if (fc is DateTime) 'fecha_cosecha': AppDateUtils.formatDDMMYYYY(fc),
          if (fr is DateTime) 'fecha_registro': AppDateUtils.formatDDMMYYYY(fr),
        };
      }).toList();
      setState(() { _batches = formatted; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistorialPeriodFilter(
          onChanged: (from, to) {
            _from = from;
            _to = to;
            _load();
          },
        ),

        SizedBox(height: context.responsiveSpacing),

        // ── Contador ──────────────────────────────────────────────────
        if (!_isLoading && _error == null)
          Padding(
            padding: EdgeInsets.only(bottom: context.responsiveSpacing / 2),
            child: Text(
              '${_batches.length} lote${_batches.length != 1 ? 's' : ''} encontrado${_batches.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),

        // ── Contenido ────────────────────────────────────────────────
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando producciones...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_batches.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Text(
                'No hay producciones en este período.',
                style: AppTextStyles.captionText,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _batches.map((b) => _BatchCard(
              batch: b,
              isExpanded: _expanded.contains(b['id']?.toString()),
              onToggle: () => setState(() {
                final id = b['id']?.toString() ?? '';
                _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
              }),
            )).toList(),
          ),
      ],
    );
  }

}

// ── Card de lote ──────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.isExpanded,
    required this.onToggle,
  });

  final Map<String, dynamic> batch;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isPending = (batch['syncStatus'] as int? ?? 1) == 0;
    final modulo = batch['modulo'] as String? ?? '';
    final productor = batch['productor'] as String? ?? '';
    final panelaKg = (batch['panela_kg'] as num?)?.toStringAsFixed(1) ?? '—';
    final canaKg = (batch['cana_kg'] as num?)?.toStringAsFixed(1) ?? '—';

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isPending ? AppColors.warning : AppColors.inputBorder,
            width: isPending ? 2 : AppDimensions.inputBorderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header compacto ─────────────────────────────────────
            Padding(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // El código del lote tiene la fila para él solo (salvo la
                  // flecha); fecha y "Por sincronizar" van debajo y bajan de
                  // línea si no caben, así nada se aplasta en pantallas
                  // angostas o con letra grande.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          batch['codigo_lote'] as String? ?? '—',
                          style: AppTextStyles.fieldLabel.copyWith(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Wrap(
                    spacing: context.responsiveSpacing / 2,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        batch['fecha_proceso'] as String? ?? '—',
                        style: AppTextStyles.captionText,
                      ),
                      if (isPending)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sync_problem, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text('Por Sincronizar',
                              style: AppTextStyles.captionText.copyWith(
                                color: AppColors.warning, fontWeight: FontWeight.w600)),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Text(
                    '${productor}${modulo.isNotEmpty ? ' · $modulo' : ''}',
                    style: AppTextStyles.captionText.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Wrap(
                    spacing: context.responsiveSpacing / 2,
                    runSpacing: 2,
                    children: [
                      _Tag(label: 'Panela $panelaKg kg', color: AppColors.successDark),
                      _Tag(label: 'Caña $canaKg kg', color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),

            // ── Detalle expandible ───────────────────────────────────
            if (isExpanded) ...[
              Divider(height: 1, color: AppColors.inputBorder),
              Padding(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HistorialInfoRow(label: 'DNI Productor:', value: batch['dni_productor']?.toString() ?? '—'),
                    SizedBox(height: context.responsiveSpacing / 2),
                    if (modulo.isNotEmpty) ...[
                      HistorialInfoRow(label: 'Módulo:', value: modulo),
                      SizedBox(height: context.responsiveSpacing / 2),
                    ],
                    HistorialInfoRow(label: 'Parcela:', value: batch['parcela']?.toString() ?? '—'),
                    SizedBox(height: context.responsiveSpacing / 2),
                    if (batch['fecha_cosecha'] != null) ...[
                      HistorialInfoRow(label: 'F. Cosecha:', value: batch['fecha_cosecha'].toString()),
                      SizedBox(height: context.responsiveSpacing / 2),
                    ],
                    if (batch['fecha_registro'] != null) ...[
                      HistorialInfoRow(label: 'F. Registro:', value: batch['fecha_registro'].toString()),
                      SizedBox(height: context.responsiveSpacing / 2),
                    ],
                    _SubBox(children: [
                      HistorialInfoRow(label: 'Jugo:', value: '${(batch['jugo_litros'] as num?)?.toStringAsFixed(2) ?? '—'} L'),
                      SizedBox(height: context.responsiveSpacing / 4),
                      HistorialInfoRow(label: 'Confitillo:', value: '${(batch['confitillo_kg'] as num?)?.toStringAsFixed(2) ?? '—'} kg'),
                      SizedBox(height: context.responsiveSpacing / 4),
                      HistorialInfoRow(label: '% Extracción:', value: '${(batch['porcentaje_extraccion'] as num?)?.toStringAsFixed(2) ?? '—'}%'),
                      SizedBox(height: context.responsiveSpacing / 4),
                      HistorialInfoRow(label: 'Rendimiento:', value: '${(batch['eficiencia'] as num?)?.toStringAsFixed(2) ?? '—'}%'),
                    ]),
                    if ((batch['registrado_por'] as String?)?.isNotEmpty ?? false) ...[
                      SizedBox(height: context.responsiveSpacing / 2),
                      Divider(height: 1, color: AppColors.inputBorder),
                      SizedBox(height: context.responsiveSpacing / 2),
                      HistorialInfoRow(label: 'Registrado por:', value: batch['registrado_por'] as String),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers visuales ──────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.captionText.copyWith(color: color, fontWeight: FontWeight.w500));
  }
}

class _SubBox extends StatelessWidget {
  const _SubBox({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: context.responsiveSpacing / 2),
      padding: EdgeInsets.all(context.responsiveSpacing / 2),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
