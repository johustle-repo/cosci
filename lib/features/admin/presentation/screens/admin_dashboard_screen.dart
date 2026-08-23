import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_activity_log.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_notice_banner.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_dashboard_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Dashboard',
      currentRoute: AppRoutes.adminHome,
      child: Consumer<AdminDashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const SizedBox(
              height: 400,
              child: AdminLoadingState(message: 'Loading dashboard...'),
            );
          }
          if (provider.error != null &&
              provider.counts.isEmpty &&
              provider.recentLogs.isEmpty) {
            return SizedBox(
              height: 400,
              child: AdminErrorState(
                message: provider.error!,
                onRetry: () => provider.loadDashboard(),
              ),
            );
          }
          return Column(
            children: [
              if (provider.error != null) ...[
                AdminNoticeBanner(
                  message: provider.error!,
                  onRetry: provider.loadDashboard,
                ),
                const SizedBox(height: 14),
              ],
              _DashboardContent(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.provider});

  final AdminDashboardProvider provider;

  @override
  Widget build(BuildContext context) {
    final counts = provider.counts;
    final totalContent =
        (counts['totalLessons'] ?? 0) +
        (counts['totalSimulations'] ?? 0) +
        (counts['totalQuizzes'] ?? 0) +
        (counts['totalPuzzles'] ?? 0);
    final publishedContent =
        (counts['publishedLessons'] ?? 0) +
        (counts['publishedSimulations'] ?? 0) +
        (counts['publishedQuizzes'] ?? 0) +
        (counts['publishedPuzzles'] ?? 0);
    final activeRate = (counts['totalStudents'] ?? 0) == 0
        ? 0
        : (((counts['activeStudents'] ?? 0) * 100) /
                  (counts['totalStudents'] ?? 1))
              .round();

    final stats = [
      (
        'Total Students',
        '${counts['totalStudents'] ?? 0}',
        Icons.people_rounded,
        const Color(0xFF1D4ED8),
        AppRoutes.adminStudents,
      ),
      (
        'Active learner rate',
        '$activeRate%',
        Icons.person_rounded,
        const Color(0xFF059669),
        AppRoutes.adminStudents,
      ),
      (
        'Learning content',
        '$totalContent',
        Icons.library_books_rounded,
        const Color(0xFF7C3AED),
        AppRoutes.adminLessons,
      ),
      (
        'Published content',
        '$publishedContent',
        Icons.verified_rounded,
        const Color(0xFF0EA5A4),
        AppRoutes.adminLessons,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomePanel(onRefresh: provider.loadDashboard),
        const SizedBox(height: 28),

        // Stats grid
        const AdminSectionHeader(title: 'Platform Overview'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1050
                ? 4
                : constraints.maxWidth > 700
                ? 2
                : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 132,
              ),
              itemCount: stats.length,
              itemBuilder: (context, i) => AdminStatCard(
                label: stats[i].$1,
                value: stats[i].$2,
                icon: stats[i].$3,
                color: stats[i].$4,
                onTap: () => Navigator.pushNamed(context, stats[i].$5),
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        const AdminSectionHeader(title: 'Learning & Content Analytics'),
        const SizedBox(height: 16),
        _AnalyticsGrid(counts: counts, recentLogs: provider.recentLogs),
        const SizedBox(height: 32),

        // Recent activity
        AdminSectionHeader(
          title: 'Recent Activity Logs',
          actionLabel: 'View All',
          actionIcon: Icons.open_in_new_rounded,
          onAction: () =>
              Navigator.pushNamed(context, AppRoutes.adminActivityLogs),
        ),
        const SizedBox(height: 16),
        provider.recentLogs.isEmpty
            ? const AdminEmptyState(
                message: 'No activity logs yet.',
                icon: Icons.history_rounded,
              )
            : _RecentLogsTable(logs: provider.recentLogs),
      ],
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2450), Color(0xFF1646A0), Color(0xFF0F8F91)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B123D82),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -65,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.waving_hand_rounded, color: Color(0xFFFBBF24)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Welcome back, Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Monitor learning, publish content, and keep CoSci running smoothly.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: .3),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: .08),
                    ),
                  ),
                ),
                child: _QuickActions(onRefresh: onRefresh),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, String?)>[
      ('New lesson', Icons.add_box_rounded, AppRoutes.adminLessons),
      ('New simulation', Icons.terminal_rounded, AppRoutes.adminSimulations),
      ('Manage users', Icons.manage_accounts_rounded, AppRoutes.adminStudents),
      ('Announcement', Icons.campaign_rounded, AppRoutes.adminAnnouncements),
      ('AI generation', Icons.auto_awesome_rounded, AppRoutes.adminSyllabus),
    ];
    return Semantics(
      label: 'Admin quick actions',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...actions.map(
            (action) => OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, action.$3!),
              icon: Icon(action.$2, size: 18),
              label: Text(action.$1),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .1),
                minimumSize: const Size(0, 44),
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Refresh dashboard',
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: .12),
              side: BorderSide(color: Colors.white.withValues(alpha: .42)),
              minimumSize: const Size(44, 44),
              maximumSize: const Size(44, 44),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}

