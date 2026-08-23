import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/activity_gamification_card.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/reward_popup_dialog.dart';
import 'package:pseudocode_apk/features/quizzes/services/quiz_draft_service.dart';
import 'package:pseudocode_apk/models/quiz.dart';
import 'package:pseudocode_apk/models/quiz_question.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';
import 'package:pseudocode_apk/providers/quizzes_provider.dart';
import 'package:pseudocode_apk/services/quiz_service.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/content_state_card.dart';
import 'package:pseudocode_apk/shared/widgets/info_chip.dart';

class QuizPlayerScreen extends StatefulWidget {
  const QuizPlayerScreen({super.key, required this.quiz});

  final Quiz quiz;

  @override
  State<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends State<QuizPlayerScreen> {
  final Map<String, String> _answers = {};
  bool _submitted = false;
  int _scorePercent = 0;
  bool _submitting = false;
  Map<String, Map<String, dynamic>> _feedback = const {};
  _DraftStatus _draftStatus = _DraftStatus.loading;
  DateTime? _draftSavedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQuiz();
    });
  }

  String get _userId =>
      context.read<AuthProvider>().currentUser?.uid.trim() ?? '';

  Future<void> _initializeQuiz() async {
    final questions = await context.read<QuizzesProvider>().loadQuestionsFor(
      widget.quiz,
    );
    if (!mounted) return;
    final draft = await QuizDraftService.load(
      userId: _userId,
      quizId: widget.quiz.id,
    );
    if (!mounted) return;
    final availableOptions = {
      for (final question in questions) question.id: question.options.toSet(),
    };
    final restored = <String, String>{};
    if (draft != null) {
      for (final entry in draft.answers.entries) {
        if (availableOptions[entry.key]?.contains(entry.value) ?? false) {
          restored[entry.key] = entry.value;
        }
      }
    }
    setState(() {
      _answers
        ..clear()
        ..addAll(restored);
      _draftSavedAt = draft?.savedAt;
      _draftStatus = restored.isEmpty
          ? _DraftStatus.ready
          : _DraftStatus.restored;
    });
  }

  Future<void> _saveAnswers() async {
    if (_submitted || _userId.isEmpty) return;
    setState(() => _draftStatus = _DraftStatus.saving);
    final saved = await QuizDraftService.save(
      userId: _userId,
      quizId: widget.quiz.id,
      answers: Map.unmodifiable(_answers),
    );
    if (!mounted) return;
    setState(() {
      _draftStatus = saved ? _DraftStatus.saved : _DraftStatus.unavailable;
      if (saved) _draftSavedAt = DateTime.now();
    });
  }

  Future<void> _clearDraft() =>
      QuizDraftService.clear(userId: _userId, quizId: widget.quiz.id);

  Future<void> _submit(List<QuizQuestion> questions) async {
    if (questions.isEmpty) {
      return;
    }

    setState(() => _submitting = true);
    late final QuizEvaluationResult evaluation;
    try {
      evaluation = await context.read<QuizzesProvider>().submitQuiz(
        widget.quiz,
        Map.unmodifiable(_answers),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
        setState(() => _submitting = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _submitted = true;
      _submitting = false;
      _scorePercent = evaluation.scorePercent;
      _feedback = evaluation.feedback;
      _draftStatus = _DraftStatus.ready;
      _draftSavedAt = null;
    });
    await _clearDraft();
    if (!mounted) return;

    final reward = await context.read<GamificationProvider>().completeQuiz(
      quizId: widget.quiz.id,
      title: widget.quiz.title,
      scorePercent: evaluation.scorePercent,
      passingScore: widget.quiz.passingScore,
    );

    if (!mounted) {
      return;
    }

    if (reward != null) {
      await RewardPopupDialog.show(context, reward);
      if (!mounted) {
        return;
      }
      context.read<GamificationProvider>().clearLatestReward();
      return;
    }

    final gamification = context.read<GamificationProvider>();
    final message = gamification.errorMessage ?? gamification.statusMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzesProvider = context.watch<QuizzesProvider>();
    final questions = quizzesProvider.questionsFor(widget.quiz.id);
    final attempts = quizzesProvider.attemptsFor(widget.quiz.id);
    final attemptsRemaining = (widget.quiz.attemptLimit - attempts.length)
        .clamp(0, widget.quiz.attemptLimit);

    final content = RefreshIndicator(
      onRefresh: () => context.read<QuizzesProvider>().loadQuestionsFor(
        widget.quiz,
        forceRefresh: true,
      ),
      child: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          _QuizHero(
            quiz: widget.quiz,
            answered: _answers.length,
            total: questions.length,
            submitted: _submitted,
            scorePercent: _scorePercent,
          ),
          const SizedBox(height: 10),
          _AutoSaveNotice(
            status: _draftStatus,
            savedAt: _draftSavedAt,
            answered: _answers.length,
          ),
          const SizedBox(height: 12),
          ActivityGamificationCard(
            rewardXp: widget.quiz.xpReward,
            requirement:
                'Score at least ${widget.quiz.passingScore}% to earn the reward.',
            completed: _submitted && _scorePercent >= widget.quiz.passingScore,
          ),
          const SizedBox(height: 12),
          _AttemptSummary(
            attempts: attempts,
            limit: widget.quiz.attemptLimit,
            passingScore: widget.quiz.passingScore,
          ),
          const SizedBox(height: 18),
          if (quizzesProvider.isLoadingQuestions && questions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (quizzesProvider.errorMessage != null && questions.isEmpty)
            ContentStateCard(
              icon: Icons.cloud_off_rounded,
              title: 'Questions unavailable',
              message: quizzesProvider.errorMessage!,
              actionLabel: 'Try again',
              onPressed: () => context.read<QuizzesProvider>().loadQuestionsFor(
                widget.quiz,
                forceRefresh: true,
              ),
            )
          else if (questions.isEmpty)
            const ContentStateCard(
              icon: Icons.quiz_rounded,
              title: 'No questions yet',
              message:
                  'This quiz is published, but it does not have questions yet.',
            )
          else ...[
            ...questions.map((question) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _QuestionCard(
                  question: question,
                  selectedAnswer: _answers[question.id],
                  submitted: _submitted,
                  feedback: _feedback[question.id],
                  onSelected: (answer) async {
                    if (_submitted) {
                      return;
                    }
                    setState(() => _answers[question.id] = answer);
                    await _saveAnswers();
                  },
                ),
              );
            }),
            FilledButton.icon(
              onPressed:
                  attemptsRemaining == 0 ||
                      _submitted ||
                      _submitting ||
                      _answers.length != questions.length
                  ? null
                  : () => _submit(questions),
              icon: const Icon(Icons.assignment_turned_in_rounded),
              label: Text(_submitting ? 'Grading securely...' : 'Submit Quiz'),
            ),
            if (_submitted) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: attemptsRemaining == 0
                    ? null
                    : () async {
                        setState(() {
                          _answers.clear();
                          _submitted = false;
                          _scorePercent = 0;
                          _feedback = const {};
                          _draftStatus = _DraftStatus.ready;
                          _draftSavedAt = null;
                        });
                        await _clearDraft();
                      },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retake Quiz'),
              ),
            ],
          ],
        ],
      ),
    );

    return AppScaffold(
      title: widget.quiz.title,
      body: content,
      maxContentWidth: 920,
    );
  }
}

