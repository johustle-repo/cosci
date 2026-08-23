import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.embedded = false});

  final bool embedded;

  static const _logoAsset = 'assets/images/cosci.png';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final normalizedRole = user?.normalizedRole ?? 'student';
    final role = _formatRole(normalizedRole);
    final homeRoute = _resolveHomeRoute(normalizedRole);
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final profileName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : _fallbackNameFromEmail(user?.email);

    final navigationItems = <_DrawerDestination>[
      _DrawerDestination(
        title: _resolveHomeTitle(normalizedRole),
        routeName: homeRoute,
        icon: Icons.space_dashboard_rounded,
      ),
      if (normalizedRole == 'student')
        const _DrawerDestination(
          title: 'Lessons',
          routeName: AppRoutes.lessons,
          icon: Icons.auto_stories_rounded,
        ),
      if (normalizedRole == 'student')
        const _DrawerDestination(
          title: 'Code Simulation',
          routeName: AppRoutes.codeSimulation,
          icon: Icons.terminal_rounded,
        ),
      if (normalizedRole == 'student')
        const _DrawerDestination(
          title: 'Quizzes',
          routeName: AppRoutes.quizzes,
          icon: Icons.help_center_rounded,
        ),
      if (normalizedRole == 'student')
        const _DrawerDestination(
          title: 'Puzzles',
          routeName: AppRoutes.puzzles,
          icon: Icons.extension_rounded,
        ),
      if (normalizedRole == 'student')
        const _DrawerDestination(
          title: 'Gamification',
          routeName: AppRoutes.gamification,
          icon: Icons.workspace_premium_rounded,
        ),
      if (normalizedRole == 'student')
        const _DrawerDestination(
          title: 'Progress',
          routeName: AppRoutes.progress,
          icon: Icons.track_changes_rounded,
        ),
    ];
    final instructorItems = normalizedRole == 'instructor'
        ? const <_DrawerDestination>[
            _DrawerDestination(
              title: 'Student Management',
              routeName: AppRoutes.instructorStudents,
              icon: Icons.groups_rounded,
            ),
            _DrawerDestination(
              title: 'Class Analytics',
              routeName: AppRoutes.instructorAnalytics,
              icon: Icons.analytics_rounded,
            ),
            _DrawerDestination(
              title: 'Lesson Library',
              routeName: AppRoutes.instructorLessons,
              icon: Icons.auto_stories_rounded,
            ),
            _DrawerDestination(
              title: 'Simulation Preview',
              routeName: AppRoutes.instructorSimulations,
              icon: Icons.terminal_rounded,
            ),
            _DrawerDestination(
              title: 'Quiz Preview',
              routeName: AppRoutes.instructorQuizzes,
              icon: Icons.fact_check_outlined,
            ),
            _DrawerDestination(
              title: 'Puzzle Preview',
              routeName: AppRoutes.instructorPuzzles,
              icon: Icons.extension_rounded,
            ),
          ]
        : const <_DrawerDestination>[];

    final panel = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A3B), Color(0xFF0B2554), Color(0xFF11397D)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                children: [
                  _DrawerHeader(
                    profileName: profileName,
                    email: user?.email ?? 'guest@psu-educode.app',
                    role: role,
                    onTap: () => _openRoute(
                      context,
                      routeName: homeRoute,
                      currentRoute: currentRoute,
                    ),
                  ),
                  if (navigationItems.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const _DrawerSectionLabel('Workspace'),
                    const SizedBox(height: 10),
                    ...navigationItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DrawerItem(
                          title: item.title,
                          routeName: item.routeName,
                          icon: item.icon,
                          isSelected: currentRoute == item.routeName,
                          embedded: embedded,
                        ),
                      ),
                    ),
                  ],
                  if (instructorItems.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const _DrawerSectionLabel('Teaching tools'),
                    const SizedBox(height: 10),
                    ...instructorItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DrawerItem(
                          title: item.title,
                          routeName: item.routeName,
                          icon: item.icon,
                          isSelected: currentRoute == item.routeName,
                          embedded: embedded,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const _DrawerSectionLabel('Account'),
                  const SizedBox(height: 10),
                  _DrawerItem(
                    title: 'Account & Security',
                    routeName: AppRoutes.account,
                    icon: Icons.manage_accounts_outlined,
                    isSelected: currentRoute == AppRoutes.account,
                    embedded: embedded,
                  ),
                  const SizedBox(height: 8),
                  _SidebarSupportCard(
                    role: role,
                    isInstructor: normalizedRole == 'instructor',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: _SignOutCard(
                onTap: () async {
                  if (!embedded) Navigator.pop(context);
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
              ),
            ),
          ],
        ),
      ),
    );
    if (embedded) return panel;
    return Drawer(
      width: 320,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: panel,
    );
  }

  static String _formatRole(String role) {
    if (role.isEmpty) {
      return 'Student';
    }

    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  static String _resolveHomeRoute(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppRoutes.adminHome;
      case 'instructor':
        return AppRoutes.professorHome;
      default:
        return AppRoutes.dashboard;
    }
  }

  static String _resolveHomeTitle(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin Hub';
      case 'instructor':
        return 'Dashboard';
      default:
        return 'Dashboard';
    }
  }

  static String _fallbackNameFromEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'PSU Learner';
    }

    final handle = email.split('@').first.replaceAll('.', ' ').trim();
    if (handle.isEmpty) {
      return 'PSU Learner';
    }

    return handle
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  void _openRoute(
    BuildContext context, {
    required String routeName,
    required String? currentRoute,
  }) {
    final navigator = Navigator.of(context);
    if (currentRoute == routeName) {
      if (!embedded) navigator.pop();
      return;
    }

    if (!embedded) {
      navigator.pop();
      Future<void>.microtask(() {
        if (navigator.mounted) navigator.pushReplacementNamed(routeName);
      });
      return;
    }
    navigator.pushReplacementNamed(routeName);
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.profileName,
    required this.email,
    required this.role,
    required this.onTap,
  });

  final String profileName;
  final String email;
  final String role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF133D86), Color(0xFF0A244D)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -28,
                right: -18,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4DA3FF).withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                bottom: -34,
                left: -10,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2DE2E6).withValues(alpha: 0.10),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            AppDrawer._logoAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CoSci',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capstone learning workspace',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.home_rounded,
                        size: 19,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF56C4FF).withValues(alpha: 0.16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.46),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.title,
    required this.routeName,
    required this.icon,
    required this.isSelected,
    required this.embedded,
  });

  final String title;
  final String routeName;
  final IconData icon;
  final bool isSelected;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (isSelected) {
            if (!embedded) Navigator.pop(context);
            return;
          }

          final navigator = Navigator.of(context);
          if (!embedded) {
            navigator.pop();
            Future<void>.microtask(() {
              if (navigator.mounted) navigator.pushReplacementNamed(routeName);
            });
            return;
          }
          navigator.pushReplacementNamed(routeName);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
            ),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A4FA7), Color(0xFF113474)],
                  )
                : null,
            color: isSelected ? null : Colors.white.withValues(alpha: 0.035),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.78),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.80),
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSupportCard extends StatelessWidget {
  const _SidebarSupportCard({required this.role, required this.isInstructor});

  final String role;
  final bool isInstructor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF57B5FF), Color(0xFF2DE2E6)],
              ),
            ),
            child: Icon(
              isInstructor
                  ? Icons.record_voice_over_rounded
                  : Icons.school_rounded,
              color: Color(0xFF07204B),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$role mode is active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isInstructor
                      ? 'Review learner attempts, provide feedback, and preview every activity.'
                      : 'Keep your workspace focused and progress visible.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.075),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFFFF8A8A).withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFFD2D2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'End this session securely',
                      style: TextStyle(
                        color: Color(0xFF9CB2D8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CB2D8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerDestination {
  const _DrawerDestination({
    required this.title,
    required this.routeName,
    required this.icon,
  });

  final String title;
  final String routeName;
  final IconData icon;
}
