import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Visual weight of an [AppButton].
enum AppButtonVariant {
  /// Filled, brand-coloured — one per screen (the primary action).
  primary,

  /// Outlined — secondary actions.
  outline,

  /// Text only — tertiary actions and "forgot password" style links.
  text,

  /// Filled with the danger tone — destructive actions.
  danger,
}

/// Full-width call-to-action button with a built-in loading state.
///
/// While [isLoading] is `true` the button is disabled and a progress indicator
/// replaces its label, which keeps form submission flows consistent everywhere.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = true,
  });

  /// Button text.
  final String label;

  /// Tap handler. Ignored while [isLoading] is `true`.
  final VoidCallback? onPressed;

  /// Visual weight.
  final AppButtonVariant variant;

  /// Renders a spinner and disables the button when `true`.
  final bool isLoading;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether the button should stretch to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? handler = isLoading ? null : onPressed;

    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: handler,
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: handler,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: handler, child: child),
      AppButtonVariant.danger => FilledButton(
        onPressed: handler,
        style: FilledButton.styleFrom(
          backgroundColor: AppSemanticColors.of(context).danger,
        ),
        child: child,
      ),
    };

    if (!expand) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}
