import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'utils/app_constants.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

/// Root of the widget tree.
///
/// It owns the long-lived controllers and hands them to [AppRouter], which
/// injects them into the views. Add new global controllers here (one per
/// concern) and expose them through the router.
class FluetpressApp extends StatefulWidget {
  const FluetpressApp({super.key});

  @override
  State<FluetpressApp> createState() => _FluetpressAppState();
}

class _FluetpressAppState extends State<FluetpressApp> {
  /// Session controller shared by the login and home screens.
  late final AuthController _authController = AuthController();

  late final AppRouter _router = AppRouter(authController: _authController);

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.login,
      onGenerateRoute: _router.onGenerateRoute,
    );
  }
}
