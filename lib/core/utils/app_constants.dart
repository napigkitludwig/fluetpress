/// Application-wide, compile-time constants.
///
/// Keeping branding, database and seed configuration in one place makes it
/// trivial to re-target the boilerplate at a brand-new project.
///
/// Anything that must differ per *environment* (API URLs, keys, app name per
/// flavor) lives in `core/config/flavors.dart` instead — this file is for values
/// that are the same everywhere.
class AppConstants {
  const AppConstants._();

  // --- Branding -------------------------------------------------------------

  /// Fallback application name (the per-flavor name lives in `Flavors`).
  static const String appName = 'FluetPress';

  /// Short tagline shown on the authentication screens.
  static const String appTagline =
      'Feature-first · offline-first · role-based access';

  // --- Database -------------------------------------------------------------

  /// File name of the SQLite database created on the device.
  static const String databaseName = 'fluetpress.db';

  /// Schema version.
  ///
  /// Bump this value whenever the schema changes, and add the matching step in
  /// `DatabaseHelper._onUpgrade`.
  ///
  /// * `1` — `users`
  /// * `2` — `app_settings` (key/value store for local preferences)
  static const int databaseVersion = 2;

  // --- Local preference keys -------------------------------------------------

  /// Persisted [ThemeMode] (`system` / `light` / `dark`).
  static const String settingThemeMode = 'settings.theme_mode';

  // --- Default seeded accounts ---------------------------------------------
  // Seeded only once, the first time the database file is created.
  // NEVER ship real credentials as seed data in a production app.

  /// Username of the seeded administrator account.
  static const String seedAdminUsername = 'admin_user';

  /// Password of the seeded administrator account (hashed before storage).
  static const String seedAdminPassword = 'AdminPassword123!';

  /// Username of the seeded standard account.
  static const String seedUserUsername = 'standard_user';

  /// Password of the seeded standard account (hashed before storage).
  static const String seedUserPassword = 'UserPassword123!';
}
