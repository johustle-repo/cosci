import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';

class XpLevelCard extends StatelessWidget {
  const XpLevelCard({super.key, required this.profile});

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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF123D9B), Color(0xFF56C4FF)],
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'XP and Level Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Simple thresholds make balancing easy as your capstone grows.',
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
                      _MetricTile(
                        label: 'Current XP',
                        value: '${profile.totalXp}',
                      ),
                      const SizedBox(height: 12),
                      _MetricTile(
                        label: 'Current level',
                        value: 'Lv ${profile.level}',
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Current XP',
                        value: '${profile.totalXp}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: 'Current level',
                        value: 'Lv ${profile.level}',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: profile.levelProgress,
                backgroundColor: const Color(0xFFE3EDF9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF123D9B),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  '${profile.xpIntoCurrentLevel} XP into this level',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${profile.xpNeededForNextLevel} XP to next level',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E4F2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9FBFF), Color(0xFFF2F7FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: const Color(0xFF0C2350)),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
