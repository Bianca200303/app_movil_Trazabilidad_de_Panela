import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';

/// Sección de salidas registradas en el historial.
/// Cada item muestra código de salida, fecha, productor, comprobante, cantidad y documento.
class HistorialExitsSection extends StatelessWidget {
  const HistorialExitsSection({required this.exitsData, super.key});

  final List<Map<String, dynamic>> exitsData;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: exitsData.map((item) {
        final isAutoconsumo = item['is_autoconsumo'] == true;

        // Formato limpio de cantidad (sin decimales innecesarios)
        final double cantidad = (item['cantidad_mostrada'] is num)
            ? (item['cantidad_mostrada'] as num).toDouble()
            : double.tryParse(item['cantidad_mostrada'].toString()) ?? 0.0;

        final String cantidadStr = cantidad % 1 == 0
            ? cantidad.toInt().toString()
            : cantidad.toString();

        final String unidadOriginal = item['unidad'].toString().toLowerCase();
        String unidadFinal = unidadOriginal;

        // Pluralización de "saco"
        if (unidadOriginal.contains('saco')) {
          unidadFinal = (cantidad == 1.0) ? 'saco' : 'sacos';
        }

        // --- NUEVA LÓGICA DE CONVERSIÓN VISUAL ---
        // Si es autoconsumo, ya está en kg. Si son sacos, multiplicamos por 50.
        final double equivalenteKg = isAutoconsumo ? cantidad : (cantidad * 50);

        // Texto que mostraremos abajo
        final String textoEquivalencia = isAutoconsumo
            ? 'Equivale a: $cantidadStr kg'
            : 'Equivale a: ${equivalenteKg.toStringAsFixed(1)} kg';

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          padding: context.responsivePadding,
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
              HistorialInfoRow(
                label: 'Código Salida:',
                value: item['codigo_salida'].toString(),
              ),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(
                label: 'Fecha:',
                value: item['fecha_salida'].toString(),
              ),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(
                label: 'Productor:',
                value: item['productor'].toString(),
              ),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(
                label: 'Comprobante:',
                value: (item['item_document_number'] ?? 'No especificado')
                    .toString(),
              ),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(
                label: 'Cantidad:',
                value: '$cantidadStr $unidadFinal',
              ),
              SizedBox(height: context.responsiveSpacing / 2),
              HistorialInfoRow(
                label: 'Documento:',
                value: item['documento'].toString(),
              ),

              // Badge AUTOCONSUMO
              if (isAutoconsumo) ...[
                SizedBox(height: context.responsiveSpacing / 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('', style: TextStyle()),
                    Flexible(
                      child: Text(
                        'AUTOCONSUMO',
                        style: AppTextStyles.bodyText.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],

              // --- FOOTER CON LA EQUIVALENCIA ---
              SizedBox(height: context.responsiveSpacing / 2),
              const Divider(color: AppColors.inputBorder),
              SizedBox(height: context.responsiveSpacing / 4),
              Row(
                children: [
                  Icon(
                    Icons.scale_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
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
        );
      }).toList(),
    );
  }
}

/// Vista de datos genérica en formato tarjeta para productores y producción.
/// Muestra cada item con sus campos en filas etiqueta-valor.
/// Resalta con borde naranja los registros pendientes de sincronización.
class HistorialMobileDataView extends StatelessWidget {
  const HistorialMobileDataView({
    required this.data,
    required this.headers,
    required this.keys,
    super.key,
  });

  final List<Map<String, dynamic>> data;
  final List<String> headers;
  final List<String> keys;

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
              color: isPending
                  ? const Color(0xFFFF9800)
                  : AppColors.inputBorder,
              width: isPending ? 2 : AppDimensions.inputBorderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge "Por Sincronizar"
              if (isPending) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.sync_problem,
                      size: 16,
                      color: Color(0xFFFF9800),
                    ),
                    SizedBox(width: context.responsiveSpacing / 4),
                    Text(
                      'Por Sincronizar',
                      style: AppTextStyles.captionText.copyWith(
                        color: const Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
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
            ],
          ),
        );
      }).toList(),
    );
  }
}
