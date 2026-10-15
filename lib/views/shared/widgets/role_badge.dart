import 'package:flutter/material.dart';

import '../../../models/user_role.dart';

/// Small colour-coded pill that renders a [UserRole].
///
/// Reused by the profile card and the admin user list so a role always looks
/// the same wherever it appears.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  /// Role to display.
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isAdmin = role.isAdmin;

    final Color background = isAdmin
        ? scheme.primaryContainer
        : scheme.secondaryContainer;
    final Color foreground = isAdmin
        ? scheme.onPrimaryContainer
        : scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isAdmin ? Icons.shield_outlined : Icons.person_outline,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
