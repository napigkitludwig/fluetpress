import '../models/user.dart';
import '../services/database_helper.dart';
import '../services/password_service.dart';
import 'base_controller.dart';

/// Owns authentication and the in-memory session.
///
/// It is the **only** thing the auth views talk to: it validates input, hashes
/// and compares passwords, and exposes the signed-in [currentUser]. It never
/// imports Flutter widgets.
class AuthController extends BaseController {
  AuthController({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  User? _currentUser;

  /// The signed-in user, or `null` when nobody is logged in.
  User? get currentUser => _currentUser;

  /// Whether a user is currently signed in.
  bool get isAuthenticated => _currentUser != null;

  /// Whether the signed-in user holds the admin role.
  bool get isAdminUser => _currentUser?.isAdmin ?? false;

  /// Validates [username] / [password] against the `users` table.
  ///
  /// Returns `true` on success (and populates [currentUser]); on failure it
  /// returns `false` and [errorMessage] holds a human-readable reason.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final String trimmedUsername = username.trim();

    if (trimmedUsername.isEmpty || password.isEmpty) {
      setError('Please enter both your username and password.');
      return false;
    }

    final User? user = await runGuarded<User?>(
      () => _databaseHelper.getUserByUsername(trimmedUsername),
    );

    // A storage failure already populated errorMessage inside runGuarded.
    if (hasError) {
      return false;
    }

    final bool passwordMatches =
        user != null &&
        PasswordService.verify(plainText: password, hash: user.password);

    if (!passwordMatches) {
      // Deliberately vague: never reveal whether the username exists.
      setError('Invalid username or password.');
      return false;
    }

    _currentUser = user;
    clearError();
    notify();
    return true;
  }

  /// Clears the in-memory session (the database is left untouched).
  void logout() {
    _currentUser = null;
    clearError();
    notify();
  }
}
