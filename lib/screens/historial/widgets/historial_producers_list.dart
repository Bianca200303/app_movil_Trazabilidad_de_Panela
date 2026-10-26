import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/widgets/common/app_badge.dart';
import 'package:panela_sys/widgets/common/app_entity_tile.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';

/// Lista de productores registrados en Historial: una fila por productor con
/// sus datos, su condición, sus parcelas y (para administradores) el acceso
/// a gestionarlas. Recibe los mapas de ProducerService.getProducersForHistorial.
class HistorialProducersList extends StatefulWidget {
  const HistorialProducersList({
    super.key,
    required this.producers,
    required this.canManagePlots,
    this.onEdit,
    required this.onManagePlots,
  });

  final List<Map<String, dynamic>> producers;
  final bool canManagePlots;
  /// Nulo si el usuario no puede editar productores (solo administradores).
  final ValueChanged<Map<String, dynamic>>? onEdit;
  final ValueChanged<Map<String, dynamic>> onManagePlots;

  @override
  State<HistorialProducersList> createState() => _HistorialProducersListState();
}

class _HistorialProducersListState extends State<HistorialProducersList> {
  /// A partir de cuántos productores se muestra el buscador.
  static const _searchThreshold = 6;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.producers;
    return widget.producers.where((p) {
      return p['nombre'].toString().toLowerCase().contains(query) ||
          p['dni'].toString().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.producers.length >= _searchThreshold) ...[
          AppTextField(
            controller: _searchController,
            hintText: 'Buscar por nombre o DNI',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Limpiar búsqueda',
                    onPressed: _searchController.clear,
                  ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
        ],
        if (widget.producers.isEmpty)
          _message('No hay productores registrados.')
        else if (visible.isEmpty)
          _message('Ningún productor coincide con la búsqueda.')
        else
          AppEntityList(
            children: [
              for (final producer in visible) _buildTile(producer),
            ],
          ),
      ],
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
        child: Text(text, style: AppTextStyles.bodyText, textAlign: TextAlign.center),
      );

  Widget _buildTile(Map<String, dynamic> producer) {
    final isPending = (producer['syncStatus'] as int? ?? 1) == 0;
    final isMember = producer['condicion'] == 'Socio';
    return AppEntityTile(
      title: producer['nombre'].toString(),
      initials: entityInitials(
        producer['firstName']?.toString() ?? producer['nombre'].toString(),
        producer['lastName']?.toString() ?? '',
      ),
      accent: AppColors.success,
      subtitle: 'DNI ${producer['dni']} · ${producer['modulo']}',
      badges: [
        AppBadge(
          text: isMember ? 'Socio' : 'No socio',
          color: isMember ? AppColors.success : AppColors.primary,
          background: isMember ? AppColors.successLight : AppColors.infoLight,
        ),
        if (isPending)
          const AppBadge(
            text: 'Por sincronizar',
            icon: Icons.sync_problem,
            color: AppColors.warning,
            background: AppColors.warningLight,
          ),
      ],
      onTap: widget.onEdit == null ? null : () => widget.onEdit!(producer),
      trailing: widget.onEdit == null
          ? null
          : IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.primary,
              tooltip: 'Editar productor',
              visualDensity: VisualDensity.compact,
              onPressed: () => widget.onEdit!(producer),
            ),
      footer: _PlotsSummary(
        plots: (producer['parcelas'] as List<dynamic>?) ?? const [],
        // Los productores aún sin sincronizar tienen id local (entero): sus
        // parcelas se gestionan cuando ya existen en el servidor.
        canManage: widget.canManagePlots,
        isSynced: !isPending && int.tryParse(producer['id'].toString()) == null,
        onManage: () => widget.onManagePlots(producer),
      ),
    );
  }
}

class _PlotsSummary extends StatelessWidget {
  const _PlotsSummary({
    required this.plots,
    required this.canManage,
    required this.isSynced,
    required this.onManage,
  });

  final List<dynamic> plots;
  final bool canManage;
  final bool isSynced;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    if (plots.isEmpty && !canManage) return const SizedBox.shrink();
    final labelStyle = AppTextStyles.captionText.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingSmall),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          color: AppColors.infoLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.landscape_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plots.isEmpty ? 'Sin parcelas' : 'Parcelas (${plots.length})',
                    style: labelStyle,
                  ),
                ),
                if (canManage && isSynced)
                  TextButton(
                    onPressed: onManage,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Gestionar'),
                  ),
              ],
            ),
            for (final plot in plots)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 6),
                child: Text(
                  _plotLabel(plot as Map),
                  style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (canManage && !isSynced)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 6),
                child: Text(
                  'Podrá gestionar sus parcelas cuando el productor se sincronice.',
                  style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _plotLabel(Map plot) {
    final code = (plot['code'] as String?) ?? '';
    final name = ((plot['name'] as String?) ?? '').trim();
    return name.isEmpty ? code : '$code · $name';
  }
}
