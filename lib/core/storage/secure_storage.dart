import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for everything sensitive: JWT access/refresh tokens and the
/// identifiers needed to restore a session on the next cold start.
///
/// * **Android** → `EncryptedSharedPreferences`, key material held in the
///   Keystore.
/// * **iOS** → Keychain.
///
/// Non-sensitive preferences (theme mode, feature flags) belong in the SQLite
/// `app_settings` table instead — see `DatabaseHelper`.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Keys are namespaced so they can never collide with another plugin's data.
  static const String _keyAccessToken = 'auth.access_token';
  static const String _keyRefreshToken = 'auth.refresh_token';
  static const String _keyUserId = 'session.user_id';
  static const String _keyUsername = 'session.username';
  static const String _keyRole = 'session.role';

  // --- Tokens ----------------------------------------------------------------

  /// Persists the token pair. [refreshToken] is left untouched when omitted.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  /// The current access token, or `null`.
  Future<String?> readAccessToken() => _storage.read(key: _keyAccessToken);

  /// The current refresh token, or `null`.
  Future<String?> readRefreshToken() => _storage.read(key: _keyRefreshToken);

  // --- Session ---------------------------------------------------------------

  /// Remembers who is signed in so the session can be restored on next launch.
  Future<void> saveSession({
    required int userId,
    required String username,
    required String role,
  }) async {
    await _storage.write(key: _keyUserId, value: '$userId');
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyRole, value: role);
  }

  /// Id of the remembered user, or `null` when nobody is signed in.
  Future<int?> readSessionUserId() async {
    final String? raw = await _storage.read(key: _keyUserId);
    return raw == null ? null : int.tryParse(raw);
  }

  /// Whether a session was persisted previously.
  Future<bool> hasSession() async => await readSessionUserId() != null;

  // --- Cleanup ---------------------------------------------------------------

  /// Wipes tokens and session data (sign-out, "my session expired", ...).
  Future<void> clearSession() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyUsername),
      _storage.delete(key: _keyRole),
    ]);
  }

  /// Wipes *everything* this service owns. Useful in tests and on "log out of
  /// all devices".
  Future<void> clearAll() => _storage.deleteAll();
}