class _RecentLogsTable extends StatelessWidget {
  const _RecentLogsTable({required this.logs});

  final List<AdminActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1080,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FBFF)),
        columns: const [
          DataColumn(label: Text('Admin')),
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('Module')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Time')),
        ],
        rows: logs.map((log) {
          final time = log.timestamp != null
              ? DateFormat('MMM d, h:mm a').format(log.timestamp!)
              : '—';
          return DataRow(
            cells: [
              DataCell(
                Text(log.adminEmail, style: const TextStyle(fontSize: 13)),
              ),
              DataCell(_ActionBadge(action: log.actionType)),
              DataCell(
                Text(log.targetModule, style: const TextStyle(fontSize: 13)),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    log.description,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.counts, required this.recentLogs});
  final Map<String, int> counts;
  final List<AdminActivityLog> recentLogs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = _ContentReadinessCard(counts: counts);
        final operations = _OperationsCard(counts: counts, logs: recentLogs);
        if (constraints.maxWidth < 850) {
          return Column(
            children: [content, const SizedBox(height: 16), operations],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: content),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: operations),
            ],
          ),
        );
      },
    );
  }
}

class _ContentReadinessCard extends StatelessWidget {
  const _ContentReadinessCard({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Lessons', 'totalLessons', 'publishedLessons', const Color(0xFF7C3AED)),
      (
        'Simulations',
        'totalSimulations',
        'publishedSimulations',
        const Color(0xFF0EA5E9),
      ),
      ('Quizzes', 'totalQuizzes', 'publishedQuizzes', const Color(0xFFD97706)),
      ('Puzzles', 'totalPuzzles', 'publishedPuzzles', const Color(0xFFDC2626)),
    ];
    return _AnalyticsSurface(
      title: 'Content readiness',
      subtitle: 'Published coverage across learning modules',
      icon: Icons.donut_large_rounded,
      child: Column(
        children: items.map((item) {
          final total = counts[item.$2] ?? 0;
          final published = counts[item.$3] ?? 0;
          final ratio = total == 0 ? 0.0 : published / total;
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '$published of $total published',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 9,
                    color: item.$4,
                    backgroundColor: item.$4.withValues(alpha: .12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OperationsCard extends StatelessWidget {
  const _OperationsCard({required this.counts, required this.logs});
  final Map<String, int> counts;
  final List<AdminActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final total = counts['totalStudents'] ?? 0;
    final active = counts['activeStudents'] ?? 0;
    final draftCount =
        [
          ('totalLessons', 'publishedLessons'),
          ('totalSimulations', 'publishedSimulations'),
          ('totalQuizzes', 'publishedQuizzes'),
          ('totalPuzzles', 'publishedPuzzles'),
        ].fold<int>(0, (sum, keys) {
          return sum + ((counts[keys.$1] ?? 0) - (counts[keys.$2] ?? 0));
        });
    final alerts = <(IconData, String, String, Color)>[
      (
        Icons.people_alt_rounded,
        '$active of $total learners active',
        total == 0 ? 'Awaiting learner enrollment' : 'Current access status',
        const Color(0xFF059669),
      ),
      (
        Icons.edit_note_rounded,
        '$draftCount content drafts',
        draftCount == 0 ? 'Everything is published' : 'Waiting for review',
        const Color(0xFFD97706),
      ),
      (
        Icons.history_rounded,
        '${logs.length} recent admin events',
        'Latest operational activity',
        const Color(0xFF2563EB),
      ),
    ];
    return _AnalyticsSurface(
      title: 'Operational pulse',
      subtitle: 'Items that may need attention',
      icon: Icons.monitor_heart_rounded,
      child: Column(
        children: alerts.map((alert) {
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alert.$4.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(alert.$1, color: alert.$4, size: 22),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.$2,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        alert.$3,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AnalyticsSurface extends StatelessWidget {
  const _AnalyticsSurface({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E4F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D173A67),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1D4ED8), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF102449),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (action) {
      case 'create':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
      case 'update':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1E40AF);
      case 'delete':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
      case 'publish':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
      case 'unpublish':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        action,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
