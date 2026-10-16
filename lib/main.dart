import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/flavors.dart';

/// Application entry point.
///
/// Order matters and is deliberate:
/// 1. bind the engine,
/// 2. resolve the flavor into [EnvConfig] (everything downstream reads it),
/// 3. bootstrap the object graph — SQLite schema/seed, secure storage, HTTP
///    client, controllers, restored session, persisted theme,
/// 4. hand the graph to the widget tree.
///
/// If step 3 fails we still render something: a diagnostic screen beats a white
/// screen and tells the user (or the developer on a client's device) what broke.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolves --dart-define=APP_FLAVOR=dev|staging|prod into EnvConfig.
  Flavors.initialize();

  try {
    final AppDependencies dependencies = await AppDependencies.bootstrap();
    runApp(FluetPressApp(dependencies: dependencies));
  } catch (error, stackTrace) {
    debugPrint('Bootstrap failed: $error\n$stackTrace');
    runApp(_BootstrapErrorApp(message: '$error'));
  }
}

/// Minimal fallback screen shown when bootstrapping could not complete.
///
/// Deliberately dependency-free: it must never rely on anything that could have
/// failed above.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'The app could not start.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
