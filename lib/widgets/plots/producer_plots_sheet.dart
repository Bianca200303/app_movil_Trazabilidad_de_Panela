import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/offline/user_error_message.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/plot.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/widgets/common/app_badge.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_confirm_dialog.dart';
import 'package:panela_sys/widgets/common/app_snackbar.dart';
import 'package:panela_sys/widgets/plots/plot_form_sheet.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

/// Parcelas de un productor ya sincronizado: agregar, editar (nombre y %
/// por defecto), dar de baja y reactivar. Solo para administradores
/// (CurrentUser.canManagePlots) y con conexión. Al cerrarse, quien la abrió
/// debe recargar sus datos (puede haber cambios).
Future<void> showProducerPlotsSheet(
  BuildContext context, {
  required String producerId,
  required String producerName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXLarge)),
    ),
    builder: (_) => _ProducerPlotsSheet(producerId: producerId, producerName: producerName),
  );
}

class _ProducerPlotsSheet extends ConsumerStatefulWidget {
  const _ProducerPlotsSheet({required this.producerId, required this.producerName});

  final String producerId;
  final String producerName;

  @override
  ConsumerState<_ProducerPlotsSheet> createState() => _ProducerPlotsSheetState();
}

class _ProducerPlotsSheetState extends ConsumerState<_ProducerPlotsSheet> {
  late final _service = PlotService(db: ref.read(appDatabaseProvider));

  List<Plot> _plots = [];
  bool _isLoading = true;
  bool _showInactive = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = _plots.isEmpty;
      _loadError = null;
    });
    try {
      final plots = await _service.getPlotsForManagement(widget.producerId);
      if (!mounted) return;
      setState(() {
        _plots = plots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = userErrorMessage(e, action: 'No se pudieron cargar las parcelas');
        _isLoading = false;
      });
    }
  }

  Future<void> _openForm([Plot? plot]) async {
    final saved = await showPlotFormSheet(
      context,
      producerId: widget.producerId,
      producerName: widget.producerName,
      plot: plot,
      existingNames: _plots.map((p) => p.name),
    );
    if (saved == null || !mounted) return;
    AppSnackBar.show(
      context,
      message: plot == null ? 'Parcela ${saved.code} agregada' : 'Parcela actualizada',
      type: SnackBarType.success,
    );
    _load();
  }

  Future<void> _toggleActive(Plot plot) async {
    if (plot.isActive) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: '¿Dar de baja la parcela?',
        message:
            '${_plotTitle(plot)} dejará de aparecer al registrar producción. '
            'Los lotes ya registrados no cambian. Puede reactivarla después.',
        confirmLabel: 'Dar de baja',
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await _service.setPlotActive(plot.id, widget.producerId, !plot.isActive);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: plot.isActive ? 'Parcela dada de baja' : 'Parcela reactivada',
        type: SnackBarType.success,
      );
      _load();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: userErrorMessage(e, action: 'No se pudo guardar el cambio'),
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.responsivePadding.left;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, context.responsivePadding.bottom),
        children: [
          Row(
            children: [
              const Icon(Icons.landscape_outlined, color: AppColors.primary),
              const SizedBox(width: AppDimensions.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parcelas', style: AppTextStyles.sectionTitle),
                    Text(
                      widget.producerName,
                      style: AppTextStyles.captionText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          ..._buildContent(),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLarge),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_loadError != null) {
      return [
        Text(_loadError!, style: AppTextStyles.bodyText, textAlign: TextAlign.center),
        const SizedBox(height: AppDimensions.spacingMedium),
        AppButton(
          text: 'Reintentar',
          icon: Icons.refresh,
          type: AppButtonType.secondary,
          onPressed: _load,
        ),
      ];
    }

    final active = _plots.where((p) => p.isActive).toList();
    final inactive = _plots.where((p) => !p.isActive).toList();

    return [
      AppButton(
        text: 'Agregar parcela',
        icon: Icons.add_location_alt_outlined,
        onPressed: () => _openForm(),
      ),
      const SizedBox(height: AppDimensions.spacingMedium),
      if (active.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
          child: Text(
            'Este productor no tiene parcelas activas.',
            style: AppTextStyles.bodyText,
            textAlign: TextAlign.center,
          ),
        )
      else
        for (final plot in active)
          _PlotTile(
            plot: plot,
            onEdit: () => _openForm(plot),
            onToggleActive: () => _toggleActive(plot),
          ),
      if (inactive.isNotEmpty) ...[
        const SizedBox(height: AppDimensions.spacingSmall),
        InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: () => setState(() => _showInactive = !_showInactive),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingSmall),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dadas de baja (${inactive.length})',
                    style: AppTextStyles.fieldLabel.copyWith(color: AppColors.primary),
                  ),
                ),
                Icon(
                  _showInactive ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        if (_showInactive)
          for (final plot in inactive)
            _PlotTile(
              plot: plot,
              onEdit: () => _openForm(plot),
              onToggleActive: () => _toggleActive(plot),
            ),
      ],
    ];
  }
}

String _plotTitle(Plot plot) =>
    plot.name.trim().isEmpty ? 'Parcela ${plot.code}' : plot.name.trim();

String _percent(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();

enum _PlotAction { edit, toggleActive }

class _PlotTile extends StatelessWidget {
  const _PlotTile({required this.plot, required this.onEdit, required this.onToggleActive});

  final Plot plot;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final accent = plot.isActive ? AppColors.success : AppColors.error;
    final extraction = plot.defaultExtractionPercentage;
    final cachaza = plot.defaultCachazaPercentage;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Icon(Icons.landscape_outlined, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plotTitle(plot),
                      style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Código ${plot.code}', style: AppTextStyles.captionText),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (!plot.isActive)
                          const AppBadge(
                            text: 'Dada de baja',
                            icon: Icons.block,
                            color: AppColors.error,
                            background: AppColors.errorLight,
                          ),
                        if (extraction != null)
                          AppBadge(
                            text: 'Extracción ${_percent(extraction)} %',
                            color: AppColors.primary,
                            background: AppColors.infoLight,
                          ),
                        if (cachaza != null)
                          AppBadge(
                            text: 'Cachaza ${_percent(cachaza)} %',
                            color: AppColors.primary,
                            background: AppColors.infoLight,
                          ),
                        if (plot.isActive && extraction == null && cachaza == null)
                          const AppBadge(
                            text: 'Usa los % del productor',
                            color: AppColors.primary,
                            background: AppColors.infoLight,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PlotAction>(
                tooltip: 'Opciones',
                icon: const Icon(Icons.more_vert, color: AppColors.primary),
                onSelected: (action) => switch (action) {
                  _PlotAction.edit => onEdit(),
                  _PlotAction.toggleActive => onToggleActive(),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _PlotAction.edit,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined, color: AppColors.primary),
                      title: Text('Editar'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _PlotAction.toggleActive,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        plot.isActive ? Icons.block : Icons.restart_alt,
                        color: plot.isActive ? AppColors.error : AppColors.success,
                      ),
                      title: Text(plot.isActive ? 'Dar de baja' : 'Reactivar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
