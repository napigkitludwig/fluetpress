import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../views/auth/login_view.dart';
import '../views/home/home_view.dart';

/// Every named route in the application, in one place.
///
/// Always navigate with these constants rather than raw strings:
/// `Navigator.pushReplacementNamed(context, AppRoutes.home)`.
class AppRoutes {
  const AppRoutes._();

  /// Login screen — also the initial route.
  static const String login = '/';

  /// Home / dashboard screen.
  static const String home = '/home';
}

/// Builds [Route]s and injects the shared controllers into their views.
///
/// Doing dependency injection here keeps views free of service/database access
/// and makes it easy to swap in a different implementation (e.g. a mock in
/// widget tests) without touching the UI.
class AppRouter {
  const AppRouter({required this.authController});

  /// Session controller shared by every authenticated screen.
  final AuthController authController;

  /// Called by [MaterialApp.onGenerateRoute].
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => LoginView(authController: authController),
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => HomeView(authController: authController),
        );
      default:
        return null;
    }
  }
}
