import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/models/certified_worker.dart';
import 'package:panela_sys/services/certified_workers_service.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';

/// Campo de nombre de un trabajador del módulo [moduleId].
///
/// Sugiere los trabajadores certificados del módulo (la lista se mantiene en
/// "Trabajadores certificados"; funciona sin señal con la copia local), y
/// también deja escribir un nombre que no esté en la lista, para no trabar
/// el registro en campo. El nombre queda en [controller].
///
/// Si el nombre corresponde a un trabajador con la certificación vencida,
/// muestra una advertencia (no bloquea: se regulariza después).
class CertifiedWorkerNameField extends StatefulWidget {
  const CertifiedWorkerNameField({
    super.key,
    required this.moduleId,
    required this.controller,
    this.label = 'Nombre y Apellidos',
    this.focusNode,
    this.validator,
  });

  /// Sin módulo no hay sugerencias: se escribe el nombre.
  final String? moduleId;
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  @override
  State<CertifiedWorkerNameField> createState() => _CertifiedWorkerNameFieldState();
}

class _CertifiedWorkerNameFieldState extends State<CertifiedWorkerNameField> {
  final _service = CertifiedWorkersService();
  FocusNode? _ownFocusNode;
  List<CertifiedWorker> _workers = [];
  bool _isLoading = false;

  FocusNode get _focusNode => widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CertifiedWorkerNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleId != widget.moduleId) _load();
  }

  @override
  void dispose() {
    _ownFocusNode?.dispose();
    super.dispose();
  }

  /// Llamado desde initState/didUpdateWidget, que ya reconstruyen: el
  /// estado inicial se asigna directo y solo la respuesta usa setState.
  Future<void> _load() async {
    final moduleId = widget.moduleId;
    _workers = [];
    _isLoading = moduleId != null;
    if (moduleId == null) return;

    final workers = await _service.getByModule(moduleId);
    // Si el módulo cambió mientras se cargaba, esta respuesta ya no sirve.
    if (!mounted || widget.moduleId != moduleId) return;
    setState(() {
      _workers = workers;
      _isLoading = false;
    });
  }

  CertifiedWorker? _matching(String text) {
    final name = text.trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final w in _workers) {
      if (w.fullName.toLowerCase() == name) return w;
    }
    return null;
  }

  String get _hint {
    if (_isLoading) return 'Cargando trabajadores...';
    if (_workers.isEmpty) return 'Escriba el nombre';
    return 'Buscar o escribir nombre...';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => RawAutocomplete<CertifiedWorker>(
            textEditingController: widget.controller,
            focusNode: _focusNode,
            optionsBuilder: (value) {
              final query = value.text.trim().toLowerCase();
              if (query.isEmpty) return _workers;
              return _workers.where((w) => w.fullName.toLowerCase().contains(query));
            },
            displayStringForOption: (w) => w.fullName,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) => AppTextField(
              label: widget.label,
              controller: controller,
              focusNode: focusNode,
              hintText: _hint,
              textCapitalization: TextCapitalization.words,
              validator: widget.validator,
              suffixIcon: _workers.isEmpty
                  ? null
                  : const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            ),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 240,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final worker = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(worker.fullName),
                        subtitle: worker.isExpired
                            ? Text(
                                'Certificación vencida',
                                style: AppTextStyles.captionText
                                    .copyWith(color: AppColors.warning),
                              )
                            : (worker.position == null ? null : Text(worker.position!)),
                        onTap: () => onSelected(worker),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final worker = _matching(widget.controller.text);
            if (worker == null || !worker.isExpired) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  border: Border.all(color: AppColors.warning),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Certificación vencida. Se puede registrar igual; el Administrador debe regularizarla.',
                        style: AppTextStyles.fieldLabel,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
