/// Reusable `FormFieldValidator`s.
///
/// Views use these directly (`validator: Validators.username`), keeping form
/// rules declarative and shared between screens.
class Validators {
  const Validators._();

  /// Matches the vast majority of real-world addresses without being
  /// RFC-5322 pedantic (the server is the real authority anyway).
  static final RegExp _emailPattern = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$',
  );

  /// At least one lower case letter, one upper case letter and one digit.
  static final RegExp _strongPassword = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$',
  );

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

  /// Password rules used by the login form (lenient: existing accounts may
  /// predate any strength policy).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  /// Stricter rules for *new* passwords (registration, password reset).
  static String? newPassword(String? value) {
    final String? basic = password(value);
    if (basic != null) {
      return basic;
    }
    if (!_strongPassword.hasMatch(value!)) {
      return 'Use upper case, lower case and a number.';
    }
    return null;
  }

  /// Confirms [confirmation] matches the original password.
  static String? confirmPassword(String? confirmation, String original) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Please confirm your password.';
    }
    if (confirmation != original) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Email rules used by registration and "forgot password".
  static String? email(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }
}
