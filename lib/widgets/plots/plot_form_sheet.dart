import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/offline/user_error_message.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/models/plot.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/widgets/common/app_button.dart';
import 'package:panela_sys/widgets/common/app_snackbar.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/form_section.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

/// Abre el formulario para agregar ([plot] null) o editar una parcela de un
/// productor ya sincronizado. Devuelve la parcela guardada, o null si se
/// canceló. Requiere conexión y rol administrador (ver PlotService.savePlot).
///
/// [existingNames]: nombres de las otras parcelas del productor, para avisar
/// de un nombre repetido antes de guardar.
Future<Plot?> showPlotFormSheet(
  BuildContext context, {
  required String producerId,
  required String producerName,
  Plot? plot,
  Iterable<String> existingNames = const [],
}) {
  return showModalBottomSheet<Plot>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXLarge)),
    ),
    builder: (_) => _PlotFormSheet(
      producerId: producerId,
      producerName: producerName,
      plot: plot,
      existingNames: existingNames
          .where((n) => n.trim().toLowerCase() != plot?.name.trim().toLowerCase())
          .map((n) => n.trim().toLowerCase())
          .toSet(),
    ),
  );
}

class _PlotFormSheet extends ConsumerStatefulWidget {
  const _PlotFormSheet({
    required this.producerId,
    required this.producerName,
    required this.plot,
    required this.existingNames,
  });

  final String producerId;
  final String producerName;
  final Plot? plot;
  final Set<String> existingNames;

  @override
  ConsumerState<_PlotFormSheet> createState() => _PlotFormSheetState();
}

class _PlotFormSheetState extends ConsumerState<_PlotFormSheet> {
  /// Ancho desde el cual los dos porcentajes van lado a lado.
  static const _twoColumnWidth = 440.0;

  final _formKey = GlobalKey<FormState>();
  // Con la base local para que la caché de parcelas quede al día al guardar.
  late final _service = PlotService(db: ref.read(appDatabaseProvider));
  late final _nameController = TextEditingController(text: widget.plot?.name);
  late final _extractionController =
      TextEditingController(text: _formatPercent(widget.plot?.defaultExtractionPercentage));
  late final _cachazaController =
      TextEditingController(text: _formatPercent(widget.plot?.defaultCachazaPercentage));
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _extractionController.dispose();
    _cachazaController.dispose();
    super.dispose();
  }

  static String _formatPercent(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
  }

  static double? _parsePercent(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return AppConfig.current.features.requirePlotNames
          ? 'Ingrese el nombre de la parcela'
          : null;
    }
    if (widget.existingNames.contains(name.toLowerCase())) {
      return 'Este productor ya tiene una parcela con ese nombre';
    }
    return null;
  }

  String? _validatePercent(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = _parsePercent(text);
    if (number == null) return 'Ingrese un número válido';
    if (number < 0 || number > 100) return 'Debe estar entre 0 y 100';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final saved = await _service.savePlot(
        id: widget.plot?.id,
        producerId: widget.producerId,
        name: _nameController.text,
        defaultExtractionPercentage: _parsePercent(_extractionController.text),
        defaultCachazaPercentage: _parsePercent(_cachazaController.text),
      );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.show(
        context,
        message: userErrorMessage(e, action: 'No se pudo guardar la parcela'),
        type: SnackBarType.error,
      );
    }
  }

  Widget _pair(bool wide, Widget a, Widget b) {
    if (!wide) return FormGroup(children: [a, b]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(child: b),
      ],
    );
  }

  AppTextField _percentField(String label, TextEditingController controller) {
    return AppTextField(
      label: label,
      controller: controller,
      hintText: 'Opcional',
      suffixText: '%',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: TextInputAction.next,
      validator: _validatePercent,
      enabled: !_isSaving,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.plot == null;
    final horizontal = context.responsivePadding.left;

    return Padding(
      // Sube el formulario por encima del teclado.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, context.responsivePadding.bottom),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _twoColumnWidth;
            return Form(
              key: _formKey,
              child: FormGroup(
                children: [
                  Row(
                    children: [
                      Icon(
                        isNew ? Icons.add_location_alt_outlined : Icons.edit_location_alt_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimensions.spacingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNew ? 'Nueva parcela' : 'Editar parcela',
                              style: AppTextStyles.sectionTitle,
                            ),
                            Text(
                              isNew
                                  ? widget.producerName
                                  : '${widget.producerName} · ${widget.plot!.code}',
                              style: AppTextStyles.captionText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppTextField(
                    label: AppConfig.current.features.requirePlotNames
                        ? 'Nombre de la parcela'
                        : 'Nombre de la parcela (opcional)',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    helperText: isNew ? 'El código se asigna automáticamente.' : null,
                    validator: _validateName,
                    enabled: !_isSaving,
                  ),
                  _pair(
                    wide,
                    _percentField('% extracción por defecto', _extractionController),
                    _percentField('% cachaza por defecto', _cachazaController),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingSmall + AppDimensions.paddingXSmall),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: AppDimensions.spacingSmall),
                        Expanded(
                          child: Text(
                            'Se proponen al registrar producción en esta parcela. '
                            'Cada lote nuevo los actualiza con sus valores reales. '
                            'Si los deja vacíos se usan los del productor.',
                            style: AppTextStyles.captionText.copyWith(color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _pair(
                    constraints.maxWidth >= 320,
                    AppButton(
                      text: 'Cancelar',
                      type: AppButtonType.secondary,
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    ),
                    AppButton(
                      text: 'Guardar',
                      onPressed: _save,
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
