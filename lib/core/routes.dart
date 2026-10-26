import 'package:flutter/material.dart';
import 'package:panela_sys/screens/cooperative_selection_screen.dart';
import 'package:panela_sys/screens/login_screen.dart';
import 'package:panela_sys/screens/register_screen.dart';
import 'package:panela_sys/screens/home_screen.dart';
import 'package:panela_sys/screens/producer_registration_screen.dart';
import 'package:panela_sys/screens/production_registration_screen.dart';
import 'package:panela_sys/screens/kardex_exit_registration_screen.dart';
import 'package:panela_sys/screens/historial/historial_screen.dart';
import 'package:panela_sys/screens/control_forms_menu_screen.dart';
import 'package:panela_sys/screens/stowage_transport_inspection_registration_screen.dart';
import 'package:panela_sys/screens/environment_inspection_registration_screen.dart';
import 'package:panela_sys/screens/cleaning_disinfection_registration_screen.dart';
import 'package:panela_sys/screens/chlorine_control_registration_screen.dart';
import 'package:panela_sys/screens/pest_control_registration_screen.dart';
import 'package:panela_sys/screens/health_accident_tracking_registration_screen.dart';
import 'package:panela_sys/screens/worker_control_registration_screen.dart';
import 'package:panela_sys/screens/maintenance_control_registration_screen.dart';
import 'package:panela_sys/screens/user_management_screen.dart';
import 'package:panela_sys/screens/module_management_screen.dart';
import 'package:panela_sys/screens/certified_workers_management_screen.dart';

class AppRoute {
  final String path;
  final String displayName;
  final Widget screen;
  final bool isUnderConstruction;
  final bool isPublic;

  const AppRoute({
    required this.path,
    required this.displayName,
    required this.screen,
    this.isUnderConstruction = false,
    this.isPublic = false,
  });
}

class AppRoutes {
  // Configuración inicial (se muestra solo una vez, antes del login)
  static const cooperativeSelection = AppRoute(
    path: '/select-cooperative',
    displayName: 'Seleccionar cooperativa',
    screen: CooperativeSelectionScreen(),
    isPublic: true,
  );

  // Authentication routes
  static const login = AppRoute(
    path: '/login',
    displayName: 'Iniciar sesión',
    screen: LoginScreen(),
    isPublic: true,
  );
  
  static const register = AppRoute(
    path: '/register',
    displayName: 'Registrarse',
    screen: RegisterScreen(),
    isPublic: true,
  );
  
  // Main routes
  static const home = AppRoute(
    path: '/home',
    displayName: 'Inicio',
    screen: HomeScreen(),
  );
  
  // Registration routes
  static const producerRegistration = AppRoute(
    path: '/producer-registration',
    displayName: 'Registrar productor',
    screen: ProducerRegistrationScreen(),
    // isUnderConstruction: true,
  );
  
  static const productionRegistration = AppRoute(
    path: '/production-registration',
    displayName: 'Registrar producción',
    screen: ProductionRegistrationScreen(),
    // isUnderConstruction: true,
  );
  
  static const kardexExit = AppRoute(
    path: '/kardex-exit',
    displayName: 'Registro de salida',
    screen: KardexExitRegistrationScreen(),
    // isUnderConstruction: true,
  );
  
  // Data routes
  static const historial = AppRoute(
    path: '/historial',
    displayName: 'Historial de registros',
    screen: HistorialScreen(),
    // isUnderConstruction: true,
  );

  // Control forms routes
  static const controlFormsModulo = AppRoute(
    path: '/control-forms/modulo',
    displayName: 'Formulario de control Módulo',
    screen: ControlFormsMenuScreen(isModulo: true),
  );

  static const controlFormsProduccion = AppRoute(
    path: '/control-forms/produccion',
    displayName: 'Formulario de control Producción',
    screen: ControlFormsMenuScreen(isModulo: false),
  );

  static const stowageTransportInspectionRegistration = AppRoute(
    path: '/control-forms/stowage-transport-inspection',
    displayName: 'Inspección de estiba y transporte',
    screen: StowageTransportInspectionRegistrationScreen(),
  );

  static const environmentInspectionRegistration = AppRoute(
    path: '/control-forms/environment-inspection',
    displayName: 'Inspección de ambientes, equipo y personal',
    screen: EnvironmentInspectionRegistrationScreen(),
  );

  static const cleaningDisinfectionRegistration = AppRoute(
    path: '/control-forms/cleaning-disinfection',
    displayName: 'Limpieza y desinfección',
    screen: CleaningDisinfectionRegistrationScreen(),
  );

  static const chlorineControlRegistration = AppRoute(
    path: '/control-forms/chlorine-control',
    displayName: 'Control de cloro libre residual',
    screen: ChlorineControlRegistrationScreen(),
  );

  static const pestControlRegistration = AppRoute(
    path: '/control-forms/pest-control',
    displayName: 'Control de plagas',
    screen: PestControlRegistrationScreen(),
  );

  static const healthAccidentTrackingRegistration = AppRoute(
    path: '/control-forms/health-accident-tracking',
    displayName: 'Seguimiento de enfermedades y accidentes',
    screen: HealthAccidentTrackingRegistrationScreen(),
    isUnderConstruction: false,
  );

  static const workerControlRegistration = AppRoute(
    path: '/control-forms/worker-control',
    displayName: 'Control de personal operario',
    screen: WorkerControlRegistrationScreen(),
    isUnderConstruction: false,
  );

  static const maintenanceControlRegistration = AppRoute(
    path: '/control-forms/maintenance-control',
    displayName: 'Mantenimiento hornilla/maquinaria/equipos',
    screen: MaintenanceControlRegistrationScreen(),
    isUnderConstruction: false,
  );

  static const userManagement = AppRoute(
    path: '/user-management',
    displayName: 'Gestión de usuarios',
    screen: UserManagementScreen(),
  );

  static const moduleManagement = AppRoute(
    path: '/module-management',
    displayName: 'Gestión de módulos',
    screen: ModuleManagementScreen(),
  );

  static const certifiedWorkersManagement = AppRoute(
    path: '/certified-workers-management',
    displayName: 'Trabajadores certificados',
    screen: CertifiedWorkersManagementScreen(),
  );

  // Private constructor to prevent instantiation
  AppRoutes._();
  
  // Get all routes as a list
  static List<AppRoute> get all => [
    cooperativeSelection,
    login,
    register,
    home,
    producerRegistration,
    productionRegistration,
    kardexExit,
    historial,
    controlFormsModulo,
    controlFormsProduccion,
    environmentInspectionRegistration,
    cleaningDisinfectionRegistration,
    chlorineControlRegistration,
    pestControlRegistration,
    healthAccidentTrackingRegistration,
    stowageTransportInspectionRegistration,
    workerControlRegistration,
    maintenanceControlRegistration,
    userManagement,
    moduleManagement,
    certifiedWorkersManagement,
  ];
  
  // Get public routes (no authentication required)
  static List<AppRoute> get publicRoutes => all.where((route) => route.isPublic).toList();
  
  // Get protected routes (authentication required)
  static List<AppRoute> get protectedRoutes => all.where((route) => !route.isPublic).toList();
  
  // Get routes under construction
  static List<AppRoute> get underConstructionRoutes => all.where((route) => route.isUnderConstruction).toList();
  
  // Get completed routes
  static List<AppRoute> get completedRoutes => all.where((route) => !route.isUnderConstruction).toList();
  
  // Find route by path
  static AppRoute? findByPath(String path) {
    try {
      return all.firstWhere((route) => route.path == path);
    } catch (e) {
      return null;
    }
  }
}