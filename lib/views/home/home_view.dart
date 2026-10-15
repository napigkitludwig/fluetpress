import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/validators.dart';
import '../shared/widgets/app_text_field.dart';
import '../shared/widgets/role_badge.dart';

/// Home / dashboard screen.
///
/// Demonstrates the full MVC loop: the view reacts to [HomeController] state and
/// renders **role-based UI** — administrators get a management panel, standard
/// users get a restricted view. All data comes from the controller; the view
/// never touches [DatabaseHelper].
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.authController});

  /// Injected by `AppRouter` — the shared session controller.
  final AuthController authController;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _controller = HomeController(
    authController: widget.authController,
  );

  @override
  void initState() {
    super.initState();
    // Kick off the initial load (admin: fetch users / user: nothing to fetch).
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    widget.authController.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete(User user) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete account'),
        content: Text('Remove "${user.username}" permanently?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final bool deleted = await _controller.deleteUser(user.id!);
    if (!mounted) {
      return;
    }
    _showMessage(
      deleted
          ? '"${user.username}" was deleted.'
          : (_controller.errorMessage ?? 'Could not delete the account.'),
    );
  }

  Future<void> _openCreateUserDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController username = TextEditingController();
    final TextEditingController password = TextEditingController();
    UserRole role = UserRole.user;

    final bool? submit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: const Text('Create account'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppTextField(
                    controller: username,
                    label: 'Username',
                    icon: Icons.person_outline,
                    validator: Validators.username,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: password,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<UserRole>(
                    segments: const <ButtonSegment<UserRole>>[
                      ButtonSegment<UserRole>(
                        value: UserRole.user,
                        label: Text('User'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.admin,
                        label: Text('Admin'),
                        icon: Icon(Icons.shield_outlined),
                      ),
                    ],
                    selected: <UserRole>{role},
                    onSelectionChanged: (Set<UserRole> selection) {
                      setDialogState(() => role = selection.first);
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (submit != true) {
      username.dispose();
      password.dispose();
      return;
    }

    final bool created = await _controller.createUser(
      username: username.text,
      password: password.text,
      role: role,
    );
    username.dispose();
    password.dispose();

    if (!mounted) {
      return;
    }
    _showMessage(
      created
          ? 'Account created successfully.'
          : (_controller.errorMessage ?? 'Could not create the account.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          final User? user = _controller.currentUser;

          // The session disappeared (e.g. signed out from another screen).
          if (user == null) {
            return const Center(child: Text('Your session has ended.'));
          }

          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (_controller.isLoading) const LinearProgressIndicator(),
                _ProfileCard(user: user),
                const SizedBox(height: 16),
                if (user.isAdmin) _buildAdminPanel() else _buildStandardUserPanel(),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminPanel() {
    final ThemeData theme = Theme.of(context);
    final List<User> users = _controller.users;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Administration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_controller.userCount} registered account(s). '
              'As an admin you can manage every account.',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            if (users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No accounts loaded yet. Pull down to refresh.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ...users.map(_buildUserTile),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openCreateUserDialog,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add user'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(User user) {
    final ThemeData theme = Theme.of(context);
    final bool isSelf = _controller.isCurrentUser(user.id);
    final String initial = user.username.isEmpty
        ? '?'
        : user.username.characters.first.toUpperCase();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(initial)),
      title: Text(user.username),
      subtitle: Text(
        'ID #${user.id ?? '-'} · ${user.role.dbValue}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: isSelf
          ? Text(
              'You',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            )
          : IconButton(
              tooltip: 'Delete account',
              onPressed: () => _confirmDelete(user),
              icon: const Icon(Icons.delete_outline),
            ),
    );
  }

  Widget _buildStandardUserPanel() {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.verified_user_outlined,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Standard access',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You are signed in with the standard user role. '
              'Administrative tools (managing accounts) are hidden. '
              'Ask an administrator if you need elevated access.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card summarising the signed-in account.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String initial = user.username.isEmpty
        ? '?'
        : user.username.characters.first.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initial,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    user.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Account ID: ${user.id ?? '-'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  RoleBadge(role: user.role),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
