import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/product_return_service.dart';

class ProductReturnsList extends StatefulWidget {
  const ProductReturnsList({required this.service, super.key});
  final ProductReturnService service;

  @override
  State<ProductReturnsList> createState() => _ProductReturnsListState();
}

class _ProductReturnsListState extends State<ProductReturnsList> {
  late DateTime _from;
  late DateTime _to;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
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
      final data = await widget.service.getReturnsHistoryByRange(_from, _to);
      setState(() { _items = data; _isLoading = false; });
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
              '${_items.length} devolución${_items.length != 1 ? 'es' : ''} encontrada${_items.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando devoluciones...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text('No hay devoluciones en este período.', style: AppTextStyles.captionText, textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _items.map((item) {
              final id = item['id']?.toString() ?? '';
              return _ReturnCard(
                data: item,
                isExpanded: _expanded.contains(id),
                onToggle: () => setState(() {
                  _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
                }),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.data, required this.isExpanded, required this.onToggle});
  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final returnDate  = data['return_date'] as DateTime?;
    final processDate = data['process_date'] as DateTime?;
    final quantity    = (data['quantity_sacks'] as int) > 0
        ? '${data['quantity_sacks']} sacos (${data['quantity_kg']} kg)'
        : '${data['quantity_kg']} kg';
    final isVoided = data['voided_at'] != null;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.inputBorder, width: AppDimensions.inputBorderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_return, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['client_name'] ?? '—',
                          style: AppTextStyles.fieldLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVoided
                              ? AppColors.textSecondary.withValues(alpha: 0.12)
                              : AppColors.successLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          border: Border.all(color: isVoided ? AppColors.textSecondary : AppColors.success),
                        ),
                        child: Text(
                          isVoided ? 'Anulada' : 'Vigente',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: isVoided ? AppColors.textSecondary : AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        returnDate != null ? DateFormat('dd/MM/yyyy').format(returnDate) : '—',
                        style: AppTextStyles.captionText,
                      ),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Text(
                    '${data['producer_name'] ?? '—'}${(data['module_name'] as String?)?.isNotEmpty == true ? ' · ${data['module_name']}' : ''}',
                    style: AppTextStyles.captionText.copyWith(color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Text(
                    quantity,
                    style: AppTextStyles.captionText.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ── Detalle expandible ───────────────────────────────────────
            if (isExpanded) ...[
              Divider(height: 1, color: AppColors.inputBorder),
              Padding(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HistorialInfoRow(label: 'Productor:', value: data['producer_name'] ?? '—'),
                    if (AppConfig.current.features.useAppagropCode)
                      HistorialInfoRow(label: 'APPAGROP:', value: data['appagrop_code'] ?? '—'),
                    if ((data['module_name'] as String?)?.isNotEmpty ?? false)
                      HistorialInfoRow(label: 'Módulo:', value: data['module_name'] as String),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(
                      label: 'Cant. original lote:',
                      value: data['batch_panela_kg'] != null ? '${data['batch_panela_kg']} kg' : '—',
                    ),
                    HistorialInfoRow(
                      label: 'F. producción:',
                      value: processDate != null ? DateFormat('dd/MM/yyyy').format(processDate) : '—',
                    ),
                    HistorialInfoRow(
                      label: 'F. devolución:',
                      value: returnDate != null ? DateFormat('dd/MM/yyyy').format(returnDate) : '—',
                    ),
                    SizedBox(height: context.responsiveSpacing / 4),
                    const Divider(height: 1),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(label: 'Cant. devuelta:', value: quantity),
                    HistorialInfoRow(label: 'Causa:', value: data['return_reason'] ?? '—'),
                    if ((data['observations'] as String?)?.isNotEmpty ?? false)
                      HistorialInfoRow(label: 'Observaciones:', value: data['observations'] ?? '—'),
                    if ((data['registered_by'] as String?)?.isNotEmpty ?? false) ...[
                      SizedBox(height: context.responsiveSpacing / 4),
                      const Divider(height: 1),
                      SizedBox(height: context.responsiveSpacing / 4),
                      HistorialInfoRow(label: 'Registrado por:', value: data['registered_by'] as String),
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
