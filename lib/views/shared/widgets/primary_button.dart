import 'package:flutter/material.dart';

/// Full-width call-to-action button with a built-in loading state.
///
/// While [isLoading] is `true` the button is disabled and a progress indicator
/// replaces its label, which keeps form submission flows consistent everywhere.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  /// Button text.
  final String label;

  /// Tap handler. Ignored while [isLoading] is `true`.
  final VoidCallback? onPressed;

  /// Renders a spinner and disables the button when `true`.
  final bool isLoading;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}
