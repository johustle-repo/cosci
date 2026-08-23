import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/progress_summary.dart';

class ProgressBreakdownCard extends StatelessWidget {
  const ProgressBreakdownCard({super.key, required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Simple progress bars make the module easy to explain in documentation and defense.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _ProgressRow(
              label: 'Lessons',
              value: summary.completedLessons,
              progress: summary.lessonProgress,
              color: const Color(0xFF123D9B),
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              label: 'Quizzes',
              value: summary.completedQuizzes,
              progress: summary.quizProgress,
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              label: 'Puzzles',
              value: summary.completedPuzzles,
              progress: summary.puzzleProgress,
              color: const Color(0xFF0EA5E9),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final int value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              value.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: progress,
            backgroundColor: const Color(0xFFE4ECF7),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
