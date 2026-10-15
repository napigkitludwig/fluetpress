import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../utils/app_constants.dart';
import 'password_service.dart';

/// Singleton wrapper around the app's SQLite connection.
///
/// **Contract:** only controllers may talk to this class. Views must never
/// import it — every data operation has to travel through a controller.
///
/// Usage:
/// ```dart
/// final users = await DatabaseHelper().getUsers();
/// ```
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper _instance = DatabaseHelper._();

  /// The single shared instance.
  factory DatabaseHelper() => _instance;

  Database? _database;

  /// The current connection; opening it lazily on first use.
  Future<Database> get database async => _database ??= await _open();

  /// Whether a connection is currently open.
  bool get isOpen => _database?.isOpen ?? false;

  // --- Platform bootstrapping -----------------------------------------------
  // Android and iOS are fully supported out of the box: the native `sqflite`
  // plugin ships the SQLite implementation, so no factory registration is
  // needed here. For optional desktop support, see the README
  // ("Optional: desktop support").

  // --- Lifecycle -------------------------------------------------------------

  /// Opens (and on first run creates + seeds) the database.
  ///
  /// Await this in `main()` so the schema and default accounts exist before the
  /// first frame is rendered.
  Future<void> initialize() async {
    final Database db = await database;
    // Touch the table so creation/migration/seeding completes before returning.
    await db.query(User.tableName, limit: 1);
  }

  /// Closes the connection (mainly useful in tests). The next call to
  /// [database] transparently re-opens it.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Deletes the database file completely — handy while developing or testing.
  Future<void> deleteDatabaseFile() async {
    final String path = p.join(
      await getDatabasesPath(),
      AppConstants.databaseName,
    );
    await close();
    await deleteDatabase(path);
  }

  Future<Database> _open() async {
    final String path = p.join(
      await getDatabasesPath(),
      AppConstants.databaseName,
    );

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${User.tableName} (
        ${User.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${User.columnUsername} TEXT UNIQUE NOT NULL,
        ${User.columnPassword} TEXT NOT NULL,
        ${User.columnRole} TEXT NOT NULL
          CHECK (${User.columnRole} IN ('${UserRole.admin.dbValue}', '${UserRole.user.dbValue}'))
      )
    ''');

    await _seedDefaults(db);
  }

  /// Migration hook.
  ///
  /// When you change the schema, increment [AppConstants.databaseVersion] and
  /// add the corresponding `ALTER TABLE` steps here, e.g.:
  /// ```dart
  /// if (oldVersion < 2) {
  ///   await db.execute('ALTER TABLE ${User.tableName} ADD COLUMN email TEXT');
  /// }
  /// ```
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // No migrations yet — version 1 is the initial schema.
  }

  /// Inserts the default accounts the first time the table is empty.
  ///
  /// Uses the [Database] passed by `onCreate` (never [database]) to avoid
  /// re-entering the open operation and dead-locking.
  Future<void> _seedDefaults(Database db) async {
    final int existing =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${User.tableName}'),
        ) ??
        0;
    if (existing > 0) {
      return; // Already seeded — never overwrite user data.
    }

    final List<User> seeds = <User>[
      User(
        username: AppConstants.seedAdminUsername,
        password: PasswordService.hash(AppConstants.seedAdminPassword),
        role: UserRole.admin,
      ),
      User(
        username: AppConstants.seedUserUsername,
        password: PasswordService.hash(AppConstants.seedUserPassword),
        role: UserRole.user,
      ),
    ];

    final Batch batch = db.batch();
    for (final User user in seeds) {
      batch.insert(User.tableName, user.toMap());
    }
    await batch.commit(noResult: true);
  }

  // --- Queries (User) --------------------------------------------------------

  /// Returns every account, administrators first.
  Future<List<User>> getUsers() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      User.tableName,
      orderBy: '${User.columnRole} ASC, ${User.columnUsername} ASC',
    );
    return rows.map(User.fromMap).toList(growable: false);
  }

  /// Finds a user by unique username, or `null` when not found.
  Future<User?> getUserByUsername(String username) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      User.tableName,
      where: '${User.columnUsername} = ?',
      whereArgs: <Object?>[username],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  /// Finds a user by primary key, or `null` when not found.
  Future<User?> getUserById(int id) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      User.tableName,
      where: '${User.columnId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  /// Whether [username] is already taken.
  Future<bool> usernameExists(String username) async {
    final Database db = await database;
    final int count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${User.tableName} WHERE ${User.columnUsername} = ?',
            <Object?>[username],
          ),
        ) ??
        0;
    return count > 0;
  }

  /// Number of accounts currently stored.
  Future<int> countUsers() async {
    final Database db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${User.tableName}'),
        ) ??
        0;
  }

  // --- Mutations (User) ------------------------------------------------------

  /// Inserts [user] (without its id) and returns the generated primary key.
  Future<int> insertUser(User user) async {
    final Database db = await database;
    return db.insert(User.tableName, user.toMap());
  }

  /// Updates the row identified by [user]. Returns the number of rows changed.
  Future<int> updateUser(User user) async {
    final int? id = user.id;
    if (id == null) {
      throw ArgumentError('Cannot update a user without an id.');
    }
    final Database db = await database;
    return db.update(
      User.tableName,
      user.toMap(),
      where: '${User.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Deletes the user with the given [id]. Returns the number of rows deleted.
  Future<int> deleteUser(int id) async {
    final Database db = await database;
    return db.delete(
      User.tableName,
      where: '${User.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }
}
