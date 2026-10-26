import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/router.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/models/auto_sync_event.dart';
import 'package:panela_sys/services/cooperative_preferences_service.dart';
import 'package:panela_sys/widgets/common/responsive_text_scale.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global key for showing SnackBars from auto-sync events
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // ── Cargar cooperativa guardada (si existe) ──────────────────────────────
  // En el primer arranque no habrá código guardado → isConfigured = false
  // → el router redirigirá a la pantalla de selección de cooperativa.
  final savedCooperativeCode =
      await CooperativePreferencesService.getSavedCode();
  if (savedCooperativeCode != null) {
    AppConfig.setCooperative(savedCooperativeCode);
  }

  // ── Inicializar Supabase ─────────────────────────────────────────────────
  // La URL y anon key son las mismas para todas las cooperativas.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize auto-sync listener on app startup
    ref.watch(autoSyncStateProvider);

    // Listen to auto-sync events and show SnackBars
    ref.listen<AsyncValue<AutoSyncEvent>>(
      autoSyncEventProvider,
      (previous, next) {
        next.whenData((event) {
          final messenger = scaffoldMessengerKey.currentState;
          if (messenger == null) return;

          switch (event.type) {
            case AutoSyncEventType.started:
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Conectado - Subiendo datos pendientes...'),
                  backgroundColor: AppColors.primary,
                  duration: Duration(seconds: 2),
                ),
              );
              break;

            case AutoSyncEventType.completed:
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Datos subidos correctamente ✓'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 2),
                ),
              );
              break;

            case AutoSyncEventType.failed:
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    event.errorMessage ?? 'No se pudieron subir los datos.',
                  ),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                ),
              );
              break;
          }
        });
      },
    );

    // El título usa el nombre de la cooperativa si ya está configurada,
    // o un nombre genérico en el primer arranque.
    final appTitle = AppConfig.isConfigured
        ? AppConfig.current.displayTitle
        : 'Panela UDEP';

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: appTitle,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'PE'),
        Locale('es', ''),
      ],
      locale: const Locale('es', 'PE'),
      builder: (context, child) => ResponsiveTextScale(child: child!),
      theme: ThemeData(
        // Los widgets de Material (switches, diálogos, selectores de fecha)
        // toman los colores exactos de AppColors, no tonos derivados.
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.textWhite,
          secondary: AppColors.primaryLight,
          error: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          outline: AppColors.inputBorder,
          outlineVariant: AppColors.border,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        datePickerTheme: DatePickerThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          headerBackgroundColor: AppColors.primary,
          headerForegroundColor: AppColors.textWhite,
          weekdayStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          dayStyle: TextStyle(
            color: AppColors.textPrimary,
          ),
          yearStyle: TextStyle(
            color: AppColors.textPrimary,
          ),
          todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.primaryLight.withValues(alpha: 0.2);
          }),
          todayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.textWhite;
            }
            return AppColors.primary;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return null;
          }),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.textWhite;
            }
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textTertiary;
            }
            return AppColors.textPrimary;
          }),
        ),
      ),
      routerConfig: createRouter(),
    );
  }
}
