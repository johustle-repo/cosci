import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/shared/widgets/action_panel_card.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/overview_stat_tile.dart';
import 'package:pseudocode_apk/shared/widgets/role_dashboard_header.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return AppScaffold(
      title: 'Admin Workspace',
      actions: [
        IconButton(
          tooltip: 'Logout',
          onPressed: () async {
            await context.read<AuthProvider>().signOut();
            if (!context.mounted) {
              return;
            }
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.startup,
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            RoleDashboardHeader(
              badge: 'Administrator',
              title: 'Welcome, ${user?.displayName ?? 'Admin'}',
              subtitle:
                  'Manage access, review platform health, and oversee instructional content from one workspace.',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 980
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth > 720
                    ? (constraints.maxWidth - 24) / 3
                    : 220.0;
                final stats = const [
                  (
                    'Seeded roles',
                    '3',
                    Icons.manage_accounts_outlined,
                    Color(0xFF123D9B),
                  ),
                  (
                    'Active modules',
                    '6',
                    Icons.dashboard_customize_outlined,
                    Color(0xFF1D4ED8),
                  ),
                  (
                    'Pending tools',
                    '4',
                    Icons.pending_actions_outlined,
                    Color(0xFF0EA5E9),
                  ),
                ];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        SizedBox(
                          width: cardWidth,
                          child: OverviewStatTile(
                            label: stats[i].$1,
                            value: stats[i].$2,
                            icon: stats[i].$3,
                            color: stats[i].$4,
                          ),
                        ),
                        if (i < stats.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Administrative Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const ActionPanelCard(
              title: 'User Oversight',
              subtitle:
                  'Track account roles, seeded credentials, and future moderation workflows.',
              icon: Icons.admin_panel_settings_outlined,
              color: Color(0xFF123D9B),
            ),
            const SizedBox(height: 12),
            const ActionPanelCard(
              title: 'Curriculum Control',
              subtitle:
                  'Prepare lesson publishing, challenge rotation, and content release tools.',
              icon: Icons.library_books_outlined,
              color: Color(0xFF1D4ED8),
            ),
            const SizedBox(height: 12),
            const ActionPanelCard(
              title: 'Platform Reports',
              subtitle:
                  'Extend this area with system analytics, engagement summaries, and issue tracking.',
              icon: Icons.analytics_outlined,
              color: Color(0xFF0EA5E9),
            ),
          ],
        ),
      ),
    );
  }
}
