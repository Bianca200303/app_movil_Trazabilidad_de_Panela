import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/core/utils/date_utils.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_info_row.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_error.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_loading.dart';
import 'package:panela_sys/screens/historial/widgets/shared/historial_period_filter.dart';
import 'package:panela_sys/services/stowage_transport_inspection_service.dart';

class StowageInspectionList extends StatefulWidget {
  const StowageInspectionList({required this.service, super.key});
  final StowageTransportInspectionService service;

  @override
  State<StowageInspectionList> createState() => _StowageInspectionListState();
}

class _StowageInspectionListState extends State<StowageInspectionList> {
  late DateTime _from;
  late DateTime _to;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    final (from, to) = historialPeriodoRange(HistorialPeriodo.esteMes);
    _from = from;
    _to = to;
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await widget.service.getInspectionsWithExitDetails(from: _from, to: _to);
      setState(() { _items = raw; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HistorialPeriodFilter(
          onChanged: (from, to) { _from = from; _to = to; _load(); },
        ),
        SizedBox(height: context.responsiveSpacing),
        if (!_isLoading && _error == null)
          Padding(
            padding: EdgeInsets.only(bottom: context.responsiveSpacing / 2),
            child: Text(
              '${_items.length} inspección${_items.length != 1 ? 'es' : ''} encontrada${_items.length != 1 ? 's' : ''}',
              style: AppTextStyles.captionText,
            ),
          ),
        if (_isLoading)
          const HistorialLoadingWidget(message: 'Cargando inspecciones...')
        else if (_error != null)
          HistorialErrorWidget(error: _error!, onRetry: _load)
        else if (_items.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(context.responsiveSpacing * 2),
              child: Text(
                'No hay inspecciones en este período.',
                style: AppTextStyles.captionText,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _items.map((item) {
              final id = item['id']?.toString() ?? '';
              return _StowageCard(
                data: item,
                isExpanded: _expanded.contains(id),
                onToggle: () => setState(() {
                  _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
                }),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _StowageCard extends StatelessWidget {
  const _StowageCard({
    required this.data,
    required this.isExpanded,
    required this.onToggle,
  });

  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final exitReg     = data['exit_registration'] as Map<String, dynamic>?;
    final exitCode    = exitReg?['exit_code'] as String?;
    final regUser     = data['registered_by_user'] as Map<String, dynamic>?;
    final regName     = regUser != null ? '${regUser['first_name']} ${regUser['last_name']}' : null;
    final docNumber   = exitReg?['document_number'] as String?;
    final exitItems   = (exitReg?['exit_items'] as List?) ?? [];
    final date        = data['inspection_date'] as String?;
    final carrierName = data['carrier_name'] as String? ?? '—';
    final carrierRuc  = data['carrier_ruc']  as String?;
    final carrierLic  = data['carrier_license'] as String?;
    final vBrand      = data['vehicle_brand'] as String? ?? '—';
    final vPlate      = data['vehicle_plate'] as String? ?? '—';
    final vCond       = data['vehicle_condition'] as String?;
    final isApto      = vCond == 'adequate';
    final obs         = data['observations'] as String?;
    final sackClean   = data['sack_clean_condition'] as String? ?? '—';
    final sackTied    = data['sack_tied_condition']  as String? ?? '—';

    final checkVehicle = <String, bool>{
      'Llanta repuesto':   data['has_spare_tire']         == true,
      'SOAT vigente':      data['has_valid_soat']          == true,
      'Revisión técnica':  data['has_technical_review']    == true,
      'Botiquín':          data['has_first_aid_kit']       == true,
      'Extintor':          data['has_fire_extinguisher']   == true,
      'GPS':               data['has_gps']                 == true,
      'Útiles limpieza':   data['has_cleaning_supplies']   == true,
    };
    final checkLimpieza = <String, bool>{
      'Piso limpio':       data['floors_clean']   == true,
      'Paredes limpias':   data['walls_clean']    == true,
      'Techo limpio':      data['ceilings_clean'] == true,
      'Sin olores':        data['no_strange_odors'] == true,
      'Toldo limpio':      data['tarp_clean']     == true,
      'Pallets limpios':   data['pallets_clean']  == true,
    };

    final allChecks = {...checkVehicle, ...checkLimpieza};
    final compliant = allChecks.values.where((v) => v).length;
    final total = allChecks.length;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.inputBorder, width: AppDimensions.inputBorderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApto ? Icons.check_circle : Icons.warning,
                        size: 16,
                        color: isApto ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          exitCode ?? '—',
                          style: AppTextStyles.fieldLabel.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      Text(
                        date != null ? AppDateUtils.formatDDMMYYYY(DateTime.tryParse(date) ?? DateTime.now()) : '—',
                        style: AppTextStyles.captionText,
                      ),
                      SizedBox(width: context.responsiveSpacing / 2),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Text(
                    '$carrierName · $vPlate',
                    style: AppTextStyles.captionText.copyWith(color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: context.responsiveSpacing / 4),
                  Row(children: [
                    _Tag(
                      label: isApto ? 'APTO' : 'NO APTO',
                      color: isApto ? Colors.green[700]! : Colors.red[700]!,
                    ),
                    SizedBox(width: context.responsiveSpacing / 2),
                    _Tag(
                      label: '$compliant/$total checks',
                      color: compliant == total ? Colors.green[700]! : AppColors.warning,
                    ),
                  ]),
                ],
              ),
            ),

            // Detalle expandible
            if (isExpanded) ...[
              Divider(height: 1, color: AppColors.inputBorder),
              Padding(
                padding: context.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Registrado por
                    if (regName != null) ...[
                      HistorialInfoRow(label: 'Registrado por:', value: regName),
                      SizedBox(height: context.responsiveSpacing / 2),
                    ],

                    // Transportista
                    _SectionTitle('Transportista'),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(label: 'Nombre:', value: carrierName),
                    if (carrierRuc?.isNotEmpty == true) ...[
                      SizedBox(height: context.responsiveSpacing / 4),
                      HistorialInfoRow(label: 'RUC:', value: carrierRuc!),
                    ],
                    if (carrierLic?.isNotEmpty == true) ...[
                      SizedBox(height: context.responsiveSpacing / 4),
                      HistorialInfoRow(label: 'Licencia:', value: carrierLic!),
                    ],
                    SizedBox(height: context.responsiveSpacing),

                    // Vehículo
                    _SectionTitle('Vehículo'),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(label: 'Marca / Placa:', value: '$vBrand · $vPlate'),
                    SizedBox(height: context.responsiveSpacing / 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          Text(
                            isApto ? 'APTO' : 'NO APTO',
                            style: TextStyle(fontSize: 13, color: isApto ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing),

                    // Checklist vehículo
                    _SectionTitle('Checklist del vehículo'),
                    SizedBox(height: context.responsiveSpacing / 4),
                    _ChecklistGrid(items: checkVehicle),
                    SizedBox(height: context.responsiveSpacing),

                    // Checklist limpieza
                    _SectionTitle('Condiciones de limpieza'),
                    SizedBox(height: context.responsiveSpacing / 4),
                    _ChecklistGrid(items: checkLimpieza),
                    SizedBox(height: context.responsiveSpacing),

                    // Sacos
                    _SectionTitle('Condición de sacos'),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(label: 'Limpieza:', value: sackClean),
                    SizedBox(height: context.responsiveSpacing / 4),
                    HistorialInfoRow(label: 'Amarrado / cosido:', value: sackTied),

                    // GR
                    if (docNumber?.isNotEmpty == true) ...[
                      SizedBox(height: context.responsiveSpacing),
                      HistorialInfoRow(label: 'Guía de Remisión:', value: docNumber!),
                    ],

                    // Observaciones
                    if (obs?.isNotEmpty == true) ...[
                      SizedBox(height: context.responsiveSpacing),
                      _SectionTitle('Observaciones'),
                      SizedBox(height: context.responsiveSpacing / 4),
                      Text(obs!, style: AppTextStyles.captionText),
                    ],

                    // Lotes
                    if (exitItems.isNotEmpty) ...[
                      SizedBox(height: context.responsiveSpacing),
                      _SectionTitle('Lotes de campo (${exitItems.length})'),
                      SizedBox(height: context.responsiveSpacing / 4),
                      ...exitItems.map((item) {
                        final pb = item['production_batch'] as Map<String, dynamic>?;
                        final prod = pb?['producer'] as Map<String, dynamic>?;
                        final prodName = prod != null ? '${prod['first_name']} ${prod['last_name']}' : null;
                        final kg = item['quantity_kg'];
                        return Padding(
                          padding: EdgeInsets.only(bottom: context.responsiveSpacing / 4),
                          child: Row(children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(child: Text(
                              '${prodName ?? '—'}${kg != null ? ' · $kg kg' : ''}',
                              style: AppTextStyles.captionText,
                            )),
                          ]),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.fieldLabel.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
  );
}

class _ChecklistGrid extends StatelessWidget {
  const _ChecklistGrid({required this.items});
  final Map<String, bool> items;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: context.responsiveSpacing / 2,
      runSpacing: context.responsiveSpacing / 4,
      children: items.entries.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            e.value ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: e.value ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(e.key, style: AppTextStyles.captionText),
        ],
      )).toList(),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label, style: AppTextStyles.captionText.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 10)),
  );
}
