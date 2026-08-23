import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/progress_summary.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key, required this.activities});

  final List<RecentLearningActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              activities.isEmpty
                  ? 'No recent activity has been recorded yet.'
                  : 'Latest simulation, quiz, puzzle, and challenge activity from Firestore.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (activities.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF7FAFF),
                  border: Border.all(color: const Color(0xFFD8E4F4)),
                ),
                child: const Text(
                  'Complete tasks to see a learning history timeline here.',
                ),
              )
            else
              ...activities.map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFFEAF2FF),
                        ),
                        child: Icon(
                          _iconFor(activity.type),
                          color: const Color(0xFF123D9B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activity.typeLabel} | ${activity.relativeLabel}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${activity.xpAwarded} XP',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          if (activity.scorePercent != null)
                            Text(
                              '${activity.scorePercent}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'simulation':
        return Icons.terminal_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'puzzle':
        return Icons.extension_rounded;
      case 'daily_challenge':
        return Icons.track_changes_rounded;
      default:
        return Icons.school_rounded;
    }
  }
}
