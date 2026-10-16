import 'package:flutter/material.dart';

import 'dialogs.dart';

/// Sugar for the two formatting problems every UI hits.
extension StringX on String {
  /// `hello` → `Hello`.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// `true` when the string is empty or whitespace only.
  bool get isBlank => trim().isEmpty;

  /// Inverse of [isBlank].
  bool get isNotBlank => !isBlank;

  /// Up to two initials, e.g. `"Ada Lovelace"` → `"AL"`.
  String get initials => trim()
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .take(2)
      .map((String word) => word[0].toUpperCase())
      .join();
}

/// Widget-tree shortcuts for the shared dialogs/snackbars.
extension BuildContextX on BuildContext {
  /// Shows a floating snack bar carrying [message].
  void showAppSnack(String message, {bool isError = false}) =>
      AppDialogs.showSnack(this, message, isError: isError);

  /// Asks the user to confirm a destructive or important action.
  Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool destructive = false,
  }) => AppDialogs.confirm(
    this,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    destructive: destructive,
  );
}
