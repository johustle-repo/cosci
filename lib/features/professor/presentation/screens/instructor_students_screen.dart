import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/professor/services/instructor_analytics_service.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';

class InstructorStudentsScreen extends StatefulWidget {
  const InstructorStudentsScreen({super.key});
  @override
  State<InstructorStudentsScreen> createState() => _InstructorStudentsState();
}

class _InstructorStudentsState extends State<InstructorStudentsScreen> {
  late Future<InstructorOverview> future;
  String query = '', program = 'All', year = 'All';

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<InstructorOverview> _load() => context
      .read<InstructorAnalyticsService>()
      .loadOverview(attemptLimit: 250);

  void _refresh() => setState(() => future = _load());

  void _details(InstructorStudent student, List<InstructorAttempt> attempts) {
    final passed = attempts.where((item) => item.passed).length;
    final rate = attempts.isEmpty
        ? 0
        : (passed * 100 / attempts.length).round();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.name),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${student.program} • ${student.yearLevel}'),
              Text(student.email),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                children: [
                  Chip(label: Text('${attempts.length} attempts')),
                  Chip(label: Text('$rate% success')),
                  Chip(label: Text('${attempts.length - passed} need review')),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Recent activity',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (attempts.isEmpty)
                const Text('No simulation attempts recorded yet.')
              else
                ...attempts
                    .take(5)
                    .map(
                      (attempt) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          attempt.passed
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: attempt.passed ? Colors.green : Colors.orange,
                        ),
                        title: Text(attempt.title),
                        subtitle: Text(
                          '${attempt.language} • ${attempt.topic.isEmpty ? 'General' : attempt.topic}',
                        ),
                        trailing: Text(attempt.passed ? 'Passed' : 'Review'),
                      ),
                    ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Student Management',
    maxContentWidth: 1480,
    body: FutureBuilder<InstructorOverview>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(message: '${snapshot.error}', onRetry: _refresh);
        }
        final overview = snapshot.data!;
        final programs = {'All', ...overview.students.map((e) => e.program)};
        final years = {'All', ...overview.students.map((e) => e.yearLevel)};
        final students = overview.students.where((student) {
          final needle = query.trim().toLowerCase();
          return (needle.isEmpty ||
                  student.name.toLowerCase().contains(needle) ||
                  student.email.toLowerCase().contains(needle)) &&
              (program == 'All' || student.program == program) &&
              (year == 'All' || student.yearLevel == year);
        }).toList();
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: AppScaffold.pagePadding(context),
            children: [
              const _PageHero(
                title: 'Learner roster and intervention',
                subtitle:
                    'Monitor participation, identify learners who need support, and inspect recent practical activity.',
                icon: Icons.groups_rounded,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 560
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Metric(
                        '${overview.studentCount}',
                        'Total learners',
                        width: width,
                        icon: Icons.groups_rounded,
                      ),
                      _Metric(
                        '${overview.attempts.length}',
                        'Recent attempts',
                        width: width,
                        icon: Icons.terminal_rounded,
                      ),
                      _Metric(
                        '${overview.successRate}%',
                        'Success rate',
                        width: width,
                        icon: Icons.trending_up_rounded,
                      ),
                      _Metric(
                        '${overview.pendingFeedback}',
                        'Awaiting feedback',
                        width: width,
                        icon: Icons.rate_review_rounded,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _StudentFilters(
                programs: programs.toList(),
                years: years.toList(),
                program: program,
                year: year,
                onSearch: (value) => setState(() => query = value),
                onProgram: (value) => setState(() => program = value),
                onYear: (value) => setState(() => year = value),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Learners',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${students.length} shown',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (students.isEmpty)
                const _EmptyState('No learners match the selected filters.')
              else
                ...students.map((student) {
                  final attempts = overview.attempts
                      .where((item) => item.studentId == student.id)
                      .toList();
                  final passed = attempts.where((item) => item.passed).length;
                  final rate = attempts.isEmpty
                      ? 0
                      : (passed * 100 / attempts.length).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StudentCard(
                      student: student,
                      attempts: attempts.length,
                      successRate: rate,
                      needsReview: attempts.length - passed,
                      onOpen: () => _details(student, attempts),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    ),
  );
}

class InstructorClassAnalyticsScreen extends StatefulWidget {
  const InstructorClassAnalyticsScreen({super.key});
  @override
  State<InstructorClassAnalyticsScreen> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<InstructorClassAnalyticsScreen> {
  late Future<InstructorOverview> future;
  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<InstructorOverview> _load() => context
      .read<InstructorAnalyticsService>()
      .loadOverview(attemptLimit: 500);
  void _refresh() => setState(() => future = _load());

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'Class Analytics',
    maxContentWidth: 1480,
    body: FutureBuilder<InstructorOverview>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(message: '${snapshot.error}', onRetry: _refresh);
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: AppScaffold.pagePadding(context),
            children: [
              const _PageHero(
                title: 'Class performance insights',
                subtitle:
                    'Use real simulation evidence to guide review sessions, interventions, and the next classroom activity.',
                icon: Icons.analytics_rounded,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1100
                      ? 5
                      : constraints.maxWidth >= 720
                      ? 3
                      : constraints.maxWidth >= 480
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Metric(
                        '${data.studentCount}',
                        'Learners',
                        width: width,
                        icon: Icons.groups_rounded,
                      ),
                      _Metric(
                        '${data.attempts.length}',
                        'Attempts analyzed',
                        width: width,
                        icon: Icons.fact_check_outlined,
                      ),
                      _Metric(
                        '${data.successRate}%',
                        'Class success',
                        width: width,
                        icon: Icons.trending_up_rounded,
                      ),
                      _Metric(
                        '${data.needsReview}',
                        'Failed attempts',
                        width: width,
                        icon: Icons.warning_amber_rounded,
                      ),
                      _Metric(
                        '${data.reviewedAttempts}',
                        'Reviewed',
                        width: width,
                        icon: Icons.rate_review_rounded,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 850;
                  final topics = _InsightPanel(
                    title: 'Topics needing reinforcement',
                    icon: Icons.trending_down_rounded,
                    color: const Color(0xFFDC2626),
                    entries: data.weakestTopics,
                    empty: 'No failed-topic data yet.',
                  );
                  final languages = _InsightPanel(
                    title: 'Attempts by programming language',
                    icon: Icons.code_rounded,
                    color: const Color(0xFF2563EB),
                    entries: data.attemptsByLanguage.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)),
                    empty: 'No language activity yet.',
                  );
                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: topics),
                            const SizedBox(width: 14),
                            Expanded(child: languages),
                          ],
                        )
                      : Column(
                          children: [
                            topics,
                            const SizedBox(height: 14),
                            languages,
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              _SupportPanel(names: data.learnersNeedingSupport),
            ],
          ),
        );
      },
    ),
  );
}

