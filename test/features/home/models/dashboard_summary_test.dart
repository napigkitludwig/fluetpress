import 'package:fluetpress/features/auth/models/user.dart';
import 'package:fluetpress/features/auth/models/user_role.dart';
import 'package:fluetpress/features/home/models/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardSummary', () {
    test('starts empty', () {
      const DashboardSummary summary = DashboardSummary.empty();

      expect(summary.isEmpty, isTrue);
      expect(summary.totalUsers, 0);
      expect(summary.adminCount, 0);
      expect(summary.standardCount, 0);
    });

    test('counts admins and standard users separately', () {
      final DashboardSummary summary = DashboardSummary.fromUsers(<User>[
        const User(id: 1, username: 'a', role: UserRole.admin),
        const User(id: 2, username: 'b', role: UserRole.admin),
        const User(id: 3, username: 'c', role: UserRole.user),
      ]);

      expect(summary.totalUsers, 3);
      expect(summary.adminCount, 2);
      expect(summary.standardCount, 1);
      expect(summary.isEmpty, isFalse);
    });

    test('an empty list is not the same as an unloaded dashboard', () {
      final DashboardSummary summary = DashboardSummary.fromUsers(
        const <User>[],
      );

      expect(summary, const DashboardSummary.empty());
      expect(summary.isEmpty, isTrue);
    });

    test('implements value equality', () {
      const DashboardSummary a = DashboardSummary(
        totalUsers: 2,
        adminCount: 1,
        standardCount: 1,
      );
      const DashboardSummary b = DashboardSummary(
        totalUsers: 2,
        adminCount: 1,
        standardCount: 1,
      );
      const DashboardSummary c = DashboardSummary(
        totalUsers: 3,
        adminCount: 1,
        standardCount: 2,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a.toString(), contains('total: 2'));
    });
  });
}
