import 'package:flutter/material.dart';

/// Shared chrome for the authentication screens (login, register, forgot
/// password): centred, width-capped, keyboard-safe scroll view with the brand
/// icon, title and subtitle.
///
/// Keeping it here means the three screens differ only in their form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.icon = Icons.lock_person_outlined,
    this.footer,
  });

  /// Screen title (usually the brand name).
  final String title;

  /// One-line explanation under the title.
  final String subtitle;

  /// Form content.
  final List<Widget> body;

  /// Icon shown above the title.
  final IconData icon;

  /// Optional content pinned below the form (links, demo credentials, ...).
  final Widget? footer;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(icon, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...body,
                  if (footer != null) ...<Widget>[
                    const SizedBox(height: 24),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
