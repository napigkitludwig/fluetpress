import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../utils/app_constants.dart';
import '../utils/password_hasher.dart';

/// Singleton wrapper around the app's SQLite connection.
///
/// ## Responsibilities
/// * owning the **connection** (lazy open, close, delete),
/// * owning the **schema** (`users`, `app_settings`) and its migrations,
/// * seeding the demo accounts on first run,
/// * the small key/value `app_settings` API used for local preferences.
///
/// ## Layering
/// This class deliberately knows nothing about any *feature*: it exposes the raw
/// [database] so typed data sources (for example
/// `features/auth/services/user_local_data_source.dart`) can map rows to models.
/// Keep it that way — `core/` must never depend on `features/`.
///
/// **Contract:** only controllers and feature services may touch this class.
/// Views must never import it; every data operation travels through a
/// controller.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper _instance = DatabaseHelper._();

  /// The single shared instance.
  factory DatabaseHelper() => _instance;

  /// `users` table name (kept in sync with `User.tableName`).
  static const String usersTable = 'users';

  /// `app_settings` table name.
  static const String settingsTable = 'app_settings';

  Database? _database;

  /// The current connection, opening it lazily on first use.
  Future<Database> get database async => _database ??= await _open();

  /// Whether a connection is currently open.
  bool get isOpen => _database?.isOpen ?? false;

  // --- Platform bootstrapping -------------------------------------------------

  /// Opens (and on first run creates + seeds) the database.
  ///
  /// Await this during bootstrapping so the schema and the default accounts
  /// exist before the first frame is rendered.
  Future<void> initialize() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Database db = await database;
    // Touch the table so creation/migration/seeding completes before returning.
    await db.query(usersTable, limit: 1);
  }

  /// Closes the connection (mainly useful in tests). The next call to
  /// [database] transparently re-opens it.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Deletes the database file completely — handy while developing or testing.
  Future<void> deleteDatabaseFile() async {
    final String path = kIsWeb
        ? AppConstants.databaseName
        : p.join(
            await getDatabasesPath(),
            AppConstants.databaseName,
          );
    await close();
    await deleteDatabase(path);
  }

  Future<Database> _open() async {
    final String path = kIsWeb
        ? AppConstants.databaseName
        : p.join(
            await getDatabasesPath(),
            AppConstants.databaseName,
          );

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: (Database db) async {
        if (!kIsWeb) {
          await db.execute('PRAGMA foreign_keys = ON');
        }
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createSettingsTable(db);
    await _seedDefaultAccounts(db);
  }

  /// Migration hook.
  ///
  /// When you change the schema, increment [AppConstants.databaseVersion] and
  /// add the corresponding step here:
  /// ```dart
  /// if (oldVersion < 3) {
  ///   await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
  /// }
  /// ```
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
    }
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('Admin', 'User'))
      )
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Inserts the default accounts the first time the table is empty.
  ///
  /// Uses the [Database] passed by `onCreate` (never [database]) to avoid
  /// re-entering the open operation and dead-locking.
  Future<void> _seedDefaultAccounts(Database db) async {
    final int existing =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $usersTable'),
        ) ??
        0;
    if (existing > 0) {
      return; // Already seeded — never overwrite user data.
    }

    final List<Map<String, Object?>> seeds = <Map<String, Object?>>[
      <String, Object?>{
        'username': AppConstants.seedAdminUsername,
        'password': PasswordHasher.hash(AppConstants.seedAdminPassword),
        'role': 'Admin',
      },
      <String, Object?>{
        'username': AppConstants.seedUserUsername,
        'password': PasswordHasher.hash(AppConstants.seedUserPassword),
        'role': 'User',
      },
    ];

    final Batch batch = db.batch();
    for (final Map<String, Object?> user in seeds) {
      batch.insert(usersTable, user);
    }
    await batch.commit(noResult: true);
  }

  // --- Local preferences (app_settings) --------------------------------------

  /// Reads a persisted preference, or `null` when unset.
  Future<String?> getSetting(String key) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      settingsTable,
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  /// Inserts or updates a preference.
  Future<void> setSetting(String key, String value) async {
    final Database db = await database;
    await db.insert(settingsTable, <String, Object?>{
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Removes a preference.
  Future<void> removeSetting(String key) async {
    final Database db = await database;
    await db.delete(settingsTable, where: 'key = ?', whereArgs: <Object?>[key]);
  }
}
