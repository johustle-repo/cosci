import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_analytics.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_notice_banner.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_student_analytics_provider.dart';

enum _View { progress, needsHelp, leaderboard }

/// Admin page that tracks student progress, flags students who need help,
/// and ranks learners on leaderboards.
class AdminStudentAnalyticsScreen extends StatefulWidget {
  const AdminStudentAnalyticsScreen({super.key});

  @override
  State<AdminStudentAnalyticsScreen> createState() =>
      _AdminStudentAnalyticsScreenState();
}

class _AdminStudentAnalyticsScreenState
    extends State<AdminStudentAnalyticsScreen> {
  _View _view = _View.progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStudentAnalyticsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Student Analytics',
      currentRoute: AppRoutes.adminStudentAnalytics,
      child: Consumer<AdminStudentAnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && !provider.hasData) {
            return const SizedBox(
              height: 400,
              child: AdminLoadingState(message: 'Loading student analytics...'),
            );
          }
          if (provider.error != null && !provider.hasData) {
            return SizedBox(
              height: 400,
              child: AdminErrorState(
                message: provider.error!,
                onRetry: provider.load,
              ),
            );
          }
          final needsHelpCount = provider.needsHelp.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.error != null) ...[
                AdminNoticeBanner(
                  message: provider.error!,
                  onRetry: provider.load,
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Student Analytics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: provider.isLoading ? null : provider.load,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Track learner progress, find students who need support, and see who is leading.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              _SummaryGrid(provider: provider, needsHelpCount: needsHelpCount),
              const SizedBox(height: 20),
              _Filters(provider: provider),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_View>(
                  segments: [
                    const ButtonSegment(
                      value: _View.progress,
                      icon: Icon(Icons.timeline_rounded),
                      label: Text('Progress'),
                    ),
                    ButtonSegment(
                      value: _View.needsHelp,
                      icon: const Icon(Icons.support_rounded),
                      label: Text('Needs help ($needsHelpCount)'),
                    ),
                    const ButtonSegment(
                      value: _View.leaderboard,
                      icon: Icon(Icons.emoji_events_rounded),
                      label: Text('Leaderboard'),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (value) =>
                      setState(() => _view = value.first),
                ),
              ),
              const SizedBox(height: 20),
              switch (_view) {
                _View.progress => _ProgressView(provider: provider),
                _View.needsHelp => _NeedsHelpView(provider: provider),
                _View.leaderboard => _LeaderboardView(provider: provider),
              },
            ],
          );
        },
      ),
    );
  }
}

// ── Summary ──────────────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.provider, required this.needsHelpCount});

  final AdminStudentAnalyticsProvider provider;
  final int needsHelpCount;

  @override
  Widget build(BuildContext context) {
    final quizAverage = provider.averageQuizScore;
    final cards = [
      AdminStatCard(
        label: 'Students',
        value: '${provider.rows.length}',
        icon: Icons.groups_rounded,
        color: const Color(0xFF2563EB),
      ),
      AdminStatCard(
        label: 'Active this week',
        value: '${provider.activeThisWeek}',
        icon: Icons.bolt_rounded,
        color: const Color(0xFF059669),
      ),
      AdminStatCard(
        label: 'Need help',
        value: '$needsHelpCount',
        icon: Icons.support_rounded,
        color: const Color(0xFFDC2626),
      ),
      AdminStatCard(
        label: 'Avg. completion',
        value: '${provider.averageCompletion}%',
        icon: Icons.donut_large_rounded,
        color: const Color(0xFF7C3AED),
      ),
      AdminStatCard(
        label: 'Avg. quiz score',
        value: quizAverage == null ? '—' : '$quizAverage%',
        icon: Icons.quiz_rounded,
        color: const Color(0xFFD97706),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 720
            ? 3
            : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

// ── Filters ──────────────────────────────────────────────────────────────────

class _Filters extends StatelessWidget {
  const _Filters({required this.provider});

  final AdminStudentAnalyticsProvider provider;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search_rounded),
        hintText: 'Search by name or email',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: provider.setSearch,
    );
    Widget dropdown({
      required String label,
      required String? value,
      required List<String> options,
      required ValueChanged<String?> onChanged,
    }) {
      return DropdownButtonFormField<String?>(
        // Keyed by value so the field resets when filters change.
        key: ValueKey('$label-$value'),
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text('All ${label}s')),
          for (final option in options)
            DropdownMenuItem<String?>(value: option, child: Text(option)),
        ],
        onChanged: onChanged,
      );
    }

    final program = dropdown(
      label: 'Program',
      value: provider.program,
      options: provider.programs,
      onChanged: provider.setProgram,
    );
    final year = dropdown(
      label: 'Year level',
      value: provider.yearLevel,
      options: provider.yearLevels,
      onChanged: provider.setYearLevel,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: program),
                  const SizedBox(width: 10),
                  Expanded(child: year),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: 12),
            Expanded(child: program),
            const SizedBox(width: 12),
            Expanded(child: year),
          ],
        );
      },
    );
  }
}

