import 'package:fluetpress/core/config/env_config.dart';
import 'package:fluetpress/core/config/flavors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(EnvConfig.reset);

  group('Environment', () {
    test('parses canonical names', () {
      expect(Environment.parse('dev'), Environment.dev);
      expect(Environment.parse('staging'), Environment.staging);
      expect(Environment.parse('prod'), Environment.prod);
    });

    test('parses common aliases, case-insensitively', () {
      expect(Environment.parse('PRODUCTION'), Environment.prod);
      expect(Environment.parse(' release '), Environment.prod);
      expect(Environment.parse('qa'), Environment.staging);
      expect(Environment.parse('Stage'), Environment.staging);
    });

    test('defaults to dev for anything unknown', () {
      expect(Environment.parse(null), Environment.dev);
      expect(Environment.parse(''), Environment.dev);
      expect(Environment.parse('banana'), Environment.dev);
    });

    test('exposes readable metadata', () {
      expect(Environment.staging.label, 'Staging');
      expect(Environment.staging.slug, 'staging');
      expect(Environment.prod.isProd, isTrue);
      expect(Environment.dev.isDev, isTrue);
    });
  });

  group('EnvConfig', () {
    test('throws a descriptive StateError before initialisation', () {
      expect(EnvConfig.isInitialized, isFalse);
      expect(
        () => EnvConfig.instance,
        throwsA(
          isA<StateError>().having(
            (StateError error) => error.message,
            'message',
            contains('EnvConfig has not been initialised'),
          ),
        ),
      );
    });

    test('initialize populates the singleton', () {
      EnvConfig.initialize(
        appName: 'Test App',
        baseUrl: 'https://api.test/v1',
        environment: Environment.staging,
        apiKey: 'key',
        enableApiLogging: true,
        useRemoteAuth: true,
      );

      expect(EnvConfig.isInitialized, isTrue);
      expect(EnvConfig.instance.appName, 'Test App');
      expect(EnvConfig.instance.baseUrl, 'https://api.test/v1');
      expect(EnvConfig.instance.environment, Environment.staging);
      expect(EnvConfig.instance.isStaging, isTrue);
      expect(EnvConfig.instance.useRemoteAuth, isTrue);
      expect(EnvConfig.instance.apiKey, 'key');
      expect(EnvConfig.instance.enableApiLogging, isTrue);
    });

    test('reset clears the singleton (test hygiene)', () {
      EnvConfig.initialize(
        appName: 'A',
        baseUrl: 'https://a.test',
        environment: Environment.dev,
      );

      EnvConfig.reset();

      expect(EnvConfig.isInitialized, isFalse);
    });
  });

  group('Flavors', () {
    test('defaults to dev when no --dart-define is supplied', () {
      expect(Flavors.environment, Environment.dev);
      expect(Flavors.useRemoteAuth, isFalse);
    });

    test('the default flavor points at a real-looking base URL', () {
      final FlavorConfig config = Flavors.current;

      expect(config.baseUrl, startsWith('https://'));
      expect(config.appName, isNotEmpty);
      // Only production silences the API logger.
      expect(config.enableApiLogging, isTrue);
    });

    test('initialize wires EnvConfig from the active flavor', () {
      Flavors.initialize();

      expect(EnvConfig.isInitialized, isTrue);
      expect(EnvConfig.instance.environment, Flavors.environment);
      expect(EnvConfig.instance.baseUrl, Flavors.current.baseUrl);
    });
  });
}
