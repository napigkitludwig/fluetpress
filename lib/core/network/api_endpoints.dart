/// Every REST path the app talks to, in one place.
///
/// Keeping paths here (instead of inlining strings in services) means a
/// back-end version bump or a renamed resource is a one-line change, and it
/// makes it obvious which endpoints a feature actually depends on.
///
/// All paths are relative to [EnvConfig.baseUrl].
class ApiEndpoints {
  const ApiEndpoints._();

  // --- Authentication --------------------------------------------------------

  /// `POST` — exchange credentials for an access/refresh token pair.
  static const String login = '/auth/login';

  /// `POST` — create a new account.
  static const String register = '/auth/register';

  /// `POST` — trade a refresh token for a fresh access token.
  static const String refresh = '/auth/refresh';

  /// `POST` — invalidate the current refresh token server-side.
  static const String logout = '/auth/logout';

  /// `POST` — request a password reset email.
  static const String forgotPassword = '/auth/forgot-password';

  /// `GET` — the profile of the currently authenticated user.
  static const String profile = '/auth/me';

  // --- Resources -------------------------------------------------------------

  /// `GET` / `POST` — account collection.
  static const String users = '/users';
}
