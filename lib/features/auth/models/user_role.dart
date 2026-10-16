import 'package:json_annotation/json_annotation.dart';

/// The set of roles a user is allowed to hold.
///
/// [dbValue] is the exact text persisted to SQLite and sent to/from the API, and
/// is intentionally restricted to `Admin` and `User`, matching the `CHECK`
/// constraint on the `users` table.
enum UserRole {
  admin('Admin'),
  user('User');

  const UserRole(this.dbValue);

  /// The literal value stored in the `role` column / JSON payload.
  final String dbValue;

  /// Convenience flag used by the views/controllers for role-based UI.
  bool get isAdmin => this == UserRole.admin;

  /// Human readable label.
  String get label => dbValue;

  /// Parses a raw database or JSON value.
  ///
  /// Unknown or legacy values fall back to [UserRole.user] so a malformed row or
  /// an unexpected API value can never crash the application.
  static UserRole fromDbValue(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    return UserRole.values.firstWhere(
      (UserRole role) => role.dbValue.toLowerCase() == normalized,
      orElse: () => UserRole.user,
    );
  }
}

/// Serialises [UserRole] as its `'Admin'` / `'User'` string, tolerantly.
///
/// A plain `@JsonValue`-annotated enum would throw on an unexpected value; this
/// converter degrades gracefully to [UserRole.user] instead, which matters when
/// a back-end adds a role the app does not know about yet.
class UserRoleConverter implements JsonConverter<UserRole, String> {
  const UserRoleConverter();

  @override
  UserRole fromJson(String json) => UserRole.fromDbValue(json);

  @override
  String toJson(UserRole object) => object.dbValue;
}
