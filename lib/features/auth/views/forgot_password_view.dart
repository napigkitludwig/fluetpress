import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_response.dart';
import '../../../app_router.dart';
import '../../../core/utils/dialogs.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_views.dart';
import '../controllers/auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// "Forgot password" — asks the backend to email a reset link.
///
/// This is a server-side flow by nature, so it only works in remote mode. In the
/// default local/demo mode the screen explains that clearly instead of pretending
/// to send anything.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final Result<bool> result = await context
        .read<AuthController>()
        .sendPasswordReset(_emailController.text.trim());

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success<bool>():
        await AppDialogs.info(
          context,
          icon: Icons.mark_email_read_outlined,
          title: 'Check your inbox',
          message:
              'If an account exists for ${_emailController.text.trim()}, a '
              'password reset link is on its way.',
        );
        if (mounted) {
          context.goNamed(AppRoute.login.name);
        }
      case Failure<bool>(:final String message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      icon: Icons.lock_reset_outlined,
      title: 'Reset your password',
      subtitle: 'We will email you a secure reset link',
      body: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.alternate_email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isSubmitting,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.email],
                validator: Validators.email,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 16),
                AppInlineError(message: _error!),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: 'Send reset link',
                icon: Icons.send_outlined,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
      footer: Center(
        child: TextButton.icon(
          onPressed: _isSubmitting
              ? null
              : () => context.goNamed(AppRoute.login.name),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to sign in'),
        ),
      ),
    );
  }
}
