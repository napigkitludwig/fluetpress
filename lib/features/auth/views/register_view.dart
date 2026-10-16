import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_views.dart';
import '../controllers/auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Self-service registration.
///
/// Accounts created here always hold the `User` role; only an administrator can
/// grant `Admin` (see the home screen's management panel). On success the
/// controller has a session, so the router guard replaces this screen with the
/// dashboard.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String email = _emailController.text.trim();
    await context.read<AuthController>().register(
      username: _usernameController.text,
      password: _passwordController.text,
      email: email.isEmpty ? null : email,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = context.watch<AuthController>();

    return AuthScaffold(
      icon: Icons.person_add_alt,
      title: 'Create your account',
      subtitle: 'It takes a few seconds',
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
                autofillHints: const <String>[AutofillHints.newUsername],
                validator: Validators.username,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email (optional)',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                    ? null
                    : Validators.email(value),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: Validators.newPassword,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmController,
                label: 'Confirm password',
                icon: Icons.lock_reset_outlined,
                obscureText: true,
                enabled: !controller.isLoading,
                textInputAction: TextInputAction.done,
                validator: (String? value) =>
                    Validators.confirmPassword(value, _passwordController.text),
                onSubmitted: (_) => _submit(),
              ),
              if (controller.hasError) ...<Widget>[
                const SizedBox(height: 16),
                AppInlineError(message: controller.errorMessage!),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Create account',
                icon: Icons.check,
                isLoading: controller.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
      footer: Center(
        child: TextButton.icon(
          onPressed: controller.isLoading
              ? null
              : () => context.goNamed(AppRoute.login.name),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('I already have an account'),
        ),
      ),
    );
  }
}
