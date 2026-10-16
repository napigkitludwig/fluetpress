import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/forgot_password_view.dart';
import 'features/auth/views/login_view.dart';
import 'features/auth/views/register_view.dart';
import 'features/home/views/home_view.dart';
import 'features/settings/views/settings_view.dart';

/// Every route in the application, in one place.
///
/// Always navigate with these constants rather than raw strings:
/// `context.goNamed(AppRoute.home.name)`.
enum AppRoute {
  login('/login', 'login'),
  register('/register', 'register'),
  forgotPassword('/forgot-password', 'forgot-password'),
  home('/home', 'home'),
  settings('/settings', 'settings');

  const AppRoute(this.path, this.name);

  /// URL path.
  final String path;

  /// Named-route identifier.
  final String name;

  /// Routes reachable without a session.
  static const Set<AppRoute> public = <AppRoute>{
    AppRoute.login,
    AppRoute.register,
    AppRoute.forgotPassword,
  };

  /// Whether this route can be visited while signed out.
  bool get isPublic => public.contains(this);
}

/// Builds the app's [GoRouter].
///
/// The router owns the **authentication guard**: it rebuilds whenever
/// [AuthController] changes and redirects accordingly, so no screen ever has to
/// check `isAuthenticated` before navigating.
///
/// Controllers are *not* injected through route builders — they come from the
/// `provider` scope created in `app.dart`, which keeps deep links and
/// restore-deep-links working after a cold start.
///
/// This file lives at the top of `lib/` (next to `app.dart`) rather than inside
/// `core/`, because mapping URLs to screens is a composition concern: it is the
/// one place allowed to name feature views. Keeping it here is what lets `core/`
/// stay free of `features/` imports.
class AppRouter {
  const AppRouter({required this.authController});

  /// Session controller driving the guard.
  final AuthController authController;

  /// Creates the configured [GoRouter].
  GoRouter create() {
    return GoRouter(
      initialLocation: AppRoute.login.path,
      refreshListenable: authController,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoute.login.path,
          name: AppRoute.login.name,
          builder: (BuildContext context, GoRouterState state) =>
              const LoginView(),
        ),
        GoRoute(
          path: AppRoute.register.path,
          name: AppRoute.register.name,
          builder: (BuildContext context, GoRouterState state) =>
              const RegisterView(),
        ),
        GoRoute(
          path: AppRoute.forgotPassword.path,
          name: AppRoute.forgotPassword.name,
          builder: (BuildContext context, GoRouterState state) =>
              const ForgotPasswordView(),
        ),
        GoRoute(
          path: AppRoute.home.path,
          name: AppRoute.home.name,
          builder: (BuildContext context, GoRouterState state) =>
              const HomeView(),
        ),
        GoRoute(
          path: AppRoute.settings.path,
          name: AppRoute.settings.name,
          builder: (BuildContext context, GoRouterState state) =>
              const SettingsView(),
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(child: Text('No route matches "${state.uri}".')),
      ),
    );
  }

  /// Guard: signed-out users only see [AppRoute.public]; signed-in users are
  /// pushed away from the auth screens.
  String? _redirect(BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;
    final AppRoute? target = _match(location);
    final bool isPublic = target?.isPublic ?? false;
    final bool isAuthenticated = authController.isAuthenticated;

    if (!isAuthenticated) {
      return isPublic ? null : AppRoute.login.path;
    }

    if (isPublic) {
      return AppRoute.home.path;
    }

    return null;
  }

  AppRoute? _match(String location) {
    for (final AppRoute route in AppRoute.values) {
      if (location == route.path) {
        return route;
      }
    }
    return null;
  }
}
