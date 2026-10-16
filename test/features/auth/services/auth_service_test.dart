import 'package:fluetpress/core/config/env_config.dart';
import 'package:fluetpress/core/network/api_client.dart';
import 'package:fluetpress/core/network/api_response.dart';
import 'package:fluetpress/core/storage/secure_storage.dart';
import 'package:fluetpress/core/utils/password_hasher.dart';
import 'package:fluetpress/features/auth/models/auth_session.dart';
import 'package:fluetpress/features/auth/models/user.dart';
import 'package:fluetpress/features/auth/models/user_role.dart';
import 'package:fluetpress/features/auth/services/auth_api_service.dart';
import 'package:fluetpress/features/auth/services/auth_service.dart';
import 'package:fluetpress/features/auth/services/user_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for the SQLite-backed data source.
class _FakeUserStore extends UserLocalDataSource {
  _FakeUserStore(List<User> users)
    : _users = <int, User>{for (final User user in users) user.id!: user},
      _nextId = users.length + 1;

  final Map<int, User> _users;
  int _nextId;

  @override
  Future<User?> getUserByUsername(String username) async {
    for (final User user in _users.values) {
      if (user.username == username) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<User?> getUserById(int id) async => _users[id];

  @override
  Future<bool> usernameExists(String username) async =>
      await getUserByUsername(username) != null;

  @override
  Future<int> insertUser(User user) async {
    final int id = _nextId++;
    _users[id] = user.copyWith(id: id);
    return id;
  }

  @override
  Future<int> deleteUser(int id) async => _users.remove(id) == null ? 0 : 1;
}

/// In-memory stand-in for encrypted storage (the real one talks to the
/// Keychain / Keystore, which is unavailable in a unit test).
class _FakeSecureStorage extends SecureStorageService {
  int? _userId;

  @override
  Future<void> saveSession({
    required int userId,
    required String username,
    required String role,
  }) async {
    _userId = userId;
  }

  @override
  Future<int?> readSessionUserId() async => _userId;

  @override
  Future<void> clearSession() async {
    _userId = null;
  }
}

void main() {
  late _FakeUserStore store;
  late _FakeSecureStorage storage;
  late AuthService service;

  setUp(() {
    // Local mode: no REST API involved.
    EnvConfig.initialize(
      appName: 'Test App',
      baseUrl: 'https://api.test/v1',
      environment: Environment.dev,
      useRemoteAuth: false,
    );

    store = _FakeUserStore(<User>[
      User(
        id: 1,
        username: 'admin_user',
        password: PasswordHasher.hash('AdminPassword123!'),
        role: UserRole.admin,
      ),
    ]);
    storage = _FakeSecureStorage();
    service = AuthService(
      apiService: AuthApiService(apiClient: ApiClient(secureStorage: storage)),
      localDataSource: store,
      secureStorage: storage,
    );
  });

  tearDown(EnvConfig.reset);

  group('signIn (local mode)', () {
    test('accepts valid credentials and remembers the session', () async {
      final Result<AuthSession> result = await service.signIn(
        username: 'admin_user',
        password: 'AdminPassword123!',
      );

      expect(result, isA<Success<AuthSession>>());
      final AuthSession session = (result as Success<AuthSession>).data;
      expect(session.user.username, 'admin_user');
      expect(session.user.role, UserRole.admin);
      expect(session.accessToken, isNull);
      expect(await storage.readSessionUserId(), 1);
    });

    test('trims the username before looking it up', () async {
      final Result<AuthSession> result = await service.signIn(
        username: '  admin_user  ',
        password: 'AdminPassword123!',
      );

      expect(result, isA<Success<AuthSession>>());
    });

    test('rejects a wrong password without revealing why', () async {
      final Result<AuthSession> result = await service.signIn(
        username: 'admin_user',
        password: 'wrong-password',
      );

      expect(result, isA<Failure<AuthSession>>());
      expect(
        (result as Failure<AuthSession>).message,
        'Invalid username or password.',
      );
      expect(await storage.readSessionUserId(), isNull);
    });

    test('rejects an unknown user with the same message', () async {
      final Result<AuthSession> result = await service.signIn(
        username: 'ghost',
        password: 'whatever',
      );

      final Failure<AuthSession> failure = result as Failure<AuthSession>;
      expect(failure.message, 'Invalid username or password.');
    });

    test('rejects blank input before touching storage', () async {
      final Result<AuthSession> result = await service.signIn(
        username: '   ',
        password: '',
      );

      expect(result, isA<Failure<AuthSession>>());
      expect(
        (result as Failure<AuthSession>).message,
        contains('username and password'),
      );
    });
  });

  group('register (local mode)', () {
    test('creates a standard account and signs it in', () async {
      final Result<AuthSession> result = await service.register(
        username: 'newcomer',
        password: 'Good1Pass',
      );

      expect(result, isA<Success<AuthSession>>());
      final AuthSession session = (result as Success<AuthSession>).data;
      expect(session.user.username, 'newcomer');
      expect(session.user.role, UserRole.user);
      expect(await storage.readSessionUserId(), session.user.id);

      // The password is stored hashed, never in the clear.
      final User? persisted = await store.getUserByUsername('newcomer');
      expect(persisted!.password, isNot('Good1Pass'));
      expect(
        PasswordHasher.verify(plainText: 'Good1Pass', hash: persisted.password),
        isTrue,
      );
    });

    test('refuses a username that is already taken', () async {
      final Result<AuthSession> result = await service.register(
        username: 'admin_user',
        password: 'Good1Pass',
      );

      expect(result, isA<Failure<AuthSession>>());
      expect(
        (result as Failure<AuthSession>).message,
        contains('already taken'),
      );
    });
  });

  group('restoreSession', () {
    test('returns the account behind the persisted session', () async {
      await service.signIn(
        username: 'admin_user',
        password: 'AdminPassword123!',
      );

      final Result<User> restored = await service.restoreSession();

      expect(restored, isA<Success<User>>());
      expect((restored as Success<User>).data.username, 'admin_user');
    });

    test('fails when nothing was persisted', () async {
      final Result<User> restored = await service.restoreSession();

      expect(restored, isA<Failure<User>>());
    });

    test('clears a session pointing at a deleted account', () async {
      await service.signIn(
        username: 'admin_user',
        password: 'AdminPassword123!',
      );
      await store.deleteUser(1);

      final Result<User> restored = await service.restoreSession();

      expect(restored, isA<Failure<User>>());
      expect(await storage.readSessionUserId(), isNull);
    });
  });

  group('session teardown', () {
    test('signOut clears the remembered session', () async {
      await service.signIn(
        username: 'admin_user',
        password: 'AdminPassword123!',
      );

      await service.signOut();

      expect(await storage.readSessionUserId(), isNull);
    });

    test('expireSession clears storage and notifies the listener', () async {
      await service.signIn(
        username: 'admin_user',
        password: 'AdminPassword123!',
      );
      bool notified = false;
      service.onSessionExpired = () => notified = true;

      await service.expireSession();

      expect(notified, isTrue);
      expect(await storage.readSessionUserId(), isNull);
    });
  });

  group('sendPasswordReset', () {
    test('explains that the local mode has no backend', () async {
      final Result<bool> result = await service.sendPasswordReset('a@b.com');

      expect(result, isA<Failure<bool>>());
      expect((result as Failure<bool>).message, contains('backend'));
    });
  });
}
