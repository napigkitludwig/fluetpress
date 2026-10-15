import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Password hashing helper used by the seeded accounts and by `AuthController`.
///
/// ## Security note — read before shipping
/// This template deliberately ships a **deterministic, application-wide salted
/// SHA-256 hash** so the sample accounts work out of the box with zero native
/// setup. That is fine for a starter template, but it is **not** production
/// grade, because:
///
///  * every user should have its own random salt (never a shared pepper alone),
///  * hashing should use a deliberately slow KDF (bcrypt / scrypt / Argon2id)
///    to resist brute-force attacks,
///  * hashing should run off the UI isolate for large payloads.
///
/// To harden the app, replace the two methods below with your production
/// implementation (e.g. the `bcrypt` package). Nothing else in the codebase
/// needs to change, because callers only depend on [hash] and [verify].
class PasswordService {
  const PasswordService._();

  /// Application-wide pepper. Replace with a per-user, randomly generated salt
  /// in production.
  static const String _pepper = 'fluetpress.default.pepper.v1';

  /// Returns the hex-encoded SHA-256 digest of `pepper + plainText`.
  static String hash(String plainText) {
    final List<int> bytes = utf8.encode('$_pepper$plainText');
    return sha256.convert(bytes).toString();
  }

  /// Compares [plainText] against a stored [hash] without short-circuiting on
  /// the first differing character.
  static bool verify({required String plainText, required String hash}) {
    final String candidate = PasswordService.hash(plainText);
    if (candidate.length != hash.length) {
      return false;
    }
    int difference = 0;
    for (int i = 0; i < candidate.length; i++) {
      difference |= candidate.codeUnitAt(i) ^ hash.codeUnitAt(i);
    }
    return difference == 0;
  }
}
