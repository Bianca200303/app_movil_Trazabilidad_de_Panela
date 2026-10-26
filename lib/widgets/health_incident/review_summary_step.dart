import 'package:flutter/material.dart';
import 'package:panela_sys/core/screen_utils.dart';
import 'package:panela_sys/widgets/widgets.dart';

class ReviewSummaryStep extends StatelessWidget {
  final String moduleName;
  final String employeeName;
  final String workArea;
  final String registrationDate;
  final String symptomsDescription;
  final bool actionRest;
  final bool actionMedicalAttention;
  final bool actionRelocation;
  final bool actionMedication;
  final bool actionOther;
  final String? otherActionDetail;
  final String? returnDate;
  final bool certificatePresented;
  final bool isSaving;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const ReviewSummaryStep({
    super.key,
    required this.moduleName,
    required this.employeeName,
    required this.workArea,
    required this.registrationDate,
    required this.symptomsDescription,
    required this.actionRest,
    required this.actionMedicalAttention,
    required this.actionRelocation,
    required this.actionMedication,
    required this.actionOther,
    this.otherActionDetail,
    this.returnDate,
    required this.certificatePresented,
    required this.isSaving,
    required this.onSubmit,
    required this.onBack,
  });

  String _getActionsText() {
    final List<String> actions = [];
    if (actionRest) actions.add('Descanso');
    if (actionMedicalAttention) actions.add('Atención médica');
    if (actionRelocation) actions.add('Reubicación');
    if (actionMedication) actions.add('Medicación');
    if (actionOther) {
      actions.add('Otro${otherActionDetail != null ? ': $otherActionDetail' : ''}');
    }
    return actions.isEmpty ? 'Ninguna' : actions.join(', ');
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBackButton(
          onPressed: onBack,
          isExpanded: false,
        ),
        SizedBox(height: context.responsiveSpacing),
        const AppTitle(
          title: 'Paso 5: Resumen y Confirmación',
        ),
        SizedBox(height: context.responsiveSpacing * 1.5),
        FormSection(
          subtitle: 'Revisa la información antes de guardar',
          children: [
            const Text(
              'DATOS DE IDENTIFICACIÓN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem('Módulo', moduleName),
            _buildSummaryItem('Nombre del personal', employeeName),
            _buildSummaryItem('Área de trabajo', workArea),
            _buildSummaryItem('Fecha de registro', registrationDate),
            const Divider(height: 24),
            const Text(
              'DESCRIPCIÓN DEL INCIDENTE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
                'Síntomas o lesiones', symptomsDescription),
            const Divider(height: 24),
            const Text(
              'ACCIONES TOMADAS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem('Acciones', _getActionsText()),
            const Divider(height: 24),
            const Text(
              'SEGUIMIENTO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
                'Fecha de reingreso', returnDate ?? 'No registrada'),
            _buildSummaryItem('Certificado médico presentado',
                certificatePresented ? 'Sí' : 'No'),
          ],
        ),
        SizedBox(height: context.responsiveSpacing * 2),
        AppButton(
          onPressed: isSaving ? null : onSubmit,
          text: isSaving ? 'Guardando...' : 'Guardar registro',
          isLoading: isSaving,
        ),
      ],
    );
  }
}
