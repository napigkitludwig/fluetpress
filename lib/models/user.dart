import 'user_role.dart';

/// Plain Dart object that maps 1:1 to the `users` table in SQLite.
///
/// Models contain **data only**: no Flutter imports, no business logic and no
/// database access. Everything the persistence layer needs is exposed through
/// [toMap] / [fromMap].
class User {
  const User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  // --- Table and column names ------------------------------------------------
  // Declared on the model so the SQL lives next to the shape it describes.

  /// Name of the backing table.
  static const String tableName = 'users';

  /// Primary key column (`INTEGER PRIMARY KEY AUTOINCREMENT`).
  static const String columnId = 'id';

  /// Unique login name column (`TEXT UNIQUE NOT NULL`).
  static const String columnUsername = 'username';

  /// Hashed password column (`TEXT NOT NULL`).
  static const String columnPassword = 'password';

  /// Role column (`TEXT NOT NULL`, `'Admin'` or `'User'`).
  static const String columnRole = 'role';

  /// `null` until the row has been inserted (the key is AUTOINCREMENT).
  final int? id;

  /// Unique login name.
  final String username;

  /// SHA-256 digest of the user's password — plain text is never persisted.
  /// See [PasswordService] for the (development-grade) hashing used here.
  final String password;

  /// Authorisation role.
  final UserRole role;

  /// Whether this account is an administrator.
  bool get isAdmin => role.isAdmin;

  /// Whether the row has already been persisted.
  bool get isPersisted => id != null;

  /// Hydrates a [User] from a SQLite row.
  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map[columnId] as int?,
      username: (map[columnUsername] as String?) ?? '',
      password: (map[columnPassword] as String?) ?? '',
      role: UserRole.fromDbValue(map[columnRole] as String?),
    );
  }

  /// Serialises this [User] into a SQLite row.
  ///
  /// The primary key is omitted while it is `null`, letting SQLite generate it.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) columnId: id,
      columnUsername: username,
      columnPassword: password,
      columnRole: role.dbValue,
    };
  }

  /// Returns a copy with the given fields replaced.
  User copyWith({
    int? id,
    String? username,
    String? password,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is User &&
            other.id == id &&
            other.username == username &&
            other.password == password &&
            other.role == role;
  }

  @override
  int get hashCode => Object.hash(id, username, password, role);

  @override
  String toString() =>
      'User(id: $id, username: $username, role: ${role.dbValue})';
}
