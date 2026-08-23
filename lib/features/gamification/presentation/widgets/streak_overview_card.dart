import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';

class StreakOverviewCard extends StatelessWidget {
  const StreakOverviewCard({super.key, required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFFFF1E7),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Streak',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only real learning tasks extend the streak.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 230) {
                  return Column(
                    children: [
                      _StreakMetric(
                        label: 'Current streak',
                        value: '${profile.dailyStreak} days',
                        accent: const Color(0xFFEA580C),
                      ),
                      const SizedBox(height: 12),
                      _StreakMetric(
                        label: 'Challenges done',
                        value: profile.completedChallenges.toString(),
                        accent: const Color(0xFF123D9B),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _StreakMetric(
                        label: 'Current streak',
                        value: '${profile.dailyStreak} days',
                        accent: const Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StreakMetric(
                        label: 'Challenges done',
                        value: profile.completedChallenges.toString(),
                        accent: const Color(0xFF123D9B),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              profile.dailyStreak >= 7
                  ? 'You unlocked the 7-day consistency badge. Excellent discipline.'
                  : 'Reach a 7-day streak to unlock the consistency badge.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E4F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: accent),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
