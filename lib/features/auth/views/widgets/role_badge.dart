import 'package:flutter/material.dart';

import '../../models/user_role.dart';

/// Small colour-coded pill that renders a [UserRole].
///
/// Lives in the auth feature because it is the auth feature that owns the role
/// concept; the home and settings screens reuse it rather than duplicating the
/// role → colour mapping.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.compact = false});

  /// Role to display.
  final UserRole role;

  /// Renders a tighter pill without the icon.
  final bool compact;

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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!compact) ...<Widget>[
            Icon(
              isAdmin ? Icons.shield_outlined : Icons.person_outline,
              size: 16,
              color: foreground,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            role.label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
