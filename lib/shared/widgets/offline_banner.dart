import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/connectivity_service.dart';
import '../../core/theme/app_colors.dart';

/// Slim banner shown at the top of the app whenever the device has no network
/// interface. Watches [ConnectivityService].
///
/// It is mounted once, by `FluetPressApp`'s `MaterialApp.builder`, so every
/// screen gets the same offline affordance for free.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = context.select<ConnectivityService, bool>(
      (ConnectivityService service) => service.isOnline,
    );
    if (isOnline) {
      return const SizedBox.shrink();
    }

    final AppSemanticColors semantic = AppSemanticColors.of(context);

    return Material(
      color: semantic.danger,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.wifi_off_outlined,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
