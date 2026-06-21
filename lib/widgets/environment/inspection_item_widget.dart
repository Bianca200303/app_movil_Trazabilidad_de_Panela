import 'package:flutter/material.dart';
import 'package:panela_sys/models/environment_inspection.dart';
import 'package:panela_sys/widgets/forms/app_text_field.dart';
import 'package:panela_sys/widgets/forms/yes_no_field.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/screen_utils.dart';

class InspectionItemWidget extends StatefulWidget {
  final String itemDescription;
  final InspectionCondition condition;
  final String correctiveActions;
  final String observations;
  final String? personnelNote;
  final Function(InspectionCondition) onConditionChanged;
  final Function(String) onCorrectiveActionsChanged;
  final Function(String) onObservationsChanged;

  const InspectionItemWidget({
    super.key,
    required this.itemDescription,
    required this.condition,
    required this.correctiveActions,
    required this.observations,
    this.personnelNote,
    required this.onConditionChanged,
    required this.onCorrectiveActionsChanged,
    required this.onObservationsChanged,
  });

  @override
  State<InspectionItemWidget> createState() => _InspectionItemWidgetState();
}

class _InspectionItemWidgetState extends State<InspectionItemWidget> {
  late final TextEditingController _correctiveActionsController;
  late final TextEditingController _observationsController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _correctiveActionsController = TextEditingController(text: widget.correctiveActions);
    _observationsController = TextEditingController(text: widget.observations);
  }

  @override
  void dispose() {
    _correctiveActionsController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  void _handleConditionChanged(bool isCompliant) {
    widget.onConditionChanged(
      isCompliant ? InspectionCondition.compliant : InspectionCondition.nonCompliant,
    );
    // Despliega los campos automáticamente para que se documente de inmediato.
    if (!isCompliant && !_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item description with pencil icon (right-aligned)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description column (left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itemDescription,
                    style: AppTextStyles.fieldLabel,
                  ),
                  if (widget.personnelNote != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.personnelNote!,
                      style: AppTextStyles.bodyTextSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Pencil icon with badges (right side)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  tooltip: _isExpanded ? 'Ocultar campos' : 'Mostrar campos',
                ),

                // Red badge (top-right) for corrective actions
                if (widget.correctiveActions.trim().isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),

                // Yellow badge (bottom-right) for observations
                if (widget.observations.trim().isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        YesNoField(
          value: widget.condition == InspectionCondition.compliant,
          yesLabel: 'CONFORME',
          noLabel: 'NO CONFORME',
          onChanged: _handleConditionChanged,
        ),

        // Collapsible textareas (shown when expanded)
        if (_isExpanded) ...[
          const SizedBox(height: 12),

          // Corrective actions - always available
          AppTextField(
            label: 'Acciones correctivas',
            controller: _correctiveActionsController,
            onChanged: widget.onCorrectiveActionsChanged,
            maxLines: 3,
            hintText: 'Describe las acciones correctivas si son necesarias',
          ),

          const SizedBox(height: 12),

          // Observations - always available
          AppTextField(
            label: 'Observaciones (opcional)',
            controller: _observationsController,
            onChanged: widget.onObservationsChanged,
            maxLines: 3,
            hintText: 'Agrega observaciones adicionales si es necesario',
          ),
        ],

        // Divider
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing),
          child: const Divider(height: 1),
        ),
      ],
    );
  }
}
