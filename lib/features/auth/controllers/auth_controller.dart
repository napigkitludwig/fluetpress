import 'package:flutter/foundation.dart';

import '../../../core/controllers/base_controller.dart';
import '../../../core/network/api_response.dart';
import '../models/auth_session.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Owns authentication and the in-memory session.
///
/// It is the **only** thing the auth views talk to. It never imports Flutter
/// widgets (only `foundation`), never touches SQLite directly, and delegates
/// every decision to [AuthService].
class AuthController extends BaseController {
  AuthController({required this._authService});

  final AuthService _authService;

  AuthSession? _session;
  bool _isRestoringSession = true;

  /// The signed-in user, or `null` when nobody is logged in.
  User? get currentUser => _session?.user;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => _session != null;

  /// Whether the signed-in user holds the admin role.
  bool get isAdminUser => currentUser?.isAdmin ?? false;

  /// `true` until [restoreSession] has finished (used by the splash/boot state).
  bool get isRestoringSession => _isRestoringSession;

  /// Whether the active flavor authenticates against a REST API.
  bool get usesRemoteApi => _authService.usesRemoteApi;

  // --- Session lifecycle -----------------------------------------------------

  /// Restores a previously persisted session.
  ///
  /// Awaited during bootstrapping so the router can choose the first screen
  /// without flashing the login page.
  Future<void> restoreSession() async {
    final Result<User> result = await _authService.restoreSession();
    if (result case Success<User>(:final User data)) {
      _session = AuthSession(user: data);
    }
    _isRestoringSession = false;
    notify();
  }

  /// Validates [username] / [password] and starts a session on success.
  Future<bool> signIn({required String username, required String password}) =>
      _authenticate(
        () => _authService.signIn(username: username, password: password),
      );

  /// Registers a new standard account and signs it in.
  Future<bool> register({
    required String username,
    required String password,
    String? email,
  }) => _authenticate(
    () => _authService.register(
      username: username,
      password: password,
      email: email,
    ),
  );

  /// Requests a password-reset email (remote mode only).
  Future<Result<bool>> sendPasswordReset(String email) =>
      _authService.sendPasswordReset(email);

  /// Clears the session locally and (in remote mode) on the server.
  Future<void> signOut() async {
    await runGuarded<void>(_authService.signOut);
    _session = null;
    clearError();
    notify();
  }

  /// Invoked by `AuthService` when the API reports the session is unusable.
  ///
  /// Dropping the session makes the router redirect to `/login` on its own.
  void handleExpiredSession() {
    _session = null;
    setError('Your session has expired. Please sign in again.');
    notify();
  }

  // --- Helpers ---------------------------------------------------------------

  /// Runs an authentication action, folding its [Result] into controller state.
  Future<bool> _authenticate(
    Future<Result<AuthSession>> Function() action,
  ) async {
    setLoading(true);
    clearError();
    try {
      final Result<AuthSession> result = await action();
      switch (result) {
        case Success<AuthSession>(:final AuthSession data):
          _session = data;
          notify();
          return true;
        case Failure<AuthSession>(:final String message):
          setError(message);
          return false;
      }
    } catch (error, stackTrace) {
      debugPrint('[$runtimeType] $error\n$stackTrace');
      setError('Something went wrong. Please try again.');
      return false;
    } finally {
      setLoading(false);
    }
  }
}
