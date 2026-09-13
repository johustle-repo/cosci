import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_notice_banner.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_reports_provider.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportsProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Reports & Analytics',
      currentRoute: AppRoutes.adminReports,
      child: Consumer<AdminReportsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const SizedBox(
              height: 400,
              child: AdminLoadingState(message: 'Loading analytics...'),
            );
          }
          if (provider.error != null &&
              provider.topicScores.isEmpty &&
              provider.topStudents.isEmpty &&
              provider.simulationAnalytics.isEmpty &&
              provider.quizAnalytics.isEmpty) {
            return SizedBox(
              height: 400,
              child: AdminErrorState(
                message: provider.error!,
                onRetry: provider.loadReports,
              ),
            );
          }
          return Column(
            children: [
              if (provider.error != null) ...[
                AdminNoticeBanner(
                  message: provider.error!,
                  onRetry: provider.loadReports,
                ),
                const SizedBox(height: 14),
              ],
              _ReportsContent(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.provider});
  final AdminReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final simulationAttempts = _asInt(provider.simulationAnalytics['attempts']);
    final quizAttempts = _asInt(provider.quizAnalytics['attempts']);
    final simulationPassRate = _asInt(provider.simulationAnalytics['passRate']);
    final quizPassRate = _asInt(provider.quizAnalytics['passRate']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reports & Analytics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.loadReports(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _ReportsHero(
          learners: provider.topStudents.length,
          attempts: simulationAttempts + quizAttempts,
          averagePassRate: simulationAttempts + quizAttempts == 0
              ? 0
              : ((simulationPassRate + quizPassRate) / 2).round(),
          topicsMeasured: provider.topicScores.length,
        ),
        const SizedBox(height: 24),

        _SimulationAnalytics(data: provider.simulationAnalytics),
        const SizedBox(height: 32),
        _QuizAnalytics(data: provider.quizAnalytics),
        const SizedBox(height: 32),

        // Topic Scores chart
        const AdminSectionHeader(title: 'Topic Mastery'),
        const SizedBox(height: 16),
        provider.topicScores.isEmpty
            ? const _InsightEmptyState(
                title: 'Topic insights will appear here',
                message:
                    'Publish a quiz and let learners submit attempts to compare mastery across topics.',
                icon: Icons.insights_rounded,
              )
            : _TopicScoresChart(data: provider.topicScores),
        const SizedBox(height: 32),

        // Weakest / Strongest topics tables
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TopicsTable(
                      title: 'Weakest Topics',
                      topics: provider.weakestTopics,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _TopicsTable(
                      title: 'Strongest Topics',
                      topics: provider.strongestTopics,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _TopicsTable(
                  title: 'Weakest Topics',
                  topics: provider.weakestTopics,
                  color: const Color(0xFFDC2626),
                ),
                const SizedBox(height: 20),
                _TopicsTable(
                  title: 'Strongest Topics',
                  topics: provider.strongestTopics,
                  color: const Color(0xFF059669),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        // Top Students
        const AdminSectionHeader(title: 'Learner Leaderboard'),
        const SizedBox(height: 16),
        provider.topStudents.isEmpty
            ? const _InsightEmptyState(
                title: 'No learner rankings yet',
                message:
                    'Learners will appear here after they earn XP from lessons, simulations, quizzes, or puzzles.',
                icon: Icons.emoji_events_rounded,
              )
            : _TopStudentsTable(students: provider.topStudents),
      ],
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class _ReportsHero extends StatelessWidget {
  const _ReportsHero({
    required this.learners,
    required this.attempts,
    required this.averagePassRate,
    required this.topicsMeasured,
  });

  final int learners;
  final int attempts;
  final int averagePassRate;
  final int topicsMeasured;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102E67), Color(0xFF1757B8), Color(0xFF10A3A3)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25102E67),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.auto_graph_rounded, color: Color(0xFFFFD45A)),
                  SizedBox(width: 10),
                  Text(
                    'Learning intelligence',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'See where learners succeed, where they struggle, and what content needs attention.',
                style: TextStyle(color: Color(0xFFDCE9FF), height: 1.4),
              ),
            ],
          );
          final metrics = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(value: '$learners', label: 'Learners ranked'),
              _HeroMetric(value: '$attempts', label: 'Total attempts'),
              _HeroMetric(
                value: '$averagePassRate%',
                label: 'Average pass rate',
              ),
              _HeroMetric(value: '$topicsMeasured', label: 'Topics measured'),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [heading, const SizedBox(height: 20), metrics],
            );
          }
          return Row(
            children: [
              Expanded(flex: 4, child: heading),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    width: 132,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFDCE9FF), fontSize: 11),
        ),
      ],
    ),
  );
}

