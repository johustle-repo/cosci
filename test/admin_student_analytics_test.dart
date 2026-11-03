import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_analytics.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_profile.dart';

final _now = DateTime(2026, 11, 3, 12);

AdminStudentProfile _student(
  String uid, {
  String name = 'Student',
  int xp = 0,
  int streak = 0,
  int lessons = 0,
  int puzzles = 0,
  DateTime? lastActivity,
  DateTime? createdAt,
}) {
  return AdminStudentProfile(
    uid: uid,
    email: '$uid@psu.edu.ph',
    displayName: name,
    role: 'student',
    isActive: true,
    course: 'BSCS',
    yearLevel: '1st Year',
    totalXp: xp,
    currentLevel: 1,
    streakDays: streak,
    badgesEarned: 0,
    completedLessons: lessons,
    completedQuizzes: 0,
    completedPuzzles: puzzles,
    completedChallenges: 0,
    lastActivityAt: lastActivity,
    createdAt: createdAt ?? _now.subtract(const Duration(days: 60)),
  );
}

StudentQuizAttempt _attempt(String uid, String quiz, int score, bool passed) =>
    StudentQuizAttempt(
      userId: uid,
      quizId: quiz,
      quizTitle: 'Quiz $quiz',
      scorePercent: score,
      passed: passed,
      createdAt: _now.subtract(const Duration(days: 1)),
    );

const _totals = ContentTotals(
  lessons: 4,
  quizzes: 2,
  puzzles: 4,
  quizAttemptLimits: {'q1': 3, 'q2': 3},
);

List<StudentAnalyticsRow> _build(
  List<AdminStudentProfile> students, [
  List<StudentQuizAttempt> attempts = const [],
]) => StudentAnalyticsCalculator.build(
  students: students,
  attempts: attempts,
  totals: _totals,
  now: _now,
);

void main() {
  test('active student with progress and good scores is on track', () {
    final rows = _build(
      [
        _student(
          'a',
          lessons: 2,
          puzzles: 1,
          lastActivity: _now.subtract(const Duration(days: 1)),
        ),
      ],
      [_attempt('a', 'q1', 90, true)],
    );
    final row = rows.single;
    expect(row.needsHelp, isFalse);
    expect(row.passedQuizzes, 1);
    expect(row.quizAverage, 90);
    // (2 lessons + 1 quiz + 1 puzzle) / 10 published items.
    expect(row.completionPercent, 40);
  });

  test('inactive student with no progress is high priority', () {
    final row = _build([_student('b')]).single;
    expect(row.reasons, [HelpReason.inactive, HelpReason.noProgress]);
    expect(row.severity, HelpSeverity.high);
  });

  test('new accounts are not flagged for inactivity or no progress', () {
    final row = _build([
      _student('c', createdAt: _now.subtract(const Duration(days: 2))),
    ]).single;
    expect(row.needsHelp, isFalse);
  });

  test('repeated failures and low average are flagged', () {
    final row = _build(
      [
        _student(
          'd',
          lessons: 1,
          lastActivity: _now.subtract(const Duration(hours: 3)),
        ),
      ],
      [_attempt('d', 'q1', 40, false), _attempt('d', 'q1', 50, false)],
    ).single;
    expect(
      row.reasons,
      containsAll([HelpReason.lowQuizAverage, HelpReason.repeatedQuizFailures]),
    );
    expect(row.strugglingQuizTitles, ['Quiz q1']);
  });

  test('using every attempt without passing is high priority', () {
    final row = _build(
      [_student('e', lessons: 3, lastActivity: _now)],
      [
        _attempt('e', 'q2', 70, false),
        _attempt('e', 'q2', 75, false),
        _attempt('e', 'q2', 78, false),
      ],
    ).single;
    expect(row.reasons, [HelpReason.exhaustedQuizAttempts]);
    expect(row.severity, HelpSeverity.high);
  });

  test('needs-help list puts high priority first', () {
    final rows = _build(
      [
        _student('medium', lessons: 1, lastActivity: _now),
        _student('high'),
        _student('fine', lessons: 1, lastActivity: _now),
      ],
      [
        // Low average across two different quizzes = one reason (medium).
        _attempt('medium', 'q1', 30, false),
        _attempt('medium', 'q2', 40, false),
        _attempt('fine', 'q1', 95, true),
      ],
    );
    final flagged = StudentAnalyticsCalculator.needsHelp(rows);
    expect(flagged.map((r) => r.profile.uid), ['high', 'medium']);
  });

  test('leaderboard ranks by metric with XP and name tie-breakers', () {
    final rows = _build([
      _student('a', name: 'Ana', xp: 100, streak: 5, lastActivity: _now),
      _student('b', name: 'Ben', xp: 300, streak: 2, lastActivity: _now),
      _student('c', name: 'Cy', xp: 300, streak: 5, lastActivity: _now),
    ]);
    expect(
      StudentAnalyticsCalculator.leaderboard(
        rows,
        LeaderboardMetric.xp,
      ).map((r) => r.profile.displayName),
      ['Ben', 'Cy', 'Ana'],
    );
    expect(
      StudentAnalyticsCalculator.leaderboard(
        rows,
        LeaderboardMetric.streak,
      ).map((r) => r.profile.displayName),
      ['Cy', 'Ana', 'Ben'],
    );
  });
}
