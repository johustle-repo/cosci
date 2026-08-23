import 'package:flutter/material.dart';

class DashboardHeaderCard extends StatelessWidget {
  const DashboardHeaderCard({
    super.key,
    required this.studentName,
    required this.currentLevel,
    required this.onContinue,
  });

  final String studentName;
  final int currentLevel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 18 : 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
        gradient: const LinearGradient(
          colors: [Color(0xFF071427), Color(0xFF0D2B66), Color(0xFF123D9B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123D9B).withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: isCompact ? 110 : 180,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Student Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      'Level $currentLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 14 : 20),
              Text(
                'Welcome back, $studentName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 22 : null,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'A premium study space for your lessons, challenges, and progress. Stay consistent and keep building momentum.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.80),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: isCompact ? double.infinity : null,
                child: FilledButton.icon(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF123D9B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue learning'),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _HighlightPill(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Focused study flow',
                    ),
                    _HighlightPill(
                      icon: Icons.insights_rounded,
                      label: 'Live progress insights',
                    ),
                    _HighlightPill(
                      icon: Icons.verified_rounded,
                      label: 'Firebase-synced activity',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
