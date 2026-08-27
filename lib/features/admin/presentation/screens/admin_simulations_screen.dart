import 'package:flutter/material.dart';
import 'package:pseudocode_apk/services/compiler_service.dart';
import 'package:pseudocode_apk/services/trusted_simulation_evaluator.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_simulation.dart';
import 'package:pseudocode_apk/features/admin/models/admin_lesson.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/student_content_preview_dialog.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_simulations_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_lessons_provider.dart';
import 'package:pseudocode_apk/models/code_simulation_activity.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _teal = Color(0xFF0891B2);
const _border = Color(0xFFE2E8F0);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

class AdminSimulationsScreen extends StatefulWidget {
  const AdminSimulationsScreen({super.key});

  @override
  State<AdminSimulationsScreen> createState() => _AdminSimulationsScreenState();
}

class _AdminSimulationsScreenState extends State<AdminSimulationsScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _languageFilter = 'All';
  String _statusFilter = 'All';
  String _focusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSimulationsProvider>().loadSimulations();
      context.read<AdminLessonsProvider>().loadLessons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Simulations',
      currentRoute: AppRoutes.adminSimulations,
      child: Consumer<AdminSimulationsProvider>(
        builder: (context, provider, _) {
          final lessons = context.watch<AdminLessonsProvider>().lessons;
          final lessonTitles = {
            for (final lesson in lessons) lesson.id: lesson.title,
          };
          final sims = provider.simulations
              .where(
                (s) =>
                    (_search.isEmpty ||
                        s.title.toLowerCase().contains(_search.toLowerCase()) ||
                        s.topic.toLowerCase().contains(
                          _search.toLowerCase(),
                        )) &&
                    (_languageFilter == 'All' ||
                        s.language == _languageFilter) &&
                    (_statusFilter == 'All' ||
                        (_statusFilter == 'Published' && s.isPublished) ||
                        (_statusFilter == 'Draft' && !s.isPublished) ||
                        (_statusFilter == 'Needs review' &&
                            !s.isReadyToPublish)) &&
                    (_focusFilter == 'All' || s.errorFocus == _focusFilter),
              )
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                count: provider.simulations.length,
                publishedCount: provider.simulations
                    .where((s) => s.isPublished)
                    .length,
                onNew: () => _showForm(context, provider),
              ),
              const SizedBox(height: 20),
              _SimulationOverview(
                simulations: provider.simulations,
                availableLessonIds: lessonTitles.keys.toSet(),
              ),
              const SizedBox(height: 16),
              if (provider.accessWarning != null) ...[
                _AccessWarning(message: provider.accessWarning!),
                const SizedBox(height: 16),
              ],
              _FilterBar(
                controller: _searchController,
                value: _search,
                onChanged: (v) => setState(() => _search = v),
                language: _languageFilter,
                status: _statusFilter,
                focus: _focusFilter,
                onLanguageChanged: (value) =>
                    setState(() => _languageFilter = value),
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value),
                onFocusChanged: (value) => setState(() => _focusFilter = value),
                onClear: () => setState(() {
                  _searchController.clear();
                  _search = '';
                  _languageFilter = 'All';
                  _statusFilter = 'All';
                  _focusFilter = 'All';
                }),
              ),
              const SizedBox(height: 16),
              if (provider.isLoading)
                const _LoadingState()
              else if (provider.error != null && provider.simulations.isEmpty)
                _ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadSimulations,
                )
              else if (sims.isEmpty)
                _EmptyState(
                  hasQuery: _search.isNotEmpty,
                  onNew: () => _showForm(context, provider),
                )
              else
                _SimulationsTable(
                  simulations: sims,
                  provider: provider,
                  lessonTitles: lessonTitles,
                  onEdit: (s) => _showForm(context, provider, s),
                  onView: (s) => _previewSimulation(context, s),
                ),
            ],
          );
        },
      ),
    );
  }

  void _previewSimulation(BuildContext context, AdminSimulation simulation) {
    showStudentSimulationPreview(context, simulation);
  }

  void _showForm(
    BuildContext context,
    AdminSimulationsProvider provider, [
    AdminSimulation? existing,
  ]) {
    if (existing == null) {
      _showLessonGenerator(context, provider);
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _SimulationFormDialog(existing: existing),
      ),
    );
  }

  void _showLessonGenerator(
    BuildContext context,
    AdminSimulationsProvider provider,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(
            value: context.read<AdminLessonsProvider>(),
          ),
        ],
        child: const _LessonSimulationGeneratorDialog(),
      ),
    );
  }
}

class _LessonSimulationGeneratorDialog extends StatefulWidget {
  const _LessonSimulationGeneratorDialog();

  @override
  State<_LessonSimulationGeneratorDialog> createState() =>
      _LessonSimulationGeneratorDialogState();
}

