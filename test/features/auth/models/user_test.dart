import 'package:fluetpress/features/auth/models/user.dart';
import 'package:fluetpress/features/auth/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('maps to the exact persisted values', () {
      expect(UserRole.admin.dbValue, 'Admin');
      expect(UserRole.user.dbValue, 'User');
    });

    test('parses values case-insensitively', () {
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

    test('fromJson hydrates every field from a database row', () {
      final User parsed = User.fromJson(<String, dynamic>{
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

    test('round-trips through toMap/fromJson', () {
      expect(User.fromJson(user.toMap()), user);
    });

    test('copyWith replaces only the requested fields', () {
      final User demoted = user.copyWith(role: UserRole.user);

      expect(demoted.role, UserRole.user);
      expect(demoted.username, user.username);
      expect(demoted.id, user.id);
    });

    test('unknown roles degrade to user instead of throwing', () {
      final User parsed = User.fromJson(<String, dynamic>{
        'username': 'someone',
        'password': 'hashed',
        'role': 'Superuser',
      });

      expect(parsed.role, UserRole.user);
    });

    test('password defaults to empty when a payload omits it', () {
      final User parsed = User.fromJson(<String, dynamic>{
        'id': 3,
        'username': 'someone',
        'role': 'User',
      });

      expect(parsed.password, '');
      expect(parsed.isPersisted, isTrue);
    });
  });
}
