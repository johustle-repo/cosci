import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/quizzes/presentation/screens/quiz_player_screen.dart';
import 'package:pseudocode_apk/providers/quizzes_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/content_state_card.dart';
import 'package:pseudocode_apk/shared/widgets/info_chip.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizzesProvider>().loadQuizzes(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizzesProvider = context.watch<QuizzesProvider>();
    final quizzes = quizzesProvider.quizzes;

    final content = Padding(
      padding: AppScaffold.pagePadding(context),
      child: quizzesProvider.isLoading && quizzes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : quizzesProvider.errorMessage != null && quizzes.isEmpty
          ? _QuizzesStateCard(
              icon: Icons.cloud_off_rounded,
              title: 'Quiz content unavailable',
              message: quizzesProvider.errorMessage!,
              actionLabel: 'Try again',
              onPressed: () => context.read<QuizzesProvider>().loadQuizzes(
                forceRefresh: true,
              ),
            )
          : quizzesProvider.isEmpty
          ? _QuizzesStateCard(
              icon: Icons.quiz_rounded,
              title: 'No quizzes yet',
              message:
                  'No quiz content is available yet. Add quiz documents in Firestore to populate this section.',
              actionLabel: 'Refresh',
              onPressed: () => context.read<QuizzesProvider>().loadQuizzes(
                forceRefresh: true,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quizzes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sharpen comprehension and logic with Firebase-backed quizzes, clear score states, and reward-linked progress.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: quizzes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];
                      final attempts = quizzesProvider.attemptsFor(quiz.id);
                      final latest = attempts.isEmpty ? null : attempts.first;
                      final bestScore = attempts.isEmpty
                          ? null
                          : attempts
                                .map((attempt) => attempt.scorePercent)
                                .reduce(
                                  (first, second) =>
                                      first > second ? first : second,
                                );
                      final attemptsRemaining =
                          (quiz.attemptLimit - attempts.length).clamp(
                            0,
                            quiz.attemptLimit,
                          );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF123D9B),
                                          Color(0xFF56C4FF),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.quiz_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quiz.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            InfoChip(
                                              label: '${quiz.totalItems} items',
                                            ),
                                            InfoChip(label: quiz.language),
                                            InfoChip(label: quiz.difficulty),
                                            if (quiz.topic.isNotEmpty)
                                              InfoChip(label: quiz.topic),
                                            InfoChip(
                                              label: '${quiz.xpReward} XP',
                                              backgroundColor: const Color(
                                                0xFFFFF7ED,
                                              ),
                                              foregroundColor: const Color(
                                                0xFFC2410C,
                                              ),
                                            ),
                                            InfoChip(
                                              label:
                                                  'Pass ${quiz.passingScore}%',
                                              backgroundColor: const Color(
                                                0xFFE8F7EE,
                                              ),
                                              foregroundColor: const Color(
                                                0xFF15803D,
                                              ),
                                            ),
                                            if (latest != null)
                                              InfoChip(
                                                label: latest.passed
                                                    ? 'Taken · Passed'
                                                    : 'Taken · Needs retry',
                                                backgroundColor: latest.passed
                                                    ? const Color(0xFFE8F7EE)
                                                    : const Color(0xFFFFF3E6),
                                                foregroundColor: latest.passed
                                                    ? const Color(0xFF15803D)
                                                    : const Color(0xFFB45309),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                quiz.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (latest != null) ...[
                                const SizedBox(height: 14),
                                _TakenQuizSummary(
                                  latestScore: latest.scorePercent,
                                  bestScore: bestScore!,
                                  passed: latest.passed,
                                  attemptsUsed: attempts.length,
                                  attemptLimit: quiz.attemptLimit,
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            QuizPlayerScreen(quiz: quiz),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    latest == null
                                        ? Icons.play_circle_rounded
                                        : attemptsRemaining > 0
                                        ? Icons.replay_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                  label: Text(
                                    latest == null
                                        ? 'Start Quiz'
                                        : attemptsRemaining > 0
                                        ? 'Retake Quiz · $attemptsRemaining remaining'
                                        : 'View Score · No attempts remaining',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );

    if (widget.embedded) {
      return content;
    }

    return AppScaffold(title: 'Quizzes', body: content, maxContentWidth: 1280);
  }
}

class _TakenQuizSummary extends StatelessWidget {
  const _TakenQuizSummary({
    required this.latestScore,
    required this.bestScore,
    required this.passed,
    required this.attemptsUsed,
    required this.attemptLimit,
  });

  final int latestScore;
  final int bestScore;
  final bool passed;
  final int attemptsUsed;
  final int attemptLimit;

  @override
  Widget build(BuildContext context) {
    final color = passed ? const Color(0xFF15803D) : const Color(0xFFB45309);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _TakenMetric(
            icon: passed
                ? Icons.check_circle_rounded
                : Icons.assignment_turned_in_rounded,
            label: passed ? 'Test taken · Passed' : 'Test taken',
            color: color,
          ),
          _TakenMetric(
            icon: Icons.score_rounded,
            label: 'Latest score $latestScore%',
            color: const Color(0xFF123D9B),
          ),
          _TakenMetric(
            icon: Icons.emoji_events_rounded,
            label: 'Best score $bestScore%',
            color: const Color(0xFF7C3AED),
          ),
          _TakenMetric(
            icon: Icons.repeat_rounded,
            label: '$attemptsUsed of $attemptLimit attempts used',
            color: const Color(0xFF475569),
          ),
        ],
      ),
    );
  }
}

class _TakenMetric extends StatelessWidget {
  const _TakenMetric({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _QuizzesStateCard extends StatelessWidget {
  const _QuizzesStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ContentStateCard(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onPressed: onPressed,
    );
  }
}
