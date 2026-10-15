/// Reusable `FormFieldValidator`s.
///
/// Views use these directly (`validator: Validators.username`), keeping form
/// rules declarative and shared between screens.
class Validators {
  const Validators._();

  /// Fails when [value] is null, empty or whitespace only.
  static String? requiredField(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }

  /// Username rules used by the login and "create account" forms.
  static String? username(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Username is required.';
    }
    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    return null;
  }

  /// Password rules used by the login and "create account" forms.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}