// ── Progress view ────────────────────────────────────────────────────────────

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.provider});

  final AdminStudentAnalyticsProvider provider;

  @override
  Widget build(BuildContext context) {
    final rows = provider.rows;
    final totals = provider.totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeader(title: 'Student Progress'),
        const SizedBox(height: 6),
        Text(
          'Completion compares finished lessons, passed quizzes, and solved puzzles against '
          '${totals.lessons} lessons, ${totals.quizzes} quizzes, and ${totals.puzzles} puzzles published.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const _EmptyCard(
            icon: Icons.person_search_rounded,
            message: 'No students match the current filters.',
          )
        else
          AdminTableSurface(
            minWidth: 1180,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Program · Year')),
                DataColumn(label: Text('Lessons'), numeric: true),
                DataColumn(label: Text('Quizzes passed'), numeric: true),
                DataColumn(label: Text('Puzzles'), numeric: true),
                DataColumn(label: Text('Quiz avg.'), numeric: true),
                DataColumn(label: Text('Completion')),
                DataColumn(label: Text('XP · Level')),
                DataColumn(label: Text('Last active')),
                DataColumn(label: Text('Status')),
              ],
              rows: [
                for (final row in rows)
                  DataRow(
                    onSelectChanged: (_) => _openStudent(context, row),
                    cells: [
                      DataCell(_StudentName(row: row)),
                      DataCell(Text(_programYear(row))),
                      DataCell(
                        Text(
                          '${row.profile.completedLessons}/${totals.lessons}',
                        ),
                      ),
                      DataCell(Text('${row.passedQuizzes}/${totals.quizzes}')),
                      DataCell(
                        Text(
                          '${row.profile.completedPuzzles}/${totals.puzzles}',
                        ),
                      ),
                      DataCell(
                        Text(
                          row.quizAverage == null ? '—' : '${row.quizAverage}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _scoreColor(row.quizAverage),
                          ),
                        ),
                      ),
                      DataCell(_CompletionBar(percent: row.completionPercent)),
                      DataCell(
                        Text(
                          '${row.profile.totalXp} XP · Lv. ${row.profile.currentLevel}',
                        ),
                      ),
                      DataCell(Text(_lastActive(row.lastActiveAt))),
                      DataCell(_StatusChip(row: row)),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Needs help view ──────────────────────────────────────────────────────────

class _NeedsHelpView extends StatelessWidget {
  const _NeedsHelpView({required this.provider});

  final AdminStudentAnalyticsProvider provider;

  @override
  Widget build(BuildContext context) {
    final flagged = provider.needsHelp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeader(title: 'Students Who Need Help'),
        const SizedBox(height: 6),
        const Text(
          'Flags: inactive 7+ days, no completed activity, quiz average below 60%, '
          'failing the same quiz twice, or running out of quiz attempts. '
          'Accounts younger than 7 days are not flagged for inactivity or lack of progress.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 14),
        if (flagged.isEmpty)
          const _EmptyCard(
            icon: Icons.verified_rounded,
            message: 'No students need help right now. Everyone is on track.',
          )
        else
          for (final row in flagged)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NeedsHelpCard(row: row),
            ),
      ],
    );
  }
}

class _NeedsHelpCard extends StatelessWidget {
  const _NeedsHelpCard({required this.row});

  final StudentAnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    final high = row.severity == HelpSeverity.high;
    final color = high ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StudentName(row: row),
              _Pill(
                label: high ? 'High priority' : 'Needs attention',
                color: color,
                icon: high ? Icons.priority_high_rounded : Icons.flag_rounded,
              ),
              Text(
                '${_programYear(row)} · Last active ${_lastActive(row.lastActiveAt)}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final reason in row.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_reasonIcon(reason), size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${reason.label}: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: reason.description),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (row.strugglingQuizTitles.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Struggling with: ${row.strugglingQuizTitles.join(', ')}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Completion ${row.completionPercent}% · Quiz avg. '
                '${row.quizAverage == null ? '—' : '${row.quizAverage}%'} · '
                '${row.quizAttempts} quiz attempts',
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              TextButton.icon(
                onPressed: () => _openStudent(context, row),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Leaderboard view ─────────────────────────────────────────────────────────

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView({required this.provider});

  final AdminStudentAnalyticsProvider provider;

  @override
  Widget build(BuildContext context) {
    final ranked = provider.leaderboard;
    final metric = provider.metric;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminSectionHeader(title: 'Leaderboard'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in LeaderboardMetric.values)
              ChoiceChip(
                label: Text(option.label),
                selected: option == metric,
                onSelected: (_) => provider.setMetric(option),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (ranked.isEmpty)
          const _EmptyCard(
            icon: Icons.emoji_events_rounded,
            message: 'No students match the current filters.',
          )
        else ...[
          _Podium(rows: ranked.take(3).toList(), metric: metric),
          const SizedBox(height: 16),
          AdminTableSurface(
            minWidth: 860,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: [
                const DataColumn(label: Text('Rank'), numeric: true),
                const DataColumn(label: Text('Student')),
                const DataColumn(label: Text('Program · Year')),
                DataColumn(label: Text(metric.label), numeric: true),
                const DataColumn(label: Text('XP'), numeric: true),
                const DataColumn(label: Text('Level'), numeric: true),
                const DataColumn(label: Text('Streak'), numeric: true),
                const DataColumn(label: Text('Badges'), numeric: true),
              ],
              rows: [
                for (var i = 0; i < ranked.length; i++)
                  DataRow(
                    onSelectChanged: (_) => _openStudent(context, ranked[i]),
                    cells: [
                      DataCell(
                        Text(
                          '#${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      DataCell(_StudentName(row: ranked[i])),
                      DataCell(Text(_programYear(ranked[i]))),
                      DataCell(
                        Text(
                          _metricText(ranked[i], metric),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      DataCell(Text('${ranked[i].profile.totalXp}')),
                      DataCell(Text('${ranked[i].profile.currentLevel}')),
                      DataCell(Text('${ranked[i].profile.streakDays}d')),
                      DataCell(Text('${ranked[i].profile.badgesEarned}')),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.rows, required this.metric});

  final List<StudentAnalyticsRow> rows;
  final LeaderboardMetric metric;

  static const _medals = [
    Color(0xFFF59E0B), // gold
    Color(0xFF94A3B8), // silver
    Color(0xFFB45309), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final stacked = constraints.maxWidth < 600;
        final width = stacked
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < rows.length; i++)
              SizedBox(
                width: width,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openStudent(context, rows[i]),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: _medals[i].withValues(alpha: 0.08),
                      border: Border.all(
                        color: _medals[i].withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: _medals[i],
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rows[i].profile.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${metric.label}: ${_metricText(rows[i], metric)}',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.emoji_events_rounded, color: _medals[i]),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Shared pieces ────────────────────────────────────────────────────────────

class _StudentName extends StatelessWidget {
  const _StudentName({required this.row});

  final StudentAnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.profile.displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (row.profile.email.isNotEmpty)
          Text(
            row.profile.email,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
      ],
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 70
        ? const Color(0xFF059669)
        : percent >= 30
        ? const Color(0xFF2563EB)
        : const Color(0xFFDC2626);
    return SizedBox(
      width: 140,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 7,
                color: color,
                backgroundColor: const Color(0xFFE2E8F0),
                semanticsLabel: 'Completion',
                semanticsValue: '$percent%',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percent%',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.row});

  final StudentAnalyticsRow row;

  @override
  Widget build(BuildContext context) {
    return switch (row.severity) {
      HelpSeverity.high => const _Pill(
        label: 'High priority',
        color: Color(0xFFDC2626),
        icon: Icons.priority_high_rounded,
      ),
      HelpSeverity.medium => const _Pill(
        label: 'Needs attention',
        color: Color(0xFFD97706),
        icon: Icons.flag_rounded,
      ),
      HelpSeverity.none => const _Pill(
        label: 'On track',
        color: Color(0xFF059669),
        icon: Icons.check_circle_rounded,
      ),
    };
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E3F2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

void _openStudent(BuildContext context, StudentAnalyticsRow row) {
  Navigator.pushNamed(
    context,
    AppRoutes.adminStudentDetail,
    arguments: row.profile.uid,
  );
}

String _programYear(StudentAnalyticsRow row) {
  final year = (row.profile.yearLevel ?? '').trim();
  return year.isEmpty ? row.profile.course : '${row.profile.course} · $year';
}

String _lastActive(DateTime? value) {
  if (value == null) return 'Never';
  final days = DateTime.now().difference(value).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 30) return '$days days ago';
  final months = (days / 30).floor();
  return months == 1 ? '1 month ago' : '$months months ago';
}

String _metricText(StudentAnalyticsRow row, LeaderboardMetric metric) {
  return switch (metric) {
    LeaderboardMetric.xp => '${row.profile.totalXp} XP',
    LeaderboardMetric.completion => '${row.completionPercent}%',
    LeaderboardMetric.quizAverage =>
      row.quizAverage == null ? '—' : '${row.quizAverage}%',
    LeaderboardMetric.streak => '${row.profile.streakDays} days',
  };
}

Color _scoreColor(int? score) {
  if (score == null) return const Color(0xFF94A3B8);
  if (score >= 80) return const Color(0xFF059669);
  if (score >= 60) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

IconData _reasonIcon(HelpReason reason) => switch (reason) {
  HelpReason.inactive => Icons.bedtime_rounded,
  HelpReason.noProgress => Icons.hourglass_empty_rounded,
  HelpReason.lowQuizAverage => Icons.trending_down_rounded,
  HelpReason.repeatedQuizFailures => Icons.replay_rounded,
  HelpReason.exhaustedQuizAttempts => Icons.block_rounded,
};
