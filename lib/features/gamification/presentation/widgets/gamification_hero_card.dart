import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';

class GamificationHeroCard extends StatelessWidget {
  const GamificationHeroCard({super.key, required this.profile});

  final GamificationProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF081B3D), Color(0xFF123C81), Color(0xFF0D285A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123D9B).withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -16,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF56C4FF).withValues(alpha: 0.11),
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            left: -10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2DE2E6).withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Text(
                  'Educational rewards only',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Gamification Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track meaningful learning: XP, streaks, challenge wins, and milestone badges tied to real academic work.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final metrics = [
                    _HeroMetric(
                      label: 'Total XP',
                      value: profile.totalXp.toString(),
                      icon: Icons.flash_on_rounded,
                    ),
                    _HeroMetric(
                      label: 'Level',
                      value: 'Lv ${profile.level}',
                      icon: Icons.layers_rounded,
                    ),
                    _HeroMetric(
                      label: 'Badges',
                      value: profile.badges
                          .where((badge) => badge.isUnlocked)
                          .length
                          .toString(),
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ];
                  if (constraints.maxWidth >= 270) {
                    return Row(
                      children: [
                        for (
                          var index = 0;
                          index < metrics.length;
                          index++
                        ) ...[
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
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
