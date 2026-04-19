import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/app_config.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/widgets/widgets.dart';


GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home.path,
    redirect: (BuildContext context, GoRouterState state) {
      final currentLocation = state.matchedLocation;

      // ── Paso 1: Verificar que la cooperativa ya fue configurada ────────────
      // Si no está configurada, redirigir a la pantalla de selección.
      // Esta es la PRIMERA verificación, antes que cualquier control de auth.
      if (!AppConfig.isConfigured) {
        if (currentLocation == AppRoutes.cooperativeSelection.path) {
          return null; // Ya está en la pantalla correcta
        }
        return AppRoutes.cooperativeSelection.path;
      }

      // ── Paso 2: Si la cooperativa ya está configurada y va a /select-cooperative
      // redirigir según estado de autenticación ──────────────────────────────
      if (currentLocation == AppRoutes.cooperativeSelection.path) {
        final isAuthenticated = AuthService().isAuthenticated;
        return isAuthenticated ? AppRoutes.home.path : AppRoutes.login.path;
      }

      // ── Paso 3: Control de autenticación (lógica original) ────────────────
      final isAuthenticated = AuthService().isAuthenticated;
      final currentRoute = AppRoutes.findByPath(currentLocation);

      // Si no está autenticado y trata de acceder a ruta protegida → login
      if (!isAuthenticated && (currentRoute == null || !currentRoute.isPublic)) {
        return AppRoutes.login.path;
      }

      // Si está autenticado y va a una ruta pública → home
      if (isAuthenticated && currentRoute != null && currentRoute.isPublic) {
        return AppRoutes.home.path;
      }

      return null;
    },
    routes: AppRoutes.all.map((route) => _buildRoute(route)).toList(),
  );
}

GoRoute _buildRoute(AppRoute route) {
  return GoRoute(
    path: route.path,
    builder: (BuildContext context, GoRouterState state) {
      if (route.isUnderConstruction) {
        return UnderConstructionScreen(screenName: route.displayName);
      }
      return route.screen;
    },
  );
}
