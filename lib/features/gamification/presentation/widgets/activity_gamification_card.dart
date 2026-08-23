import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';

class ActivityGamificationCard extends StatelessWidget {
  const ActivityGamificationCard({
    super.key,
    required this.rewardXp,
    required this.requirement,
    this.completed = false,
  });

  final int rewardXp;
  final String requirement;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<GamificationProvider>().profile;
    final color = completed ? const Color(0xFF059669) : const Color(0xFF2457D6);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFECFDF5) : const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final reward = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  completed ? Icons.verified_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed ? 'Activity completed' : 'Earn +$rewardXp XP',
                      style: const TextStyle(
                        color: Color(0xFF102447),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      completed
                          ? 'The completion reward can only be claimed once.'
                          : '$requirement Rewarded once per activity.',
                      style: const TextStyle(
                        color: Color(0xFF5B6B85),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final profileSummary = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Level ${profile.level}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${profile.totalXp} XP  •  ${profile.dailyStreak} day streak',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                reward,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: profileSummary),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: reward),
              const SizedBox(width: 16),
              profileSummary,
            ],
          );
        },
      ),
    );
  }
}
