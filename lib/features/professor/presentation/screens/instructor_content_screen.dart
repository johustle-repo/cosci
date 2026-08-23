import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/models/code_simulation_activity.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/models/quiz.dart';
import 'package:pseudocode_apk/providers/lessons_provider.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';
import 'package:pseudocode_apk/providers/quizzes_provider.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';

enum _Kind { lesson, simulation, quiz, puzzle }

class InstructorLessonLibraryScreen extends StatelessWidget {
  const InstructorLessonLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Catalog(kind: _Kind.lesson);
}

class InstructorSimulationPreviewScreen extends StatelessWidget {
  const InstructorSimulationPreviewScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Catalog(kind: _Kind.simulation);
}

class InstructorQuizPreviewScreen extends StatelessWidget {
  const InstructorQuizPreviewScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Catalog(kind: _Kind.quiz);
}

class InstructorPuzzlePreviewScreen extends StatelessWidget {
  const InstructorPuzzlePreviewScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Catalog(kind: _Kind.puzzle);
}

class _Catalog extends StatefulWidget {
  const _Catalog({required this.kind});
  final _Kind kind;
  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  String search = '', language = 'All', difficulty = 'All';
  _Config get config => _Config.of(widget.kind);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    switch (widget.kind) {
      case _Kind.lesson:
        await context.read<LessonsProvider>().loadLessons(forceRefresh: true);
      case _Kind.simulation:
        await context.read<SimulationProvider>().loadActivities(
          forceRefresh: true,
        );
      case _Kind.quiz:
        await context.read<QuizzesProvider>().loadQuizzes(forceRefresh: true);
      case _Kind.puzzle:
        await context.read<PuzzlesProvider>().loadPuzzles(forceRefresh: true);
    }
  }

  List<_Item> _all(BuildContext context) => switch (widget.kind) {
    _Kind.lesson =>
      context.watch<LessonsProvider>().lessons.map(_Item.lesson).toList(),
    _Kind.simulation =>
      context
          .watch<SimulationProvider>()
          .activities
          .map(_Item.simulation)
          .toList(),
    _Kind.quiz =>
      context.watch<QuizzesProvider>().quizzes.map(_Item.quiz).toList(),
    _Kind.puzzle =>
      context.watch<PuzzlesProvider>().puzzles.map(_Item.puzzle).toList(),
  };

  bool _loading(BuildContext context) => switch (widget.kind) {
    _Kind.lesson => context.watch<LessonsProvider>().isLoading,
    _Kind.simulation => context.watch<SimulationProvider>().isLoadingActivities,
    _Kind.quiz => context.watch<QuizzesProvider>().isLoading,
    _Kind.puzzle => context.watch<PuzzlesProvider>().isLoading,
  };

  void _preview(_Item item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _InstructorPreviewDialog(item: item, kind: widget.kind),
    );
  }

  void _review(_Item item) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Teaching review: ${item.title}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: config.checks
              .map(
                (text) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF0F9F6E),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(text)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(dialogContext);
            _preview(item);
          },
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Learner preview'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final all = _all(context);
    final query = search.trim().toLowerCase();
    final filtered = all.where((item) {
      return (query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.topic.toLowerCase().contains(query)) &&
          (language == 'All' || item.language == language) &&
          (difficulty == 'All' || item.difficulty == difficulty);
    }).toList();
    final languages = {'All', ...all.map((item) => item.language)}.toList();
    final difficulties = {
      'All',
      ...all.map((item) => item.difficulty),
    }.toList();
    final ready = all.where((item) => item.ready).length;

    return AppScaffold(
      title: config.title,
      maxContentWidth: 1480,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: AppScaffold.pagePadding(context),
          children: [
            _Header(config: config),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Stat(
                      value: '${all.length}',
                      label: 'Available',
                      width: width,
                    ),
                    _Stat(
                      value: '$ready',
                      label: 'Ready for class',
                      width: width,
                    ),
                    _Stat(
                      value: '${all.map((e) => e.language).toSet().length}',
                      label: 'Languages',
                      width: width,
                    ),
                    _Stat(
                      value: all.isEmpty
                          ? '0%'
                          : '${(ready * 100 / all.length).round()}%',
                      label: 'Readiness',
                      width: width,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _Toolbar(
              languages: languages,
              difficulties: difficulties,
              language: languages.contains(language) ? language : 'All',
              difficulty: difficulties.contains(difficulty)
                  ? difficulty
                  : 'All',
              onSearch: (value) => setState(() => search = value),
              onLanguage: (value) => setState(() => language = value),
              onDifficulty: (value) => setState(() => difficulty = value),
              onRefresh: _load,
            ),
            const SizedBox(height: 14),
            if (_loading(context) && all.isEmpty)
              const _Empty(loading: true, message: 'Loading teaching content')
            else if (filtered.isEmpty)
              const _Empty(message: 'No content matches these filters.')
            else
              ...filtered.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ContentCard(
                    item: item,
                    accent: config.accent,
                    onReview: () => _review(item),
                    onPreview: () => _preview(item),
                    onCopy: () async {
                      await Clipboard.setData(ClipboardData(text: item.id));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Content ID copied.')),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InstructorPreviewDialog extends StatelessWidget {
  const _InstructorPreviewDialog({required this.item, required this.kind});

  final _Item item;
  final _Kind kind;

  String get typeLabel => switch (kind) {
    _Kind.lesson => 'Lesson',
    _Kind.simulation => 'Simulation',
    _Kind.quiz => 'Quiz',
    _Kind.puzzle => 'Puzzle',
  };

  List<({String label, String value})> get details {
    final common = <({String label, String value})>[
      (label: 'Topic', value: item.topic.isEmpty ? 'General' : item.topic),
      (label: 'Language', value: item.language),
      (label: 'Difficulty', value: item.difficulty),
      (label: 'Activity scope', value: item.metric),
    ];
    switch (kind) {
      case _Kind.lesson:
        final lesson = item.source as Lesson;
        return [
          ...common,
          (label: 'Learning objective', value: lesson.learningObjective),
          (
            label: 'Algorithm steps',
            value: lesson.algorithmSteps.isEmpty
                ? 'No steps supplied.'
                : lesson.algorithmSteps
                      .asMap()
                      .entries
                      .map((entry) => '${entry.key + 1}. ${entry.value}')
                      .join('\n'),
          ),
          (label: 'Runnable example', value: lesson.sourceCode),
          (label: 'Expected output', value: lesson.expectedOutput),
        ];
      case _Kind.simulation:
        final simulation = item.source as CodeSimulationActivity;
        return [
          ...common,
          (label: 'Learner instructions', value: simulation.instructions),
          (label: 'Starter code', value: simulation.starterCode),
          (label: 'Expected output', value: simulation.expectedOutput),
          (
            label: 'Validation coverage',
            value: '${simulation.effectiveTestCases.length} test case(s)',
          ),
        ];
      case _Kind.quiz:
        final quiz = item.source as Quiz;
        return [
          ...common,
          (label: 'Description', value: quiz.description),
          (label: 'Passing score', value: '${quiz.passingScore}%'),
          (label: 'Attempt limit', value: '${quiz.attemptLimit}'),
          (
            label: 'Delivery',
            value: quiz.shuffleQuestions
                ? 'Questions and choices are randomized.'
                : 'Questions use a fixed order.',
          ),
        ];
      case _Kind.puzzle:
        final puzzle = item.source as Puzzle;
        return [
          ...common,
          (label: 'Activity format', value: puzzle.type.label),
          if (puzzle.codeFlowData != null)
            (
              label: 'Correct code order',
              value: puzzle.codeFlowData!.correctOrder.isEmpty
                  ? 'No code tiles supplied.'
                  : puzzle.codeFlowData!.correctOrder.join('\n'),
            ),
          if (puzzle.outputPredictionData != null)
            (
              label: 'Code sample',
              value: puzzle.outputPredictionData!.codeSnippet,
            ),
          if (puzzle.debugBugData != null)
            (
              label: 'Debugging clue',
              value:
                  puzzle.debugBugData!.explanationHint ??
                  'Learners identify and correct the faulty line.',
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2857),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$typeLabel teaching preview',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(22),
              shrinkWrap: true,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(color: Color(0xFF53647E), height: 1.5),
                ),
                const SizedBox(height: 18),
                ...details
                    .where((entry) => entry.value.trim().isNotEmpty)
                    .map(
                      (entry) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F8FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCE6F3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.label,
                              style: const TextStyle(
                                color: Color(0xFF164BA5),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(entry.value),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to library'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.config});
  final _Config config;
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: config.accent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(config.icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.eyebrow.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .65),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                config.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                config.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .76),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.width = 180});
  final String value, label;
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD7E2F2)),
    ),
    child: Row(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.languages,
    required this.difficulties,
    required this.language,
    required this.difficulty,
    required this.onSearch,
    required this.onLanguage,
    required this.onDifficulty,
    required this.onRefresh,
  });
  final List<String> languages, difficulties;
  final String language, difficulty;
  final ValueChanged<String> onSearch, onLanguage, onDifficulty;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final searchBox = TextField(
        onChanged: onSearch,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search title or topic',
        ),
      );
      final filters = Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: language,
              decoration: const InputDecoration(labelText: 'Language'),
              items: languages
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => onLanguage(value ?? 'All'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: difficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: difficulties
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => onDifficulty(value ?? 'All'),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.outlined(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
      return size.maxWidth < 760
          ? Column(children: [searchBox, const SizedBox(height: 10), filters])
          : Row(
              children: [
                Expanded(flex: 2, child: searchBox),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: filters),
              ],
            );
    },
  );
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.item,
    required this.accent,
    required this.onReview,
    required this.onPreview,
    required this.onCopy,
  });
  final _Item item;
  final Color accent;
  final VoidCallback onReview, onPreview, onCopy;
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 900;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _Tag(item.language),
            _Tag(item.difficulty),
            _Tag(item.topic.isEmpty ? 'General' : item.topic),
            _Tag(item.metric),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF53647E), height: 1.4),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onReview,
          icon: const Icon(Icons.checklist),
          label: const Text('Review guide'),
        ),
        FilledButton.icon(
          onPressed: onPreview,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Learner preview'),
        ),
        IconButton.outlined(onPressed: onCopy, icon: const Icon(Icons.copy)),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E2F2)),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 12),
                _Ready(ready: item.ready),
                const SizedBox(height: 12),
                actions,
              ],
            )
          : Row(
              children: [
                Container(
                  width: 5,
                  height: 74,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: info),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Ready(ready: item.ready),
                    const SizedBox(height: 10),
                    actions,
                  ],
                ),
              ],
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F5FC),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(value, style: const TextStyle(fontSize: 11)),
  );
}

