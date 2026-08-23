import 'package:pseudocode_apk/models/achievement.dart';

class LearningReward {
  const LearningReward({
    required this.activityTitle,
    required this.activityType,
    required this.xpAwarded,
    required this.newTotalXp,
    required this.previousLevel,
    required this.newLevel,
    required this.currentStreak,
    required this.unlockedBadges,
    required this.message,
  });

  final String activityTitle;
  final String activityType;
  final int xpAwarded;
  final int newTotalXp;
  final int previousLevel;
  final int newLevel;
  final int currentStreak;
  final List<Achievement> unlockedBadges;
  final String message;

  bool get leveledUp => newLevel > previousLevel;
  bool get hasUnlockedBadges => unlockedBadges.isNotEmpty;
}
