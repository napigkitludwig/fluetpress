import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user.dart';
import '../../auth/models/user_role.dart';
import '../../auth/views/widgets/role_badge.dart';
import '../controllers/home_controller.dart';

/// Home / dashboard screen.
///
/// Demonstrates the full MVC loop: the view reacts to [HomeController] state and
/// renders **role-based UI** — administrators get a management panel, standard
/// users get a restricted view. Every value comes from the controller; the view
/// never touches SQLite or the network.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeController _controller = HomeController(
    authController: context.read<AuthController>(),
  );

  @override
  void initState() {
    super.initState();
    // Initial load: admins fetch the accounts, standard users fetch nothing.
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final bool confirmed = await context.confirm(
      title: 'Sign out',
      message: 'End your session on this device?',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) {
      return;
    }
    await _controller.signOut();
  }

  Future<void> _confirmDelete(User user) async {
    final bool confirmed = await context.confirm(
      title: 'Delete account',
      message: 'Remove "${user.username}" permanently?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final bool deleted = await _controller.deleteUser(user.id!);
    if (!mounted) {
      return;
    }
    context.showAppSnack(
      deleted
          ? '"${user.username}" was deleted.'
          : (_controller.errorMessage ?? 'Could not delete the account.'),
      isError: !deleted,
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
                    validator: Validators.newPassword,
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

    if (submit == true) {
      await _controller.createUser(
        username: username.text,
        password: password.text,
        role: role,
      );
    }

    username.dispose();
    password.dispose();

    if (!mounted || submit != true) {
      return;
    }
    final bool created = !_controller.hasError;
    context.showAppSnack(
      created
          ? 'Account created successfully.'
          : (_controller.errorMessage ?? 'Could not create the account.'),
      isError: !created,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.pushNamed(AppRoute.settings.name),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          final User? user = _controller.currentUser;

          // The session disappeared (e.g. signed out from the settings screen).
          if (user == null) {
            return const EmptyView(
              icon: Icons.lock_clock_outlined,
              title: 'Your session has ended',
              message: 'Please sign in again to continue.',
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (_controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                _ProfileCard(user: user),
                const SizedBox(height: 16),
                if (_controller.isAdmin)
                  _buildAdminPanel()
                else
                  _buildStandardUserPanel(),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Sign out',
                  icon: Icons.logout,
                  variant: AppButtonVariant.outline,
                  onPressed: _signOut,
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
    final AppSemanticColors semantic = AppSemanticColors.of(context);
    final List<User> accounts = _controller.accounts;
    final counts = _controller.summary;

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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _StatChip(
                  label: 'Accounts',
                  value: '${counts.totalUsers}',
                  color: theme.colorScheme.primary,
                ),
                _StatChip(
                  label: 'Admins',
                  value: '${counts.adminCount}',
                  color: semantic.info,
                ),
                _StatChip(
                  label: 'Standard',
                  value: '${counts.standardCount}',
                  color: semantic.success,
                ),
              ],
            ),
            const Divider(height: 24),
            if (accounts.isEmpty)
              Text(
                'No accounts loaded yet. Pull down to refresh.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...accounts.map(_buildAccountTile),
            const SizedBox(height: 16),
            AppButton(
              label: 'Add user',
              icon: Icons.person_add_alt,
              variant: AppButtonVariant.primary,
              onPressed: _openCreateUserDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile(User user) {
    final ThemeData theme = Theme.of(context);
    final bool isSelf = _controller.isCurrentUser(user.id);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(user.username.initials)),
      title: Text(user.username),
      subtitle: Text('ID #${user.id ?? '-'}', style: theme.textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RoleBadge(role: user.role, compact: true),
          const SizedBox(width: 4),
          if (isSelf)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'You',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Delete account',
              onPressed: () => _confirmDelete(user),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
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
              'You are signed in with the standard user role. Administrative '
              'tools (managing accounts) are hidden. Ask an administrator if '
              'you need elevated access.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Small statistic pill used by the admin panel.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.username.initials,
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
