import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/env_config.dart';
import '../../../app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_views.dart';
import '../controllers/auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Login screen.
///
/// The view is intentionally "dumb": it owns the text controllers and the form
/// key, but every decision (validation against the store, session state, error
/// messages) is delegated to [AuthController]. It never touches SQLite or the
/// network, and it does not navigate on success — the router's auth guard does
/// that as soon as the controller reports an authenticated session.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await context.read<AuthController>().signIn(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    // Success is handled by the router guard in `AppRouter`.
  }

  /// Convenience for trying the template out — fills the form with a seeded
  /// account instead of typing it.
  void _useDemoCredentials(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
    context.read<AuthController>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthController controller = context.watch<AuthController>();

    return AuthScaffold(
      title: AppBrand.current.displayName,
      subtitle: 'Sign in to continue',
      body: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                controller: _usernameController,
                label: 'Username',
                icon: Icons.person_outline,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.text,
                autofillHints: const <String>[AutofillHints.username],
                validator: Validators.username,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                validator: Validators.password,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => context.goNamed(AppRoute.forgotPassword.name),
                  child: const Text('Forgot password?'),
                ),
              ),
              if (controller.hasError)
                AppInlineError(message: controller.errorMessage!),
              const SizedBox(height: 16),
              AppButton(
                label: 'Sign in',
                icon: Icons.login,
                isLoading: controller.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'New here?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: controller.isLoading
                    ? null
                    : () => context.goNamed(AppRoute.register.name),
                child: const Text('Create an account'),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            'Try a seeded account',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => _useDemoCredentials(
                          AppConstants.seedAdminUsername,
                          AppConstants.seedAdminPassword,
                        ),
                  child: const Text('Admin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => _useDemoCredentials(
                          AppConstants.seedUserUsername,
                          AppConstants.seedUserPassword,
                        ),
                  child: const Text('User'),
                ),
              ),
            ],
          ),
          if (!EnvConfig.instance.isProd) ...<Widget>[
            const SizedBox(height: 24),
            _EnvironmentBadge(),
          ],
        ],
      ),
    );
  }
}

/// Small footer showing which flavor/base URL the build is pointing at.
///
/// Invaluable when a client reports "the login is broken on staging" — the
/// screen itself tells you which backend it hit. Hidden in production.
class _EnvironmentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final EnvConfig config = EnvConfig.instance;
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Text(
          '${config.environment.label} · ${config.appName}',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          config.baseUrl,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
