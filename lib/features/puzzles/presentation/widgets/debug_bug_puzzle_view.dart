import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/screens/puzzle_player_screen.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';

class DebugBugPuzzleView extends StatefulWidget {
  const DebugBugPuzzleView({super.key, required this.puzzle});

  final Puzzle puzzle;

  @override
  State<DebugBugPuzzleView> createState() => _DebugBugPuzzleViewState();
}

class _DebugBugPuzzleViewState extends State<DebugBugPuzzleView> {
  int? _selectedLineIndex;
  String? _selectedIssueId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzlesProvider>();
    final data = widget.puzzle.debugBugData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug the bug',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick the incorrect line and identify the real issue.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (data?.explanationHint != null) ...[
              const SizedBox(height: 10),
              Text(
                'Hint: ${data!.explanationHint}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF123D9B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF0A1730),
              ),
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < (data?.codeLines.length ?? 0);
                    index++
                  )
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _selectedLineIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: _selectedLineIndex == index
                                ? const Color(0xFF14376D)
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedLineIndex == index
                                  ? const Color(0xFF57B5FF)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF78A8FF),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  data!.codeLines[index],
                                  style: const TextStyle(
                                    color: Color(0xFFEAF2FF),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'What is the issue?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...?data?.issueOptions.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectableIssueCard(
                  label: option.text,
                  isSelected: _selectedIssueId == option.id,
                  onTap: () => setState(() => _selectedIssueId = option.id),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed:
                  provider.isSubmitting ||
                      _selectedLineIndex == null ||
                      _selectedIssueId == null
                  ? null
                  : () async {
                      final result = await context
                          .read<PuzzlesProvider>()
                          .submitDebugBugAttempt(
                            puzzle: widget.puzzle,
                            selectedLineIndex: _selectedLineIndex!,
                            selectedIssueId: _selectedIssueId!,
                          );

                      if (result == null || !context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: result.isCorrect
                              ? const Color(0xFF166534)
                              : const Color(0xFFB91C1C),
                          content: Text(
                            result.isCorrect
                                ? 'Bug identified correctly. Score: ${result.score}%'
                                : 'Not quite right yet. Score: ${result.score}%',
                          ),
                        ),
                      );
                      await PuzzlePlayerScreen.showRewardIfNeeded(context);
                    },
              icon: const Icon(Icons.bug_report_rounded),
              label: const Text('Submit Debug Answer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableIssueCard extends StatelessWidget {
  const _SelectableIssueCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? const Color(0xFFEAF2FF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF123D9B)
                : const Color(0xFFD8E4F4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF123D9B)
                      : const Color(0xFF9FB5D6),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF123D9B) : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 8, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
