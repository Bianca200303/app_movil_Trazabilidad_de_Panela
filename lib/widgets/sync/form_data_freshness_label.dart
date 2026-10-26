import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/core/theme/app_text_styles.dart';
import 'package:panela_sys/providers/form_data_refresh_provider.dart';

/// Texto "Datos actualizados hace X" de la pantalla de inicio: le dice al
/// técnico si el celular tiene al día lo necesario para trabajar sin señal.
/// Pasa a ámbar si los datos tienen más de [staleAfter] o nunca se bajaron.
class FormDataFreshnessLabel extends ConsumerStatefulWidget {
  const FormDataFreshnessLabel({super.key});

  static const staleAfter = Duration(hours: 24);

  @override
  ConsumerState<FormDataFreshnessLabel> createState() => _FormDataFreshnessLabelState();
}

class _FormDataFreshnessLabelState extends ConsumerState<FormDataFreshnessLabel> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    // Redibuja cada minuto para que "hace X min" no se quede congelado.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final freshness = ref.watch(formDataRefreshProvider);
    final last = freshness.lastRefreshedAt;

    final String text;
    final IconData icon;
    final bool isStale;
    if (freshness.isRefreshing) {
      text = 'Actualizando datos para trabajar sin señal…';
      icon = Icons.sync;
      isStale = false;
    } else if (last == null) {
      text = 'Datos para trabajar sin señal aún no descargados. '
          'Se descargarán al tener conexión.';
      icon = Icons.cloud_off_outlined;
      isStale = true;
    } else {
      final age = DateTime.now().difference(last);
      text = 'Datos actualizados ${_describeAge(age)}';
      icon = Icons.cloud_done_outlined;
      isStale = age > FormDataFreshnessLabel.staleAfter;
    }

    final color = isStale ? AppColors.warning : AppColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.captionText.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  static String _describeAge(Duration age) {
    if (age.inMinutes < 1) return 'hace un momento';
    if (age.inMinutes < 60) return 'hace ${age.inMinutes} min';
    if (age.inHours < 24) {
      return age.inHours == 1 ? 'hace 1 hora' : 'hace ${age.inHours} horas';
    }
    return age.inDays == 1 ? 'hace 1 día' : 'hace ${age.inDays} días';
  }
}