class _QuizAnalytics extends StatelessWidget {
  const _QuizAnalytics({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final programs = List<Map<String, dynamic>>.from(
      data['programs'] as List? ?? const [],
    );
    final years = List<Map<String, dynamic>>.from(
      data['years'] as List? ?? const [],
    );
    final missed = List<Map<String, dynamic>>.from(
      data['mostMissed'] as List? ?? const [],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeader(title: 'Trusted Quiz Analytics'),
        const SizedBox(height: 14),
        _AnalyticsStatGrid(
          children: [
            _AnalyticsStat(
              label: 'Secure attempts',
              value: '${data['attempts'] ?? 0}',
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF7C3AED),
            ),
            _AnalyticsStat(
              label: 'Overall pass rate',
              value: '${data['passRate'] ?? 0}%',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF059669),
            ),
            ...years.map(
              (row) => _AnalyticsStat(
                label: '${row['label']} pass rate',
                value: '${row['passRate']}%',
                icon: Icons.school_rounded,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _AnalyticsList(
                title: 'Performance by program',
                subtitle: 'Compare outcomes across learner groups',
                icon: Icons.groups_2_rounded,
                color: const Color(0xFF7C3AED),
                rows: programs,
                value: (row) =>
                    '${row['attempts']} attempts • ${row['passRate']}% pass',
              ),
              _AnalyticsList(
                title: 'Questions needing review',
                subtitle: 'Items learners answer incorrectly most often',
                icon: Icons.help_center_rounded,
                color: const Color(0xFFEA580C),
                rows: missed,
                value: (row) => '${row['count']} incorrect responses',
              ),
            ];
            return constraints.maxWidth > 760
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 14),
                      Expanded(child: cards[1]),
                    ],
                  )
                : Column(
                    children: [cards[0], const SizedBox(height: 14), cards[1]],
                  );
          },
        ),
      ],
    );
  }
}

class _SimulationAnalytics extends StatelessWidget {
  const _SimulationAnalytics({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final languages = List<Map<String, dynamic>>.from(
      data['languages'] as List? ?? const [],
    );
    final failed = List<Map<String, dynamic>>.from(
      data['mostFailed'] as List? ?? const [],
    );
    final errors = List<Map<String, dynamic>>.from(
      data['errors'] as List? ?? const [],
    );
    return Semantics(
      container: true,
      label: 'Simulation learning analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(title: 'Simulation Learning Analytics'),
          const SizedBox(height: 14),
          _AnalyticsStatGrid(
            children: [
              _AnalyticsStat(
                label: 'Compiler attempts',
                value: '${data['attempts'] ?? 0}',
                icon: Icons.terminal_rounded,
                color: const Color(0xFF0284C7),
              ),
              _AnalyticsStat(
                label: 'Submission pass rate',
                value: '${data['passRate'] ?? 0}%',
                icon: Icons.fact_check_rounded,
                color: const Color(0xFF059669),
              ),
              ...languages.map(
                (item) => _AnalyticsStat(
                  label: '${item['label']} pass rate',
                  value: '${item['passRate']}%',
                  icon: Icons.code_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final children = [
                _AnalyticsList(
                  title: 'Most failed simulations',
                  subtitle: 'Activities that may need clearer guidance',
                  icon: Icons.troubleshoot_rounded,
                  color: const Color(0xFFDC2626),
                  rows: failed,
                  value: (row) =>
                      '${row['failures']} failures • ${row['passRate']}% pass',
                ),
                _AnalyticsList(
                  title: 'Common error categories',
                  subtitle: 'Frequent compiler and logic problems',
                  icon: Icons.bug_report_rounded,
                  color: const Color(0xFFD97706),
                  rows: errors,
                  value: (row) => '${row['count']} occurrences',
                ),
              ];
              return constraints.maxWidth > 760
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 14),
                        Expanded(child: children[1]),
                      ],
                    )
                  : Column(
                      children: [
                        children[0],
                        const SizedBox(height: 14),
                        children[1],
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStat extends StatelessWidget {
  const _AnalyticsStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD8E2EF)),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 21, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF13213A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AnalyticsStatGrid extends StatelessWidget {
  const _AnalyticsStatGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final preferredColumns = constraints.maxWidth >= 1180
          ? 4
          : constraints.maxWidth >= 720
          ? 2
          : 1;
      final columns = children.length < preferredColumns
          ? children.length
          : preferredColumns;
      final cardWidth = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: children
            .map((child) => SizedBox(width: cardWidth, child: child))
            .toList(),
      );
    },
  );
}

class _AnalyticsList extends StatelessWidget {
  const _AnalyticsList({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.rows,
    required this.value,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic>) value;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 168),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD8E2EF)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const _CompactEmptyState()
          else
            ...rows.map(
              (row) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text((row['label'] ?? 'Unknown').toString()),
                subtitle: Text(value(row)),
              ),
            ),
        ],
      ),
    ),
  );
}

