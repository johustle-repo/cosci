import 'package:flutter/material.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/gamification_style.dart';
import 'package:pseudocode_apk/models/learning_reward.dart';

class RewardPopupDialog extends StatelessWidget {
  const RewardPopupDialog({super.key, required this.reward});

  final LearningReward reward;

  static Future<void> show(BuildContext context, LearningReward reward) {
    return showDialog<void>(
      context: context,
      builder: (_) => RewardPopupDialog(reward: reward),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF081B3D), Color(0xFF123B81)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF6C66C), Color(0xFF56C4FF)],
                ),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF07204B),
                size: 27,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Reward earned',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reward.activityTitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Pill(
                  label: '+${reward.xpAwarded} XP',
                  icon: Icons.flash_on_rounded,
                ),
                _Pill(
                  label: 'Streak ${reward.currentStreak}',
                  icon: Icons.local_fire_department_rounded,
                ),
                if (reward.leveledUp)
                  _Pill(
                    label: 'Level ${reward.newLevel}',
                    icon: Icons.layers_rounded,
                  ),
              ],
            ),
            if (reward.hasUnlockedBadges) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: reward.unlockedBadges
                    .map(
                      (badge) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              GamificationStyle.badgeIcon(badge.iconName),
                              color: GamificationStyle.badgeColor(
                                badge.accentHex,
                              ),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              badge.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF08204A),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
