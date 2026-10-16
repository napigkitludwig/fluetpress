import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/widgets/role_badge.dart';
import '../controllers/settings_controller.dart';

/// Settings screen.
///
/// Read-only diagnostics (which flavor, which API, how auth works) plus the two
/// things a client app always needs: appearance and sign out.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    final AuthController auth = context.watch<AuthController>();
    final EnvConfig env = EnvConfig.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _Section(
            title: 'Appearance',
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: <ThemeMode>{settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) =>
                  settings.setThemeMode(selection.first),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Account',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        auth.currentUser?.username ?? 'Not signed in',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (auth.currentUser != null)
                      RoleBadge(role: auth.currentUser!.role),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Account ID: ${auth.currentUser?.id ?? '-'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Environment',
            child: Column(
              children: <Widget>[
                _InfoRow(label: 'Brand', value: AppBrand.current.displayName),
                _InfoRow(label: 'Environment', value: env.environment.label),
                _InfoRow(label: 'API base URL', value: env.baseUrl),
                _InfoRow(
                  label: 'Authentication',
                  value: env.useRemoteAuth
                      ? 'REST API (JWT)'
                      : 'Local demo store',
                ),
                _InfoRow(
                  label: 'Database',
                  value:
                      '${AppConstants.databaseName} v${AppConstants.databaseVersion}',
                ),
                _InfoRow(
                  label: 'API logging',
                  value: env.enableApiLogging ? 'Enabled' : 'Disabled',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Session',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Signing out clears the session stored on this device. '
                  'Your account is not deleted.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Sign out',
                  icon: Icons.logout,
                  variant: AppButtonVariant.outline,
                  // Capture the controller before awaiting so no `BuildContext`
                  // is used across an await boundary.
                  onPressed: () async {
                    final AuthController controller = context
                        .read<AuthController>();
                    final bool confirmed = await context.confirm(
                      title: 'Sign out',
                      message: 'End your session on this device?',
                      confirmLabel: 'Sign out',
                    );
                    if (!confirmed) {
                      return;
                    }
                    await controller.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
