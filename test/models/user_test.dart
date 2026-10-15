import 'package:fluetpress/models/user.dart';
import 'package:fluetpress/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('maps to the exact database values', () {
      expect(UserRole.admin.dbValue, 'Admin');
      expect(UserRole.user.dbValue, 'User');
    });

    test('parses database values case-insensitively', () {
      expect(UserRole.fromDbValue('Admin'), UserRole.admin);
      expect(UserRole.fromDbValue('admin'), UserRole.admin);
      expect(UserRole.fromDbValue('USER'), UserRole.user);
    });

    test('falls back to the standard role for unknown values', () {
      expect(UserRole.fromDbValue(null), UserRole.user);
      expect(UserRole.fromDbValue('superuser'), UserRole.user);
    });
  });

  group('User', () {
    const User user = User(
      id: 7,
      username: 'admin_user',
      password: 'hashed',
      role: UserRole.admin,
    );

    test('toMap serialises every column', () {
      expect(user.toMap(), <String, Object?>{
        'id': 7,
        'username': 'admin_user',
        'password': 'hashed',
        'role': 'Admin',
      });
    });

    test('toMap omits the id until the row is persisted', () {
      const User unsaved = User(
        username: 'standard_user',
        password: 'hashed',
        role: UserRole.user,
      );

      expect(unsaved.toMap().containsKey(User.columnId), isFalse);
      expect(unsaved.isPersisted, isFalse);
    });

    test('fromMap hydrates every field', () {
      final User parsed = User.fromMap(<String, Object?>{
        'id': 1,
        'username': 'standard_user',
        'password': 'hashed',
        'role': 'User',
      });

      expect(parsed.id, 1);
      expect(parsed.username, 'standard_user');
      expect(parsed.password, 'hashed');
      expect(parsed.role, UserRole.user);
      expect(parsed.isAdmin, isFalse);
    });

    test('round-trips through toMap/fromMap', () {
      expect(User.fromMap(user.toMap()), user);
    });

    test('copyWith replaces only the requested fields', () {
      final User promoted = user.copyWith(role: UserRole.user);

      expect(promoted.role, UserRole.user);
      expect(promoted.username, user.username);
      expect(promoted.id, user.id);
    });
  });
}
