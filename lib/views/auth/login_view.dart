import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart';
import '../../utils/validators.dart';
import '../shared/widgets/app_text_field.dart';
import '../shared/widgets/primary_button.dart';

/// Login screen.
///
/// The view is intentionally "dumb": it owns the text controllers and the form
/// key, but every decision (validation against the database, session state,
/// error messages) is delegated to [AuthController]. It never touches SQLite.
class LoginView extends StatefulWidget {
  const LoginView({super.key, required this.authController});

  /// Injected by `AppRouter`.
  final AuthController authController;

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

    final bool success = await widget.authController.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }
    if (!success) {
      return; // The controller exposes the error message to the UI.
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  /// Convenience for trying the template out — fills the form with a seeded
  /// account instead of typing it.
  void _useDemoCredentials(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
    widget.authController.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: widget.authController,
                builder: (BuildContext context, Widget? _) {
                  final AuthController controller = widget.authController;

                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Icon(
                          Icons.lock_person_outlined,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        AppTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                          enabled: !controller.isLoading,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          autofillHints: const <String>[
                            AutofillHints.username,
                          ],
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
                          autofillHints: const <String>[
                            AutofillHints.password,
                          ],
                          validator: Validators.password,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (controller.hasError) ...<Widget>[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: controller.errorMessage!),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Sign in',
                          icon: Icons.login,
                          isLoading: controller.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 32),
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline, theme-aware error message rendered above the submit button.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