class _CompactEmptyState extends StatelessWidget {
  const _CompactEmptyState();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F9FD),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.hourglass_empty_rounded, size: 18, color: Color(0xFF94A3B8)),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Waiting for learner attempts',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
      ],
    ),
  );
}

class _InsightEmptyState extends StatelessWidget {
  const _InsightEmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDCE6F4)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 28),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _TopicScoresChart extends StatelessWidget {
  const _TopicScoresChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final maxScore = data
        .map((d) => (d['avgScore'] as int))
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              maxY: (maxScore + 20).toDouble().clamp(20, 120),
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final topic = data[groupIndex]['topic'] as String;
                    return BarTooltipItem(
                      '$topic\n${rod.toY.toInt()}%',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final topic = data[idx]['topic'] as String;
                      final label = topic.length > 8
                          ? '${topic.substring(0, 8)}…'
                          : topic;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((e) {
                final score = (e.value['avgScore'] as int).toDouble();
                final color = score < 60
                    ? const Color(0xFFDC2626)
                    : score < 80
                    ? const Color(0xFFD97706)
                    : const Color(0xFF059669);
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: score,
                      color: color,
                      width: 24,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicsTable extends StatelessWidget {
  const _TopicsTable({
    required this.title,
    required this.topics,
    required this.color,
  });
  final String title;
  final List<Map<String, dynamic>> topics;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (topics.isEmpty)
              const Text('No data.', style: TextStyle(color: Color(0xFF94A3B8)))
            else
              ...topics.map((t) {
                final score = t['avgScore'] as int;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t['topic'] as String,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TopStudentsTable extends StatelessWidget {
  const _TopStudentsTable({required this.students});
  final List<Map<String, dynamic>> students;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 980,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FBFF)),
        columns: const [
          DataColumn(label: Text('Rank')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Total XP')),
          DataColumn(label: Text('Level')),
          DataColumn(label: Text('Streak')),
          DataColumn(label: Text('Badges')),
        ],
        rows: students.asMap().entries.map((e) {
          final rank = e.key + 1;
          final s = e.value;
          return DataRow(
            cells: [
              DataCell(
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: rank <= 3
                        ? const Color(0xFFD97706)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
              DataCell(
                Text(
                  s['displayName'] as String? ?? s['uid'] as String? ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text('${s['totalXp'] ?? 0} XP')),
              DataCell(Text('Lv. ${s['currentLevel'] ?? 1}')),
              DataCell(Text('${s['streakDays'] ?? 0}d')),
              DataCell(Text('${s['badgesEarned'] ?? 0}')),
            ],
          );
        }).toList(),
      ),
    );
  }
}
