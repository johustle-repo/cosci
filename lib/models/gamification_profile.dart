import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/achievement.dart';

class GamificationProfile {
  const GamificationProfile({
    required this.totalXp,
    required this.level,
    required this.currentLevelFloorXp,
    required this.nextLevelXp,
    required this.dailyStreak,
    required this.completedChallenges,
    required this.completedLessons,
    required this.completedQuizzes,
    required this.completedPuzzles,
    required this.highScoreQuizCount,
    required this.lastActivityAt,
    required this.badges,
  });

  static const List<int> levelThresholds = [
    0,
    60,
    150,
    280,
    450,
    680,
    960,
    1300,
    1700,
    2150,
    2650,
  ];

  final int totalXp;
  final int level;
  final int currentLevelFloorXp;
  final int nextLevelXp;
  final int dailyStreak;
  final int completedChallenges;
  final int completedLessons;
  final int completedQuizzes;
  final int completedPuzzles;
  final int highScoreQuizCount;
  final DateTime? lastActivityAt;
  final List<Achievement> badges;

  double get levelProgress {
    if (nextLevelXp <= currentLevelFloorXp) {
      return 1;
    }

    final span = nextLevelXp - currentLevelFloorXp;
    final progress = totalXp - currentLevelFloorXp;
    return (progress / span).clamp(0.0, 1.0);
  }

  int get xpIntoCurrentLevel =>
      (totalXp - currentLevelFloorXp).clamp(0, totalXp);

  int get xpNeededForNextLevel => (nextLevelXp - totalXp).clamp(0, nextLevelXp);

  bool get hasUnlockedBadges => badges.any((badge) => badge.isUnlocked);

  factory GamificationProfile.empty() {
    return GamificationProfile(
      totalXp: 0,
      level: 1,
      currentLevelFloorXp: 0,
      nextLevelXp: levelThresholds[1],
      dailyStreak: 0,
      completedChallenges: 0,
      completedLessons: 0,
      completedQuizzes: 0,
      completedPuzzles: 0,
      highScoreQuizCount: 0,
      lastActivityAt: null,
      badges: const [],
    );
  }

  factory GamificationProfile.fromFirestore({
    required Map<String, dynamic>? profileData,
    required Map<String, dynamic>? progressData,
    required List<Achievement> badges,
    List<int>? configuredLevelThresholds,
  }) {
    final totalXp =
        _readInt(profileData?['totalXp']) ??
        _readInt(profileData?['points']) ??
        _readInt(progressData?['totalXp']) ??
        _readInt(progressData?['points']) ??
        0;
    final thresholds = _validThresholds(configuredLevelThresholds);
    final level = resolveLevel(totalXp, thresholds: thresholds);

    return GamificationProfile(
      totalXp: totalXp,
      level: level,
      currentLevelFloorXp: floorXpForLevel(level, thresholds: thresholds),
      nextLevelXp: nextLevelThreshold(totalXp, thresholds: thresholds),
      dailyStreak:
          _readInt(profileData?['streakDays']) ??
          _readInt(progressData?['streakDays']) ??
          0,
      completedChallenges:
          _readInt(progressData?['completedChallenges']) ??
          _readInt(profileData?['completedChallenges']) ??
          0,
      completedLessons: _readInt(progressData?['completedLessons']) ?? 0,
      completedQuizzes: _readInt(progressData?['completedQuizzes']) ?? 0,
      completedPuzzles: _readInt(progressData?['completedPuzzles']) ?? 0,
      highScoreQuizCount: _readInt(progressData?['highScoreQuizCount']) ?? 0,
      lastActivityAt:
          _parseTimestamp(progressData?['lastActivityAt']) ??
          _parseTimestamp(profileData?['lastActivityAt']),
      badges: badges,
    );
  }

  static int resolveLevel(int xp, {List<int>? thresholds}) {
    final values = _validThresholds(thresholds);
    for (var index = values.length - 1; index >= 0; index--) {
      if (xp >= values[index]) {
        return index + 1;
      }
    }

    return 1;
  }

  static int floorXpForLevel(int level, {List<int>? thresholds}) {
    final values = _validThresholds(thresholds);
    final safeIndex = (level - 1).clamp(0, values.length - 1);
    return values[safeIndex];
  }

  static int nextLevelThreshold(int xp, {List<int>? thresholds}) {
    final values = _validThresholds(thresholds);
    for (final threshold in values) {
      if (threshold > xp) {
        return threshold;
      }
    }

    return xp;
  }

  static List<int> _validThresholds(List<int>? configured) {
    if (configured == null || configured.length < 2) return levelThresholds;
    final values = configured.toSet().toList()..sort();
    return values.first == 0 ? values : [0, ...values];
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