class _LessonSimulationGeneratorDialogState
    extends State<_LessonSimulationGeneratorDialog> {
  String? _lessonId;
  String _language = 'C++';
  bool _isGenerating = false;

  String _printProgram(String language, String output) {
    final escaped = output
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\r', '')
        .replaceAll('\n', r'\n');
    return switch (language) {
      'Java' =>
        'public class Main {\n  public static void main(String[] args) {\n    System.out.println("$escaped");\n  }\n}',
      'JavaScript' => 'console.log("$escaped");',
      _ =>
        '#include <iostream>\nusing namespace std;\n\nint main() {\n  cout << "$escaped" << endl;\n  return 0;\n}',
    };
  }

  AdminSimulation _buildDraft(AdminLesson lesson, String language) {
    final sameLanguage = lesson.language == language;
    final fallbackOutput = 'Lesson example: ${lesson.topic}';
    final output = sameLanguage && lesson.expectedOutput.trim().isNotEmpty
        ? lesson.expectedOutput.trim()
        : fallbackOutput;
    final sourceCode = sameLanguage && lesson.sourceCode.trim().isNotEmpty
        ? lesson.sourceCode
        : _printProgram(language, output);
    final hasRunnableExample =
        sourceCode.trim().isNotEmpty && output.isNotEmpty;
    final steps = lesson.algorithmSteps
        .asMap()
        .entries
        .map(
          (entry) => SimulationStep(
            stepNumber: entry.key + 1,
            description: entry.value,
            variableStates: const {},
          ),
        )
        .toList();
    final focus = lesson.errorFocus.toLowerCase().contains('syntax')
        ? 'Syntax'
        : 'Logic';

    return AdminSimulation(
      id: '',
      title: '${lesson.topic} in $language — Interactive Simulation',
      topic: lesson.topic,
      language: language,
      difficulty: lesson.difficulty,
      codeSnippet: sourceCode,
      executionSteps: steps,
      expectedOutput: output,
      explanation: lesson.summary.trim().isNotEmpty
          ? lesson.summary
          : lesson.description,
      xpReward: switch (lesson.difficulty.toLowerCase()) {
        'hard' => 30,
        'medium' => 25,
        _ => 20,
      },
      isPublished: false,
      linkedLessonId: lesson.id,
      stdin: sameLanguage ? lesson.standardInput : '',
      testCases: hasRunnableExample
          ? [
              SimulationTestCase(
                name: 'Lesson example',
                stdin: sameLanguage ? lesson.standardInput : '',
                expectedOutput: output,
              ),
            ]
          : const [],
      audiencePrograms: lesson.audiencePrograms,
      yearLevels: lesson.yearLevels,
      problemGoal: lesson.learningObjective,
      inputsDescription: !sameLanguage || lesson.standardInput.trim().isEmpty
          ? 'No standard input is required for the lesson example.'
          : 'Use the lesson standard input: ${lesson.standardInput.trim()}',
      algorithmSteps: lesson.algorithmSteps,
      keyConcepts: lesson.keyConcepts,
      commonMistakes: lesson.commonMistakes,
      hints: [
        if (lesson.introduction.trim().isNotEmpty) lesson.introduction.trim(),
        'Trace each statement in the same order as the lesson algorithm.',
        'Compare the variable state and output after every step.',
      ],
      errorFocus: focus,
      compilerValidated:
          sameLanguage && hasRunnableExample && lesson.compilerValidated,
      compilerValidatedAt: sameLanguage && hasRunnableExample
          ? lesson.compilerValidatedAt
          : null,
    );
  }

  Future<void> _generate(AdminLesson lesson) async {
    setState(() => _isGenerating = true);
    final provider = context.read<AdminSimulationsProvider>();
    final created = await provider.createSimulation(
      _buildDraft(lesson, _language),
    );
    if (!mounted) return;
    setState(() => _isGenerating = false);
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'The simulation draft could not be generated.',
          ),
        ),
      );
      provider.clearError();
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulation draft generated from “${lesson.title}”. Review and validate it before publishing.',
        ),
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonsProvider = context.watch<AdminLessonsProvider>();
    final lessons = lessonsProvider.lessons;
    final selectedLesson = lessons
        .where((lesson) => lesson.id == _lessonId)
        .firstOrNull;

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_navy, _teal]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_fix_high_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Create simulation from lesson',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a lesson and CoSci will prepare its simulation structure, code example, test case, algorithm trace, audience, and learning guidance.',
              style: TextStyle(color: _textSub, height: 1.45),
            ),
            const SizedBox(height: 18),
            if (lessonsProvider.isLoading)
              const LinearProgressIndicator()
            else if (lessons.isEmpty)
              const _AccessWarning(
                message:
                    'No lessons are available. Create or generate a lesson before creating a simulation.',
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _lessonId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Lesson *',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: lessons
                    .map(
                      (lesson) => DropdownMenuItem(
                        value: lesson.id,
                        child: Text(
                          '${lesson.language} • ${lesson.title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _lessonId = value;
                  final lesson = lessons
                      .where((candidate) => candidate.id == value)
                      .firstOrNull;
                  if (lesson != null) _language = lesson.language;
                }),
              ),
            if (selectedLesson != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_language),
                initialValue: _language,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Programming language *',
                  prefixIcon: Icon(Icons.code_rounded),
                  helperText:
                      'The runnable example and compiler test will use this language.',
                ),
                items: const ['C++', 'Java', 'JavaScript']
                    .map(
                      (language) => DropdownMenuItem(
                        value: language,
                        child: Text(language),
                      ),
                    )
                    .toList(),
                onChanged: _isGenerating
                    ? null
                    : (value) => setState(() => _language = value ?? 'C++'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedLesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_language • ${selectedLesson.difficulty} • ${selectedLesson.topic}',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedLesson.language != _language
                          ? 'CoSci will create a safe $_language runnable example while preserving this lesson’s topic and learning guidance.'
                          : selectedLesson.sourceCode.trim().isEmpty
                          ? 'The lesson has no runnable example yet. A structured draft will be created for completion.'
                          : 'The lesson code and expected output will become the first compiler test.',
                      style: const TextStyle(color: _textSub),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: selectedLesson == null || _isGenerating
              ? null
              : () => _generate(selectedLesson),
          icon: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_fix_high_rounded),
          label: Text(_isGenerating ? 'Generating…' : 'Generate simulation'),
        ),
      ],
    );
  }
}

