import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/offline/offline_config.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/widgets/common/app_button.dart';

/// Menú principal del historial con las 4 opciones de navegación.
/// Habilita/deshabilita opciones según conectividad y soporte offline.
class HistorialMainMenu extends ConsumerWidget {
  const HistorialMainMenu({
    required this.onOptionSelected,
    super.key,
  });

  /// Callback al seleccionar una opción (índice 0-3).
  final void Function(int index) onOptionSelected;

  static const _options = [
    {'title': 'Productores registrados', 'icon': Icons.person, 'index': 0},
    {'title': 'Producción registrada', 'icon': Icons.shopping_bag, 'index': 1},
    {'title': 'Salidas registradas', 'icon': Icons.signpost, 'index': 2},
    {'title': 'Inspecciones de control', 'icon': Icons.assignment_outlined, 'index': 3},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (isOnline) => _buildOptions(context, isOnline: isOnline),
      loading: () => _buildOptions(context, isOnline: true),
      error: (_, __) => _buildOptions(context, isOnline: false),
    );
  }

  Widget _buildOptions(BuildContext context, {required bool isOnline}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _options.map((option) {
        final index = option['index'] as int;
        final isEnabled = _isOptionEnabled(index, isOnline);

        return Padding(
          padding: EdgeInsets.only(bottom: context.responsiveSpacing),
          child: SizedBox(
            width: double.infinity,
            child: AppButton(
              text: option['title'] as String,
              icon: option['icon'] as IconData,
              type: isEnabled ? AppButtonType.primary : AppButtonType.secondary,
              onPressed: isEnabled ? () => onOptionSelected(index) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isOptionEnabled(int index, bool isOnline) {
    switch (index) {
      case 0:
        return isOnline || OfflineConfig.instance.features.producers;
      case 1:
        return isOnline || OfflineConfig.instance.features.production;
      case 2:
        return isOnline || OfflineConfig.instance.features.exits;
      case 3:
        return isOnline; // Formularios de control solo online por ahora
      default:
        return false;
    }
  }
}