class _Ready extends StatelessWidget {
  const _Ready({required this.ready});
  final bool ready;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        ready ? Icons.verified : Icons.warning_amber,
        size: 18,
        color: ready ? const Color(0xFF0F9F6E) : const Color(0xFFD97706),
      ),
      const SizedBox(width: 6),
      Text(
        ready ? 'Ready for class' : 'Review recommended',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.loading = false});
  final String message;
  final bool loading;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        if (loading)
          const CircularProgressIndicator()
        else
          const Icon(Icons.search_off, size: 40),
        const SizedBox(height: 12),
        Text(message),
      ],
    ),
  );
}

class _Item {
  const _Item({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.difficulty,
    required this.topic,
    required this.metric,
    required this.ready,
    required this.source,
  });
  final String id, title, description, language, difficulty, topic, metric;
  final bool ready;
  final Object source;

  factory _Item.lesson(Lesson x) => _Item(
    id: x.id,
    title: x.title,
    description: x.description,
    language: x.language,
    difficulty: x.difficulty,
    topic: x.topic,
    metric: '${x.estimatedMinutes} min',
    ready:
        x.learningObjective.isNotEmpty &&
        x.algorithmSteps.isNotEmpty &&
        (x.sourceCode.isEmpty || x.compilerValidated),
    source: x,
  );
  factory _Item.simulation(CodeSimulationActivity x) => _Item(
    id: x.id,
    title: x.title,
    description: x.instructions,
    language: x.language,
    difficulty: x.difficulty,
    topic: x.topic,
    metric: '${x.effectiveTestCases.length} tests',
    ready: x.starterCode.isNotEmpty && x.expectedOutput.isNotEmpty,
    source: x,
  );
  factory _Item.quiz(Quiz x) => _Item(
    id: x.id,
    title: x.title,
    description: x.description,
    language: x.language,
    difficulty: x.difficulty,
    topic: x.topic,
    metric: '${x.totalItems} items',
    ready: x.totalItems >= 5 && x.passingScore > 0,
    source: x,
  );
  factory _Item.puzzle(Puzzle x) => _Item(
    id: x.id,
    title: x.title,
    description: x.description,
    language: x.language,
    difficulty: x.difficulty,
    topic: x.type.label,
    metric: '${x.xpReward} XP',
    ready: x.title.isNotEmpty && x.description.isNotEmpty,
    source: x,
  );
}

