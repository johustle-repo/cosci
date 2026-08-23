import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_audience_selector.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_quiz.dart';
import 'package:pseudocode_apk/features/admin/models/admin_lesson.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/student_content_preview_dialog.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_quizzes_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_lessons_provider.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _purple = Color(0xFF7C3AED);
const _border = Color(0xFFE2E8F0);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

class AdminQuizzesScreen extends StatefulWidget {
  const AdminQuizzesScreen({super.key});

  @override
  State<AdminQuizzesScreen> createState() => _AdminQuizzesScreenState();
}

class _AdminQuizzesScreenState extends State<AdminQuizzesScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminQuizzesProvider>().loadQuizzes();
      context.read<AdminLessonsProvider>().loadLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Quizzes',
      currentRoute: AppRoutes.adminQuizzes,
      child: Consumer<AdminQuizzesProvider>(
        builder: (context, provider, _) {
          final quizzes = provider.quizzes
              .where(
                (q) =>
                    _search.isEmpty ||
                    q.title.toLowerCase().contains(_search.toLowerCase()) ||
                    q.topic.toLowerCase().contains(_search.toLowerCase()),
              )
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                count: provider.quizzes.length,
                publishedCount: provider.quizzes
                    .where((q) => q.isPublished)
                    .length,
                onNew: () => _showQuizForm(context, provider),
              ),
              const SizedBox(height: 20),
              _SearchBar(
                value: _search,
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 16),
              if (provider.isLoading)
                const _LoadingState()
              else if (provider.error != null && provider.quizzes.isEmpty)
                _ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadQuizzes,
                )
              else if (quizzes.isEmpty)
                _EmptyState(
                  hasQuery: _search.isNotEmpty,
                  onNew: () => _showQuizForm(context, provider),
                )
              else
                _QuizzesTable(
                  quizzes: quizzes,
                  provider: provider,
                  onEdit: (q) => _showQuizForm(context, provider, q),
                  onView: (q) => _previewQuiz(context, provider, q),
                  onManageQuestions: (q) =>
                      _showQuestionsDialog(context, provider, q),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _previewQuiz(
    BuildContext context,
    AdminQuizzesProvider provider,
    AdminQuiz quiz,
  ) async {
    await provider.loadQuestions(quiz.id);
    if (!context.mounted) return;
    if (provider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
      provider.clearError();
      return;
    }
    await showStudentQuizPreview(
      context,
      quiz.copyWith(questions: List.of(provider.questions)),
    );
  }

  void _showQuizForm(
    BuildContext context,
    AdminQuizzesProvider provider, [
    AdminQuiz? existing,
  ]) {
    if (existing == null) {
      _showLessonQuizGenerator(context, provider);
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _QuizFormDialog(existing: existing),
      ),
    );
  }

  void _showLessonQuizGenerator(
    BuildContext context,
    AdminQuizzesProvider provider,
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
        child: const _LessonQuizGeneratorDialog(),
      ),
    );
  }

  void _showQuestionsDialog(
    BuildContext context,
    AdminQuizzesProvider provider,
    AdminQuiz quiz,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _QuizQuestionsDialog(quiz: quiz),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _LessonQuizGeneratorDialog extends StatefulWidget {
  const _LessonQuizGeneratorDialog();

  @override
  State<_LessonQuizGeneratorDialog> createState() =>
      _LessonQuizGeneratorDialogState();
}

class _LessonQuizGeneratorDialogState
    extends State<_LessonQuizGeneratorDialog> {
  String? _lessonId;
  int _itemCount = 5;
  String _difficultyOverride = 'Match lesson';
  bool _isGenerating = false;

  String _effectiveDifficulty(AdminLesson lesson) =>
      _difficultyOverride == 'Match lesson'
      ? lesson.difficulty
      : _difficultyOverride;

  List<String> _options(String correct, Iterable<String> candidates) {
    final values = <String>[correct];
    for (final value in candidates) {
      final clean = value.trim();
      if (clean.isNotEmpty && !values.contains(clean)) values.add(clean);
      if (values.length == 4) break;
    }
    const fallback = [
      'It skips the required processing steps.',
      'It changes the program language automatically.',
      'It always produces a syntax error.',
      'It removes all variables from the program.',
    ];
    for (final value in fallback) {
      if (values.length == 4) break;
      if (!values.contains(value)) values.add(value);
    }
    return values;
  }

  String _quizPhrase(String value, {int maxLength = 150}) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return '';
    final sentence =
        RegExp(r'^.*?[.!?](?:\s|$)').firstMatch(clean)?.group(0)?.trim() ??
        clean;
    if (sentence.length <= maxLength) return sentence;
    final clipped = sentence.substring(0, maxLength);
    final boundary = clipped.lastIndexOf(' ');
    return '${clipped.substring(0, boundary > 70 ? boundary : maxLength).trim()}…';
  }

  List<String> _clearOptions(String correct, Iterable<String> distractors) {
    final answer = _quizPhrase(correct);
    final result = <String>[answer];
    final seen = <String>{answer.toLowerCase()};
    for (final candidate in distractors) {
      final value = _quizPhrase(candidate);
      if (value.isNotEmpty && seen.add(value.toLowerCase())) result.add(value);
      if (result.length == 4) break;
    }
    const fallbacks = [
      'Skip validation and assume the result is correct.',
      'Replace the algorithm with unrelated instructions.',
      'Ignore the input and guess the final output.',
      'Remove every variable from the program.',
    ];
    for (final value in fallbacks) {
      if (result.length == 4) break;
      if (seen.add(value.toLowerCase())) result.add(value);
    }
    return result;
  }

  List<AdminQuizQuestion> _questions(AdminLesson lesson) {
    final concepts =
        (lesson.keyConcepts.isEmpty
                ? <String>[lesson.topic]
                : lesson.keyConcepts)
            .map(_quizPhrase)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();
    final steps = lesson.algorithmSteps
        .map(_quizPhrase)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final prerequisites = lesson.prerequisites
        .map(_quizPhrase)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final bank = <AdminQuizQuestion>[];

    void addQuestion({
      required String text,
      required String answer,
      required Iterable<String> distractors,
      required String explanation,
      String? codeSnippet,
    }) {
      final question = _quizPhrase(text, maxLength: 220);
      final correct = _quizPhrase(answer);
      if (question.isEmpty || correct.isEmpty) return;
      if (bank.any(
        (item) => item.questionText.toLowerCase() == question.toLowerCase(),
      )) {
        return;
      }
      final options = _clearOptions(correct, distractors);
      if (options.length != 4 || !options.contains(correct)) return;
      bank.add(
        AdminQuizQuestion(
          id: '',
          questionType: 'multiple_choice',
          questionText: question,
          options: options,
          correctAnswer: correct,
          sortOrder: bank.length + 1,
          codeSnippet: codeSnippet,
          explanation: _quizPhrase(explanation, maxLength: 240),
        ),
      );
    }

    final objective = lesson.learningObjective.trim().isEmpty
        ? lesson.description
        : lesson.learningObjective;
    addQuestion(
      text:
          'Which outcome best describes what learners should achieve after this lesson?',
      answer: objective,
      distractors: const [
        'Memorize the example without explaining how it works.',
        'Skip testing and assume that the program is correct.',
        'Replace the lesson algorithm with unrelated statements.',
      ],
      explanation:
          'This is the measurable learning objective stated in the lesson.',
    );
    addQuestion(
      text: 'Which topic is the primary focus of this lesson?',
      answer: lesson.topic,
      distractors: concepts.followedBy(const [
        'Computer hardware repair',
        'Network cable installation',
        'Graphic layout design',
      ]),
      explanation: 'The lesson is organized around ${lesson.topic}.',
    );
    if (steps.isNotEmpty) {
      addQuestion(
        text:
            'Before writing the final code, what should the learner do first?',
        answer: steps.first,
        distractors: steps.skip(1).followedBy(const [
          'Guess the final output without tracing the solution.',
          'Publish the program before checking it.',
        ]),
        explanation:
            'This is the first documented step in the lesson procedure.',
      );
    }
    if (lesson.expectedOutput.trim().isNotEmpty) {
      addQuestion(
        text:
            'After the lesson example runs successfully, which output should appear?',
        answer: lesson.expectedOutput,
        distractors: const [
          'No output is displayed.',
          'A compilation error appears.',
          'The result is undefined.',
        ],
        explanation:
            'The answer matches the expected output verified for the example.',
        codeSnippet: lesson.sourceCode.trim().isEmpty
            ? null
            : lesson.sourceCode,
      );
    }
    addQuestion(
      text:
          'Which action is most likely to cause the beginner error discussed in this lesson?',
      answer: lesson.commonMistakes.trim().isEmpty
          ? 'Skipping the required algorithm steps.'
          : lesson.commonMistakes,
      distractors: const [
        'Trace each operation in order.',
        'Compare the actual and expected output.',
        'Test the program with a valid input.',
      ],
      explanation: lesson.commonMistakes.trim().isEmpty
          ? 'Skipping required steps makes the solution unreliable.'
          : lesson.commonMistakes,
    );

    for (var index = 0; index < steps.length; index++) {
      final position = 'Step ${index + 1}';
      addQuestion(
        text: 'Where does “${steps[index]}” belong in the lesson procedure?',
        answer: position,
        distractors: List.generate(
          steps.length.clamp(4, 8),
          (item) => 'Step ${item + 1}',
        ).where((value) => value != position),
        explanation: 'The lesson places this action at $position.',
      );
      if (index + 1 < steps.length) {
        addQuestion(
          text: 'What should happen immediately after “${steps[index]}”?',
          answer: steps[index + 1],
          distractors: steps.where((value) => value != steps[index + 1]),
          explanation:
              'This answer follows the documented sequence of the algorithm.',
        );
      }
    }

    for (final prerequisite in prerequisites) {
      addQuestion(
        text:
            'Which prior skill helps a learner understand ${lesson.topic} before starting?',
        answer: prerequisite,
        distractors: prerequisites
            .where((value) => value != prerequisite)
            .followedBy(const [
              'Advanced hardware diagnostics',
              'Graphic asset composition',
              'Physical network installation',
            ]),
        explanation: 'The lesson identifies this as prerequisite knowledge.',
      );
    }

    for (var index = 0; index < concepts.length; index++) {
      addQuestion(
        text:
            'Which term is identified as concept ${index + 1} in the ${lesson.topic} lesson?',
        answer: concepts[index],
        distractors: concepts
            .where((value) => value != concepts[index])
            .followedBy(const [
              'Hardware replacement',
              'Cable termination',
              'Page layout styling',
            ]),
        explanation:
            '${concepts[index]} is one of the lesson’s stated key concepts.',
      );
    }

    if (bank.isEmpty) {
      return _legacyQuestions(lesson).take(_itemCount).toList();
    }
    return bank.take(_itemCount).toList();
  }

  List<AdminQuizQuestion> _legacyQuestions(AdminLesson lesson) {
    final concepts = lesson.keyConcepts.isEmpty
        ? [lesson.topic]
        : lesson.keyConcepts;
    final steps = lesson.algorithmSteps;
    final objective = lesson.learningObjective.trim().isEmpty
        ? lesson.description.trim()
        : lesson.learningObjective.trim();
    final firstStep = steps.isEmpty
        ? 'Review the problem and identify the required result.'
        : steps.first;
    final expected = lesson.expectedOutput.trim();
    final mistake = lesson.commonMistakes.trim().isEmpty
        ? 'Ignoring the required order of the algorithm steps.'
        : lesson.commonMistakes.trim();

    final questions = <AdminQuizQuestion>[
      AdminQuizQuestion(
        id: '',
        questionType: 'multiple_choice',
        questionText: 'What is the main learning goal of this lesson?',
        options: _options(objective, [
          'Memorize code without understanding its behavior.',
          'Replace the algorithm with unrelated statements.',
          'Avoid testing the program output.',
        ]),
        correctAnswer: objective,
        sortOrder: 1,
        explanation: lesson.summary,
      ),
      AdminQuizQuestion(
        id: '',
        questionType: 'multiple_choice',
        questionText: 'Which step should be performed first?',
        options: _options(
          firstStep,
          steps.skip(1).followedBy([
            'Publish the result before checking it.',
            'Skip directly to the final output.',
          ]),
        ),
        correctAnswer: firstStep,
        sortOrder: 2,
        explanation:
            'The algorithm must follow the sequence taught in the lesson.',
      ),
      AdminQuizQuestion(
        id: '',
        questionType: 'multiple_choice',
        questionText: 'Which concept is directly covered by this lesson?',
        options: _options(
          concepts.first,
          concepts.skip(1).followedBy([
            'Unrelated hardware configuration',
            'Graphic design composition',
            'Network cable installation',
          ]),
        ),
        correctAnswer: concepts.first,
        sortOrder: 3,
        explanation: 'This concept is listed in the lesson’s key concepts.',
      ),
      if (expected.isNotEmpty)
        AdminQuizQuestion(
          id: '',
          questionType: 'multiple_choice',
          questionText: 'What is the expected output of the lesson example?',
          options: _options(expected, [
            'No output',
            'Compilation failed',
            'Undefined result',
          ]),
          correctAnswer: expected,
          sortOrder: 4,
          codeSnippet: lesson.sourceCode.trim().isEmpty
              ? null
              : lesson.sourceCode,
          explanation: 'This matches the validated example in the lesson.',
        ),
      AdminQuizQuestion(
        id: '',
        questionType: 'multiple_choice',
        questionText: 'Which mistake should learners avoid?',
        options: _options(mistake, [
          'Tracing each statement carefully.',
          'Checking the expected output.',
          'Following the algorithm in order.',
        ]),
        correctAnswer: mistake,
        sortOrder: expected.isEmpty ? 4 : 5,
        explanation: lesson.commonMistakes,
      ),
    ];
    var stepIndex = 0;
    var conceptIndex = 0;
    while (questions.length < _itemCount) {
      final number = questions.length + 1;
      if (steps.isNotEmpty && number.isEven) {
        final correct = steps[stepIndex % steps.length];
        questions.add(
          AdminQuizQuestion(
            id: '',
            questionType: 'multiple_choice',
            questionText:
                'Which statement represents algorithm step ${(stepIndex % steps.length) + 1}?',
            options: _options(
              correct,
              steps.where((step) => step != correct).followedBy([
                'Skip the algorithm and guess the output.',
                'Remove the required condition from the program.',
              ]),
            ),
            correctAnswer: correct,
            sortOrder: number,
            explanation: 'This step follows the lesson’s documented algorithm.',
          ),
        );
        stepIndex++;
      } else {
        final correct = concepts[conceptIndex % concepts.length];
        questions.add(
          AdminQuizQuestion(
            id: '',
            questionType: 'multiple_choice',
            questionText:
                'Which key concept belongs to ${lesson.topic}? (Review item $number)',
            options: _options(
              correct,
              concepts.where((concept) => concept != correct).followedBy([
                'Unrelated hardware maintenance',
                'Graphic layout composition',
                'Network cable installation',
              ]),
            ),
            correctAnswer: correct,
            sortOrder: number,
            explanation: 'The answer is included in the lesson’s key concepts.',
          ),
        );
        conceptIndex++;
      }
    }
    return questions.take(_itemCount).toList();
  }

  Future<void> _generate(AdminLesson lesson) async {
    setState(() => _isGenerating = true);
    final questions = _questions(lesson);
    final difficulty = _effectiveDifficulty(lesson);
    final quiz = AdminQuiz(
      id: '',
      title: '${lesson.title} — Multiple Choice Quiz',
      topic: lesson.topic,
      difficulty: difficulty,
      xpReward: switch (difficulty.toLowerCase()) {
        'hard' => 35,
        'medium' => 30,
        _ => 25,
      },
      isPublished: false,
      lessonId: lesson.id,
      questions: questions,
      audiencePrograms: lesson.audiencePrograms,
      yearLevels: lesson.yearLevels,
      language: lesson.language,
      errorFocus: lesson.errorFocus.toLowerCase().contains('syntax')
          ? 'syntax'
          : lesson.errorFocus.toLowerCase().contains('logic')
          ? 'logic'
          : 'concept',
      passingScore: 80,
      attemptLimit: 3,
      shuffleQuestions: true,
    );
    final provider = context.read<AdminQuizzesProvider>();
    final created = await provider.createQuizWithQuestions(quiz, questions);
    if (!mounted) return;
    setState(() => _isGenerating = false);
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Quiz generation failed.')),
      );
      provider.clearError();
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${questions.length} multiple-choice questions were generated from “${lesson.title}”.',
        ),
        backgroundColor: const Color(0xFF047857),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonsProvider = context.watch<AdminLessonsProvider>();
    final lessons = lessonsProvider.lessons;
    final lesson = lessons.where((item) => item.id == _lessonId).firstOrNull;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.quiz_rounded, color: _purple),
          SizedBox(width: 12),
          Text('Create quiz from lesson'),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a lesson. CoSci will generate a draft quiz containing multiple-choice questions, answer keys, and explanations based on that lesson.',
              style: TextStyle(color: _textSub, height: 1.45),
            ),
            const SizedBox(height: 18),
            if (lessonsProvider.isLoading)
              const LinearProgressIndicator()
            else if (lessons.isEmpty)
              const Text(
                'No lessons are available. Create a lesson first.',
                style: TextStyle(color: Color(0xFFB45309)),
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
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.language} • ${item.title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _lessonId = value),
              ),
            if (lesson != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Text(
                  '${lesson.title}\n${lesson.language} • ${_effectiveDifficulty(lesson)} • ${_questions(lesson).length} questions',
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _difficultyOverride,
              decoration: const InputDecoration(
                labelText: 'Quiz difficulty',
                prefixIcon: Icon(Icons.signal_cellular_alt_rounded),
                helperText:
                    'Choose a challenge level or keep the lesson difficulty.',
              ),
              items: const ['Match lesson', 'Easy', 'Medium', 'Hard']
                  .map(
                    (difficulty) => DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _difficultyOverride = value ?? 'Match lesson'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _itemCount,
              decoration: const InputDecoration(
                labelText: 'Number of quiz items',
                prefixIcon: Icon(Icons.format_list_numbered_rounded),
                helperText: 'Generated as multiple-choice questions.',
              ),
              items: const [5, 10, 15, 20]
                  .map(
                    (count) => DropdownMenuItem(
                      value: count,
                      child: Text('$count items'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _itemCount = value ?? 5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: lesson == null || _isGenerating
              ? null
              : () => _generate(lesson),
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
          label: Text(_isGenerating ? 'Generating…' : 'Generate quiz'),
        ),
      ],
    );
  }
}

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
              colors: [_purple, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quiz Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '$count quiz${count == 1 ? '' : 'zes'}  ·  $publishedCount published',
                style: const TextStyle(fontSize: 13, color: _textSub),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onNew,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Quiz'),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: TextField(
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
                  onPressed: () => onChanged(''),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _QuizzesTable extends StatelessWidget {
  const _QuizzesTable({
    required this.quizzes,
    required this.provider,
    required this.onEdit,
    required this.onView,
    required this.onManageQuestions,
  });
  final List<AdminQuiz> quizzes;
  final AdminQuizzesProvider provider;
  final void Function(AdminQuiz) onEdit;
  final void Function(AdminQuiz) onView;
  final void Function(AdminQuiz) onManageQuestions;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1240,
      child: Column(
        children: [
          // Header row
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 8), // dot
                SizedBox(width: 12),
                Expanded(flex: 5, child: _H('Title')),
                Expanded(flex: 3, child: _H('Topic')),
                SizedBox(width: 90, child: _H('Difficulty')),
                SizedBox(width: 72, child: _H('XP', center: true)),
                SizedBox(width: 120, child: _H('Date created')),
                SizedBox(width: 90, child: _H('Status')),
                SizedBox(width: 140, child: _H('Actions', center: true)),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // Rows
          ...quizzes.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            return _QuizRow(
              quiz: q,
              isLast: i == quizzes.length - 1,
              onEdit: () => onEdit(q),
              onView: () => onView(q),
              onManageQuestions: () => onManageQuestions(q),
              onToggle: () => provider.togglePublished(q.id, !q.isPublished),
              onDelete: () async {
                final confirmed = await showAdminConfirmDialog(
                  context,
                  title: 'Delete Quiz',
                  message: 'Delete "${q.title}"? This cannot be undone.',
                );
                if (confirmed && context.mounted) {
                  await provider.deleteQuiz(q.id, q.title);
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

class _QuizRow extends StatelessWidget {
  const _QuizRow({
    required this.quiz,
    required this.isLast,
    required this.onEdit,
    required this.onView,
    required this.onManageQuestions,
    required this.onToggle,
    required this.onDelete,
  });
  final AdminQuiz quiz;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onManageQuestions;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Published dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: quiz.isPublished
                      ? const Color(0xFF059669)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(width: 12),

              // Title + linked lesson
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (quiz.lessonId != null && quiz.lessonId!.isNotEmpty)
                      Text(
                        'Linked lesson: ${quiz.lessonId}',
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
                  quiz.topic,
                  style: const TextStyle(fontSize: 12, color: _textSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Difficulty
              SizedBox(width: 90, child: _DiffBadge(level: quiz.difficulty)),

              // XP
              SizedBox(
                width: 72,
                child: Text(
                  '${quiz.xpReward} XP',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),

              SizedBox(
                width: 120,
                child: _CreatedDate(createdAt: quiz.createdAt),
              ),

              // Status
              SizedBox(
                width: 90,
                child: _StatusBadge(isPublished: quiz.isPublished),
              ),

              // Actions
              SizedBox(
                width: 140,
                child: PopupMenuButton<String>(
                  tooltip: 'Manage quiz',
                  onSelected: (value) {
                    if (value == 'view') onView();
                    if (value == 'questions') onManageQuestions();
                    if (value == 'toggle') onToggle();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.visibility_rounded),
                        title: Text('Preview quiz'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'questions',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.list_alt_rounded),
                        title: Text('Questions'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      enabled: quiz.isPublished || quiz.isReadyToPublish,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          quiz.isPublished
                              ? Icons.visibility_off_rounded
                              : Icons.publish_rounded,
                        ),
                        title: Text(quiz.isPublished ? 'Unpublish' : 'Publish'),
                        subtitle: !quiz.isPublished && !quiz.isReadyToPublish
                            ? Text(
                                'Complete ${quiz.readinessIssues.join(', ')}',
                              )
                            : null,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Edit quiz'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                        ),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manage',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.more_horiz_rounded, size: 17),
                      ],
                    ),
                  ),
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

class _CreatedDate extends StatelessWidget {
  const _CreatedDate({required this.createdAt});

  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final date = createdAt?.toLocal();
    if (date == null) {
      return const Text('—', style: TextStyle(fontSize: 12, color: _textSub));
    }
    return Tooltip(
      message: DateFormat('MMMM d, yyyy • h:mm a').format(date),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('MMM d, yyyy').format(date),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textMain,
            ),
          ),
          Text(
            DateFormat('h:mm a').format(date),
            style: const TextStyle(fontSize: 10, color: _textSub),
          ),
        ],
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
            'Loading quizzes…',
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
              color: _purple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_rounded, size: 30, color: _purple),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No quizzes match your search.' : 'No quizzes yet.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasQuery)
            const Text(
              'Create your first quiz to get started.',
              style: TextStyle(fontSize: 13, color: _textSub),
            ),
          const SizedBox(height: 20),
          if (!hasQuery)
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create Quiz'),
              style: FilledButton.styleFrom(backgroundColor: _navy),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _QuizFormDialog extends StatefulWidget {
  const _QuizFormDialog({this.existing});
  final AdminQuiz? existing;

  @override
  State<_QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<_QuizFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _lessonIdCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _passingCtrl;
  late final TextEditingController _attemptCtrl;
  late final TextEditingController _simulationIdCtrl;
  String _difficulty = 'Easy';
  String _language = 'C++';
  String _errorFocus = 'concept';
  bool _isPublished = false;
  bool _shuffleQuestions = true;
  late Set<String> _audiencePrograms;
  late Set<String> _yearLevels;
  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _topicCtrl = TextEditingController(text: e?.topic ?? '');
    _lessonIdCtrl = TextEditingController(text: e?.lessonId ?? '');
    _xpCtrl = TextEditingController(text: '${e?.xpReward ?? 30}');
    _passingCtrl = TextEditingController(text: '${e?.passingScore ?? 80}');
    _attemptCtrl = TextEditingController(text: '${e?.attemptLimit ?? 3}');
    _simulationIdCtrl = TextEditingController(text: e?.simulationId ?? '');
    _difficulty = e?.difficulty ?? 'Easy';
    _language = normalizeQuizLanguage(e?.language);
    _errorFocus = e?.errorFocus ?? 'concept';
    _isPublished = e?.isPublished ?? false;
    _shuffleQuestions = e?.shuffleQuestions ?? true;
    _audiencePrograms = {...?e?.audiencePrograms};
    _yearLevels = {...?e?.yearLevels};
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _lessonIdCtrl.dispose();
    _xpCtrl.dispose();
    _passingCtrl.dispose();
    _attemptCtrl.dispose();
    _simulationIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminQuizzesProvider>();
    final quiz = AdminQuiz(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      difficulty: _difficulty,
      xpReward: int.tryParse(_xpCtrl.text) ?? 30,
      isPublished: _isPublished,
      lessonId: _lessonIdCtrl.text.trim().isEmpty
          ? null
          : _lessonIdCtrl.text.trim(),
      audiencePrograms: _audiencePrograms.toList(),
      yearLevels: _yearLevels.toList(),
      language: _language,
      errorFocus: _errorFocus,
      passingScore: int.tryParse(_passingCtrl.text) ?? 80,
      attemptLimit: int.tryParse(_attemptCtrl.text) ?? 3,
      simulationId: _simulationIdCtrl.text.trim().isEmpty
          ? null
          : _simulationIdCtrl.text.trim(),
      shuffleQuestions: _shuffleQuestions,
    );
    final ok = _isEdit
        ? await provider.updateQuiz(quiz)
        : await provider.createQuiz(quiz);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminQuizzesProvider>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purple, _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Quiz' : 'New Quiz',
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
                    children: [
                      _field(
                        'Title',
                        _titleCtrl,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _field('Topic', _topicCtrl),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                        ),
                        borderRadius: BorderRadius.circular(10),
                        items: _difficulties
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _difficulty = v!),
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
                              items: const ['C++', 'Java', 'JavaScript']
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _language = v!),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _errorFocus,
                              decoration: const InputDecoration(
                                labelText: 'Learning focus',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'concept',
                                  child: Text('Concept'),
                                ),
                                DropdownMenuItem(
                                  value: 'syntax',
                                  child: Text('Syntax errors'),
                                ),
                                DropdownMenuItem(
                                  value: 'logic',
                                  child: Text('Logic errors'),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _errorFocus = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AdminAudienceSelector(
                        programs: _audiencePrograms,
                        years: _yearLevels,
                        onProgramsChanged: (value) =>
                            setState(() => _audiencePrograms = value),
                        onYearsChanged: (value) =>
                            setState(() => _yearLevels = value),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'Passing score (%)',
                              _passingCtrl,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                return n == null || n < 50 || n > 100
                                    ? 'Use 50–100'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _field(
                              'Attempt limit',
                              _attemptCtrl,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                return n == null || n < 1 || n > 10
                                    ? 'Use 1–10'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              'XP Reward',
                              _xpCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _field(
                              'Linked Lesson ID (optional)',
                              _lessonIdCtrl,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Linked Simulation ID (optional)',
                        _simulationIdCtrl,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Switch(
                            value: _shuffleQuestions,
                            onChanged: (v) =>
                                setState(() => _shuffleQuestions = v),
                          ),
                          const SizedBox(width: 8),
                          const Text('Randomize questions and choices'),
                          const Spacer(),
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
                        : Text(_isEdit ? 'Save Changes' : 'Create Quiz'),
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

// ─────────────────────────────────────────────────────────────────────────────
// QUIZ QUESTIONS DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _QuizQuestionsDialog extends StatefulWidget {
  const _QuizQuestionsDialog({required this.quiz});
  final AdminQuiz quiz;

  @override
  State<_QuizQuestionsDialog> createState() => _QuizQuestionsDialogState();
}

class _QuizQuestionsDialogState extends State<_QuizQuestionsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminQuizzesProvider>().selectQuiz(widget.quiz);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminQuizzesProvider>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 640),
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purple, _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Questions',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.quiz.title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showQuestionForm(context, provider),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Add Question'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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

            // Content
            Expanded(
              child: provider.isQuestionsLoading
                  ? const Center(child: CircularProgressIndicator(color: _navy))
                  : provider.questions.isEmpty
                  ? const AdminEmptyState(
                      message:
                          'No questions yet. Click "Add Question" to start.',
                      icon: Icons.help_outline_rounded,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.questions.length,
                      itemBuilder: (context, i) {
                        final q = provider.questions[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _purple.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _purple,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        q.questionText,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 7),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          _QTypeBadge(type: q.questionType),
                                          Text(
                                            'Answer: ${q.correctAnswer}',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _textSub,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.edit_rounded,
                                      color: _blue,
                                      tooltip: 'Edit',
                                      onTap: () => _showQuestionForm(
                                        context,
                                        provider,
                                        q,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _ActionBtn(
                                      icon: Icons.delete_outline_rounded,
                                      color: const Color(0xFFDC2626),
                                      tooltip: 'Delete',
                                      onTap: () async {
                                        final ok = await showAdminConfirmDialog(
                                          context,
                                          title: 'Delete Question',
                                          message: 'Remove this question?',
                                        );
                                        if (ok && context.mounted) {
                                          await provider.deleteQuestion(
                                            widget.quiz.id,
                                            q.id,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Text(
                    '${provider.questions.length} question${provider.questions.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13, color: _textSub),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionForm(
    BuildContext ctx,
    AdminQuizzesProvider provider, [
    AdminQuizQuestion? existing,
  ]) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _QuestionFormDialog(quizId: widget.quiz.id, existing: existing),
      ),
    );
  }
}

class _QTypeBadge extends StatelessWidget {
  const _QTypeBadge({required this.type});
  final String type;

  static const _colors = {
    'multiple_choice': Color(0xFF1D4ED8),
    'output_prediction': Color(0xFF7C3AED),
    'code_tracing': Color(0xFF0891B2),
    'identify_error': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type] ?? _textSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUESTION FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({required this.quizId, this.existing});
  final String quizId;
  final AdminQuizQuestion? existing;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionCtrl;
  late final TextEditingController _snippetCtrl;
  late final TextEditingController _correctCtrl;
  late final TextEditingController _explanationCtrl;
  late final List<TextEditingController> _optionCtrls;
  String _questionType = 'multiple_choice';
  static const _types = [
    'multiple_choice',
    'output_prediction',
    'code_tracing',
    'identify_error',
  ];
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _questionCtrl = TextEditingController(text: e?.questionText ?? '');
    _snippetCtrl = TextEditingController(text: e?.codeSnippet ?? '');
    _correctCtrl = TextEditingController(text: e?.correctAnswer ?? '');
    _explanationCtrl = TextEditingController(text: e?.explanation ?? '');
    final opts = e?.options ?? ['', '', '', ''];
    _optionCtrls = List.generate(
      4,
      (i) => TextEditingController(text: i < opts.length ? opts[i] : ''),
    );
    _questionType = e?.questionType ?? 'multiple_choice';
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _snippetCtrl.dispose();
    _correctCtrl.dispose();
    _explanationCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminQuizzesProvider>();
    final options = _optionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final q = AdminQuizQuestion(
      id: widget.existing?.id ?? '',
      questionType: _questionType,
      questionText: _questionCtrl.text.trim(),
      options: options,
      correctAnswer: _correctCtrl.text.trim(),
      sortOrder: widget.existing?.sortOrder ?? provider.questions.length,
      codeSnippet: _snippetCtrl.text.trim().isEmpty
          ? null
          : _snippetCtrl.text.trim(),
      explanation: _explanationCtrl.text.trim().isEmpty
          ? null
          : _explanationCtrl.text.trim(),
    );
    final ok = await provider.saveQuestion(widget.quizId, q);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminQuizzesProvider>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purple, _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Question' : 'New Question',
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

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _questionType,
                        decoration: const InputDecoration(
                          labelText: 'Question Type',
                        ),
                        borderRadius: BorderRadius.circular(10),
                        items: _types
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.replaceAll('_', ' ')),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _questionType = v!),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Question Text',
                        _questionCtrl,
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Code Snippet (optional)',
                        _snippetCtrl,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _field('Option ${i + 1}', _optionCtrls[i]),
                        ),
                      ),
                      _field(
                        'Correct Answer',
                        _correctCtrl,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Explanation (optional)',
                        _explanationCtrl,
                        maxLines: 2,
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
                        : Text(_isEdit ? 'Save' : 'Add Question'),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
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
