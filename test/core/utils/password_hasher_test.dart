import 'package:fluetpress/core/utils/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordHasher', () {
    test('produces a stable, hex-encoded SHA-256 digest', () {
      final String hash = PasswordHasher.hash('AdminPassword123!');

      expect(hash, hasLength(64));
      expect(hash, matches(RegExp(r'^[0-9a-f]+$')));
      expect(PasswordHasher.hash('AdminPassword123!'), hash);
    });

    test('different inputs produce different digests', () {
      expect(
        PasswordHasher.hash('password-a'),
        isNot(PasswordHasher.hash('password-b')),
      );
    });

    test('verify accepts the matching plaintext', () {
      final String hash = PasswordHasher.hash('s3cret');

      expect(PasswordHasher.verify(plainText: 's3cret', hash: hash), isTrue);
    });

    test('verify rejects a wrong plaintext', () {
      final String hash = PasswordHasher.hash('s3cret');

      expect(PasswordHasher.verify(plainText: 's3crey', hash: hash), isFalse);
      expect(PasswordHasher.verify(plainText: '', hash: hash), isFalse);
    });

    test('verify rejects malformed stored hashes without throwing', () {
      expect(PasswordHasher.verify(plainText: 'x', hash: ''), isFalse);
      expect(
        PasswordHasher.verify(plainText: 'x', hash: 'not-a-hash'),
        isFalse,
      );
    });
  });
}
