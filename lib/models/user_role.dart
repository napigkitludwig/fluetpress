/// The set of roles a [User] is allowed to hold.
///
/// [dbValue] is the exact text persisted to SQLite and is intentionally
/// restricted to `Admin` and `User`, matching the `CHECK` constraint on the
/// `users` table.
enum UserRole {
  admin('Admin'),
  user('User');

  const UserRole(this.dbValue);

  /// The literal value stored in the `role` column.
  final String dbValue;

  /// Convenience flag used by the views/controllers for role-based UI.
  bool get isAdmin => this == UserRole.admin;

  /// Human readable label.
  String get label => dbValue;

  /// Parses a raw database value.
  ///
  /// Unknown or legacy values fall back to [UserRole.user] so a malformed row
  /// can never crash the application.
  static UserRole fromDbValue(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    return UserRole.values.firstWhere(
      (UserRole role) => role.dbValue.toLowerCase() == normalized,
      orElse: () => UserRole.user,
    );
  }
}
