import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/screens/puzzle_player_screen.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';

class CodeFlowPuzzleView extends StatefulWidget {
  const CodeFlowPuzzleView({super.key, required this.puzzle});

  final Puzzle puzzle;

  @override
  State<CodeFlowPuzzleView> createState() => _CodeFlowPuzzleViewState();
}

class _CodeFlowPuzzleViewState extends State<CodeFlowPuzzleView> {
  late List<String> _lines;
  Timer? _clueTimer;
  int _clueSeconds = 10;

  @override
  void initState() {
    super.initState();
    _lines = List<String>.from(
      widget.puzzle.codeFlowData?.scrambledLines ?? const [],
    );
    final correct =
        widget.puzzle.codeFlowData?.correctOrder ?? const <String>[];
    if (_lines.length > 1 && listEquals(_lines, correct)) {
      final first = _lines.removeAt(0);
      _lines.add(first);
    }
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

  @override
  void dispose() {
    _clueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzlesProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build the correct syntax',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Drag each code tile and stack them from top to bottom. The first tile should be the first line of the program.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _clueSeconds > 0
                  ? Container(
                      key: const ValueKey('visible-clue'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(height: 12),
                          SelectableText(
                            (widget.puzzle.codeFlowData?.correctOrder ??
                                    const <String>[])
                                .join('\n'),
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      key: const ValueKey('hidden-clue'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.visibility_off_rounded,
                            color: Color(0xFFC2410C),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Clue hidden. Arrange the code tiles from memory.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _lines.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _lines.removeAt(oldIndex);
                  _lines.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final line = _lines[index];
                return Container(
                  key: ValueKey('syntax-tile-$line-$index'),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1.4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFEAF2FF),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFF123D9B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.drag_indicator_rounded,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: provider.isSubmitting
                  ? null
                  : () async {
                      final result = await context
                          .read<PuzzlesProvider>()
                          .submitCodeFlowAttempt(
                            puzzle: widget.puzzle,
                            currentOrder: _lines,
                          );

                      if (result == null || !context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: result.isCorrect
                              ? const Color(0xFF166534)
                              : const Color(0xFFB45309),
                          content: Text(
                            result.isCorrect
                                ? 'Correct sequence. Score: ${result.score}%'
                                : 'Sequence needs work. Score: ${result.score}%',
                          ),
                        ),
                      );
                      await PuzzlePlayerScreen.showRewardIfNeeded(context);
                    },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Check Sequence'),
            ),
          ],
        ),
      ),
    );
  }
}
