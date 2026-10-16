import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_role.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// An account, and the shape of the `users` table.
///
/// Generated once with `freezed` + `json_serializable`, so:
/// * the class is immutable and gets `copyWith` / `==` / `hashCode` for free,
/// * [fromJson] / [toJson] are compiled, not hand-written, which removes an
///   entire class of parsing bugs,
/// * the JSON keys are pinned with `@JsonKey` to the exact **column names**, so
///   `toJson()` doubles as the SQLite row map ([toMap]).
///
/// Models contain **data only**: no Flutter imports, no business logic and no
/// database access.
///
/// Regenerate after editing: `dart run build_runner build --delete-conflicting-outputs`
@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    /// `null` until the row has been inserted (the key is AUTOINCREMENT), and
    /// omitted from the row map while it is `null` so SQLite generates it.
    @JsonKey(includeIfNull: false) int? id,

    /// Unique login name.
    required String username,

    /// SHA-256 digest of the user's password — plain text is never persisted.
    /// See `PasswordHasher` for the (development-grade) hashing used here.
    /// Defaults to empty so API payloads may omit it.
    @Default('') String password,

    /// Authorisation role, serialised as `'Admin'` / `'User'`.
    @UserRoleConverter() required UserRole role,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // --- Table and column names ------------------------------------------------
  // The DDL lives in `core/storage/database_helper.dart`; these constants are
  // what the typed data source queries with.

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

  /// Whether this account is an administrator.
  bool get isAdmin => role.isAdmin;

  /// Whether the row has already been persisted.
  bool get isPersisted => id != null;

  /// Serialises this user into a SQLite row (alias of [toJson]).
  ///
  /// The primary key is omitted while it is `null`, letting SQLite generate it.
  Map<String, Object?> toMap() => toJson();
}
