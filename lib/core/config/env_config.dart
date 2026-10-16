/// Deployment environments supported by the boilerplate.
///
/// A flavor selects one of these, which in turn selects the base URL, app name
/// and logging behaviour (see `flavors.dart`).
enum Environment {
  dev('Development', 'dev'),
  staging('Staging', 'staging'),
  prod('Production', 'prod');

  const Environment(this.label, this.slug);

  /// Human readable name (shown in the settings screen / debug banners).
  final String label;

  /// Short machine name (`dev`, `staging`, `prod`).
  final String slug;

  bool get isDev => this == Environment.dev;
  bool get isStaging => this == Environment.staging;
  bool get isProd => this == Environment.prod;

  /// Parses a raw flavor string.
  ///
  /// Anything unrecognised falls back to [Environment.dev] so a typo in
  /// `--dart-define=APP_FLAVOR=...` never ships a broken production build
  /// silently pointing at the wrong API.
  static Environment parse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'prod':
      case 'production':
      case 'release':
        return Environment.prod;
      case 'staging':
      case 'stage':
      case 'qa':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }
}

/// Immutable, globally readable runtime configuration.
///
/// Initialised exactly once during bootstrapping (`Flavors.initialize()` in
/// `main.dart`) and then read everywhere through [EnvConfig.instance]. This
/// keeps environment details out of business logic: swap the flavor and the
/// whole app points at a different backend.
class EnvConfig {
  const EnvConfig._({
    required this.appName,
    required this.baseUrl,
    required this.environment,
    required this.apiKey,
    required this.enableApiLogging,
    required this.useRemoteAuth,
  });

  static EnvConfig? _instance;

  /// Builds the configuration. Call once, before `runApp`.
  ///
  /// Values normally come from `Flavors` (i.e. `--dart-define`s), but tests and
  /// tools may call this directly with explicit values.
  static void initialize({
    required String appName,
    required String baseUrl,
    required Environment environment,
    String apiKey = '',
    bool enableApiLogging = false,
    bool useRemoteAuth = false,
  }) {
    _instance = EnvConfig._(
      appName: appName,
      baseUrl: baseUrl,
      environment: environment,
      apiKey: apiKey,
      enableApiLogging: enableApiLogging,
      useRemoteAuth: useRemoteAuth,
    );
  }

  /// The active configuration.
  ///
  /// Throws a descriptive [StateError] when read before [initialize] instead of
  /// failing later with a confusing `LateInitializationError`.
  static EnvConfig get instance {
    final EnvConfig? instance = _instance;
    if (instance == null) {
      throw StateError(
        'EnvConfig has not been initialised. Call Flavors.initialize() '
        '(or EnvConfig.initialize()) from main() before using the app.',
      );
    }
    return instance;
  }

  /// Whether [initialize] has run.
  static bool get isInitialized => _instance != null;

  /// Clears the configuration. Intended for tests only.
  static void reset() => _instance = null;

  /// Display name — e.g. `FluetPress (Staging)`.
  final String appName;

  /// API root, e.g. `https://api.staging.example.com/v1`.
  final String baseUrl;

  /// Active environment.
  final Environment environment;

  /// Optional public API key (never commit production secrets; inject them with
  /// `--dart-define-from-file`).
  final String apiKey;

  /// Whether Dio should log requests/responses (enabled outside production).
  final bool enableApiLogging;

  /// When `false` (the default) authentication runs against the local SQLite
  /// demo store. Flip it with `--dart-define=USE_REMOTE_AUTH=true` to use the
  /// REST endpoints in `ApiEndpoints`.
  final bool useRemoteAuth;

  bool get isDev => environment.isDev;
  bool get isStaging => environment.isStaging;
  bool get isProd => environment.isProd;

  @override
  String toString() =>
      'EnvConfig(appName: $appName, environment: ${environment.slug}, '
      'baseUrl: $baseUrl, useRemoteAuth: $useRemoteAuth)';
}
