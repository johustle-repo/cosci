import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/professor/services/instructor_analytics_service.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/overview_stat_tile.dart';
import 'package:pseudocode_apk/shared/widgets/role_dashboard_header.dart';

class ProfessorHomeScreen extends StatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  State<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends State<ProfessorHomeScreen> {
  late Future<InstructorOverview> _overview;
  int _attemptLimit = 25;
  String _search = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _overview = context.read<InstructorAnalyticsService>().loadOverview(
      attemptLimit: _attemptLimit,
    );
  }

  void _refresh() {
    setState(() {
      _overview = context.read<InstructorAnalyticsService>().loadOverview(
        attemptLimit: _attemptLimit,
      );
    });
  }

  Future<void> _review(InstructorAttempt attempt) async {
    final controller = TextEditingController(text: attempt.feedback);
    final feedback = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Instructor feedback'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Feedback for the learner',
              hintText: 'Explain what worked and what to improve next.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save feedback'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (feedback == null || !mounted) return;
    final instructorId = context.read<AuthProvider>().currentUser?.uid;
    if (instructorId == null) return;
    try {
      await context.read<InstructorAnalyticsService>().saveFeedback(
        attempt: attempt,
        instructorId: instructorId,
        feedback: feedback,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Feedback saved.')));
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save feedback: $error')),
      );
    }
  }

  void _showStudent(InstructorAttempt student, List<InstructorAttempt> all) {
    final attempts = all
        .where((item) => item.studentId == student.studentId)
        .toList();
    final passed = attempts.where((item) => item.passed).length;
    final rate = attempts.isEmpty ? 0.0 : passed / attempts.length;
    final recommendation = rate >= .8
        ? 'Strong mastery: assign a harder activity or introduce the next topic.'
        : rate >= .5
        ? 'Developing mastery: assign another guided practice activity.'
        : 'Needs support: review syntax feedback and the current topic before retrying.';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student.studentName),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${student.program} • ${student.yearLevel}'),
              const SizedBox(height: 12),
              Text('Simulation mastery: $passed/${attempts.length} passed'),
              const SizedBox(height: 8),
              Text(recommendation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return AppScaffold(
      title: 'Dashboard',
      maxContentWidth: 1480,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: FutureBuilder<InstructorOverview>(
        future: _overview,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final overview = snapshot.data!;
          final visibleAttempts = overview.attempts.where((attempt) {
            final query = _search.trim().toLowerCase();
            final matchesText =
                query.isEmpty ||
                attempt.studentName.toLowerCase().contains(query) ||
                attempt.title.toLowerCase().contains(query) ||
                attempt.program.toLowerCase().contains(query);
            return matchesText &&
                (_filter == 'all' ||
                    (_filter == 'passed' ? attempt.passed : !attempt.passed));
          }).toList();
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _overview;
            },
            child: ListView(
              padding: AppScaffold.pagePadding(context),
              children: [
                RoleDashboardHeader(
                  badge: 'Instructor',
                  title: 'Welcome, ${user?.displayName ?? 'Instructor'}',
                  subtitle:
                      'Monitor real compiler attempts and give focused guidance to first- and second-year programming learners.',
                ),
                const SizedBox(height: 14),
                _DashboardActions(
                  onStudents: () => Navigator.pushNamed(
                    context,
                    AppRoutes.instructorStudents,
                  ),
                  onAnalytics: () => Navigator.pushNamed(
                    context,
                    AppRoutes.instructorAnalytics,
                  ),
                  onLessons: () =>
                      Navigator.pushNamed(context, AppRoutes.instructorLessons),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 4
                        : constraints.maxWidth >= 620
                        ? 2
                        : 1;
                    final tileWidth =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: OverviewStatTile(
                            label: 'Active learners',
                            value: '${overview.studentCount}',
                            icon: Icons.groups_rounded,
                            color: const Color(0xFF123D9B),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: OverviewStatTile(
                            label: 'Compiler attempts',
                            value: '${overview.attempts.length}',
                            icon: Icons.terminal_rounded,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: OverviewStatTile(
                            label: 'Success rate',
                            value: '${overview.successRate}%',
                            icon: Icons.insights_rounded,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: OverviewStatTile(
                            label: 'Needs review',
                            value: '${overview.needsReview}',
                            icon: Icons.rate_review_rounded,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _TeachingCommandCenter(
                  overview: overview,
                  onOpenLessons: () =>
                      Navigator.pushNamed(context, AppRoutes.instructorLessons),
                  onOpenSimulations: () => Navigator.pushNamed(
                    context,
                    AppRoutes.instructorSimulations,
                  ),
                  onOpenQuizzes: () =>
                      Navigator.pushNamed(context, AppRoutes.instructorQuizzes),
                  onOpenPuzzles: () =>
                      Navigator.pushNamed(context, AppRoutes.instructorPuzzles),
                ),
                const SizedBox(height: 22),
                Text(
                  'Recent simulation attempts',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth < 600
                            ? constraints.maxWidth
                            : constraints.maxWidth - 170,
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            labelText: 'Search learner, activity, or program',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => setState(() => _search = value),
                        ),
                      ),
                      DropdownButton<String>(
                        value: _filter,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All results'),
                          ),
                          DropdownMenuItem(
                            value: 'passed',
                            child: Text('Passed'),
                          ),
                          DropdownMenuItem(
                            value: 'review',
                            child: Text('Needs review'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _filter = value ?? 'all'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (visibleAttempts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No learner compiler attempts have been recorded yet.',
                      ),
                    ),
                  )
                else
                  ...visibleAttempts.map(
                    (attempt) => _AttemptCard(
                      attempt: attempt,
                      onReview: () => _review(attempt),
                      onStudent: () => _showStudent(attempt, overview.attempts),
                    ),
                  ),
                if (overview.hasMore)
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _attemptLimit += 25;
                        _refresh();
                      },
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Load more attempts'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardActions extends StatelessWidget {
  const _DashboardActions({
    required this.onStudents,
    required this.onAnalytics,
    required this.onLessons,
  });

  final VoidCallback onStudents;
  final VoidCallback onAnalytics;
  final VoidCallback onLessons;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
      final actions = [
        _InstructorAction(
          icon: Icons.groups_rounded,
          label: 'Manage learners',
          description: 'Roster and intervention history',
          onTap: onStudents,
        ),
        _InstructorAction(
          icon: Icons.analytics_rounded,
          label: 'View class analytics',
          description: 'Mastery and difficult topics',
          onTap: onAnalytics,
        ),
        _InstructorAction(
          icon: Icons.auto_stories_rounded,
          label: 'Browse teaching content',
          description: 'Lessons and learning activities',
          onTap: onLessons,
        ),
      ];
      if (compact) {
        return Column(
          children: actions
              .map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: action,
                ),
              )
              .toList(),
        );
      }
      return Row(
        children: actions
            .asMap()
            .entries
            .map(
              (entry) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: entry.key == actions.length - 1 ? 0 : 10,
                  ),
                  child: entry.value,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _InstructorAction extends StatelessWidget {
  const _InstructorAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD7E2F2)),
          borderRadius: BorderRadius.circular(16),
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
              child: Icon(icon, color: const Color(0xFF164BA5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}

class _TeachingCommandCenter extends StatelessWidget {
  const _TeachingCommandCenter({
    required this.overview,
    required this.onOpenLessons,
    required this.onOpenSimulations,
    required this.onOpenQuizzes,
    required this.onOpenPuzzles,
  });

  final InstructorOverview overview;
  final VoidCallback onOpenLessons;
  final VoidCallback onOpenSimulations;
  final VoidCallback onOpenQuizzes;
  final VoidCallback onOpenPuzzles;

  @override
  Widget build(BuildContext context) {
    final reviewTotal = overview.needsReview;
    final reviewed = overview.attempts
        .where((attempt) => !attempt.passed && attempt.feedback.isNotEmpty)
        .length;
    final reviewProgress = reviewTotal == 0 ? 1.0 : reviewed / reviewTotal;
    final languages = overview.attemptsByLanguage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF16A6B6),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teaching command center',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Actionable guidance based on recent learner activity',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final width = wide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InsightPanel(
                  width: width,
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFF1D4ED8),
                  title: 'Review queue',
                  subtitle:
                      '${overview.pendingFeedback} attempts need feedback',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: reviewProgress,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reviewTotal == 0
                            ? 'No failed attempts are waiting for review.'
                            : '$reviewed of $reviewTotal reviewed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _InsightPanel(
                  width: width,
                  icon: Icons.person_search_outlined,
                  color: const Color(0xFFB45309),
                  title: 'Learners needing support',
                  subtitle: 'Repeated difficulty in recent attempts',
                  child: overview.learnersNeedingSupport.isEmpty
                      ? const Text('No learners are currently flagged.')
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: overview.learnersNeedingSupport
                              .map(
                                (name) => Chip(
                                  avatar: const Icon(
                                    Icons.priority_high_rounded,
                                    size: 16,
                                  ),
                                  label: Text(name),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                ),
                _InsightPanel(
                  width: width,
                  icon: Icons.code_rounded,
                  color: const Color(0xFF0F766E),
                  title: 'Activity coverage',
                  subtitle: 'Attempts grouped by programming language',
                  child: languages.isEmpty
                      ? const Text('No language activity recorded yet.')
                      : Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: languages
                              .take(4)
                              .map(
                                (entry) => Chip(
                                  label: Text('${entry.key} · ${entry.value}'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final weakWidth = wide
                ? (constraints.maxWidth - 12) * .55
                : constraints.maxWidth;
            final actionWidth = wide
                ? (constraints.maxWidth - 12) * .45
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InsightPanel(
                  width: weakWidth,
                  icon: Icons.troubleshoot_rounded,
                  color: const Color(0xFFBE123C),
                  title: 'Topics needing reinforcement',
                  subtitle: 'Topics with the most unsuccessful attempts',
                  child: overview.weakestTopics.isEmpty
                      ? const Text('No weak topics detected yet.')
                      : Column(
                          children: overview.weakestTopics
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE4E6),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '${entry.value} missed',
                                          style: const TextStyle(
                                            color: Color(0xFF9F1239),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                _InsightPanel(
                  width: actionWidth,
                  icon: Icons.rocket_launch_outlined,
                  color: const Color(0xFF6D28D9),
                  title: 'Preview learning content',
                  subtitle: 'Experience activities before assigning guidance',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickAction(
                        icon: Icons.menu_book_outlined,
                        label: 'Lessons',
                        onTap: onOpenLessons,
                      ),
                      _QuickAction(
                        icon: Icons.terminal_rounded,
                        label: 'Simulations',
                        onTap: onOpenSimulations,
                      ),
                      _QuickAction(
                        icon: Icons.quiz_outlined,
                        label: 'Quizzes',
                        onTap: onOpenQuizzes,
                      ),
                      _QuickAction(
                        icon: Icons.extension_outlined,
                        label: 'Puzzles',
                        onTap: onOpenPuzzles,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.width,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final double width;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E2F2)),
      ),
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
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
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
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard({
    required this.attempt,
    required this.onReview,
    required this.onStudent,
  });
  final InstructorAttempt attempt;
  final VoidCallback onReview;
  final VoidCallback onStudent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: attempt.passed
              ? const Color(0xFFE8F7EE)
              : const Color(0xFFFFF7ED),
          child: Icon(
            attempt.passed ? Icons.check_rounded : Icons.priority_high_rounded,
            color: attempt.passed
                ? const Color(0xFF15803D)
                : const Color(0xFFB45309),
          ),
        ),
        title: InkWell(
          onTap: onStudent,
          child: Text(
            '${attempt.studentName} • ${attempt.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Text(
          '${attempt.program} • ${attempt.yearLevel} • ${attempt.language}\n${attempt.feedback.isEmpty ? (attempt.passed ? 'Passed' : 'Review recommended') : 'Feedback: ${attempt.feedback}'}',
        ),
        isThreeLine: true,
        trailing: OutlinedButton.icon(
          onPressed: onReview,
          icon: const Icon(Icons.feedback_outlined),
          label: Text(attempt.feedback.isEmpty ? 'Review' : 'Edit'),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load instructor analytics.'),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
