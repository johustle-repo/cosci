import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final String route;
}

const _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_rounded,
    route: AppRoutes.adminHome,
  ),
  _NavItem(
    label: 'Users',
    icon: Icons.people_rounded,
    route: AppRoutes.adminStudents,
  ),
  _NavItem(
    label: 'Lessons',
    icon: Icons.menu_book_rounded,
    route: AppRoutes.adminLessons,
  ),
  _NavItem(
    label: 'Simulations',
    icon: Icons.terminal_rounded,
    route: AppRoutes.adminSimulations,
  ),
  _NavItem(
    label: 'Quizzes',
    icon: Icons.quiz_rounded,
    route: AppRoutes.adminQuizzes,
  ),
  _NavItem(
    label: 'Puzzles',
    icon: Icons.extension_rounded,
    route: AppRoutes.adminPuzzles,
  ),
  _NavItem(
    label: 'Gamification',
    icon: Icons.emoji_events_rounded,
    route: AppRoutes.adminGamification,
  ),
  _NavItem(
    label: 'Daily Challenges',
    icon: Icons.today_rounded,
    route: AppRoutes.adminChallenges,
  ),
  _NavItem(
    label: 'Reports',
    icon: Icons.analytics_rounded,
    route: AppRoutes.adminReports,
  ),
  _NavItem(
    label: 'Announcements',
    icon: Icons.campaign_rounded,
    route: AppRoutes.adminAnnouncements,
  ),
  _NavItem(
    label: 'Settings',
    icon: Icons.settings_rounded,
    route: AppRoutes.adminSettings,
  ),
  _NavItem(
    label: 'Activity Logs',
    icon: Icons.history_rounded,
    route: AppRoutes.adminActivityLogs,
  ),
  // AI Section
  _NavItem(
    label: 'Syllabi & AI',
    icon: Icons.auto_awesome_rounded,
    route: AppRoutes.adminSyllabus,
  ),
  _NavItem(
    label: 'Gen Jobs',
    icon: Icons.batch_prediction_rounded,
    route: AppRoutes.adminGenerationJobs,
  ),
];

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.currentRoute, this.width = 236});

  final String currentRoute;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061633), Color(0xFF0A2A5B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26020B1A),
            blurRadius: 24,
            offset: Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / brand
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3514B8A6),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/images/cosci.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'CoSci logo',
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CoSci',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              children: [
                ..._navItems.map((item) {
                  // Insert a section divider before the AI items
                  final isAiSectionStart =
                      item.route == AppRoutes.adminSyllabus;
                  final isActive = currentRoute == item.route;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isAiSectionStart) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.1),
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                          child: Text(
                            'AI Content',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                      _SidebarTile(
                        item: item,
                        isActive: isActive,
                        onTap: () {
                          if (!isActive) {
                            Navigator.pushReplacementNamed(context, item.route);
                          }
                          if (Scaffold.maybeOf(context)?.isDrawerOpen ??
                              false) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Tooltip(
              message: 'Sign out of the admin workspace',
              child: InkWell(
                onTap: () => _handleLogout(context),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFFF87171).withValues(alpha: .24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFCA5A5),
                        size: 19,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sign out',
                          style: TextStyle(
                            color: Color(0xFFFECACA),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Version tag
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'CoSci v1.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will return to the CoSci sign-in screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.startup,
      (route) => false,
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        canRequestFocus: true,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF0EA5A4)],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x302563EB),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
