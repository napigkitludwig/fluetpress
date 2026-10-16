import 'package:fluetpress/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.requiredField', () {
    test('rejects null, empty and whitespace-only values', () {
      expect(Validators.requiredField(null), isNotNull);
      expect(Validators.requiredField(''), isNotNull);
      expect(Validators.requiredField('   '), isNotNull);
    });

    test('accepts a value and names the field in the message', () {
      expect(Validators.requiredField('value'), isNull);
      expect(Validators.requiredField('', field: 'Email'), contains('Email'));
    });
  });

  group('Validators.username', () {
    test('requires at least three characters', () {
      expect(Validators.username(null), isNotNull);
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('abc'), isNull);
      expect(Validators.username('  admin_user  '), isNull);
    });
  });

  group('Validators.password', () {
    test('requires at least six characters', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.newPassword', () {
    test('enforces mixed case and a digit on top of the minimum length', () {
      expect(Validators.newPassword('onlylowercase1'), isNotNull);
      expect(Validators.newPassword('ONLYUPPERCASE1'), isNotNull);
      expect(Validators.newPassword('NoDigitsHere'), isNotNull);
      expect(Validators.newPassword('Good1Pass'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects empty and mismatched values', () {
      expect(Validators.confirmPassword(null, 'abc'), isNotNull);
      expect(Validators.confirmPassword('', 'abc'), isNotNull);
      expect(Validators.confirmPassword('abd', 'abc'), isNotNull);
    });

    test('accepts an exact match', () {
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts common shapes', () {
      expect(Validators.email('dev@example.com'), isNull);
      expect(Validators.email('first.last+tag@sub.example.co.uk'), isNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('no-at-sign'), isNotNull);
      expect(Validators.email('missing@tld'), isNotNull);
      expect(Validators.email('@example.com'), isNotNull);
    });
  });
}
