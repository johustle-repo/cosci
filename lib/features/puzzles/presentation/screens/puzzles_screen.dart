import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/screens/puzzle_player_screen.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/content_state_card.dart';
import 'package:pseudocode_apk/shared/widgets/info_chip.dart';

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PuzzlesProvider>().loadPuzzles(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzlesProvider>();

    final content = RefreshIndicator(
      onRefresh: () =>
          context.read<PuzzlesProvider>().loadPuzzles(forceRefresh: true),
      child: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          _PuzzlesHero(puzzles: provider.puzzles, provider: provider),
          const SizedBox(height: 18),
          if (provider.isLoading && provider.puzzles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (provider.errorMessage != null && provider.puzzles.isEmpty)
            _EmptyState(
              title: 'Puzzle content unavailable',
              message: provider.errorMessage!,
            )
          else if (provider.puzzles.isEmpty)
            const _EmptyState(
              title: 'No puzzles yet',
              message:
                  'No puzzles are available yet. Add puzzle documents to Firestore to populate this module.',
            )
          else
            ...provider.puzzles.map(
              (puzzle) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PuzzleCard(
                  puzzle: puzzle,
                  progress: provider.progressFor(puzzle.id),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return AppScaffold(title: 'Puzzles', body: content, maxContentWidth: 1280);
  }
}

class _PuzzlesHero extends StatelessWidget {
  const _PuzzlesHero({required this.puzzles, required this.provider});

  final List<Puzzle> puzzles;
  final PuzzlesProvider provider;

  @override
  Widget build(BuildContext context) {
    final completedCount = puzzles
        .where((puzzle) => provider.progressFor(puzzle.id).isCompleted)
        .length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A3B), Color(0xFF0D285A), Color(0xFF123C81)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123D9B).withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Puzzle Lab',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Strengthen logic, debugging, and code-reading confidence through structured puzzle activities synced from Firestore.',
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
                _HeroMetric(label: 'Puzzles', value: puzzles.length.toString()),
                _HeroMetric(
                  label: 'Completed',
                  value: completedCount.toString(),
                ),
                _HeroMetric(
                  label: 'Types',
                  value: PuzzleType.values.length.toString(),
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
          if (puzzles.isNotEmpty) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: completedCount / puzzles.length,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF4ADE80),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              completedCount == puzzles.length
                  ? 'Puzzle collection complete — excellent work!'
                  : '${puzzles.length - completedCount} puzzle${puzzles.length - completedCount == 1 ? '' : 's'} left to solve',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
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

class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard({required this.puzzle, required this.progress});

  final Puzzle puzzle;
  final PuzzleProgress progress;

  @override
  Widget build(BuildContext context) {
    final isSolved = progress.isCompleted;
    const solvedGreen = Color(0xFF15803D);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isSolved
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
              )
            : const LinearGradient(colors: [Colors.white, Colors.white]),
        border: Border.all(
          color: isSolved ? const Color(0xFF86EFAC) : const Color(0xFFD7E2F3),
          width: isSolved ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSolved
                ? solvedGreen.withValues(alpha: 0.10)
                : const Color(0xFF0F2F68).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PuzzlePlayerScreen(puzzle: puzzle),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 430;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: isSolved
                              ? const [Color(0xFF15803D), Color(0xFF34D399)]
                              : const [Color(0xFF123D9B), Color(0xFF56C4FF)],
                        ),
                      ),
                      child: Icon(
                        isSolved ? Icons.check_rounded : _iconFor(puzzle.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MiniTag(puzzle.type.label),
                              _MiniTag(puzzle.language),
                              _MiniTag(puzzle.difficulty),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            puzzle.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isSolved
                                      ? const Color(0xFF14532D)
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            puzzle.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ProgressPill(
                                label: 'Attempts ${progress.attempts}',
                                color: const Color(0xFF123D9B),
                              ),
                              _ProgressPill(
                                label: 'Best ${progress.bestScore}%',
                                color: const Color(0xFF0EA5E9),
                              ),
                              _ProgressPill(
                                label: isSolved ? 'Completed' : 'Not started',
                                color: isSolved
                                    ? solvedGreen
                                    : const Color(0xFFEA580C),
                                icon: isSolved
                                    ? Icons.check_circle_rounded
                                    : Icons.play_circle_outline_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (isSolved ? solvedGreen : const Color(0xFF123D9B))
                                  .withValues(alpha: 0.10),
                        ),
                        child: Icon(
                          isSolved
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          color: isSolved
                              ? solvedGreen
                              : const Color(0xFF123D9B),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(PuzzleType type) {
    switch (type) {
      case PuzzleType.codeFlow:
        return Icons.swap_vert_rounded;
      case PuzzleType.outputPrediction:
        return Icons.visibility_rounded;
      case PuzzleType.debugBug:
        return Icons.bug_report_rounded;
    }
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return InfoChip(label: label);
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InfoChip(
      label: label,
      icon: icon,
      backgroundColor: color.withValues(alpha: 0.10),
      foregroundColor: color,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ContentStateCard(
      icon: Icons.extension_rounded,
      title: title,
      message: message,
    );
  }
}
