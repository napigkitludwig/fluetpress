import '../../../core/config/env_config.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/utils/password_hasher.dart';
import '../models/auth_session.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'auth_api_service.dart';
import 'user_local_data_source.dart';

/// Orchestrates authentication for whichever backend the current flavor uses.
///
/// * **Local mode (default)** — credentials are verified against the on-device
///   SQLite `users` table, so the boilerplate is fully demonstrable with no
///   server. The session is remembered in encrypted storage.
/// * **Remote mode** (`--dart-define=USE_REMOTE_AUTH=true`) — credentials go to
///   the REST API and the returned JWT pair is written to secure storage, where
///   `ApiClient` picks it up automatically (and refreshes it on `401`).
///
/// This is the only class that knows about both worlds, so no controller ever
/// has to branch on the environment.
class AuthService {
  AuthService({
    required this._apiService,
    required this._localDataSource,
    required this._secureStorage,
  });

  final AuthApiService _apiService;
  final UserLocalDataSource _localDataSource;
  final SecureStorageService _secureStorage;

  /// Invoked when the API rejects the session and it cannot be recovered.
  ///
  /// `AuthController` subscribes to this (wired in the app bootstrapper) to drop
  /// the in-memory session, which makes the router send the user to `/login`.
  void Function()? onSessionExpired;

  /// Whether the active flavor talks to a REST API.
  bool get usesRemoteApi => EnvConfig.instance.useRemoteAuth;

  // --- Sign in ---------------------------------------------------------------

  /// Authenticates [username] / [password].
  Future<Result<AuthSession>> signIn({
    required String username,
    required String password,
  }) async {
    final String trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      return const Failure<AuthSession>(
        'Please enter both your username and password.',
      );
    }

    if (usesRemoteApi) {
      return _signInRemotely(trimmedUsername, password);
    }
    return _signInLocally(trimmedUsername, password);
  }

  Future<Result<AuthSession>> _signInLocally(
    String username,
    String password,
  ) async {
    try {
      final User? user = await _localDataSource.getUserByUsername(username);
      final bool matches =
          user != null &&
          PasswordHasher.verify(plainText: password, hash: user.password);

      if (!matches) {
        // Deliberately vague: never reveal whether the username exists.
        return const Failure<AuthSession>('Invalid username or password.');
      }

      // `matches` (a final bool built from `user != null && ...`) promotes
      // `user` to non-null from here on.
      final int? id = user.id;
      if (id == null) {
        return const Failure<AuthSession>(
          'This account is missing an identifier.',
        );
      }

      await _secureStorage.saveSession(
        userId: id,
        username: user.username,
        role: user.role.dbValue,
      );
      return Success<AuthSession>(AuthSession(user: user));
    } catch (error) {
      return Failure<AuthSession>('Could not read local storage ($error).');
    }
  }

  Future<Result<AuthSession>> _signInRemotely(
    String username,
    String password,
  ) async {
    final Result<AuthSession> result = await _apiService.signIn(
      username: username,
      password: password,
    );

    if (result case Success<AuthSession>(:final AuthSession data)) {
      await _storeRemoteSession(data);
    }
    return result;
  }

  // --- Registration ----------------------------------------------------------

  /// Creates an account (`User` role) and signs it in.
  Future<Result<AuthSession>> register({
    required String username,
    required String password,
    String? email,
  }) async {
    final String trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      return const Failure<AuthSession>(
        'Please choose a username and a password.',
      );
    }

    if (usesRemoteApi) {
      final Result<AuthSession> result = await _apiService.register(
        username: trimmedUsername,
        password: password,
        email: email,
      );
      if (result case Success<AuthSession>(:final AuthSession data)) {
        await _storeRemoteSession(data);
      }
      return result;
    }

    return _registerLocally(trimmedUsername, password);
  }

  Future<Result<AuthSession>> _registerLocally(
    String username,
    String password,
  ) async {
    try {
      if (await _localDataSource.usernameExists(username)) {
        return Failure<AuthSession>(
          'The username "$username" is already taken.',
        );
      }

      final int id = await _localDataSource.insertUser(
        User(
          username: username,
          password: PasswordHasher.hash(password),
          role: UserRole.user,
        ),
      );

      final User? created = await _localDataSource.getUserById(id);
      if (created == null) {
        return const Failure<AuthSession>('The account could not be created.');
      }

      await _secureStorage.saveSession(
        userId: id,
        username: created.username,
        role: created.role.dbValue,
      );
      return Success<AuthSession>(AuthSession(user: created));
    } catch (error) {
      return Failure<AuthSession>('Could not create the account ($error).');
    }
  }

  // --- Session restore -------------------------------------------------------

  /// Restores the session remembered in secure storage, if any.
  ///
  /// Awaited during bootstrapping so the router can pick the right first screen
  /// without flashing the login page.
  Future<Result<User>> restoreSession() async {
    try {
      final int? userId = await _secureStorage.readSessionUserId();
      if (userId == null) {
        return const Failure<User>('No saved session.');
      }

      if (usesRemoteApi) {
        final Result<User> remote = await _apiService.profile();
        if (remote case Success<User>(:final User data)) {
          return Success<User>(data);
        }
        // Fall through to the cached account when the network is unavailable;
        // the next authenticated call will surface the real state.
      }

      final User? cached = await _localDataSource.getUserById(userId);
      if (cached == null) {
        await _secureStorage.clearSession();
        return const Failure<User>('The saved account no longer exists.');
      }
      return Success<User>(cached);
    } catch (error) {
      return Failure<User>('Could not restore the session ($error).');
    }
  }

  // --- Password reset --------------------------------------------------------

  /// Requests a password-reset email.
  Future<Result<bool>> sendPasswordReset(String email) async {
    if (!usesRemoteApi) {
      return const Failure<bool>(
        'Password reset needs a backend. Run with '
        '--dart-define=USE_REMOTE_AUTH=true to use it.',
      );
    }
    return _apiService.forgotPassword(email: email.trim());
  }

  // --- Sign out / expiry -----------------------------------------------------

  /// Ends the session locally and, in remote mode, on the server too.
  Future<void> signOut() async {
    if (usesRemoteApi) {
      await _apiService.signOut();
    }
    await _secureStorage.clearSession();
  }

  /// Called by `ApiClient` when a `401` could not be refreshed.
  ///
  /// Clears the stored session and notifies whoever is listening so the UI can
  /// bounce the user back to the login screen.
  Future<void> expireSession() async {
    await _secureStorage.clearSession();
    onSessionExpired?.call();
  }

  // --- Helpers ---------------------------------------------------------------

  Future<void> _storeRemoteSession(AuthSession session) async {
    final int? id = session.user.id;
    if (session.accessToken != null) {
      await _secureStorage.saveTokens(
        accessToken: session.accessToken!,
        refreshToken: session.refreshToken,
      );
    }
    if (id != null) {
      await _secureStorage.saveSession(
        userId: id,
        username: session.user.username,
        role: session.user.role.dbValue,
      );
    }
  }
}
