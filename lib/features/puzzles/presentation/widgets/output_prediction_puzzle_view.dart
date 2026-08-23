import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/screens/puzzle_player_screen.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';

class OutputPredictionPuzzleView extends StatefulWidget {
  const OutputPredictionPuzzleView({super.key, required this.puzzle});

  final Puzzle puzzle;

  @override
  State<OutputPredictionPuzzleView> createState() =>
      _OutputPredictionPuzzleViewState();
}

class _OutputPredictionPuzzleViewState
    extends State<OutputPredictionPuzzleView> {
  String? _selectedOptionId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzlesProvider>();
    final data = widget.puzzle.outputPredictionData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Predict the output',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Read the code carefully, then choose the correct output.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF0A1730),
              ),
              child: Text(
                data?.codeSnippet ?? '',
                style: const TextStyle(
                  color: Color(0xFFEAF2FF),
                  fontFamily: 'monospace',
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...?data?.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectableOptionCard(
                  label: option.text,
                  isSelected: _selectedOptionId == option.id,
                  onTap: () => setState(() => _selectedOptionId = option.id),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: provider.isSubmitting || _selectedOptionId == null
                  ? null
                  : () async {
                      final result = await context
                          .read<PuzzlesProvider>()
                          .submitOutputPredictionAttempt(
                            puzzle: widget.puzzle,
                            selectedOptionId: _selectedOptionId!,
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
                                ? 'Correct output. Score: ${result.score}%'
                                : 'That output is incorrect. Score: ${result.score}%',
                          ),
                        ),
                      );
                      await PuzzlePlayerScreen.showRewardIfNeeded(context);
                    },
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
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
