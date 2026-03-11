import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/core/offline/sync_status.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/models/coop_module.dart';
import 'package:panela_sys/models/plot.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/services/coop_modules_service.dart';
import 'package:panela_sys/services/plot_service.dart';
import 'package:panela_sys/services/producer_service.dart';
import 'package:panela_sys/widgets/forms/app_dropdown.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/radio_group.dart';

/// Diálogo de edición de productor y sus parcelas.
///
/// Soporta dos modos:
/// - Productor sincronizado (id = UUID): edita directamente en Supabase.
///   Requiere conexión a internet.
/// - Productor pendiente (id = entero): edita en la base de datos local.
///   Funciona sin conexión.
class ProducerEditDialog extends ConsumerStatefulWidget {
  const ProducerEditDialog({
    required this.producerData,
    required this.onSaved,
    super.key,
  });

  /// Datos del productor del mapa del historial.
  final Map<String, dynamic> producerData;

  /// Callback invocado tras guardar exitosamente.
  final VoidCallback onSaved;

  @override
  ConsumerState<ProducerEditDialog> createState() => _ProducerEditDialogState();
}

class _ProducerEditDialogState extends ConsumerState<ProducerEditDialog> {
  late final ProducerService _producerService;
  late final PlotService _plotService;
  late final CoopModulesService _modulesService;

  final _formKey = GlobalKey<FormState>();
  final _namesController = TextEditingController();
  final _surnamesController = TextEditingController();
  final _appagropCodeController = TextEditingController();

  List<CoopModule> _modules = [];
  String? _selectedModuleId;
  String _memberStatus = 'SOCIO';

  // Existing plots loaded from service
  List<Plot> _plots = [];
  // Map: plot.id → controller for editing name
  final Map<String, TextEditingController> _plotControllers = {};

  // New plots pending to be created on save
  final List<String> _plotsToAdd = [];
  final _newPlotNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  // Whether this producer is synced (UUID) or pending (local int)
  late final bool _isSynced;
  late final String _producerId;