class _Config {
  const _Config({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.icon,
    required this.accent,
    required this.checks,
  });
  final String title, eyebrow, description;
  final IconData icon;
  final Color accent;
  final List<String> checks;
  factory _Config.of(_Kind kind) => switch (kind) {
    _Kind.lesson => const _Config(
      title: 'Lesson Library',
      eyebrow: 'Curriculum review',
      description:
          'Review objectives, explanations, examples, prerequisites, and compiler readiness before using a lesson in class.',
      icon: Icons.auto_stories,
      accent: Color(0xFF2563EB),
      checks: [
        'The objective is measurable and appropriate for the target year level.',
        'Examples match the selected programming language and topic.',
        'Runnable code is compiler-validated before publication.',
      ],
    ),
    _Kind.simulation => const _Config(
      title: 'Simulation Library',
      eyebrow: 'Practical activity review',
      description:
          'Check starter code, expected output, test coverage, hints, and error focus before learners run an activity.',
      icon: Icons.terminal,
      accent: Color(0xFF0891B2),
      checks: [
        'The activity aligns with a lesson and clear learning goal.',
        'Test cases cover normal and incorrect solutions.',
        'Feedback distinguishes syntax errors from logic errors.',
      ],
    ),
    _Kind.quiz => const _Config(
      title: 'Quiz Library',
      eyebrow: 'Assessment review',
      description:
          'Evaluate coverage, difficulty, passing score, and classroom suitability without creating an instructor attempt.',
      icon: Icons.fact_check,
      accent: Color(0xFF7C3AED),
      checks: [
        'Questions cover distinct concepts without repetition.',
        'Distractors are plausible and unambiguous.',
        'Passing score and attempts match the assessment purpose.',
      ],
    ),
    _Kind.puzzle => const _Config(
      title: 'Puzzle Library',
      eyebrow: 'Syntax activity review',
      description:
          'Inspect code tiles, clues, correct ordering, and difficulty before classroom use.',
      icon: Icons.extension,
      accent: Color(0xFF0F9F6E),
      checks: [
        'The correct sequence produces valid code.',
        'The clue supports learning without revealing the answer.',
        'Tile count matches the selected difficulty.',
      ],
    ),
  };
}
