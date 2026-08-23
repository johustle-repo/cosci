import 'package:pseudocode_apk/models/daily_challenge.dart';
import 'package:pseudocode_apk/models/dashboard_badge.dart';

class StudentDashboardData {
  const StudentDashboardData({
    required this.studentName,
    required this.currentLevel,
    required this.totalXp,
    required this.streakCount,
    required this.learningProgress,
    required this.completedLessons,
    required this.completedActivities,
    required this.dailyChallenge,
    required this.badges,
  });

  final String studentName;
  final int currentLevel;
  final int totalXp;
  final int streakCount;
  final double learningProgress;
  final int completedLessons;
  final int completedActivities;
  final DailyChallenge dailyChallenge;
  final List<DashboardBadge> badges;

  bool get hasBadges => badges.isNotEmpty;

  factory StudentDashboardData.empty({String studentName = 'Student'}) {
    return StudentDashboardData(
      studentName: studentName,
      currentLevel: 1,
      totalXp: 0,
      streakCount: 0,
      learningProgress: 0,
      completedLessons: 0,
      completedActivities: 0,
      dailyChallenge: const DailyChallenge(
        id: 'starter-challenge',
        title: 'Complete your first simulation',
        description:
            'Open the code simulation area and run through a simple Co-Sci exercise.',
        xpReward: 40,
        completionLabel: 'Start now',
      ),
      badges: const [],
    );
  }
}
