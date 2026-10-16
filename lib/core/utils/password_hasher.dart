import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Password hashing helper shared by the seeded accounts, the local sign-in flow
/// and the "create account" flow.
///
/// ## Security note — read before shipping
/// This boilerplate deliberately ships a **deterministic, application-wide
/// salted SHA-256 hash** so the sample accounts work out of the box with zero
/// native setup. That is fine for a starter template, but it is **not**
/// production grade, because:
///
///  * every user should have its own random salt (never a shared pepper alone),
///  * hashing should use a deliberately slow KDF (bcrypt / scrypt / Argon2id)
///    to resist brute-force attacks,
///  * hashing should run off the UI isolate for large payloads.
///
/// To harden the app, replace the two methods below with your production
/// implementation (e.g. the `bcrypt` package, or your backend's hashing).
/// Nothing else in the codebase changes, because callers only depend on
/// [hash] and [verify].
class PasswordHasher {
  const PasswordHasher._();

  /// Application-wide pepper. Replace with a per-user, randomly generated salt
  /// in production.
  static const String _pepper = 'fluetpress.default.pepper.v1';

  /// Returns the hex-encoded SHA-256 digest of `pepper + plainText`.
  static String hash(String plainText) {
    final List<int> bytes = utf8.encode('$_pepper$plainText');
    return sha256.convert(bytes).toString();
  }

  /// Compares [plainText] against a stored [hash] in constant time.
  ///
  /// Stops short-circuiting on the first differing character so verification
  /// time does not leak how much of the digest matched.
  static bool verify({required String plainText, required String hash}) {
    final String candidate = PasswordHasher.hash(plainText);
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
