import 'package:fluetpress/features/auth/models/auth_session.dart';
import 'package:fluetpress/features/auth/models/user.dart';
import 'package:fluetpress/features/auth/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession', () {
    test('decodes a login response containing a nested user', () {
      final AuthSession session = AuthSession.fromJson(<String, dynamic>{
        'accessToken': 'access-123',
        'refreshToken': 'refresh-456',
        'user': <String, dynamic>{
          'id': 1,
          'username': 'admin_user',
          'role': 'Admin',
        },
      });

      expect(session.accessToken, 'access-123');
      expect(session.refreshToken, 'refresh-456');
      expect(session.user.id, 1);
      expect(session.user.username, 'admin_user');
      expect(session.user.role, UserRole.admin);
    });

    test('encodes the nested user through its own mapping', () {
      const AuthSession session = AuthSession(
        user: User(id: 2, username: 'standard_user', role: UserRole.user),
        accessToken: 'access',
      );

      final Map<String, dynamic> json = session.toJson();

      expect(json['user'], isA<Map<String, dynamic>>());
      final Map<String, dynamic> userJson =
          json['user'] as Map<String, dynamic>;
      expect(userJson['username'], 'standard_user');
      expect(userJson['role'], 'User');
      // The hash is never part of an API payload.
      expect(userJson['password'], '');
    });

    test('round-trips through JSON', () {
      final AuthSession original = AuthSession(
        user: User.fromJson(<String, dynamic>{
          'id': 9,
          'username': 'standard_user',
          'password': 'hashed',
          'role': 'User',
        }),
        accessToken: 'a',
        refreshToken: 'r',
      );

      expect(AuthSession.fromJson(original.toJson()), original);
    });

    test('tolerates a missing token pair (local/offline mode)', () {
      final AuthSession session = AuthSession.fromJson(<String, dynamic>{
        'user': <String, dynamic>{'id': 1, 'username': 'x', 'role': 'User'},
      });

      expect(session.accessToken, isNull);
      expect(session.refreshToken, isNull);
    });
  });
}
