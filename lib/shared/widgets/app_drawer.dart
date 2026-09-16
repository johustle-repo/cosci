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

    if (embedded) {
      return _DesktopWorkspaceSidebar(
        profileName: profileName,
        role: role,
        verified:
            normalizedRole == 'student' &&
            !(user?.requiresIdVerification ?? true),
        currentRoute: currentRoute,
        navigationItems: navigationItems,
        instructorItems: instructorItems,
        onSignOut: () async {
          await context.read<AuthProvider>().signOut();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.startup,
            (route) => false,
          );
        },
      );
    }

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
                    role: role,
                    verified:
                        normalizedRole == 'student' &&
                        !(user?.requiresIdVerification ?? true),
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

class _DesktopWorkspaceSidebar extends StatelessWidget {
  const _DesktopWorkspaceSidebar({
    required this.profileName,
    required this.role,
    required this.verified,
    required this.currentRoute,
    required this.navigationItems,
    required this.instructorItems,
    required this.onSignOut,
  });

  final String profileName;
  final String role;
  final bool verified;
  final String? currentRoute;
  final List<_DrawerDestination> navigationItems;
  final List<_DrawerDestination> instructorItems;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Image.asset(AppDrawer._logoAsset),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CoSci',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$role workspace',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white.withValues(alpha: .1)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFF1E4C91),
                    child: Text(
                      profileName.isEmpty ? 'U' : profileName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          verified ? 'Verified student' : role,
                          style: TextStyle(
                            color: verified
                                ? const Color(0xFF6EE7C7)
                                : Colors.white.withValues(alpha: .55),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                children: [
                  ...navigationItems.map(
                    (item) => _DesktopSidebarTile(
                      item: item,
                      selected: currentRoute == item.routeName,
                    ),
                  ),
                  if (instructorItems.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                      child: Text(
                        'TEACHING TOOLS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .38),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                    ),
                    ...instructorItems.map(
                      (item) => _DesktopSidebarTile(
                        item: item,
                        selected: currentRoute == item.routeName,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _DesktopSidebarTile(
                    item: const _DrawerDestination(
                      title: 'Account & Security',
                      routeName: AppRoutes.account,
                      icon: Icons.manage_accounts_outlined,
                    ),
                    selected: currentRoute == AppRoutes.account,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFCA5A5),
                  minimumSize: const Size(double.infinity, 44),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebarTile extends StatelessWidget {
  const _DesktopSidebarTile({required this.item, required this.selected});

  final _DrawerDestination item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? const Color(0xFF174B99) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: selected
              ? null
              : () => Navigator.pushReplacementNamed(context, item.routeName),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  item.icon,
                  size: 18,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: .68),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: .76),
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.profileName,
    required this.role,
    required this.verified,
    required this.onTap,
  });

  final String profileName;
  final String role;
  final bool verified;
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
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capstone learning workspace',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 11.5,
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
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        verified
                            ? Icons.verified_rounded
                            : Icons.account_circle_outlined,
                        size: 16,
                        color: verified
                            ? const Color(0xFF5EE6BE)
                            : Colors.white.withValues(alpha: 0.68),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        verified ? 'Verified' : role,
                        style: TextStyle(
                          color: verified
                              ? const Color(0xFF8AF0D2)
                              : Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
