import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_profile.dart';

/// One graded quiz attempt, as stored in `quiz_attempts`.
class StudentQuizAttempt {
  const StudentQuizAttempt({
    required this.userId,
    required this.quizId,
    required this.scorePercent,
    required this.passed,
    this.quizTitle = '',
    this.createdAt,
  });

  final String userId;
  final String quizId;
  final String quizTitle;
  final int scorePercent;
  final bool passed;
  final DateTime? createdAt;

  factory StudentQuizAttempt.fromMap(Map<String, dynamic> map) {
    final created = map['createdAt'];
    return StudentQuizAttempt(
      userId: (map['userId'] ?? '').toString(),
      quizId: (map['quizId'] ?? '').toString(),
      quizTitle: (map['title'] ?? '').toString(),
      scorePercent: (map['scorePercent'] as num?)?.round() ?? 0,
      passed: map['passed'] == true,
      createdAt: created is Timestamp
          ? created.toDate()
          : created is DateTime
          ? created
          : DateTime.tryParse(created?.toString() ?? ''),
    );
  }
}

/// Published content totals used to compute completion percentages.
class ContentTotals {
  const ContentTotals({
    this.lessons = 0,
    this.quizzes = 0,
    this.puzzles = 0,
    this.quizAttemptLimits = const {},
  });

  final int lessons;
  final int quizzes;
  final int puzzles;

  /// quizId → attempt limit (default 3 when missing).
  final Map<String, int> quizAttemptLimits;

  int get total => lessons + quizzes + puzzles;
}

/// Why a student was flagged as needing help.
enum HelpReason {
  inactive('Inactive', 'No learning activity in the last 7 days.'),
  noProgress(
    'No progress',
    'Has not completed any lesson, quiz, or puzzle yet.',
  ),
  lowQuizAverage('Low quiz average', 'Average quiz score is below 60%.'),
  repeatedQuizFailures(
    'Repeated quiz failures',
    'Failed the same quiz at least twice without passing.',
  ),
  exhaustedQuizAttempts(
    'Out of quiz attempts',
    'Used every attempt on a quiz without passing it.',
  );

  const HelpReason(this.label, this.description);
  final String label;
  final String description;
}

enum HelpSeverity { none, medium, high }

enum LeaderboardMetric {
  xp('Total XP'),
  completion('Completion'),
  quizAverage('Quiz average'),
  streak('Streak');

  const LeaderboardMetric(this.label);
  final String label;
}

/// Progress and risk summary for one student.
class StudentAnalyticsRow {
  const StudentAnalyticsRow({
    required this.profile,
    required this.quizAttempts,
    required this.passedQuizzes,
    required this.quizAverage,
    required this.completionPercent,
    required this.lastActiveAt,
    required this.reasons,
    required this.strugglingQuizTitles,
  });

  final AdminStudentProfile profile;
  final int quizAttempts;

  /// Distinct quizzes passed at least once.
  final int passedQuizzes;

  /// Average score across all attempts, or null with no attempts.
  final int? quizAverage;
  final int completionPercent;
  final DateTime? lastActiveAt;
  final List<HelpReason> reasons;

  /// Quizzes failed repeatedly or exhausted without a pass.
  final List<String> strugglingQuizTitles;

  bool get needsHelp => reasons.isNotEmpty;

  HelpSeverity get severity {
    if (reasons.isEmpty) return HelpSeverity.none;
    if (reasons.length >= 2 ||
        reasons.contains(HelpReason.exhaustedQuizAttempts)) {
      return HelpSeverity.high;
    }
    return HelpSeverity.medium;
  }

  int get completedActivities =>
      profile.completedLessons + passedQuizzes + profile.completedPuzzles;

  num metricValue(LeaderboardMetric metric) => switch (metric) {
    LeaderboardMetric.xp => profile.totalXp,
    LeaderboardMetric.completion => completionPercent,
    LeaderboardMetric.quizAverage => quizAverage ?? -1,
    LeaderboardMetric.streak => profile.streakDays,
  };
}

/// Builds analytics rows and rankings from raw admin data.
class StudentAnalyticsCalculator {
  const StudentAnalyticsCalculator._();

  static const inactiveAfter = Duration(days: 7);
  static const lowQuizAverageThreshold = 60;
  static const repeatedFailureThreshold = 2;

