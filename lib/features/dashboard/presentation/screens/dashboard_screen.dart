import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/widgets/badge_strip.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/widgets/daily_challenge_card.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/widgets/dashboard_header_card.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/widgets/dashboard_section_header.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/widgets/progress_summary_card.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/widgets/quick_access_grid.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/widgets/student_stat_card.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/providers/dashboard_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/content_state_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(title: 'Dashboard', body: const _DashboardHome());
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard({bool forceRefresh = false}) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) {
      return;
    }

    await context.read<DashboardProvider>().loadDashboard(
      userId: user.uid,
      fallbackName: user.displayName ?? user.email,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final dashboardData = provider.dashboardData;

    if (provider.isLoading && dashboardData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && dashboardData == null) {
      return _DashboardErrorState(
        message: provider.errorMessage!,
        onRetry: () => _loadDashboard(forceRefresh: true),
      );
    }

    if (dashboardData == null) {
      return _DashboardEmptyState(
        onRefresh: () => _loadDashboard(forceRefresh: true),
      );
    }

    final quickAccessItems = [
      QuickAccessItem(
        title: 'Lessons',
        subtitle: 'Continue your guided learning path',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF123D9B),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.lessons);
        },
      ),
      QuickAccessItem(
        title: 'Code Simulation',
        subtitle: 'Trace, run, and understand code',
        icon: Icons.terminal_rounded,
        color: const Color(0xFF0891B2),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.codeSimulation);
        },
      ),
      QuickAccessItem(
        title: 'Quizzes',
        subtitle: 'Check your understanding by lesson',
        icon: Icons.quiz_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.quizzes);
        },
      ),
      QuickAccessItem(
        title: 'Puzzles',
        subtitle: 'Build syntax with draggable code tiles',
        icon: Icons.extension_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.puzzles);
        },
      ),
      QuickAccessItem(
        title: 'Achievements',
        subtitle: 'Review XP, levels, streaks, and badges',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFEA580C),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.gamification);
        },
      ),
      QuickAccessItem(
        title: 'Progress',
        subtitle: 'See your growth summary',
        icon: Icons.insights_rounded,
        color: const Color(0xFF2563EB),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.progress);
        },
      ),
    ];

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(forceRefresh: true),
      child: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          DashboardHeaderCard(
            studentName: dashboardData.studentName,
            currentLevel: dashboardData.currentLevel,
            onContinue: () => Navigator.pushNamed(context, AppRoutes.lessons),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stats = [
                StudentStatCard(
                  label: 'Current Level',
                  value: 'Lv ${dashboardData.currentLevel}',
                  icon: Icons.layers_outlined,
                  color: const Color(0xFF123D9B),
                ),
                StudentStatCard(
                  label: 'Total XP',
                  value: dashboardData.totalXp.toString(),
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFF1D4ED8),
                ),
                StudentStatCard(
                  label: 'Streak Count',
                  value: '${dashboardData.streakCount} days',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFEA580C),
                ),
              ];

              final itemWidth = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 20) / 3
                  : constraints.maxWidth >= 480
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final stat in stats)
                    SizedBox(width: itemWidth, child: stat),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          DailyChallengeCard(challenge: dashboardData.dailyChallenge),
          const SizedBox(height: 18),
          const DashboardSectionHeader(
            title: 'Recently Earned Badges',
            subtitle: 'Milestones and recognition from your recent work',
          ),
          const SizedBox(height: 10),
          BadgeStrip(badges: dashboardData.badges),
          const SizedBox(height: 18),
          const DashboardSectionHeader(
            title: 'Quick Access',
            subtitle: 'Jump directly into your most important learning tasks',
          ),
          const SizedBox(height: 10),
          QuickAccessGrid(items: quickAccessItems),
          const SizedBox(height: 18),
          ProgressSummaryCard(
            learningProgress: dashboardData.learningProgress,
            completedLessons: dashboardData.completedLessons,
            completedActivities: dashboardData.completedActivities,
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ContentStateCard(
        icon: Icons.space_dashboard_outlined,
        title: 'Your dashboard is not ready yet',
        message:
            'Connect your Firestore data or refresh once your student records are available.',
        actionLabel: 'Refresh dashboard',
        onPressed: onRefresh,
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ContentStateCard(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load dashboard',
        message: message,
        actionLabel: 'Try again',
        onPressed: onRetry,
      ),
    );
  }
}
