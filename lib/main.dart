import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/router.dart';
import 'package:panela_sys/core/theme/app_colors.dart';
import 'package:panela_sys/providers/offline_provider.dart';
import 'package:panela_sys/models/auto_sync_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global key for showing SnackBars from auto-sync events
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    // This watches for connectivity changes and triggers auto-sync when going online
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
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
              break;

            case AutoSyncEventType.completed:
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Datos subidos correctamente ✓'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
              break;

            case AutoSyncEventType.failed:
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Error al subir datos: ${event.errorMessage ?? "Error desconocido"}',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
              break;
          }
        });
      },
    );

    return MaterialApp.router(
              debugShowCheckedModeBanner: false,

      scaffoldMessengerKey: scaffoldMessengerKey,
      title: AppConfig.current.displayTitle,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'PE'), // Spanish (Peru)
        Locale('es', ''), // Spanish (fallback)
      ],
      locale: const Locale('es', 'PE'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
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


