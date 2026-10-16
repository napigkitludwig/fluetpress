import '../../auth/models/user.dart';

/// Aggregated numbers shown on the dashboard.
///
/// A plain immutable value object: it is computed in memory from the loaded
/// accounts and never crosses the wire, so it does not need (or want) code
/// generation.
class DashboardSummary {
  const DashboardSummary({
    required this.totalUsers,
    required this.adminCount,
    required this.standardCount,
  });

  /// Empty summary, used before the accounts are loaded.
  const DashboardSummary.empty()
    : totalUsers = 0,
      adminCount = 0,
      standardCount = 0;

  /// Derives the summary from a list of accounts.
  factory DashboardSummary.fromUsers(List<User> users) {
    int admins = 0;
    for (final User user in users) {
      if (user.isAdmin) {
        admins++;
      }
    }
    return DashboardSummary(
      totalUsers: users.length,
      adminCount: admins,
      standardCount: users.length - admins,
    );
  }

  /// Total number of registered accounts.
  final int totalUsers;

  /// Accounts holding the admin role.
  final int adminCount;

  /// Accounts holding the standard user role.
  final int standardCount;

  bool get isEmpty => totalUsers == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardSummary &&
          other.totalUsers == totalUsers &&
          other.adminCount == adminCount &&
          other.standardCount == standardCount;

  @override
  int get hashCode => Object.hash(totalUsers, adminCount, standardCount);

  @override
  String toString() =>
      'DashboardSummary(total: $totalUsers, admins: $adminCount, '
      'standard: $standardCount)';
}
