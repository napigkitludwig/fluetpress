import '../../../core/controllers/base_controller.dart';
import '../../../core/utils/password_hasher.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user.dart';
import '../../auth/models/user_role.dart';
import '../../auth/services/user_local_data_source.dart';
import '../models/dashboard_summary.dart';

/// Backs the home / dashboard screen.
///
/// It exposes the signed-in user plus, for administrators, every registered
/// account and the admin-only actions (create / delete). Standard users get an
/// empty list, which the view renders as a restricted panel — the role-based UI
/// split lives in the view, the *permission* enforcement lives here.
class HomeController extends BaseController {
  HomeController({required this.authController, UserLocalDataSource? userStore})
    : _userStore = userStore ?? UserLocalDataSource();

  /// Session controller backing this screen.
  ///
  /// Exposed so views can delegate session actions (e.g. sign out) without
  /// keeping a second reference around.
  final AuthController authController;

  final UserLocalDataSource _userStore;

  List<User> _accounts = const <User>[];

  /// Registered accounts. Empty for non-admin users.
  List<User> get accounts => List<User>.unmodifiable(_accounts);

  /// Dashboard counters derived from the loaded accounts.
  DashboardSummary get summary => DashboardSummary.fromUsers(_accounts);

  /// The signed-in user (delegated to [AuthController]).
  User? get currentUser => authController.currentUser;

  /// Whether the signed-in user is an administrator.
  bool get isAdmin => authController.isAdminUser;

  /// Whether [userId] belongs to the signed-in user.
  bool isCurrentUser(int? userId) =>
      userId != null && userId == currentUser?.id;

  // --- Loading ---------------------------------------------------------------

  /// Loads everything the current role is allowed to see.
  ///
  /// Safe to call from `initState` and from pull-to-refresh.
  Future<void> load() async {
    if (!isAdmin) {
      _accounts = const <User>[];
      notify();
      return;
    }

    final List<User>? result = await runGuarded<List<User>>(
      _userStore.getUsers,
    );
    if (result != null) {
      _accounts = result;
      notify();
    }
  }

  // --- Admin actions ---------------------------------------------------------

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

    final bool? alreadyTaken = await runGuarded<bool>(
      () => _userStore.usernameExists(trimmedUsername),
    );
    if (alreadyTaken == null) {
      return false; // storage failure, errorMessage already set
    }
    if (alreadyTaken) {
      setError('The username "$trimmedUsername" is already taken.');
      return false;
    }

    final int? newId = await runGuarded<int>(
      () => _userStore.insertUser(
        User(
          username: trimmedUsername,
          password: PasswordHasher.hash(password),
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

    final int? deleted = await runGuarded<int>(
      () => _userStore.deleteUser(userId),
    );
    if (deleted == null) {
      return false;
    }

    await load();
    return true;
  }

  // --- Session ---------------------------------------------------------------

  /// Ends the session. The router guard navigates back to `/login`.
  Future<void> signOut() => authController.signOut();
}
