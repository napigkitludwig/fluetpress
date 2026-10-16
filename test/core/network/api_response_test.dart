import 'package:fluetpress/core/network/api_response.dart';
import 'package:fluetpress/core/network/network_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success exposes its data', () {
      const Result<int> result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 42);
      expect(result.errorOrNull, isNull);
    });

    test('Failure exposes a user-safe message and status', () {
      const Result<int> result = Failure<int>('Nope', statusCode: 403);

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, 'Nope');
      expect(result.dataOrNull, isNull);
      expect((result as Failure<int>).statusCode, 403);
    });

    test('Failure.isUnauthorized recognises 401 and the typed exception', () {
      expect(const Failure<int>('x', statusCode: 401).isUnauthorized, isTrue);
      expect(
        const Failure<int>(
          'x',
          exception: UnauthorizedException(),
        ).isUnauthorized,
        isTrue,
      );
      expect(const Failure<int>('x', statusCode: 500).isUnauthorized, isFalse);
    });

    test('when folds both branches', () {
      const Result<int> ok = Success<int>(2);
      const Result<int> bad = Failure<int>('boom');

      expect(
        ok.when(
          success: (int value) => 'value: $value',
          failure: (Failure<int> failure) => 'error: ${failure.message}',
        ),
        'value: 2',
      );
      expect(
        bad.when(
          success: (int value) => 'value: $value',
          failure: (Failure<int> failure) => 'error: ${failure.message}',
        ),
        'error: boom',
      );
    });

    test('map transforms success and preserves failure', () {
      const Result<int> ok = Success<int>(2);
      const Result<int> bad = Failure<int>('boom', statusCode: 500);

      expect(ok.map<String>((int v) => 'n$v').dataOrNull, 'n2');

      final Result<String> mapped = bad.map<String>((int v) => 'n$v');
      expect(mapped, isA<Failure<String>>());
      expect((mapped as Failure<String>).statusCode, 500);
      expect(mapped.message, 'boom');
    });

    group('guard', () {
      test('wraps a successful value', () async {
        final Result<int> result = await Result.guard<int>(() async => 7);

        expect(result, const Success<int>(7));
      });

      test('captures typed network exceptions', () async {
        final Result<int> result = await Result.guard<int>(
          () async => throw const NoInternetException(),
        );

        expect(result, isA<Failure<int>>());
        final Failure<int> failure = result as Failure<int>;
        expect(failure.message, contains('No internet'));
        expect(failure.exception, isA<NoInternetException>());
      });

      test('captures unexpected errors with the fallback message', () async {
        final Result<int> result = await Result.guard<int>(
          () async => throw StateError('kaboom'),
          fallbackMessage: 'Could not load.',
        );

        expect(result, isA<Failure<int>>());
        expect((result as Failure<int>).message, contains('Could not load.'));
      });
    });
  });
}
