import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pseudocode_apk/features/admin/models/admin_puzzle.dart';
import 'package:pseudocode_apk/features/admin/models/admin_quiz.dart';
import 'package:pseudocode_apk/features/admin/models/admin_simulation.dart';

Future<void> showStudentQuizPreview(BuildContext context, AdminQuiz quiz) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StudentPreviewFrame(
      title: 'Learner quiz preview',
      icon: Icons.quiz_rounded,
      child: _QuizPreview(quiz: quiz),
    ),
  );
}

Future<void> showStudentSimulationPreview(
  BuildContext context,
  AdminSimulation simulation,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StudentPreviewFrame(
      title: 'Learner simulation preview',
      icon: Icons.terminal_rounded,
      child: _SimulationPreview(simulation: simulation),
    ),
  );
}

Future<void> showStudentPuzzlePreview(
  BuildContext context,
  AdminPuzzle puzzle,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StudentPreviewFrame(
      title: 'Learner puzzle preview',
      icon: Icons.extension_rounded,
      child: _PuzzlePreview(puzzle: puzzle),
    ),
  );
}

class _StudentPreviewFrame extends StatelessWidget {
  const _StudentPreviewFrame({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFF0B2F6B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const Text(
                        'Student point of view • Preview mode does not save progress',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close preview',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF3F7FD),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuizPreview extends StatefulWidget {
  const _QuizPreview({required this.quiz});
  final AdminQuiz quiz;

  @override
  State<_QuizPreview> createState() => _QuizPreviewState();
}

class _QuizPreviewState extends State<_QuizPreview> {
  int _index = 0;
  final Map<int, String> _answers = {};

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    if (quiz.questions.isEmpty) {
      return const _EmptyPreview(
        message: 'This quiz has no questions to show yet.',
      );
    }
    final question = quiz.questions[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityHeading(
          title: quiz.title,
          subtitle:
              '${quiz.topic} • ${quiz.language} • ${quiz.difficulty} • ${quiz.passingScore}% to pass',
          badge: 'Question ${_index + 1} of ${quiz.questions.length}',
        ),
        const SizedBox(height: 14),
        LinearProgressIndicator(
          value: (_index + 1) / quiz.questions.length,
          minHeight: 7,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(height: 20),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if ((question.codeSnippet ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _CodePanel(code: question.codeSnippet!),
              ],
              const SizedBox(height: 18),
              ...question.options.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _answers[_index] = entry.value),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _answers[_index] == entry.value
                            ? const Color(0xFFEFF6FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _answers[_index] == entry.value
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD9E2EF),
                          width: _answers[_index] == entry.value ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color(0xFFE8EEF8),
                            child: Text(
                              String.fromCharCode(65 + entry.key),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _index == 0 ? null : () => setState(() => _index--),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Previous'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _index == quiz.questions.length - 1
                  ? null
                  : () => setState(() => _index++),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _index == quiz.questions.length - 1 ? 'Finish' : 'Next',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SimulationPreview extends StatefulWidget {
  const _SimulationPreview({required this.simulation});
  final AdminSimulation simulation;

  @override
  State<_SimulationPreview> createState() => _SimulationPreviewState();
}

class _SimulationPreviewState extends State<_SimulationPreview> {
  bool _hasRun = false;
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final simulation = widget.simulation;
    final steps = simulation.executionSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityHeading(
          title: simulation.title,
          subtitle:
              '${simulation.topic} • ${simulation.language} • ${simulation.difficulty}',
          badge: '${simulation.xpReward} XP',
        ),
        const SizedBox(height: 18),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Challenge goal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(simulation.problemGoal),
              const SizedBox(height: 16),
              _CodePanel(code: simulation.codeSnippet),
              if (simulation.stdin.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Input\n${simulation.stdin}'),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _hasRun = true;
                  _step = 0;
                }),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run simulation'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Program output',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _hasRun
                    ? simulation.expectedOutput
                    : 'Run the simulation to view its output.',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              if (_hasRun && steps.isNotEmpty) ...[
                const Divider(height: 28),
                Text(
                  'Step ${_step + 1} of ${steps.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(steps[_step].description),
                if (steps[_step].variableStates.isNotEmpty)
                  Text('Variables: ${steps[_step].variableStates}'),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _step >= steps.length - 1
                      ? null
                      : () => setState(() => _step++),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Next step'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PuzzlePreview extends StatefulWidget {
  const _PuzzlePreview({required this.puzzle});
  final AdminPuzzle puzzle;

  @override
  State<_PuzzlePreview> createState() => _PuzzlePreviewState();
}

class _PuzzlePreviewState extends State<_PuzzlePreview> {
  String? _selected;
  late List<String> _codeTiles;
  Timer? _clueTimer;
  int _clueSeconds = 10;

  @override
  void initState() {
    super.initState();
    _codeTiles = List<String>.from(widget.puzzle.scrambledLines);
    if (_codeTiles.length > 1 &&
        _sameOrder(_codeTiles, widget.puzzle.correctOrder)) {
      final first = _codeTiles.removeAt(0);
      _codeTiles.add(first);
    }
    if (widget.puzzle.puzzleType == 'code_flow') {
      _clueTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_clueSeconds <= 1) {
          timer.cancel();
          setState(() => _clueSeconds = 0);
        } else {
          setState(() => _clueSeconds--);
        }
      });
    }
  }

  @override
  void dispose() {
    _clueTimer?.cancel();
    super.dispose();
  }

  bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = widget.puzzle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityHeading(
          title: puzzle.title,
          subtitle: '${puzzle.topic} • ${puzzle.difficulty}',
          badge: '${puzzle.xpReward} XP',
        ),
        const SizedBox(height: 18),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                puzzle.explanation ?? _instruction(puzzle.puzzleType),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (puzzle.puzzleType != 'code_flow' &&
                  (puzzle.codeSnippet ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _CodePanel(code: puzzle.codeSnippet!),
              ],
              const SizedBox(height: 16),
              if (puzzle.puzzleType == 'code_flow') ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: _clueSeconds > 0
                      ? Container(
                          key: const ValueKey('preview-clue'),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_rounded,
                                    color: Color(0xFFFBBF24),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Memorize this clue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$_clueSeconds s',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                puzzle.correctOrder.join('\n'),
                                style: const TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontFamily: 'monospace',
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Row(
                          key: ValueKey('preview-clue-hidden'),
                          children: [
                            Icon(
                              Icons.visibility_off_rounded,
                              color: Color(0xFFC2410C),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Clue hidden. Build the syntax from memory.',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
              ],
              if (puzzle.puzzleType == 'code_flow')
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _codeTiles.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final tile = _codeTiles.removeAt(oldIndex);
                      _codeTiles.insert(newIndex, tile);
                    });
                  },
                  itemBuilder: (context, index) => Container(
                    key: ValueKey('preview-${_codeTiles[index]}-$index'),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x100F172A),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 16, child: Text('${index + 1}')),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _codeTiles[index],
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_indicator_rounded,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (puzzle.puzzleType == 'output_prediction')
                ...puzzle.outputChoices.map(
                  (choice) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selected = choice),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selected == choice
                              ? const Color(0xFFEFF6FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selected == choice
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFD9E2EF),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selected == choice
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(choice)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                Text(
                  puzzle.bugDescription ?? 'Identify and correct the error.',
                ),
                const SizedBox(height: 12),
                const TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Your corrected code or explanation',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Check answer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _instruction(String type) => switch (type) {
    'output_prediction' => 'Predict the output produced by the code.',
    'debug_bug' => 'Find the error and provide the correct solution.',
    _ => 'Arrange the code statements in the correct execution order.',
  };
}

class _ActivityHeading extends StatelessWidget {
  const _ActivityHeading({
    required this.title,
    required this.subtitle,
    required this.badge,
  });
  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
      Chip(label: Text(badge)),
    ],
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD9E2EF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0F172A),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(12),
    ),
    child: SelectableText(
      code,
      style: const TextStyle(
        color: Color(0xFFE2E8F0),
        fontFamily: 'monospace',
        height: 1.5,
      ),
    ),
  );
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(message)),
    ),
  );
}
