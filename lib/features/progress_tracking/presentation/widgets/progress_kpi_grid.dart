import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/progress_summary.dart';

class ProgressKpiGrid extends StatelessWidget {
  const ProgressKpiGrid({super.key, required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        title: 'Completed Lessons',
        value: summary.completedLessons.toString(),
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF123D9B),
      ),
      _KpiCard(
        title: 'Completed Quizzes',
        value: summary.completedQuizzes.toString(),
        icon: Icons.quiz_rounded,
        color: const Color(0xFF2563EB),
      ),
      _KpiCard(
        title: 'Completed Puzzles',
        value: summary.completedPuzzles.toString(),
        icon: Icons.extension_rounded,
        color: const Color(0xFF0EA5E9),
      ),
      _KpiCard(
        title: 'Daily Streak',
        value: '${summary.streakDays} days',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEA580C),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth >= 300
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: columns == 1 ? 96 : 112,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0C2350),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