  static List<StudentAnalyticsRow> build({
    required List<AdminStudentProfile> students,
    required List<StudentQuizAttempt> attempts,
    required ContentTotals totals,
    required DateTime now,
  }) {
    final attemptsByUser = <String, List<StudentQuizAttempt>>{};
    for (final attempt in attempts) {
      attemptsByUser.putIfAbsent(attempt.userId, () => []).add(attempt);
    }
    return [
      for (final student in students)
        _row(student, attemptsByUser[student.uid] ?? const [], totals, now),
    ];
  }

  static StudentAnalyticsRow _row(
    AdminStudentProfile student,
    List<StudentQuizAttempt> attempts,
    ContentTotals totals,
    DateTime now,
  ) {
    final byQuiz = <String, List<StudentQuizAttempt>>{};
    for (final attempt in attempts) {
      byQuiz.putIfAbsent(attempt.quizId, () => []).add(attempt);
    }

    var passedQuizzes = 0;
    var repeatedFailures = false;
    var exhausted = false;
    final struggling = <String>[];
    byQuiz.forEach((quizId, quizAttempts) {
      if (quizAttempts.any((a) => a.passed)) {
        passedQuizzes++;
        return;
      }
      final limit = totals.quizAttemptLimits[quizId] ?? 3;
      final failures = quizAttempts.length;
      final title = quizAttempts.first.quizTitle.isNotEmpty
          ? quizAttempts.first.quizTitle
          : 'Quiz';
      if (failures >= limit) {
        exhausted = true;
        struggling.add(title);
      } else if (failures >= repeatedFailureThreshold) {
        repeatedFailures = true;
        struggling.add(title);
      }
    });

    final quizAverage = attempts.isEmpty
        ? null
        : (attempts.map((a) => a.scorePercent).reduce((a, b) => a + b) /
                  attempts.length)
              .round();

    final completed =
        student.completedLessons + passedQuizzes + student.completedPuzzles;
    final completionPercent = totals.total == 0
        ? 0
        : (completed * 100 / totals.total).round().clamp(0, 100);

    final lastActiveAt = _latest([
      student.lastActivityAt,
      student.lastLoginAt,
      ...attempts.map((a) => a.createdAt),
    ]);

    final accountAge = student.createdAt == null
        ? null
        : now.difference(student.createdAt!);
    final isNewAccount = accountAge != null && accountAge < inactiveAfter;

    final reasons = <HelpReason>[
      if (!isNewAccount &&
          (lastActiveAt == null ||
              now.difference(lastActiveAt) > inactiveAfter))
        HelpReason.inactive,
      if (!isNewAccount && completed == 0) HelpReason.noProgress,
      if (attempts.length >= 2 &&
          quizAverage != null &&
          quizAverage < lowQuizAverageThreshold)
        HelpReason.lowQuizAverage,
      if (repeatedFailures) HelpReason.repeatedQuizFailures,
      if (exhausted) HelpReason.exhaustedQuizAttempts,
    ];

    return StudentAnalyticsRow(
      profile: student,
      quizAttempts: attempts.length,
      passedQuizzes: passedQuizzes,
      quizAverage: quizAverage,
      completionPercent: completionPercent,
      lastActiveAt: lastActiveAt,
      reasons: reasons,
      strugglingQuizTitles: struggling,
    );
  }

  /// Students needing help, most urgent first.
  static List<StudentAnalyticsRow> needsHelp(List<StudentAnalyticsRow> rows) {
    final flagged = rows.where((row) => row.needsHelp).toList();
    flagged.sort((a, b) {
      final severity = b.severity.index.compareTo(a.severity.index);
      if (severity != 0) return severity;
      final count = b.reasons.length.compareTo(a.reasons.length);
      if (count != 0) return count;
      return (a.quizAverage ?? 101).compareTo(b.quizAverage ?? 101);
    });
    return flagged;
  }

  /// Rows ranked by [metric] (highest first), ties broken by XP then name.
  static List<StudentAnalyticsRow> leaderboard(
    List<StudentAnalyticsRow> rows,
    LeaderboardMetric metric,
  ) {
    final ranked = List<StudentAnalyticsRow>.from(rows);
    ranked.sort((a, b) {
      final primary = b.metricValue(metric).compareTo(a.metricValue(metric));
      if (primary != 0) return primary;
      final xp = b.profile.totalXp.compareTo(a.profile.totalXp);
      if (xp != 0) return xp;
      return a.profile.displayName.toLowerCase().compareTo(
        b.profile.displayName.toLowerCase(),
      );
    });
    return ranked;
  }

  static DateTime? _latest(Iterable<DateTime?> values) {
    DateTime? latest;
    for (final value in values) {
      if (value != null && (latest == null || value.isAfter(latest))) {
        latest = value;
      }
    }
    return latest;
  }
}
