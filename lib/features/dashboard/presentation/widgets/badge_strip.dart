import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/dashboard_badge.dart';

class BadgeStrip extends StatelessWidget {
  const BadgeStrip({super.key, required this.badges});

  final List<DashboardBadge> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const _EmptyBadgeState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 520
            ? (constraints.maxWidth * 0.72).clamp(164.0, 220.0).toDouble()
            : 188.0;

        return SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgeCard(badge: badge, width: cardWidth);
            },
          ),
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.width});

  final DashboardBadge badge;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD8EE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFDBEAFE),
            child: Icon(
              _iconFor(badge.iconKey),
              color: const Color(0xFF123D9B),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                badge.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  height: 1.18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.earnedAtLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'puzzle':
        return Icons.extension_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }
}

class _EmptyBadgeState extends StatelessWidget {
  const _EmptyBadgeState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE0E7FF),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: Color(0xFF123D9B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No badges earned yet. Complete your first challenge to start your collection.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF123D9B)),
          ],
        ),
      ),
    );
  }
}
