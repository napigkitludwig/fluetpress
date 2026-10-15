import 'package:fluetpress/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.username', () {
    test('rejects empty and whitespace-only values', () {
      expect(Validators.username(null), isNotNull);
      expect(Validators.username(''), isNotNull);
      expect(Validators.username('   '), isNotNull);
    });

    test('rejects usernames shorter than three characters', () {
      expect(Validators.username('ab'), isNotNull);
    });

    test('accepts valid usernames', () {
      expect(Validators.username('admin_user'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty values', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('rejects passwords shorter than six characters', () {
      expect(Validators.password('12345'), isNotNull);
    });

    test('accepts the seeded passwords', () {
      expect(Validators.password('AdminPassword123!'), isNull);
      expect(Validators.password('UserPassword123!'), isNull);
    });
  });
}
