import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/language_progress.dart';

/// Overall progress plus a percentage breakdown per programming language,
/// split into lessons, quizzes, and puzzles.
class LanguageProgressCard extends StatelessWidget {
  const LanguageProgressCard({
    super.key,
    required this.report,
    this.isLoading = false,
  });

  final LanguageProgressReport report;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress by Programming Language',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'How much of each language you have finished. Every lesson, quiz, '
              'and puzzle counts as one item toward the percentage.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (isLoading && report.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (report.isEmpty)
              Text(
                'No published content yet.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              _OverallBanner(progress: report.overall),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 560
                      ? 2
                      : 1;
                  const gap = 12.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final language in report.languages)
                        SizedBox(
                          width: width,
                          child: _LanguageTile(progress: language),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverallBanner extends StatelessWidget {
  const _OverallBanner({required this.progress});

  final LanguageProgress progress;

  @override
  Widget build(BuildContext context) {
    final overall = progress.overall;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF081B3D), Color(0xFF123C81)],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: overall.ratio,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF4ADE80)),
                ),
                Center(
                  child: Text(
                    '${overall.percent}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall progress (all languages)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${overall.completed} of ${overall.total} items · '
                  'Lessons ${progress.lessons.percent}% · '
                  'Quizzes ${progress.quizzes.percent}% · '
                  'Puzzles ${progress.puzzles.percent}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.progress});

  final LanguageProgress progress;

  @override
  Widget build(BuildContext context) {
    final overall = progress.overall;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.language,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '${overall.percent}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF123D9B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Bar(
            ratio: overall.ratio,
            color: const Color(0xFF123D9B),
            height: 10,
          ),
          const SizedBox(height: 4),
          Text(
            '${overall.completed} of ${overall.total} items complete',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          _KindRow(
            label: 'Lessons',
            count: progress.lessons,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 8),
          _KindRow(
            label: 'Quizzes',
            count: progress.quizzes,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 8),
          _KindRow(
            label: 'Puzzles',
            count: progress.puzzles,
            color: const Color(0xFF0891B2),
          ),
        ],
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final CompletionCount count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              count.total == 0
                  ? 'none yet'
                  : '${count.completed}/${count.total} · ${count.percent}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _Bar(ratio: count.ratio, color: color, height: 6),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, required this.color, required this.height});

  final double ratio;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: height,
        value: ratio,
        backgroundColor: const Color(0xFFE4ECF7),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
