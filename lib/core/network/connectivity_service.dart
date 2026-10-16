import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Watches the device's network connectivity and exposes a single
/// [isOnline] flag that the UI can react to (see `OfflineBanner`).
///
/// It is a [ChangeNotifier] because it is genuinely app-wide state that many
/// widgets need to observe — the same reason a controller is one.
///
/// **Note:** [isOnline] reflects whether a network *interface* is available
/// (Wi-Fi, mobile, ethernet...). It is not a guarantee that the backend is
/// reachable; treat it as a cheap hint for the offline banner, not as proof of
/// internet access.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Optimistic default: assume online until the platform says otherwise, so
  /// the banner never flashes on a cold start.
  bool _isOnline = true;

  /// Whether at least one usable network interface is available.
  bool get isOnline => _isOnline;

  /// Convenience inverse of [isOnline].
  bool get isOffline => !_isOnline;

  /// Starts listening. Call once during bootstrapping.
  ///
  /// Failures are swallowed on purpose: connectivity is a nice-to-have and must
  /// never prevent the app from starting.
  Future<void> initialize() async {
    try {
      _apply(await _connectivity.checkConnectivity());
      _subscription = _connectivity.onConnectivityChanged.listen(
        _apply,
        onError: (Object error) =>
            debugPrint('[ConnectivityService] stream error: $error'),
      );
    } catch (error) {
      debugPrint('[ConnectivityService] initialisation failed: $error');
    }
  }

  void _apply(List<ConnectivityResult> results) {
    final bool online =
        results.isNotEmpty &&
        !results.every(
          (ConnectivityResult result) => result == ConnectivityResult.none,
        );

    if (online == _isOnline) {
      return;
    }
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
