import 'package:flutter/material.dart';

import 'app.dart';
import 'services/database_helper.dart';

/// Application entry point.
///
/// The database must be initialised before the first frame is drawn, so the
/// schema and the default accounts exist by the time the login screen appears.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseHelper().initialize();
  } catch (error, stackTrace) {
    debugPrint('Database initialisation failed: $error\n$stackTrace');
    runApp(_BootstrapErrorApp(message: '$error'));
    return;
  }

  runApp(const FluetpressApp());
}

/// Minimal fallback screen shown when the database could not be opened.
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
                const Icon(Icons.storage_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'The local database could not be opened.',
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
