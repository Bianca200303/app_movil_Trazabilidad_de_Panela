import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/core/offline/debug_logger.dart';
import 'package:panela_sys/core/offline/network_detector.dart';
import 'package:panela_sys/providers/offline_provider.dart';

/// Estado de los datos que el celular guarda para trabajar sin señal
/// (módulos, productores, trabajadores certificados, lotes recientes...).
@immutable
class FormDataFreshness {
  /// Última actualización completa, o null si aún no se descargaron.
  final DateTime? lastRefreshedAt;
  final bool isRefreshing;

  const FormDataFreshness({this.lastRefreshedAt, this.isRefreshing = false});

  FormDataFreshness copyWith({DateTime? lastRefreshedAt, bool? isRefreshing}) =>
      FormDataFreshness(
        lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );
}

/// Mantiene al día, sin que el usuario haga nada, los datos para trabajar
/// sin señal. Se actualizan:
///   - al iniciar sesión (login_screen, siempre);
///   - al abrir la app o volver a ella (si la sesión ya estaba iniciada);
///   - al volver la señal, después de subir los pendientes (AutoSyncNotifier).
/// Salvo al iniciar sesión, como máximo una vez cada [minInterval] para no
/// gastar datos móviles. Si falla, no se avisa: se reintenta en el siguiente
/// momento y el texto de la pantalla de inicio sigue mostrando la fecha real.
class FormDataRefreshNotifier extends StateNotifier<FormDataFreshness> {
  static const minInterval = Duration(minutes: 30);

  final Ref _ref;
  late final AppLifecycleListener _lifecycleListener;

  FormDataRefreshNotifier(this._ref) : super(const FormDataFreshness()) {
    _lifecycleListener = AppLifecycleListener(onResume: refreshIfStale);
    reload();
  }

  /// Vuelve a leer la fecha guardada (tras iniciar o cerrar sesión).
  Future<void> reload() async {
    final at = await _ref.read(formDataCacheServiceProvider).getLastRefreshedAt();
    if (mounted) state = FormDataFreshness(lastRefreshedAt: at, isRefreshing: state.isRefreshing);
  }

  /// Actualiza los datos si pasaron más de [minInterval] desde la última vez,
  /// hay sesión, hay señal y no se está sincronizando.
  Future<void> refreshIfStale() async {
    if (state.isRefreshing) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    final last = state.lastRefreshedAt;
    if (last != null && DateTime.now().difference(last) < minInterval) return;

    // Mientras se suben pendientes no se tocan las tablas locales: al
    // terminar, AutoSyncNotifier vuelve a llamar a este método.
    if (_ref.read(autoSyncStateProvider)) return;
    if (!await NetworkDetector().isConnected) return;

    state = state.copyWith(isRefreshing: true);
    try {
      await _ref.read(formDataCacheServiceProvider).refreshAllFormData();
      DebugLogger.info('FormDataRefreshNotifier', 'refreshIfStale', 'Datos para trabajar sin señal actualizados');
    } catch (e) {
      DebugLogger.warning('FormDataRefreshNotifier', 'refreshIfStale', 'No se pudieron actualizar los datos: $e');
    } finally {
      final at = await _ref.read(formDataCacheServiceProvider).getLastRefreshedAt();
      if (mounted) state = FormDataFreshness(lastRefreshedAt: at);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }
}

final formDataRefreshProvider =
    StateNotifierProvider<FormDataRefreshNotifier, FormDataFreshness>(
  (ref) => FormDataRefreshNotifier(ref),
);
