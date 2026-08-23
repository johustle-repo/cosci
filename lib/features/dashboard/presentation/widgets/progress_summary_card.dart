import 'package:flutter/material.dart';

class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({
    super.key,
    required this.learningProgress,
    required this.completedLessons,
    required this.completedActivities,
  });

  final double learningProgress;
  final int completedLessons;
  final int completedActivities;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (learningProgress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Learning Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'A refined snapshot of your lesson completion and learning activity growth.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: learningProgress,
                backgroundColor: const Color(0xFFE2E8F0),
                color: const Color(0xFF123D9B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$progressPercent% complete',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: 'Lessons completed',
                    value: completedLessons.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: 'Activities done',
                    value: completedActivities.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF9FBFF), Color(0xFFF3F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFCBD8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