class _AttemptSummary extends StatelessWidget {
  const _AttemptSummary({
    required this.attempts,
    required this.limit,
    required this.passingScore,
  });

  final List<QuizAttemptSummary> attempts;
  final int limit;
  final int passingScore;

  @override
  Widget build(BuildContext context) {
    final best = attempts.isEmpty
        ? null
        : attempts
              .map((attempt) => attempt.scorePercent)
              .reduce((first, second) => first > second ? first : second);
    final remaining = (limit - attempts.length).clamp(0, limit);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: Color(0xFF123D9B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quiz attempts',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        best == null
                            ? 'Pass at $passingScore% · $remaining of $limit attempts available'
                            : 'Best score $best% · $remaining attempts remaining',
                      ),
                    ],
                  ),
                ),
                _AttemptCountBadge(used: attempts.length, limit: limit),
              ],
            ),
            if (attempts.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attempts.take(5).map((attempt) {
                  final date = attempt.createdAt;
                  final dateLabel = date == null
                      ? 'Saved attempt'
                      : '${_month(date.month)} ${date.day}, ${date.year}';
                  return Chip(
                    avatar: Icon(
                      attempt.passed
                          ? Icons.check_circle_rounded
                          : Icons.replay_rounded,
                      size: 17,
                      color: attempt.passed
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                    ),
                    label: Text(
                      '#${attempt.attemptNumber} · ${attempt.scorePercent}% · $dateLabel',
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttemptCountBadge extends StatelessWidget {
  const _AttemptCountBadge({required this.used, required this.limit});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      '$used / $limit used',
      style: const TextStyle(
        color: Color(0xFF123D9B),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ignore: unused_element
class _LegacyAttemptSummary extends StatelessWidget {
  const _LegacyAttemptSummary({
    required this.attempts,
    required this.limit,
    required this.passingScore,
  });
  final List<QuizAttemptSummary> attempts;
  final int limit;
  final int passingScore;

  @override
  Widget build(BuildContext context) {
    final best = attempts.isEmpty
        ? null
        : attempts
              .map((item) => item.scorePercent)
              .reduce((a, b) => a > b ? a : b);
    final remaining = (limit - attempts.length).clamp(0, limit);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.insights_rounded, color: Color(0xFF123D9B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                best == null
                    ? 'Pass at $passingScore% • $remaining of $limit attempts available'
                    : 'Best score $best% • $remaining attempts remaining',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (attempts.isNotEmpty)
              Text(
                '${attempts.length} attempt${attempts.length == 1 ? '' : 's'}',
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizHero extends StatelessWidget {
  const _QuizHero({
    required this.quiz,
    required this.answered,
    required this.total,
    required this.submitted,
    required this.scorePercent,
  });

  final Quiz quiz;
  final int answered;
  final int total;
  final bool submitted;
  final int scorePercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071A3B), Color(0xFF123C81)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InfoChip(label: quiz.difficulty),
              InfoChip(label: quiz.language),
              if (quiz.topic.isNotEmpty) InfoChip(label: quiz.topic),
              InfoChip(label: '+${quiz.xpReward} XP'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            quiz.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            quiz.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            submitted
                ? 'Score: $scorePercent%'
                : 'Answered $answered of $total questions',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedAnswer,
    required this.submitted,
    required this.onSelected,
    required this.feedback,
  });

  final QuizQuestion question;
  final String? selectedAnswer;
  final bool submitted;
  final ValueChanged<String> onSelected;
  final Map<String, dynamic>? feedback;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.questionText,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (question.codeSnippet != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1730),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  question.codeSnippet!,
                  style: const TextStyle(
                    color: Color(0xFFEAF2FF),
                    fontFamily: 'monospace',
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...question.options.map((option) {
              final selected = selectedAnswer == option;
              final correct =
                  submitted &&
                  _normalize(option) ==
                      _normalize(feedback?['correctAnswer']?.toString());
              final showCorrect = submitted && correct;
              final showWrong = submitted && selected && !correct;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelected(option),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: showCorrect
                          ? const Color(0xFFE8F7EE)
                          : showWrong
                          ? const Color(0xFFFFF1F1)
                          : selected
                          ? const Color(0xFFEAF2FF)
                          : Colors.white,
                      border: Border.all(
                        color: showCorrect
                            ? const Color(0xFF15803D)
                            : showWrong
                            ? const Color(0xFFB91C1C)
                            : selected
                            ? const Color(0xFF123D9B)
                            : const Color(0xFFD8E4F4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          showCorrect
                              ? Icons.check_circle_rounded
                              : showWrong
                              ? Icons.cancel_rounded
                              : selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: showCorrect
                              ? const Color(0xFF15803D)
                              : showWrong
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF123D9B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(option)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (submitted &&
                (feedback?['explanation']?.toString().isNotEmpty ?? false)) ...[
              const SizedBox(height: 6),
              Text(
                feedback!['explanation'].toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _DraftStatus { loading, ready, saving, saved, restored, unavailable }

class _AutoSaveNotice extends StatelessWidget {
  const _AutoSaveNotice({
    required this.status,
    required this.savedAt,
    required this.answered,
  });

  final _DraftStatus status;
  final DateTime? savedAt;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final (icon, message, color) = switch (status) {
      _DraftStatus.loading => (
        Icons.sync_rounded,
        'Checking for a saved answer draft...',
        const Color(0xFF64748B),
      ),
      _DraftStatus.saving => (
        Icons.sync_rounded,
        'Saving your answers...',
        const Color(0xFF2563EB),
      ),
      _DraftStatus.saved => (
        Icons.cloud_done_rounded,
        'Answers saved automatically${_timeSuffix(savedAt)}.',
        const Color(0xFF15803D),
      ),
      _DraftStatus.restored => (
        Icons.restore_rounded,
        'Restored $answered saved answer${answered == 1 ? '' : 's'}.',
        const Color(0xFF2563EB),
      ),
      _DraftStatus.unavailable => (
        Icons.cloud_off_rounded,
        'Auto-save is temporarily unavailable.',
        const Color(0xFFB45309),
      ),
      _DraftStatus.ready => (
        Icons.cloud_queue_rounded,
        'Your selected answers will be saved automatically on this device.',
        const Color(0xFF64748B),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _timeSuffix(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return ' at $hour:$minute $period';
}

String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

String _normalize(String? value) => (value ?? '').trim().toLowerCase();
