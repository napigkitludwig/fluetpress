import 'package:sqflite/sqflite.dart';

import '../../../core/storage/database_helper.dart';
import '../models/user.dart';

/// Typed, local (SQLite) data source for accounts.
///
/// This is the feature's persistence adapter: it owns the row ⇄ `User` mapping
/// and the SQL for the `users` table, and it is the only place that reads or
/// writes those rows. `core/storage/database_helper.dart` owns the *connection*
/// and the *schema*; this class owns the *queries*.
///
/// Only controllers/services in the auth feature may use it.
class UserLocalDataSource {
  UserLocalDataSource({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  /// Returns every account, administrators first.
  Future<List<User>> getUsers() async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, Object?>> rows = await db.query(
      User.tableName,
      orderBy: '${User.columnRole} ASC, ${User.columnUsername} ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  /// Finds a user by unique username, or `null` when not found.
  Future<User?> getUserByUsername(String username) async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, Object?>> rows = await db.query(
      User.tableName,
      where: '${User.columnUsername} = ?',
      whereArgs: <Object?>[username],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// Finds a user by primary key, or `null` when not found.
  Future<User?> getUserById(int id) async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, Object?>> rows = await db.query(
      User.tableName,
      where: '${User.columnId} = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// Whether [username] is already taken.
  Future<bool> usernameExists(String username) async {
    final Database db = await _databaseHelper.database;
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
    final Database db = await _databaseHelper.database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${User.tableName}'),
        ) ??
        0;
  }

  /// Counts the accounts holding [role].
  Future<int> countUsersWithRole(String role) async {
    final Database db = await _databaseHelper.database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${User.tableName} WHERE ${User.columnRole} = ?',
            <Object?>[role],
          ),
        ) ??
        0;
  }

  /// Inserts [user] (without its id) and returns the generated primary key.
  Future<int> insertUser(User user) async {
    final Database db = await _databaseHelper.database;
    return db.insert(User.tableName, user.toMap());
  }

  /// Updates the row identified by [user]. Returns the number of rows changed.
  Future<int> updateUser(User user) async {
    final int? id = user.id;
    if (id == null) {
      throw ArgumentError('Cannot update a user without an id.');
    }
    final Database db = await _databaseHelper.database;
    return db.update(
      User.tableName,
      user.toMap(),
      where: '${User.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Deletes the user with the given [id]. Returns the number of rows deleted.
  Future<int> deleteUser(int id) async {
    final Database db = await _databaseHelper.database;
    return db.delete(
      User.tableName,
      where: '${User.columnId} = ?',
      whereArgs: <Object?>[id],
    );
  }

  User _fromRow(Map<String, Object?> row) => User.fromJson(row);
}
