import 'env_config.dart';

/// Immutable description of a single flavor.
class FlavorConfig {
  const FlavorConfig({
    required this.environment,
    required this.appName,
    required this.baseUrl,
    required this.enableApiLogging,
  });

  final Environment environment;
  final String appName;
  final String baseUrl;
  final bool enableApiLogging;

  @override
  String toString() => 'FlavorConfig(${environment.slug}) -> $baseUrl';
}

/// Compile-time flavor switches.
///
/// Everything here is injected at build time, so nothing environment-specific
/// is ever committed to the repository:
///
/// ```bash
/// flutter run  --dart-define=APP_FLAVOR=dev
/// flutter run  --dart-define=APP_FLAVOR=staging --dart-define-from-file=config/staging.json
/// flutter build apk --release --dart-define=APP_FLAVOR=prod --dart-define-from-file=config/prod.json
/// ```
///
/// `config/*.example.json` documents the keys you can put in a define-file
/// (`API_BASE_URL`, `API_KEY`, `USE_REMOTE_AUTH`, ...). Keep the real files out
/// of Git (`.gitignore` already ignores `config/*.json` except the examples).
///
/// This is the "no extra dependency" equivalent of `flutter_dotenv` / `envied`:
/// secrets stay outside the repository and are read through `EnvConfig`.
class Flavors {
  const Flavors._();

  /// `--dart-define=APP_FLAVOR=dev|staging|prod`.
  static const String _flavorName = String.fromEnvironment(
    'APP_FLAVOR',
    defaultValue: 'dev',
  );

  /// Optional override: `--dart-define=API_BASE_URL=https://...`.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Optional public API key: `--dart-define=API_KEY=...`.
  static const String _apiKey = String.fromEnvironment('API_KEY');

  /// `--dart-define=USE_REMOTE_AUTH=true` to hit the REST API instead of the
  /// local SQLite store.
  static const bool _useRemoteAuth = bool.fromEnvironment('USE_REMOTE_AUTH');

  /// The active environment.
  static Environment get environment => Environment.parse(_flavorName);

  /// The active flavor's configuration.
  static FlavorConfig get current {
    final Environment env = environment;
    return FlavorConfig(
      environment: env,
      appName: _appNameFor(env),
      baseUrl: _baseUrlOverride.isNotEmpty
          ? _baseUrlOverride
          : _baseUrlFor(env),
      enableApiLogging: !env.isProd,
    );
  }

  /// Whether authentication should run against the REST API.
  static bool get useRemoteAuth => _useRemoteAuth;

  /// Public API key injected at build time (empty when not provided).
  static String get apiKey => _apiKey;

  /// Convenience: initialise [EnvConfig] from the current flavor.
  static void initialize() {
    final FlavorConfig config = current;
    EnvConfig.initialize(
      appName: config.appName,
      baseUrl: config.baseUrl,
      environment: config.environment,
      apiKey: _apiKey,
      enableApiLogging: config.enableApiLogging,
      useRemoteAuth: _useRemoteAuth,
    );
  }

  static String _appNameFor(Environment env) {
    switch (env) {
      case Environment.dev:
        return 'FluetPress (Dev)';
      case Environment.staging:
        return 'FluetPress (Staging)';
      case Environment.prod:
        return 'FluetPress';
    }
  }

  static String _baseUrlFor(Environment env) {
    switch (env) {
      case Environment.dev:
        return 'https://api.dev.fluetpress.example/v1';
      case Environment.staging:
        return 'https://api.staging.fluetpress.example/v1';
      case Environment.prod:
        return 'https://api.fluetpress.example/v1';
    }
  }
}
