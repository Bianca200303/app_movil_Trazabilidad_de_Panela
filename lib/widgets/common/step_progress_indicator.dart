import 'package:flutter/material.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_dimensions.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';

/// Indicador de progreso para flujos de pasos.
/// - totalSteps <= 5: muestra círculos numerados con conectores
/// - totalSteps > 5: muestra barra lineal con texto "Paso X de Y"
class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// Paso actual (base 1).
  final int currentStep;
  final int totalSteps;

  bool get _useCircles => totalSteps <= 5;

  @override
  Widget build(BuildContext context) {
    return _useCircles ? _buildCircles() : _buildBar();
  }

  Widget _buildCircles() {
    return Row(
      children: [
        for (int i = 1; i <= totalSteps; i++) ...[
          _StepDot(step: i, currentStep: currentStep),
          if (i < totalSteps)
            Expanded(
              child: Container(
                height: 2,
                color: i < currentStep ? AppColors.primary : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildBar() {
    final progress = currentStep / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
          child: Text(
            'Paso $currentStep de $totalSteps',
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.step, required this.currentStep});

  final int step;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final isCompleted = step < currentStep;
    final isCurrent = step == currentStep;
    final isFilled = isCompleted || isCurrent;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: isFilled ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: AppColors.textWhite)
            : Text(
                '$step',
                style: TextStyle(
                  color: isCurrent ? AppColors.textWhite : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}
