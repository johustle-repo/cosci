import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/activity_gamification_card.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/reward_popup_dialog.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/widgets/code_flow_puzzle_view.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/widgets/debug_bug_puzzle_view.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/widgets/output_prediction_puzzle_view.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/info_chip.dart';

class PuzzlePlayerScreen extends StatelessWidget {
  const PuzzlePlayerScreen({super.key, required this.puzzle});

  final Puzzle puzzle;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PuzzlesProvider>();
    final progress = provider.progressFor(puzzle.id);

    final content = ListView(
      padding: AppScaffold.pagePadding(context),
      children: [
        _PuzzleHero(puzzle: puzzle, progress: progress),
        const SizedBox(height: 12),
        ActivityGamificationCard(
          rewardXp: puzzle.xpReward,
          requirement: 'Solve the puzzle correctly to earn the reward.',
          completed: progress.isCompleted,
        ),
        const SizedBox(height: 18),
        if (provider.errorMessage != null) ...[
          _FeedbackBanner(message: provider.errorMessage!, isError: true),
          const SizedBox(height: 12),
        ] else if (provider.statusMessage != null) ...[
          _FeedbackBanner(message: provider.statusMessage!),
          const SizedBox(height: 12),
        ],
        switch (puzzle.type) {
          PuzzleType.codeFlow => CodeFlowPuzzleView(puzzle: puzzle),
          PuzzleType.outputPrediction => OutputPredictionPuzzleView(
            puzzle: puzzle,
          ),
          PuzzleType.debugBug => DebugBugPuzzleView(puzzle: puzzle),
        },
      ],
    );

    return AppScaffold(
      title: puzzle.title,
      body: content,
      maxContentWidth: 980,
    );
  }

  static Future<void> showRewardIfNeeded(BuildContext context) async {
    final reward = context.read<PuzzlesProvider>().latestReward;
    if (reward == null) {
      return;
    }

    await RewardPopupDialog.show(context, reward);
    if (!context.mounted) {
      return;
    }
    context.read<PuzzlesProvider>().clearLatestReward();
  }
}

class _PuzzleHero extends StatelessWidget {
  const _PuzzleHero({required this.puzzle, required this.progress});

  final Puzzle puzzle;
  final PuzzleProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A3B), Color(0xFF0D285A), Color(0xFF123C81)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(label: puzzle.type.label),
              _HeroChip(label: puzzle.language),
              _HeroChip(label: puzzle.difficulty),
              _HeroChip(label: '+${puzzle.xpReward} XP'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            puzzle.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            puzzle.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroMetric(
                label: 'Attempts',
                value: progress.attempts.toString(),
              ),
              _HeroMetric(label: 'Best Score', value: '${progress.bestScore}%'),
              _HeroMetric(
                label: 'Status',
                value: progress.isCompleted ? 'Solved' : 'Open',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InfoChip(
      label: label,
      backgroundColor: Colors.white.withValues(alpha: 0.10),
      foregroundColor: Colors.white,
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
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.all(14),
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
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isError ? const Color(0xFFFFF1F1) : const Color(0xFFEAF3FF),
        border: Border.all(
          color: isError ? const Color(0xFFF4CCCC) : const Color(0xFFD5E4FF),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? const Color(0xFF9F1C1C) : const Color(0xFF123D9B),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
