import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/cleaning_disinfection.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';

/// Lista de registros de limpieza y desinfección con cards expandibles por área.
/// Es StatefulWidget porque maneja su propio estado de expansión.
class CleaningDisinfectionList extends StatefulWidget {
  const CleaningDisinfectionList({
    required this.error,
    required this.data,
    super.key,
  });

  final String? error;
  final List<Map<String, dynamic>> data;

  @override
  State<CleaningDisinfectionList> createState() =>
      _CleaningDisinfectionListState();
}

class _CleaningDisinfectionListState extends State<CleaningDisinfectionList> {
  /// IDs de registros actualmente expandidos
  final Set<String> _expandedRecords = {};

  @override
  Widget build(BuildContext context) {
    if (widget.error != null) {
      return HistorialErrorWidget(error: widget.error!);
    }

    if (widget.data.isEmpty) {
      return const Center(
        child: Text(
          'No hay registros de limpieza y desinfección',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.data.map((record) {
        final recordId = record['id'] as String;
        final isExpanded = _expandedRecords.contains(recordId);
        final moduleName = record['module_name'] as String;
        final formattedDate = record['formatted_date'] as String;
        final hasObservations = record['has_observations'] as bool;
        final generalObservations = record['general_observations'] as String?;
        final itemsByArea =
            record['items_by_area'] as Map<String, List<CleaningDisinfectionItem>>;
        final totalItems = record['total_items'] as int;

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
              // HEADER clickeable para expandir/colapsar
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedRecords.remove(recordId);
                    } else {
                      _expandedRecords.add(recordId);
                    }
                  });
                },
                child: Padding(
                  padding: context.responsivePadding,
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Icon(Icons.cleaning_services,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(moduleName, style: AppTextStyles.cardTitle),
                            const SizedBox(height: 4),
                            Text(formattedDate, style: AppTextStyles.captionText),
                          ],
                        ),
                      ),
                      // Badge con total de ítems
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalItems',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (hasObservations)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.info_outline,
                              color: Colors.orange, size: 20),
                        ),
                    ],
                  ),
                ),
              ),

              // CONTENIDO EXPANDIBLE
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: context.responsivePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Observaciones generales
                      if (hasObservations && generalObservations != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16, color: Colors.orange[900]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Observaciones Generales:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.orange[900],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                generalObservations,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange[900]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text('Detalles de limpieza:', style: AppTextStyles.fieldLabel),
                      const SizedBox(height: 12),

                      // Detalles por área
                      ...itemsByArea.entries.map((entry) {
                        final areaCode = entry.key;
                        final items = entry.value;
                        final areaName = CleaningAreas.getDisplayName(areaCode);
                        final firstItem = items.first;

                        final cleaningTypes = <String>[];
                        if (firstItem.isDailyCleaning) cleaningTypes.add('Diaria');
                        if (firstItem.isGeneralCleaning) cleaningTypes.add('General');
                        if (firstItem.isDeepCleaning) cleaningTypes.add('Profunda');

                        final products = <String>[];
                        if (firstItem.usesChlorine) products.add('Cloro');
                        if (firstItem.usesDetergent) products.add('Detergente');
                        if (firstItem.usesOtherProduct) products.add('Otro');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.room_outlined,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      areaName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '${items.length} puntos',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.cleaning_services_outlined,
                                      size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    cleaningTypes.join(', '),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.science_outlined,
                                      size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    products.join(', '),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, top: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 14, color: Colors.green[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.pointDescription,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
