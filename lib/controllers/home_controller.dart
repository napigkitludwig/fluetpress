import '../models/user.dart';
import '../models/user_role.dart';
import '../services/database_helper.dart';
import '../services/password_service.dart';
import 'auth_controller.dart';
import 'base_controller.dart';

/// Backs the home screen.
///
/// It exposes the signed-in user plus, for administrators, the full list of
/// registered accounts and the admin-only actions (create / delete). Standard
/// users simply get an empty list, which the view renders as a restricted view.
class HomeController extends BaseController {
  HomeController({
    required this.authController,
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Session controller backing this screen.
  ///
  /// Exposed so views can delegate session actions (e.g. sign out) without
  /// keeping a second reference around.
  final AuthController authController;

  final DatabaseHelper _databaseHelper;

  List<User> _users = const <User>[];

  /// Registered accounts. Empty for non-admin users.
  List<User> get users => List<User>.unmodifiable(_users);

  /// Number of accounts currently loaded.
  int get userCount => _users.length;

  /// The signed-in user (delegated to [AuthController]).
  User? get currentUser => authController.currentUser;

  /// Whether the signed-in user is an administrator.
  bool get isAdmin => authController.isAdminUser;

  /// Whether [userId] belongs to the signed-in user.
  bool isCurrentUser(int? userId) =>
      userId != null && userId == currentUser?.id;

  /// Loads everything the current role is allowed to see.
  ///
  /// Safe to call from `initState` and from pull-to-refresh.
  Future<void> load() async {
    if (!isAdmin) {
      _users = const <User>[];
      notify();
      return;
    }

    final List<User>? result = await runGuarded(_databaseHelper.getUsers);
    if (result != null) {
      _users = result;
      notify();
    }
  }

  /// Admin-only: creates a new account with a hashed password.
  Future<bool> createUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    if (!isAdmin) {
      setError('Only administrators can create accounts.');
      return false;
    }

    final String trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      setError('A username and password are required.');
      return false;
    }

    final bool? alreadyTaken = await runGuarded(
      () => _databaseHelper.usernameExists(trimmedUsername),
    );
    if (alreadyTaken == null) {
      return false; // storage failure, errorMessage already set
    }
    if (alreadyTaken) {
      setError('The username "$trimmedUsername" is already taken.');
      return false;
    }

    final int? newId = await runGuarded(
      () => _databaseHelper.insertUser(
        User(
          username: trimmedUsername,
          password: PasswordService.hash(password),
          role: role,
        ),
      ),
    );
    if (newId == null) {
      return false;
    }

    await load();
    return true;
  }

  /// Admin-only: deletes the account with [userId].
  Future<bool> deleteUser(int userId) async {
    if (!isAdmin) {
      setError('Only administrators can delete accounts.');
      return false;
    }
    if (isCurrentUser(userId)) {
      setError('You cannot delete the account you are signed in with.');
      return false;
    }

    final int? deleted = await runGuarded(
      () => _databaseHelper.deleteUser(userId),
    );
    if (deleted == null) {
      return false;
    }

    await load();
    return true;
  }
}
