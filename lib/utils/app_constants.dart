/// Application-wide, compile-time constants.
///
/// Keeping branding, database and seed configuration in one place makes it
/// trivial to re-target the template at a brand-new project.
class AppConstants {
  const AppConstants._();

  // --- Branding -------------------------------------------------------------

  /// Human readable application name (used as the [MaterialApp] title).
  static const String appName = 'FluetPress';

  /// Short tagline shown on the login screen.
  static const String appTagline = 'MVC starter template · SQLite · Role-based auth';

  // --- Database -------------------------------------------------------------

  /// File name of the SQLite database created on the device.
  static const String databaseName = 'fluetpress.db';

  /// Schema version.
  ///
  /// Bump this value whenever the schema changes, and add the migration step in
  /// `DatabaseHelper._onUpgrade`.
  static const int databaseVersion = 1;

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
