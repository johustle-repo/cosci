import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/progress_summary.dart';

class ProgressHeroCard extends StatelessWidget {
  const ProgressHeroCard({super.key, required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF081B3D), Color(0xFF123C81)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123D9B).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A polished overview of completion, mastery, badges, and recent Firebase-synced learning activity.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = [
                _HeroMetric(
                  label: 'Total XP',
                  value: summary.points.toString(),
                ),
                _HeroMetric(
                  label: 'Level',
                  value: 'Lv ${summary.currentLevel}',
                ),
                _HeroMetric(
                  label: 'Badges',
                  value: summary.earnedBadges.length.toString(),
                ),
              ];
              if (constraints.maxWidth >= 260) {
                return Row(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(child: metrics[index]),
                    ],
                  ],
                );
              }
              return Wrap(spacing: 8, runSpacing: 8, children: metrics);
            },
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
          ),
        ],
      ),
    );
  }
}
