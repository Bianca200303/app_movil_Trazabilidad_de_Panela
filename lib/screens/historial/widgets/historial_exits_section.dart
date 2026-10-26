import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';

class HistorialExitsSection extends StatefulWidget {
  const HistorialExitsSection({
    required this.exitsData,
    this.onAddGR,
    super.key,
  });

  final List<Map<String, dynamic>> exitsData;
  final Future<void> Function(String exitRegistrationId)? onAddGR;

  @override
  State<HistorialExitsSection> createState() => _HistorialExitsSectionState();
}

class _HistorialExitsSectionState extends State<HistorialExitsSection> {
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List.filled(widget.exitsData.length, false);
  }

  @override
  void didUpdateWidget(HistorialExitsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exitsData.length != oldWidget.exitsData.length) {
      _expanded = List.filled(widget.exitsData.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.exitsData.length, (i) {
        return _buildCard(context, i);
      }),
    );
  }

  Widget _buildCard(BuildContext context, int index) {
    final item = widget.exitsData[index];
    final isExpanded = _expanded[index];
    final isAutoconsumo = item['is_autoconsumo'] == true;

    final double cantidad = (item['cantidad_mostrada'] is num)
        ? (item['cantidad_mostrada'] as num).toDouble()
        : double.tryParse(item['cantidad_mostrada'].toString()) ?? 0.0;

    final String cantidadStr =
        cantidad % 1 == 0 ? cantidad.toInt().toString() : cantidad.toString();

    final String unidadOriginal = item['unidad'].toString().toLowerCase();
    String unidadFinal = unidadOriginal;
    if (unidadOriginal.contains('saco')) {
      unidadFinal = cantidad == 1.0 ? 'saco' : 'sacos';
    }

    final double equivalenteKg =
        isAutoconsumo ? cantidad : cantidad * 50;
    final String textoEquivalencia = isAutoconsumo
        ? 'Equivale a: $cantidadStr kg'
        : 'Equivale a: ${equivalenteKg.toStringAsFixed(1)} kg';

    final loteProcesoRaw = item['lote_fecha_proceso']?.toString() ?? '';
    String loteProcesoDiaMes = loteProcesoRaw;
    if (loteProcesoRaw.length == 10) {
      final parts = loteProcesoRaw.split('-');
      if (parts.length == 3) {
        loteProcesoDiaMes = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }

    final loteKg = item['lote_panela_kg'];
    final loteKgStr =
        loteKg != null ? '${(loteKg as num).toStringAsFixed(0)} kg' : 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.inputBorder,
          width: AppDimensions.inputBorderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header (siempre visible) ──────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded[index] = !isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppDimensions.radiusMedium),
              bottom: isExpanded
                  ? Radius.zero
                  : const Radius.circular(AppDimensions.radiusMedium),
            ),
            child: Padding(
              padding: context.responsivePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HistorialInfoRow(
                          label: 'Productor:',
                          value: item['productor'].toString(),
                        ),
                        SizedBox(height: context.responsiveSpacing / 2),
                        HistorialInfoRow(
                          label: 'Código salida:',
                          value: item['codigo_salida'].toString(),
                        ),
                        SizedBox(height: context.responsiveSpacing / 2),
                        HistorialInfoRow(
                          label: 'Fecha salida:',
                          value: item['fecha_salida'].toString(),
                        ),
                        SizedBox(height: context.responsiveSpacing / 2),
                        HistorialInfoRow(
                          label: 'Cantidad:',
                          value: '$cantidadStr $unidadFinal',
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // ── Detalles desplegables ─────────────────────────────────
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.inputBorder),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppDimensions.radiusMedium),
                ),
              ),
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Registro de salida
                  HistorialInfoRow(
                    label: 'Destino:',
                    value: item['destino'].toString(),
                  ),
                  SizedBox(height: context.responsiveSpacing / 2),
                  HistorialInfoRow(
                    label: 'Documento salida:',
                    value: item['documento'].toString(),
                  ),
                  if (item['documento'].toString() == 'N/A' &&
                      widget.onAddGR != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => widget.onAddGR!(
                            item['exit_registration_id'].toString()),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Agregar GR'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),

                  SizedBox(height: context.responsiveSpacing / 2),
                  const Divider(color: AppColors.inputBorder),
                  SizedBox(height: context.responsiveSpacing / 2),

                  // Ítem enviado
                  HistorialInfoRow(
                    label: 'Comprobante ítem:',
                    value: (item['item_document_number'] ?? 'No especificado')
                        .toString(),
                  ),

                  SizedBox(height: context.responsiveSpacing / 2),
                  const Divider(color: AppColors.inputBorder),
                  SizedBox(height: context.responsiveSpacing / 2),

                  // Lote de producción
                  HistorialInfoRow(
                    label: 'Código lote:',
                    value: item['lote_codigo'].toString(),
                  ),
                  SizedBox(height: context.responsiveSpacing / 2),
                  HistorialInfoRow(
                    label: 'Fecha proceso lote:',
                    value: loteProcesoDiaMes,
                  ),
                  SizedBox(height: context.responsiveSpacing / 2),
                  HistorialInfoRow(
                    label: 'Panela total lote:',
                    value: loteKgStr,
                  ),

                  SizedBox(height: context.responsiveSpacing / 2),
                  const Divider(color: AppColors.inputBorder),
                  SizedBox(height: context.responsiveSpacing / 2),

                  // Módulo + autoconsumo badge
                  HistorialInfoRow(
                    label: 'Módulo:',
                    value: item['modulo'].toString(),
                  ),
                  if (isAutoconsumo) ...[
                    SizedBox(height: context.responsiveSpacing / 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'AUTOCONSUMO',
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.successDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Footer equivalencia
                  SizedBox(height: context.responsiveSpacing / 2),
                  const Divider(color: AppColors.inputBorder),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Row(
                    children: [
                      const Icon(Icons.scale_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          textoEquivalencia,
                          style: AppTextStyles.captionText.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Vista de datos genérica en formato tarjeta para productores y producción.
/// Muestra cada item con sus campos en filas etiqueta-valor.
/// Resalta con borde naranja los registros pendientes de sincronización.
/// Si [onEdit] está definido, muestra un ícono de edición en cada tarjeta.
/// Si [footerBuilder] está definido, renderiza contenido adicional al pie de
/// cada tarjeta (por ejemplo, la lista de parcelas de un productor).
class HistorialMobileDataView extends StatelessWidget {
  const HistorialMobileDataView({
    required this.data,
    required this.headers,
    required this.keys,
    this.onEdit,
    this.footerBuilder,
    super.key,
  });

  final List<Map<String, dynamic>> data;
  final List<String> headers;
  final List<String> keys;

  final void Function(Map<String, dynamic> item)? onEdit;
  final Widget Function(Map<String, dynamic> item)? footerBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: data.map((item) {
        final syncStatus = item['syncStatus'] as int? ?? 1;
        final isPending = syncStatus == 0;

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
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
              if (isPending || onEdit != null) ...[
                Row(
                  children: [
                    if (isPending) ...[
                      const Icon(Icons.sync_problem,
                          size: 16, color: AppColors.warning),
                      SizedBox(width: context.responsiveSpacing / 4),
                      Text(
                        'Por Sincronizar',
                        style: AppTextStyles.captionText.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (onEdit != null)
                      GestureDetector(
                        onTap: () => onEdit!(item),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing / 2),
              ],
              ...List.generate(headers.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < headers.length - 1
                        ? context.responsiveSpacing / 2
                        : 0,
                  ),
                  child: HistorialInfoRow(
                    label: '${headers[index]}:',
                    value: item[keys[index]].toString(),
                  ),
                );
              }),
              if (footerBuilder != null) footerBuilder!(item),
            ],
          ),
        );
      }).toList(),
    );
  }
}