  @override
  void initState() {
    super.initState();

    final db = ref.read(appDatabaseProvider);
    _producerService = ProducerService(db: db);
    _plotService = PlotService(db: db);
    _modulesService = CoopModulesService(db: db);

    _producerId = widget.producerData['id'].toString();
    final syncStatus =
        widget.producerData['syncStatus'] as int? ?? SyncStatus.synced.value;
    _isSynced = syncStatus == SyncStatus.synced.value;

    // Pre-fill from historial data using separated firstName/lastName fields
    _namesController.text =
        widget.producerData['firstName']?.toString() ?? '';
    _surnamesController.text =
        widget.producerData['lastName']?.toString() ?? '';
    if (AppConfig.current.features.useAppagropCode) {
      _appagropCodeController.text =
          widget.producerData['appagropCode']?.toString() ?? '';
    }
    _memberStatus =
        widget.producerData['condicion'] == 'Socio' ? 'SOCIO' : 'NO SOCIO';

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Check connectivity for synced producers
      if (_isSynced) {
        final isConnected = await NetworkDetector().isConnected;
        if (!isConnected) {
          setState(() {
            _isLoading = false;
            _loadError =
                'Necesitas conexión a internet para editar registros sincronizados.';
          });
          return;
        }
      }

      // Load modules
      final modules = await _modulesService.getModules();

      // Try coopModuleId directly; fall back to matching by name
      final coopModuleId = widget.producerData['coopModuleId']?.toString();
      String? resolvedModuleId;
      if (coopModuleId != null && modules.any((m) => m.id == coopModuleId)) {
        resolvedModuleId = coopModuleId;
      } else {
        final moduloName = widget.producerData['modulo'].toString();
        final matchedModule = modules.firstWhere(
          (m) => m.name == moduloName,
          orElse: () => CoopModule(id: '', name: moduloName),
        );
        resolvedModuleId =
            matchedModule.id.isNotEmpty ? matchedModule.id : null;
      }

      // Load producer's plots
      final plots = await _plotService.getPlotsForEdit(_producerId);
      for (final plot in plots) {
        _plotControllers[plot.id] = TextEditingController(text: plot.name);
      }

      if (mounted) {
        setState(() {
          _modules = modules;
          _selectedModuleId = resolvedModuleId;
          _plots = plots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ── Agregar parcela ──────────────────────────────────────────────────────────

  void _addNewPlot() {
    final name = _newPlotNameController.text.trim();

    // Validate: if names required for this cooperative
    if (AppConfig.current.features.requirePlotNames && name.isEmpty) {
      _showSnack('Ingresa el nombre de la parcela', isError: true);
      return;
    }

    // Check duplicate among existing and pending
    if (name.isNotEmpty) {
      final existsInCurrent = _plots.any(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
      final existsInPending = _plotsToAdd.any(
        (n) => n.toLowerCase() == name.toLowerCase(),
      );
      if (existsInCurrent || existsInPending) {
        _showSnack('Ya existe una parcela con ese nombre', isError: true);
        return;
      }
    }

    setState(() {
      _plotsToAdd.add(name);
      _newPlotNameController.clear();
    });
  }

  void _removePendingPlot(int index) {
    setState(() => _plotsToAdd.removeAt(index));
  }

  // ── Guardar ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedModuleId == null) {
      _showSnack('Selecciona un módulo', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = CreateProducerRequest(
        firstName: _namesController.text.trim(),
        lastName: _surnamesController.text.trim(),
        dni: widget.producerData['dni'].toString(),
        coopModuleId: _selectedModuleId!,
        isMember: _memberStatus == 'SOCIO',
        appagropCode: AppConfig.current.features.useAppagropCode
            ? _appagropCodeController.text.trim().isNotEmpty
                ? _appagropCodeController.text.trim()
                : null
            : null,
      );

      if (_isSynced) {
        // ── Productor sincronizado: actualiza en Supabase ──────────────────
        await _producerService.updateProducer(_producerId, request);

        // Actualiza nombres de parcelas existentes
        for (final plot in _plots) {
          final controller = _plotControllers[plot.id];
          if (controller != null) {
            final newName = controller.text.trim();
            if (newName != plot.name) {
              await _plotService.updatePlot(
                plot.id,
                CreatePlotRequest(name: newName, producerId: _producerId),
              );
            }
          }
        }

        // Agrega nuevas parcelas
        for (final name in _plotsToAdd) {
          await _plotService.addPlotForEdit(_producerId, name);
        }
      } else {
        // ── Productor pendiente: actualiza en DB local ─────────────────────
        final localId = int.parse(_producerId);
        await _producerService.updateLocalPendingProducer(localId, request);

        // Actualiza nombres de parcelas existentes localmente
        for (final plot in _plots) {
          final controller = _plotControllers[plot.id];
          if (controller != null) {
            final newName = controller.text.trim();
            if (newName != plot.name) {
              await _plotService.updateLocalPendingPlot(
                  int.parse(plot.id), newName);
            }
          }
        }

        // Agrega nuevas parcelas localmente
        for (final name in _plotsToAdd) {
          await _plotService.addPlotForEdit(_producerId, name);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        _showSnack('Cambios guardados correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field es requerido';
    return null;
  }

  @override
  void dispose() {
    _namesController.dispose();
    _surnamesController.dispose();
    _appagropCodeController.dispose();
    _newPlotNameController.dispose();
    for (final c in _plotControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusMedium),
          topRight: Radius.circular(AppDimensions.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editar productor',
              style: AppTextStyles.bodyText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              style: AppTextStyles.bodyText.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // DNI (read-only)
          _buildReadOnlyField(
            label: 'DNI',
            value: widget.producerData['dni'].toString(),
            hint: 'El DNI no puede modificarse',
          ),
          const SizedBox(height: 12),

          AppTextField(
            label: 'Nombres',
            controller: _namesController,
            textCapitalization: TextCapitalization.words,
            validator: (v) => _validateRequired(v, 'Nombres'),
          ),
          const SizedBox(height: 12),

          AppTextField(
            label: 'Apellidos',
            controller: _surnamesController,
            textCapitalization: TextCapitalization.words,
            validator: (v) => _validateRequired(v, 'Apellidos'),
          ),
          const SizedBox(height: 12),

          AppDropdown<String>(
            label: 'Módulo',
            hintText: 'Selecciona un módulo',
            value: _selectedModuleId,
            options: _modules
                .map((m) => DropdownOption(value: m.id, label: m.name))
                .toList(),
            onChanged: (v) => setState(() => _selectedModuleId = v),
          ),
          const SizedBox(height: 12),

          if (AppConfig.current.features.useAppagropCode) ...[
            AppTextField(
              label: 'APPAGROP',
              controller: _appagropCodeController,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => _validateRequired(v, 'APPAGROP'),
            ),
            const SizedBox(height: 12),
          ],

          AppRadioGroup<String>(
            label: 'Condición',
            options: [
              RadioOption(value: 'SOCIO', label: 'SOCIO'),
              RadioOption(value: 'NO SOCIO', label: 'NO SOCIO'),
            ],
            groupValue: _memberStatus,
            onChanged: (v) => setState(() => _memberStatus = v ?? 'SOCIO'),
          ),

          // ── Sección de parcelas ────────────────────────────────────────────
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.landscape, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Parcelas', style: AppTextStyles.fieldLabel),
            ],
          ),
          const SizedBox(height: 12),

          // Parcelas existentes (editar nombre)
          if (_plots.isNotEmpty) ...[
            ..._plots.map((plot) => _buildPlotEditor(plot)),
            const SizedBox(height: 8),
          ],

          // Parcelas pendientes de agregar
          if (_plotsToAdd.isNotEmpty) ...[
            ..._plotsToAdd.asMap().entries.map(
                  (entry) => _buildPendingPlotChip(entry.key, entry.value),
                ),
            const SizedBox(height: 8),
          ],

          // Input para agregar nueva parcela
          _buildAddPlotRow(),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('CANCELAR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('GUARDAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Widgets auxiliares ───────────────────────────────────────────────────────

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.bodyText
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              if (hint != null)
                Tooltip(
                  message: hint,
                  child: const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tarjeta para editar el nombre de una parcela existente.
  Widget _buildPlotEditor(Plot plot) {
    final controller = _plotControllers[plot.id]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tag, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Código: ${plot.code}',
                style: AppTextStyles.smallText
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppTextField(
            label: 'Nombre de parcela',
            controller: controller,
          ),
        ],
      ),
    );
  }

  /// Chip que representa una parcela nueva aún no guardada.
  Widget _buildPendingPlotChip(int index, String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_location_alt_outlined,
              size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name.isEmpty ? 'Parcela sin nombre' : name,
              style: AppTextStyles.smallText.copyWith(
                color: AppColors.primary,
                fontStyle:
                    name.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _removePendingPlot(index),
            child: const Icon(Icons.close, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  /// Fila de input + botón para agregar una nueva parcela.
  Widget _buildAddPlotRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            label: null,
            hintText: AppConfig.current.features.requirePlotNames
                ? 'Nombre de parcela (requerido)'
                : 'Nombre de parcela (opcional)',
            controller: _newPlotNameController,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _addNewPlot,
              tooltip: 'Agregar parcela',
            ),
          ),
        ),
      ],
    );
  }
}
