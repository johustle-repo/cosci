import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/daily_challenge.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key, required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF6FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFCBD8EE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF123D9B), Color(0xFF38BDF8)],
                    ),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Challenge',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.completionLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDBEAFE), Color(0xFFE0F2FE)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${challenge.xpReward} XP',
                    style: const TextStyle(
                      color: Color(0xFF123D9B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              challenge.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  size: 18,
                  color: Color(0xFF123D9B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete today\'s challenge to accelerate your level progress.',
                    style: Theme.of(context).textTheme.bodySmall,
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
