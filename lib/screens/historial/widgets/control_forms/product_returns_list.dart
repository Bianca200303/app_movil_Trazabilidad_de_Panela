import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/widgets/common/app_card.dart';

/// Lista de quejas y devoluciones de producto.
class ProductReturnsList extends StatelessWidget {
  const ProductReturnsList({
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
        message: 'Cargando devoluciones de producto...',
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Error: $error',
              style: AppTextStyles.bodyText.copyWith(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No hay devoluciones registradas',
              style: AppTextStyles.bodyText.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final returnData = data[index];
        final returnDate = returnData['return_date'] as DateTime?;
        final quantity = returnData['quantity_sacks'] > 0
            ? '${returnData['quantity_sacks']} Sacos (${returnData['quantity_kg']} kg)'
            : '${returnData['quantity_kg']} kg';

        return Padding(
          padding: EdgeInsets.only(bottom: context.responsiveSpacing),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: cliente + fecha devolución
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        returnData['client_name'] ?? '-',
                        style: AppTextStyles.cardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      returnDate != null
                          ? DateFormat('dd/MM/yyyy').format(returnDate)
                          : '-',
                      style: AppTextStyles.bodyText.copyWith(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing),
                const Divider(height: 1),
                const SizedBox(height: 12),

                HistorialInfoRow(
                    label: 'Productor:',
                    value: returnData['producer_name'] ?? '-'),
                if (AppConfig.current.features.useAppagropCode)
                  HistorialInfoRow(
                      label: 'APPAGROP:',
                      value: returnData['appagrop_code'] ?? '-'),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                HistorialInfoRow(label: 'Cantidad:', value: quantity),
                HistorialInfoRow(
                    label: 'Causa:',
                    value: returnData['return_reason'] ?? '-'),
                if ((returnData['observations'] as String?)?.isNotEmpty ?? false)
                  HistorialInfoRow(
                      label: 'Observaciones:',
                      value: returnData['observations'] ?? '-'),
              ],
            ),
          ),
        );
      },
    );
  }
}