class _AccessWarning extends StatelessWidget {
  const _AccessWarning({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF59E0B)),
    ),
    child: Row(
      children: [
        const Icon(Icons.security_rounded, color: Color(0xFFB45309)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.count,
    required this.publishedCount,
    required this.onNew,
  });
  final int count;
  final int publishedCount;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_teal, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.terminal_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulation Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '$count simulation${count == 1 ? '' : 's'}  ·  $publishedCount published',
                style: const TextStyle(fontSize: 13, color: _textSub),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onNew,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Simulation'),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.value,
    required this.controller,
    required this.onChanged,
    required this.language,
    required this.status,
    required this.focus,
    required this.onLanguageChanged,
    required this.onStatusChanged,
    required this.onFocusChanged,
    required this.onClear,
  });
  final String value;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String language;
  final String status;
  final String focus;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onFocusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by title or topic…',
              hintStyle: const TextStyle(fontSize: 13, color: _textSub),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: _textSub,
              ),
              suffixIcon: value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: _textSub,
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _blue, width: 1.5),
              ),
            ),
          ),
        ),
        _FilterDropdown(
          label: 'Language',
          value: language,
          values: const ['All', 'C++', 'Java', 'JavaScript'],
          onChanged: onLanguageChanged,
        ),
        _FilterDropdown(
          label: 'Status',
          value: status,
          values: const ['All', 'Published', 'Draft', 'Needs review'],
          onChanged: onStatusChanged,
        ),
        _FilterDropdown(
          label: 'Focus',
          value: focus,
          values: const ['All', 'Syntax', 'Logic', 'Syntax and Logic'],
          onChanged: onFocusChanged,
        ),
        if (value.isNotEmpty ||
            language != 'All' ||
            status != 'All' ||
            focus != 'All')
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 17),
            label: const Text('Clear'),
          ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      ),
      selectedItemBuilder: (context) => values
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (item) => onChanged(item!),
    ),
  );
}

class _SimulationOverview extends StatelessWidget {
  const _SimulationOverview({
    required this.simulations,
    required this.availableLessonIds,
  });
  final List<AdminSimulation> simulations;
  final Set<String> availableLessonIds;

