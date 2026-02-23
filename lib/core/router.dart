import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panela_sys/core/routes.dart';
import 'package:panela_sys/services/auth_service.dart';
import 'package:panela_sys/widgets/widgets.dart';


GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home.path,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthService authService = AuthService();
      final isAuthenticated = authService.isAuthenticated;
      final currentLocation = state.matchedLocation;

      // Find the current route
      final currentRoute = AppRoutes.findByPath(currentLocation);
      
      // If user is not authenticated and trying to access protected route
      if (!isAuthenticated && (currentRoute == null || !currentRoute.isPublic)) {
        return AppRoutes.login.path;
      }

      // If user is authenticated and trying to access login/register
      if (isAuthenticated && currentRoute != null && currentRoute.isPublic) {
        return AppRoutes.home.path;
      }

      // No redirect needed
      return null;
    },
    routes: AppRoutes.all.map((route) => _buildRoute(route)).toList(),
  );
}

GoRoute _buildRoute(AppRoute route) {
  return GoRoute(
    path: route.path,
    builder: (BuildContext context, GoRouterState state) {
      // Check if route is under construction
      if (route.isUnderConstruction) {
        return UnderConstructionScreen(screenName: route.displayName);
      }
      return route.screen;
    },
  );
}