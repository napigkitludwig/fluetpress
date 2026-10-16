import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'core/config/env_config.dart';
import 'core/network/api_client.dart';
import 'core/network/connectivity_service.dart';
import 'core/storage/database_helper.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/services/auth_api_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/user_local_data_source.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'shared/widgets/offline_banner.dart';

/// The app's object graph, assembled once at startup.
///
/// Building everything in one place (instead of letting each screen construct
/// its own dependencies) is what makes the layers swappable: point
/// [AuthService] at a different data source, or [ApiClient] at a mock adapter,
/// and nothing else changes.
///
/// [EnvConfig] must be initialised before [bootstrap] runs — `main.dart` calls
/// `Flavors.initialize()` first.
class AppDependencies {
  const AppDependencies({
    required this.databaseHelper,
    required this.secureStorage,
    required this.apiClient,
    required this.connectivityService,
    required this.authService,
    required this.authController,
    required this.settingsController,
  });

  final DatabaseHelper databaseHelper;
  final SecureStorageService secureStorage;
  final ApiClient apiClient;
  final ConnectivityService connectivityService;
  final AuthService authService;
  final AuthController authController;
  final SettingsController settingsController;

  /// Creates and wires every long-lived object.
  ///
  /// Anything that must be ready before the first frame (schema + seed data,
  /// restored session, persisted theme) is awaited here.
  static Future<AppDependencies> bootstrap() async {
    // 1. Open SQLite first: schema, migrations and demo seeding.
    final DatabaseHelper databaseHelper = DatabaseHelper();
    await databaseHelper.initialize();

    // 2. Storage + HTTP.
    final SecureStorageService secureStorage = SecureStorageService();
    final ApiClient apiClient = ApiClient(secureStorage: secureStorage);

    // 3. Feature services (HTTP shape + local persistence).
    final AuthService authService = AuthService(
      apiService: AuthApiService(apiClient: apiClient),
      localDataSource: UserLocalDataSource(databaseHelper: databaseHelper),
      secureStorage: secureStorage,
    );

    // 4. Controllers.
    final AuthController authController = AuthController(
      authService: authService,
    );

    // Wire the "session expired" hop: ApiClient → AuthService → AuthController.
    // Done here rather than in constructors to avoid a circular dependency.
    apiClient.onUnauthorized = authService.expireSession;
    authService.onSessionExpired = authController.handleExpiredSession;

    await authController.restoreSession();

    final SettingsController settingsController = SettingsController(
      databaseHelper: databaseHelper,
    );
    await settingsController.load();

    // 5. Connectivity (never blocks startup).
    final ConnectivityService connectivityService = ConnectivityService();
    await connectivityService.initialize();

    return AppDependencies(
      databaseHelper: databaseHelper,
      secureStorage: secureStorage,
      apiClient: apiClient,
      connectivityService: connectivityService,
      authService: authService,
      authController: authController,
      settingsController: settingsController,
    );
  }

  /// Releases long-lived resources. The OS normally reclaims these when the
  /// process dies; call it explicitly in tests.
  void dispose() {
    apiClient.dispose();
    connectivityService.dispose();
    authController.dispose();
    settingsController.dispose();
  }
}

/// Root of the widget tree.
///
/// Publishes the object graph through `provider`, so any view can reach its
/// controller with `context.watch<T>()` / `context.read<T>()` — including from a
/// deep link after a cold start.
class FluetPressApp extends StatefulWidget {
  const FluetPressApp({super.key, required this.dependencies});

  /// The assembled object graph.
  final AppDependencies dependencies;

  @override
  State<FluetPressApp> createState() => _FluetPressAppState();
}

class _FluetPressAppState extends State<FluetPressApp> {
  late final GoRouter _router = AppRouter(
    authController: widget.dependencies.authController,
  ).create();

  late final ThemeData _lightTheme = AppTheme.light(AppBrand.current);
  late final ThemeData _darkTheme = AppTheme.dark(AppBrand.current);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: widget.dependencies),
        Provider<DatabaseHelper>.value(
          value: widget.dependencies.databaseHelper,
        ),
        Provider<SecureStorageService>.value(
          value: widget.dependencies.secureStorage,
        ),
        Provider<ApiClient>.value(value: widget.dependencies.apiClient),
        ChangeNotifierProvider<ConnectivityService>.value(
          value: widget.dependencies.connectivityService,
        ),
        ChangeNotifierProvider<AuthController>.value(
          value: widget.dependencies.authController,
        ),
        ChangeNotifierProvider<SettingsController>.value(
          value: widget.dependencies.settingsController,
        ),
      ],
      child: _AppView(
        router: _router,
        lightTheme: _lightTheme,
        darkTheme: _darkTheme,
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({
    required this.router,
    required this.lightTheme,
    required this.darkTheme,
  });

  final GoRouter router;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = context.select<SettingsController, ThemeMode>(
      (SettingsController controller) => controller.themeMode,
    );

    return MaterialApp.router(
      title: EnvConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) =>
          _OfflineAware(child: child),
    );
  }
}

/// Stacks the offline banner above the app when the device loses connectivity.
///
/// `MediaQuery.removePadding` stops the banner from being *additional* to the
/// status-bar inset, so the layout does not jump when the banner appears.
class _OfflineAware extends StatelessWidget {
  const _OfflineAware({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool isOnline = context.select<ConnectivityService, bool>(
      (ConnectivityService service) => service.isOnline,
    );

    final Widget app = child ?? const SizedBox.shrink();
    if (isOnline) {
      return app;
    }

    return Column(
      children: <Widget>[
        const OfflineBanner(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: app,
          ),
        ),
      ],
    );
  }
}