class _PageHero extends StatelessWidget {
  const _PageHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFF071A3B), Color(0xFF123C81)],
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF2563EB),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
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

class _Metric extends StatelessWidget {
  const _Metric(
    this.value,
    this.label, {
    this.width = 185,
    this.icon = Icons.insights_rounded,
  });
  final String value, label;
  final double width;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD7E2F2)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF164BA5), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$value\n',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _StudentFilters extends StatelessWidget {
  const _StudentFilters({
    required this.programs,
    required this.years,
    required this.program,
    required this.year,
    required this.onSearch,
    required this.onProgram,
    required this.onYear,
  });
  final List<String> programs, years;
  final String program, year;
  final ValueChanged<String> onSearch, onProgram, onYear;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 760;
      final search = TextField(
        onChanged: onSearch,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search learner or email',
        ),
      );
      final programField = DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: program,
        decoration: const InputDecoration(labelText: 'Program'),
        items: programs
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) => onProgram(value ?? 'All'),
      );
      final yearField = DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: year,
        decoration: const InputDecoration(labelText: 'Year level'),
        items: years
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) => onYear(value ?? 'All'),
      );
      if (narrow) {
        return Column(
          children: [
            search,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: programField),
                const SizedBox(width: 10),
                Expanded(child: yearField),
              ],
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(flex: 5, child: search),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: programField),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: yearField),
        ],
      );
    },
  );
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.attempts,
    required this.successRate,
    required this.needsReview,
    required this.onOpen,
  });
  final InstructorStudent student;
  final int attempts, successRate, needsReview;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
      final identity = Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE1EAFE),
            foregroundColor: const Color(0xFF164BA5),
            child: Text(
              student.name.isEmpty ? 'L' : student.name[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${student.program} • ${student.yearLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
                Text(
                  student.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      final stats = Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _RosterStat('$attempts', 'Attempts'),
          _RosterStat('$successRate%', 'Success', positive: successRate >= 70),
          if (needsReview > 0)
            _RosterStat('$needsReview', 'Review', warning: true),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.person_search_rounded, size: 18),
            label: const Text('View learner'),
          ),
        ],
      );
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD7E2F2)),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [identity, const SizedBox(height: 14), stats],
              )
            : Row(
                children: [
                  Expanded(flex: 5, child: identity),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: stats,
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _RosterStat extends StatelessWidget {
  const _RosterStat(
    this.value,
    this.label, {
    this.positive = false,
    this.warning = false,
  });
  final String value, label;
  final bool positive, warning;
  @override
  Widget build(BuildContext context) {
    final color = warning
        ? const Color(0xFFB45309)
        : positive
        ? const Color(0xFF15803D)
        : const Color(0xFF334155);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            TextSpan(text: label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.entries,
    required this.empty,
  });
  final String title, empty;
  final IconData icon;
  final Color color;
  final List<MapEntry<String, int>> entries;
  @override
  Widget build(BuildContext context) {
    final max = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 9),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Text(empty)
          else
            ...entries
                .take(6)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(entry.key)),
                            Text('${entry.value}'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: entry.value / max,
                          color: color,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({required this.names});
  final List<String> names;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFD7E2F2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learners needing support',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 6),
        const Text(
          'Learners with unsuccessful results in at least half of their recent attempts.',
        ),
        const SizedBox(height: 14),
        if (names.isEmpty)
          const Text('No learners currently meet the intervention threshold.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: names
                .map(
                  (name) => Chip(
                    avatar: const Icon(Icons.person, size: 17),
                    label: Text(name),
                  ),
                )
                .toList(),
          ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(36),
    child: Center(child: Text(message)),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 44),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
