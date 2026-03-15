import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/production_calculator.dart';

class CaneDensityNotifier extends StateNotifier<double> {
  CaneDensityNotifier() : super(ProductionCalculator.sugarCaneDensity);

  final _supabase = Supabase.instance.client;

  void _safeSetState(double value) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      state = value;
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) state = value;
      });
    }
  }

  Future<void> load() async {
    try {
      final data = await _supabase
          .from('cooperatives')
          .select('cane_density')
          .eq('id', AppConfig.current.id)
          .single();
      final value = (data['cane_density'] as num?)?.toDouble();
      if (value != null && value > 0) _safeSetState(value);
    } catch (_) {
      // Keep default if column doesn't exist yet or query fails
    }
  }

  Future<void> update(double newDensity) async {
    await _supabase
        .from('cooperatives')
        .update({'cane_density': newDensity})
        .eq('id', AppConfig.current.id);
    _safeSetState(newDensity);
  }
}

final caneDensityProvider =
    StateNotifierProvider<CaneDensityNotifier, double>((ref) {
  final notifier = CaneDensityNotifier();
  notifier.load();
  return notifier;
});
