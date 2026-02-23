import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

class DataTableWidget extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> data;
  final List<int>? flexValues;

  const DataTableWidget({
    super.key,
    required this.headers,
    required this.data,
    this.flexValues,
  });

  @override
  Widget build(BuildContext context) {
    final defaultFlex = List.filled(headers.length, 1);
    final flex = flexValues ?? defaultFlex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.textSecondary,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: headers.asMap().entries.map((entry) {
              return Expanded(
                flex: flex[entry.key],
                child: Text(
                  entry.value,
                  style: AppTextStyles.fieldLabel,
                ),
              );
            }).toList(),
          ),
        ),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final row = data[index];
              return Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: row.asMap().entries.map((entry) {
                    return Expanded(
                      flex: flex[entry.key],
                      child: Text(
                        entry.value,
                        style: AppTextStyles.bodyText,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}