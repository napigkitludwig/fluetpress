import 'package:fluetpress/services/password_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordService', () {
    test('never returns the plain text', () {
      const String plain = 'AdminPassword123!';

      expect(PasswordService.hash(plain), isNot(plain));
      expect(PasswordService.hash(plain), hasLength(64)); // SHA-256 hex digest
    });

    test('is deterministic for the same input', () {
      expect(
        PasswordService.hash('secret'),
        PasswordService.hash('secret'),
      );
    });

    test('produces different digests for different inputs', () {
      expect(
        PasswordService.hash('secret'),
        isNot(PasswordService.hash('secret ')),
      );
    });

    test('verify accepts the original password', () {
      final String stored = PasswordService.hash('UserPassword123!');

      expect(
        PasswordService.verify(
          plainText: 'UserPassword123!',
          hash: stored,
        ),
        isTrue,
      );
    });

    test('verify rejects a wrong password or a malformed hash', () {
      final String stored = PasswordService.hash('UserPassword123!');

      expect(
        PasswordService.verify(plainText: 'wrong', hash: stored),
        isFalse,
      );
      expect(
        PasswordService.verify(plainText: 'UserPassword123!', hash: 'short'),
        isFalse,
      );
    });
  });
}
