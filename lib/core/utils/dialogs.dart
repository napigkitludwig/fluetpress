import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared, theme-aware dialogs and snack bars.
///
/// Views call these instead of hand-rolling `showDialog` / `ScaffoldMessenger`
/// boilerplate, so every confirmation looks and behaves the same.
class AppDialogs {
  const AppDialogs._();

  /// Shows a floating snack bar. Uses the theme's danger tone when [isError].
  static void showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppSemanticColors semantic = AppSemanticColors.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: isError
                  ? scheme.onErrorContainer
                  : scheme.onInverseSurface,
            ),
          ),
          backgroundColor: isError
              ? scheme.errorContainer
              : scheme.inverseSurface,
          duration: Duration(seconds: isError ? 5 : 3),
          showCloseIcon: isError,
          closeIconColor: isError
              ? scheme.onErrorContainer
              : scheme.onInverseSurface,
          // Keeps the semantic palette reachable for callers that customise the
          // bar further.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isError ? semantic.danger : scheme.outline),
          ),
        ),
      );
  }

  /// Shows a confirmation dialog and resolves to `true` when accepted.
  ///
  /// [destructive] paints the accept button in the danger tone.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppSemanticColors semantic = AppSemanticColors.of(dialogContext);
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: semantic.danger)
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return accepted ?? false;
  }

  /// Shows an informational dialog with a single dismiss action.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String closeLabel = 'Got it',
    IconData icon = Icons.info_outline,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: Icon(icon),
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(closeLabel),
          ),
        ],
      ),
    );
  }
}