  @override
  Widget build(BuildContext context) {
    final published = simulations.where((item) => item.isPublished).length;
    final validated = simulations
        .where((item) => item.compilerValidated)
        .length;
    final syntax = simulations
        .where((item) => item.errorFocus.contains('Syntax'))
        .length;
    final logic = simulations
        .where((item) => item.errorFocus.contains('Logic'))
        .length;
    final aligned = simulations
        .where((item) => availableLessonIds.contains(item.linkedLessonId))
        .length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _OverviewChip(
          Icons.account_tree_rounded,
          '$aligned lesson-aligned',
          const Color(0xFF0F766E),
        ),
        _OverviewChip(Icons.public_rounded, '$published published', _blue),
        _OverviewChip(
          Icons.verified_rounded,
          '$validated validated',
          const Color(0xFF059669),
        ),
        _OverviewChip(
          Icons.rule_rounded,
          '$syntax syntax-focused',
          const Color(0xFFD97706),
        ),
        _OverviewChip(
          Icons.psychology_alt_rounded,
          '$logic logic-focused',
          const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _SimulationsTable extends StatelessWidget {
  const _SimulationsTable({
    required this.simulations,
    required this.provider,
    required this.lessonTitles,
    required this.onEdit,
    required this.onView,
  });
  final List<AdminSimulation> simulations;
  final AdminSimulationsProvider provider;
  final Map<String, String> lessonTitles;
  final void Function(AdminSimulation) onEdit;
  final void Function(AdminSimulation) onView;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1380,
      child: Column(
        children: [
          // Header row
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 8), // dot
                SizedBox(width: 12),
                Expanded(flex: 5, child: _H('Title')),
                Expanded(flex: 3, child: _H('Topic')),
                SizedBox(width: 90, child: _H('Language')),
                SizedBox(width: 90, child: _H('Difficulty')),
                SizedBox(width: 120, child: _H('Focus')),
                SizedBox(width: 70, child: _H('Tests', center: true)),
                SizedBox(width: 90, child: _H('Readiness', center: true)),
                SizedBox(width: 70, child: _H('XP', center: true)),
                SizedBox(width: 90, child: _H('Status')),
                SizedBox(width: 150, child: _H('Actions', center: true)),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // Rows
          ...simulations.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return _SimRow(
              sim: s,
              linkedLessonTitle: lessonTitles[s.linkedLessonId],
              isLast: i == simulations.length - 1,
              onEdit: () => onEdit(s),
              onView: () => onView(s),
              onToggle: () async {
                await provider.togglePublished(s.id, !s.isPublished);
                if (provider.error != null && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(provider.error!)));
                  provider.clearError();
                }
              },
              onDelete: () async {
                final confirmed = await showAdminConfirmDialog(
                  context,
                  title: 'Delete Simulation',
                  message: 'Delete "${s.title}"? This cannot be undone.',
                );
                if (confirmed && context.mounted) {
                  await provider.deleteSimulation(s.id, s.title);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text, {this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  const _SimRow({
    required this.sim,
    required this.linkedLessonTitle,
    required this.isLast,
    required this.onEdit,
    required this.onView,
    required this.onToggle,
    required this.onDelete,
  });
  final AdminSimulation sim;
  final String? linkedLessonTitle;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Published dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sim.isPublished
                      ? const Color(0xFF059669)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(width: 12),

              // Title + language hint
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sim.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      linkedLessonTitle == null
                          ? 'Not linked to an available lesson'
                          : 'Lesson: $linkedLessonTitle',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: linkedLessonTitle == null
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF047857),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sim.expectedOutput.isNotEmpty)
                      Text(
                        'Output: ${sim.expectedOutput}',
                        style: const TextStyle(fontSize: 11, color: _textSub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Topic
              Expanded(
                flex: 3,
                child: Text(
                  sim.topic,
                  style: const TextStyle(fontSize: 12, color: _textSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Language badge
              SizedBox(width: 90, child: _LangBadge(label: sim.language)),

              // Difficulty badge
              SizedBox(width: 90, child: _DiffBadge(level: sim.difficulty)),

              SizedBox(
                width: 150,
                child: Text(
                  sim.errorFocus,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textSub,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(
                width: 70,
                child: Tooltip(
                  message:
                      '${sim.testCases.where((test) => !test.isHidden).length} visible, ${sim.testCases.where((test) => test.isHidden).length} hidden',
                  child: Text(
                    '${sim.testCases.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: 90,
                child: Tooltip(
                  message: sim.isReadyToPublish
                      ? 'Ready to publish'
                      : 'Missing: ${sim.readinessIssues.join(', ')}',
                  child: Text(
                    '${sim.readinessPercent}%',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: sim.isReadyToPublish
                          ? const Color(0xFF059669)
                          : sim.readinessPercent >= 70
                          ? const Color(0xFFD97706)
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),

              // XP
              SizedBox(
                width: 70,
                child: Text(
                  '${sim.xpReward} XP',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),

              // Status badge
              SizedBox(
                width: 90,
                child: _StatusBadge(isPublished: sim.isPublished),
              ),

              // Actions
              SizedBox(
                width: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionBtn(
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF0F766E),
                      tooltip: 'Preview simulation',
                      onTap: onView,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: sim.isPublished
                          ? Icons.unpublished_rounded
                          : Icons.publish_rounded,
                      color: sim.isPublished
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                      tooltip: sim.isPublished ? 'Unpublish' : 'Publish',
                      onTap: onToggle,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.edit_rounded,
                      color: _blue,
                      tooltip: 'Edit',
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFDC2626),
                      tooltip: 'Delete',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: _border),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED BADGES & ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.label});
  final String label;

  static const _map = {
    'Python': Color(0xFF3B82F6),
    'JavaScript': Color(0xFFCA8A04),
    'C': Color(0xFF6366F1),
    'C++': Color(0xFF8B5CF6),
    'PHP': Color(0xFF6B7280),
    'Dart': Color(0xFF0EA5E9),
    'Java': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final color = _map[label] ?? _blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (level) {
      'Easy' => (const Color(0xFF059669), const Color(0xFFDCFCE7)),
      'Medium' => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      'Hard' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      _ => (_textSub, const Color(0xFFF1F5F9)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPublished
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: isPublished
              ? const Color(0xFF059669)
              : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Text(
          isPublished ? 'Published' : 'Draft',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isPublished
                ? const Color(0xFF059669)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _navy, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Loading simulations…',
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
        ],
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
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.onNew});
  final bool hasQuery;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.terminal_rounded, size: 30, color: _navy),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery
                ? 'No simulations match your search.'
                : 'No simulations yet.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasQuery)
            Text(
              'Create your first simulation to get started.',
              style: const TextStyle(fontSize: 13, color: _textSub),
            ),
          const SizedBox(height: 20),
          if (!hasQuery)
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create Simulation'),
              style: FilledButton.styleFrom(backgroundColor: _navy),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _SimulationFormDialog extends StatefulWidget {
  const _SimulationFormDialog({this.existing});
  final AdminSimulation? existing;

  @override
  State<_SimulationFormDialog> createState() => _SimulationFormDialogState();
}

class _SimulationFormDialogState extends State<_SimulationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _snippetCtrl;
  late final TextEditingController _outputCtrl;
  late final TextEditingController _stdinCtrl;
  late final TextEditingController _hiddenInputCtrl;
  late final TextEditingController _hiddenOutputCtrl;
  final List<_ExtraTestCaseControllers> _extraCases = [];
  late final TextEditingController _explanationCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _linkedLessonCtrl;
  late final TextEditingController _goalCtrl;
  late final TextEditingController _inputsDescriptionCtrl;
  late final TextEditingController _algorithmCtrl;
  late final TextEditingController _conceptsCtrl;
  late final TextEditingController _mistakesCtrl;
  late final TextEditingController _hintsCtrl;
  late final TextEditingController _stepsCtrl;
  String _language = 'C++';
  String _difficulty = 'Easy';
  String _errorFocus = 'Logic';
  bool _isPublished = false;
  bool _compilerValidated = false;
  DateTime? _compilerValidatedAt;
  bool _isValidating = false;
  String? _validationMessage;
  late Set<String> _audiencePrograms;
  late Set<String> _yearLevels;

  static const _languages = ['C++', 'Java', 'JavaScript'];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _programs = [
    'BS Computer Science',
    'BS Information Technology',
    'BS Mathematics-CIT',
  ];
  static const _years = ['1st Year', '2nd Year'];
  bool get _isEdit => widget.existing != null;

  void _applyLesson(AdminLesson lesson) {
    setState(() {
      _linkedLessonCtrl.text = lesson.id;
      _topicCtrl.text = lesson.topic;
      _language = _languages.contains(lesson.language)
          ? lesson.language
          : 'C++';
      _difficulty = _difficulties.contains(lesson.difficulty)
          ? lesson.difficulty
          : 'Easy';
      _audiencePrograms = lesson.audiencePrograms.toSet();
      _yearLevels = lesson.yearLevels.toSet();
      _goalCtrl.text = lesson.learningObjective;
      _algorithmCtrl.text = lesson.algorithmSteps.join('\n');
      _conceptsCtrl.text = lesson.keyConcepts.join(', ');
      _mistakesCtrl.text = lesson.commonMistakes;
      if (!_isEdit || _titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = '${lesson.title} — Code Simulation';
      }
      if (_explanationCtrl.text.trim().isEmpty) {
        _explanationCtrl.text = lesson.summary.trim().isNotEmpty
            ? lesson.summary
            : lesson.description;
      }
      if (_snippetCtrl.text.trim().isEmpty &&
          lesson.sourceCode.trim().isNotEmpty) {
        _snippetCtrl.text = lesson.sourceCode;
        _stdinCtrl.text = lesson.standardInput;
        _outputCtrl.text = lesson.expectedOutput;
      }
      _compilerValidated = false;
      _compilerValidatedAt = null;
      _validationMessage =
          'Lesson details applied. Validate the simulation tests before publishing.';
    });
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _topicCtrl = TextEditingController(text: e?.topic ?? '');
    _snippetCtrl = TextEditingController(text: e?.codeSnippet ?? '');
    _outputCtrl = TextEditingController(text: e?.expectedOutput ?? '');
    _stdinCtrl = TextEditingController(text: e?.stdin ?? '');
    final hiddenCases =
        e?.testCases.where((test) => test.isHidden).toList() ?? [];
    _hiddenInputCtrl = TextEditingController(
      text: hiddenCases.isEmpty ? '' : hiddenCases.first.stdin,
    );
    _hiddenOutputCtrl = TextEditingController(
      text: hiddenCases.isEmpty ? '' : hiddenCases.first.expectedOutput,
    );
    var visibleConsumed = false;
    var hiddenConsumed = false;
    for (final test in e?.testCases ?? const <SimulationTestCase>[]) {
      if (!test.isHidden && !visibleConsumed) {
        visibleConsumed = true;
        continue;
      }
      if (test.isHidden && !hiddenConsumed) {
        hiddenConsumed = true;
        continue;
      }
      _extraCases.add(_ExtraTestCaseControllers.fromTest(test));
    }
    _explanationCtrl = TextEditingController(text: e?.explanation ?? '');
    _xpCtrl = TextEditingController(text: '${e?.xpReward ?? 20}');
    _linkedLessonCtrl = TextEditingController(text: e?.linkedLessonId ?? '');
    _goalCtrl = TextEditingController(text: e?.problemGoal ?? '');
    _inputsDescriptionCtrl = TextEditingController(
      text: e?.inputsDescription ?? '',
    );
    _algorithmCtrl = TextEditingController(
      text: e?.algorithmSteps.join('\n') ?? '',
    );
    _conceptsCtrl = TextEditingController(
      text: e?.keyConcepts.join(', ') ?? '',
    );
    _mistakesCtrl = TextEditingController(text: e?.commonMistakes ?? '');
    _hintsCtrl = TextEditingController(text: e?.hints.join('\n') ?? '');
    _stepsCtrl = TextEditingController(
      text:
          e?.executionSteps
              .map((step) {
                final states = step.variableStates.entries
                    .map((entry) => '${entry.key}=${entry.value}')
                    .join(', ');
                return '${step.description}${states.isEmpty ? '' : ' | $states'}';
              })
              .join('\n') ??
          '',
    );
    _language = _languages.contains(e?.language) ? e!.language : 'C++';
    _difficulty = e?.difficulty ?? 'Easy';
    _errorFocus = e?.errorFocus ?? 'Logic';
    _isPublished = e?.isPublished ?? false;
    _audiencePrograms = {...?e?.audiencePrograms};
    _yearLevels = {...?e?.yearLevels};
    _compilerValidated = e?.compilerValidated ?? false;
    _compilerValidatedAt = e?.compilerValidatedAt;
    for (final controller in [
      _snippetCtrl,
      _outputCtrl,
      _stdinCtrl,
      _hiddenInputCtrl,
      _hiddenOutputCtrl,
    ]) {
      controller.addListener(_invalidateValidation);
    }
  }

  void _invalidateValidation() {
    if (!_compilerValidated || !mounted) return;
    setState(() {
      _compilerValidated = false;
      _compilerValidatedAt = null;
      _validationMessage = 'Code or test data changed. Validate again.';
    });
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _topicCtrl,
      _snippetCtrl,
      _outputCtrl,
      _stdinCtrl,
      _hiddenInputCtrl,
      _hiddenOutputCtrl,
      _explanationCtrl,
      _xpCtrl,
      _linkedLessonCtrl,
      _goalCtrl,
      _inputsDescriptionCtrl,
      _algorithmCtrl,
      _conceptsCtrl,
      _mistakesCtrl,
      _hintsCtrl,
      _stepsCtrl,
    ]) {
      c.dispose();
    }
    for (final test in _extraCases) {
      test.dispose();
    }
    super.dispose();
  }

  List<String> _items(TextEditingController controller) => controller.text
      .split(RegExp(r'\r?\n|,'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  List<SimulationStep> _executionSteps() => _stepsCtrl.text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList()
      .asMap()
      .entries
      .map((entry) {
        final parts = entry.value.split('|');
        final states = <String, String>{};
        if (parts.length > 1) {
          for (final pair in parts.sublist(1).join('|').split(',')) {
            final split = pair.split('=');
            if (split.length >= 2 && split.first.trim().isNotEmpty) {
              states[split.first.trim()] = split.sublist(1).join('=').trim();
            }
          }
        }
        return SimulationStep(
          stepNumber: entry.key + 1,
          description: parts.first.trim(),
          variableStates: states,
        );
      })
      .toList();

  List<SimulationTestCase> _buildTestCases() => [
    SimulationTestCase(
      name: 'Visible test',
      stdin: _stdinCtrl.text,
      expectedOutput: _outputCtrl.text.trim(),
    ),
    if (_hiddenOutputCtrl.text.trim().isNotEmpty)
      SimulationTestCase(
        name: 'Hidden test',
        stdin: _hiddenInputCtrl.text,
        expectedOutput: _hiddenOutputCtrl.text.trim(),
        isHidden: true,
      ),
    ..._extraCases
        .where((test) => test.output.text.trim().isNotEmpty)
        .map(
          (test) => SimulationTestCase(
            name: test.name.text.trim().isEmpty
                ? 'Additional test'
                : test.name.text.trim(),
            stdin: test.input.text,
            expectedOutput: test.output.text.trim(),
            isHidden: test.isHidden,
          ),
        ),
  ];

  Future<bool> _validateTests(List<SimulationTestCase> testCases) async {
    if (_snippetCtrl.text.trim().isEmpty || testCases.isEmpty) {
      setState(
        () => _validationMessage = 'Add code and at least one test case.',
      );
      return false;
    }
    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });
    for (final testCase in testCases) {
      final result = await const CompilerService().execute(
        language: ProgrammingLanguageX.fromLabel(_language),
        sourceCode: _snippetCtrl.text,
        stdin: testCase.stdin,
      );
      if (!mounted) return false;
      if (!result.succeeded ||
          _normalize(result.output) != _normalize(testCase.expectedOutput)) {
        setState(() {
          _isValidating = false;
          _compilerValidated = false;
          _compilerValidatedAt = null;
          _validationMessage =
              '${testCase.name} failed: ${result.message}${result.output.isEmpty ? '' : ' Actual output: ${result.output}'}';
        });
        return false;
      }
    }
    setState(() {
      _isValidating = false;
      _compilerValidated = true;
      _compilerValidatedAt = DateTime.now();
      _validationMessage =
          'All ${testCases.length} compiler test${testCases.length == 1 ? '' : 's'} passed.';
    });
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final lessons = context.read<AdminLessonsProvider>().lessons;
    final linkedLesson = lessons
        .where((lesson) => lesson.id == _linkedLessonCtrl.text.trim())
        .firstOrNull;
    if (linkedLesson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a lesson that is still available.'),
        ),
      );
      return;
    }
    if (_audiencePrograms.isEmpty || _yearLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one eligible program and year level.'),
        ),
      );
      return;
    }
    if (_linkedLessonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select the lesson this simulation practices.'),
        ),
      );
      return;
    }
    final testCases = _buildTestCases();
    if (_isPublished) {
      final hasHidden = testCases.any((test) => test.isHidden);
      if (hasHidden && !TrustedSimulationEvaluator.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot publish hidden tests until SIMULATION_EVALUATOR_URL is configured.',
            ),
          ),
        );
        return;
      }
      if (!await _validateTests(testCases)) return;
      if (!mounted) return;
    }
    final provider = context.read<AdminSimulationsProvider>();
    final sim = AdminSimulation(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      topic: linkedLesson.topic,
      language: linkedLesson.language,
      difficulty: _difficulty,
      codeSnippet: _snippetCtrl.text.trim(),
      executionSteps: _executionSteps(),
      expectedOutput: _outputCtrl.text.trim(),
      explanation: _explanationCtrl.text.trim(),
      xpReward: int.tryParse(_xpCtrl.text) ?? 20,
      isPublished: _isPublished,
      linkedLessonId: linkedLesson.id,
      stdin: _stdinCtrl.text,
      testCases: testCases,
      audiencePrograms: linkedLesson.audiencePrograms,
      yearLevels: linkedLesson.yearLevels,
      problemGoal: _goalCtrl.text.trim(),
      inputsDescription: _inputsDescriptionCtrl.text.trim(),
      algorithmSteps: _items(_algorithmCtrl),
      keyConcepts: _items(_conceptsCtrl),
      commonMistakes: _mistakesCtrl.text.trim(),
      hints: _items(_hintsCtrl),
      errorFocus: _errorFocus,
      compilerValidated: _compilerValidated,
      compilerValidatedAt: _compilerValidatedAt,
    );
    final ok = _isEdit
        ? await provider.updateSimulation(sim)
        : await provider.createSimulation(sim);
    if (ok && mounted) Navigator.pop(context);
  }

  String _normalize(String value) => value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminSimulationsProvider>();
    final lessonsProvider = context.watch<AdminLessonsProvider>();
    final lessons = lessonsProvider.lessons;
    final selectedLessonId =
        lessons.any((lesson) => lesson.id == _linkedLessonCtrl.text)
        ? _linkedLessonCtrl.text
        : null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.terminal_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Simulation' : 'New Simulation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedLessonId),
                        initialValue: selectedLessonId,
                        decoration: const InputDecoration(
                          labelText: 'Related lesson *',
                          helperText:
                              'Topic, language, difficulty, audience, and learning guidance are inherited from the lesson.',
                          prefixIcon: Icon(Icons.menu_book_rounded),
                        ),
                        isExpanded: true,
                        items: lessons
                            .map(
                              (lesson) => DropdownMenuItem(
                                value: lesson.id,
                                child: Text(
                                  '${lesson.language} • ${lesson.title}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        validator: (value) =>
                            value == null ? 'Select an available lesson' : null,
                        onChanged: (id) {
                          if (id == null) return;
                          _applyLesson(
                            lessons.firstWhere((lesson) => lesson.id == id),
                          );
                        },
                      ),
                      if (lessonsProvider.isLoading) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(minHeight: 2),
                      ] else if (lessons.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Create or generate lessons first. Every simulation must support an available lesson.',
                          style: TextStyle(color: Color(0xFFB45309)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _field(
                        'Title',
                        _titleCtrl,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _field('Topic', _topicCtrl),
                      const SizedBox(height: 14),
                      _field(
                        'Problem goal',
                        _goalCtrl,
                        maxLines: 2,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'A learner-facing goal is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Inputs and constraints',
                        _inputsDescriptionCtrl,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Algorithm steps',
                        _algorithmCtrl,
                        maxLines: 4,
                        hint: 'One algorithm step per line',
                        validator: (_) => _items(_algorithmCtrl).isEmpty
                            ? 'Add at least one algorithm step'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'Key concepts',
                              _conceptsCtrl,
                              hint: 'loops, conditions, variables',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _errorFocus,
                              decoration: const InputDecoration(
                                labelText: 'Learning focus',
                              ),
                              items:
                                  const ['Syntax', 'Logic', 'Syntax and Logic']
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) =>
                                  setState(() => _errorFocus = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Progressive hints',
                        _hintsCtrl,
                        maxLines: 4,
                        hint: 'One hint per line, from general to specific',
                      ),
                      const SizedBox(height: 14),
                      _field('Common mistakes', _mistakesCtrl, maxLines: 3),
                      const SizedBox(height: 14),
                      _field(
                        'Execution trace steps',
                        _stepsCtrl,
                        maxLines: 6,
                        hint: 'Description | variable=value, output=value',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _language,
                              decoration: const InputDecoration(
                                labelText: 'Language',
                              ),
                              borderRadius: BorderRadius.circular(10),
                              items: _languages
                                  .map(
                                    (l) => DropdownMenuItem(
                                      value: l,
                                      child: Text(l),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _language = v!),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _difficulty,
                              decoration: const InputDecoration(
                                labelText: 'Difficulty',
                              ),
                              borderRadius: BorderRadius.circular(10),
                              items: _difficulties
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _difficulty = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Code Snippet',
                        _snippetCtrl,
                        maxLines: 5,
                        hint: 'Enter the code to simulate',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Source code is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Expected Output',
                        _outputCtrl,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Expected output is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Program Input (stdin, optional)',
                        _stdinCtrl,
                        maxLines: 3,
                        hint: 'Input passed to the program during execution',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Hidden validation case',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _field(
                        'Hidden Input (optional)',
                        _hiddenInputCtrl,
                        maxLines: 2,
                        hint: 'Learners will not see this input',
                      ),
                      const SizedBox(height: 10),
                      _field(
                        'Hidden Expected Output (optional)',
                        _hiddenOutputCtrl,
                        maxLines: 2,
                        hint:
                            'Used to check whether the algorithm handles another case',
                      ),
                      const SizedBox(height: 10),
                      ..._extraCases.asMap().entries.map((entry) {
                        final index = entry.key;
                        final test = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _field(
                                        'Test case name',
                                        test.name,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove test case',
                                      onPressed: () => setState(() {
                                        final removed = _extraCases.removeAt(
                                          index,
                                        );
                                        removed.dispose();
                                      }),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _field(
                                  'Input (stdin)',
                                  test.input,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 8),
                                _field(
                                  'Expected output',
                                  test.output,
                                  maxLines: 2,
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Hide this case from learners',
                                  ),
                                  value: test.isHidden,
                                  onChanged: (value) =>
                                      setState(() => test.isHidden = value),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _extraCases.add(
                            _ExtraTestCaseControllers.empty(),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add another test case'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _compilerValidated
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _compilerValidated
                                ? const Color(0xFFA7F3D0)
                                : _border,
                          ),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isValidating
                                  ? null
                                  : () => _validateTests(_buildTestCases()),
                              icon: _isValidating
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _compilerValidated
                                          ? Icons.verified_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                              label: Text(
                                _compilerValidated
                                    ? 'Validated'
                                    : 'Validate all tests',
                              ),
                            ),
                            Text(
                              _validationMessage ??
                                  'Run every visible and hidden case before publishing.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _compilerValidated
                                    ? const Color(0xFF047857)
                                    : _textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field('Explanation', _explanationCtrl, maxLines: 3),
                      const SizedBox(height: 14),
                      Text(
                        'Learner audience',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Leave a group unselected to make the activity available to all supported learners.',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _programs
                            .map(
                              (program) => FilterChip(
                                label: Text(program),
                                selected: _audiencePrograms.contains(program),
                                onSelected: (selected) => setState(
                                  () => selected
                                      ? _audiencePrograms.add(program)
                                      : _audiencePrograms.remove(program),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _years
                            .map(
                              (year) => FilterChip(
                                label: Text(year),
                                selected: _yearLevels.contains(year),
                                onSelected: (selected) => setState(
                                  () => selected
                                      ? _yearLevels.add(year)
                                      : _yearLevels.remove(year),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'XP Reward',
                        _xpCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Switch(
                            value: _isPublished,
                            onChanged: (v) => setState(() => _isPublished = v),
                            activeThumbColor: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isPublished
                                  ? const Color(0xFF059669)
                                  : _textSub,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  OutlinedButton(
                    onPressed: provider.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: provider.isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: provider.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEdit ? 'Save Changes' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
}

class _ExtraTestCaseControllers {
  _ExtraTestCaseControllers({
    required this.name,
    required this.input,
    required this.output,
    required this.isHidden,
  });

  factory _ExtraTestCaseControllers.empty() => _ExtraTestCaseControllers(
    name: TextEditingController(),
    input: TextEditingController(),
    output: TextEditingController(),
    isHidden: true,
  );

  factory _ExtraTestCaseControllers.fromTest(SimulationTestCase test) =>
      _ExtraTestCaseControllers(
        name: TextEditingController(text: test.name),
        input: TextEditingController(text: test.stdin),
        output: TextEditingController(text: test.expectedOutput),
        isHidden: test.isHidden,
      );

  final TextEditingController name;
  final TextEditingController input;
  final TextEditingController output;
  bool isHidden;

  void dispose() {
    name.dispose();
    input.dispose();
    output.dispose();
  }
}
