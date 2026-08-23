import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/dashboard_badge.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';

class ProgressSummary {
  const ProgressSummary({
    required this.completedLessons,
    required this.completedQuizzes,
    required this.completedPuzzles,
    required this.points,
    required this.streakDays,
    required this.currentLevel,
    required this.earnedBadges,
    required this.weakTopics,
    required this.recentActivities,
  });

  final int completedLessons;
  final int completedQuizzes;
  final int completedPuzzles;
  final int points;
  final int streakDays;
  final int currentLevel;
  final List<DashboardBadge> earnedBadges;
  final List<WeakTopic> weakTopics;
  final List<RecentLearningActivity> recentActivities;

  int get totalCompletedActivities =>
      completedLessons + completedQuizzes + completedPuzzles;

  double get lessonProgress => _ratio(completedLessons, 12);
  double get quizProgress => _ratio(completedQuizzes, 10);
  double get puzzleProgress => _ratio(completedPuzzles, 10);

  factory ProgressSummary.empty() {
    return const ProgressSummary(
      completedLessons: 0,
      completedQuizzes: 0,
      completedPuzzles: 0,
      points: 0,
      streakDays: 0,
      currentLevel: 1,
      earnedBadges: [],
      weakTopics: [],
      recentActivities: [],
    );
  }

  factory ProgressSummary.fromFirestore({
    required Map<String, dynamic>? progressData,
    required Map<String, dynamic>? profileData,
    required List<DashboardBadge> earnedBadges,
    required List<WeakTopic> weakTopics,
    required List<RecentLearningActivity> recentActivities,
  }) {
    final totalXp =
        _readInt(progressData?['totalXp']) ??
        _readInt(progressData?['points']) ??
        _readInt(profileData?['totalXp']) ??
        _readInt(profileData?['points']) ??
        0;

    return ProgressSummary(
      completedLessons: _readInt(progressData?['completedLessons']) ?? 0,
      completedQuizzes: _readInt(progressData?['completedQuizzes']) ?? 0,
      completedPuzzles: _readInt(progressData?['completedPuzzles']) ?? 0,
      points: totalXp,
      streakDays:
          _readInt(progressData?['streakDays']) ??
          _readInt(profileData?['streakDays']) ??
          0,
      currentLevel:
          _readInt(profileData?['currentLevel']) ??
          GamificationProfile.resolveLevel(totalXp),
      earnedBadges: earnedBadges,
      weakTopics: weakTopics,
      recentActivities: recentActivities,
    );
  }

  static double _ratio(int value, int target) {
    if (target <= 0) {
      return 0;
    }

    return (value / target).clamp(0.0, 1.0);
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

class WeakTopic {
  const WeakTopic({
    required this.title,
    required this.averageScore,
    required this.attempts,
    required this.recommendation,
  });

  final String title;
  final int averageScore;
  final int attempts;
  final String recommendation;
}

class RecentLearningActivity {
  const RecentLearningActivity({
    required this.title,
    required this.type,
    required this.xpAwarded,
    required this.completedAt,
    this.scorePercent,
  });

  final String title;
  final String type;
  final int xpAwarded;
  final DateTime completedAt;
  final int? scorePercent;

  String get relativeLabel {
    final now = DateTime.now();
    final difference = now.difference(completedAt);

    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  String get typeLabel {
    switch (type) {
      case 'simulation':
        return 'Simulation';
      case 'quiz':
        return 'Quiz';
      case 'puzzle':
        return 'Puzzle';
      case 'daily_challenge':
        return 'Daily Challenge';
      default:
        return 'Activity';
    }
  }

  factory RecentLearningActivity.fromMap(Map<String, dynamic> map) {
    return RecentLearningActivity(
      title: _readString(map['title'], fallback: 'Learning activity'),
      type: _readString(map['type'], fallback: 'activity'),
      xpAwarded: _readInt(map['xpAwarded']) ?? 0,
      completedAt: _parseDate(map['completedAt']) ?? DateTime.now(),
      scorePercent: _readInt(map['scorePercent']),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    return fallback;
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

  static DateTime? _parseDate(Object? value) {
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
}
