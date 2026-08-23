import 'package:pseudocode_apk/models/daily_challenge.dart';
import 'package:pseudocode_apk/models/dashboard_badge.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';
import 'package:pseudocode_apk/models/student_dashboard_data.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

class DashboardService {
  DashboardService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Future<StudentDashboardData> fetchDashboardData({
    required String userId,
    String? fallbackName,
  }) async {
    final userSnapshot = await _firestoreService.userDocument(userId).get();
    final profileSnapshot = await _firestoreService
        .userProfileDocument(userId)
        .get();
    final progressSnapshot = await _firestoreService
        .progressDocument(userId)
        .get();
    final today = DateTime.now();
    final todayKey =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayChallenges = await _firestoreService
        .dailyChallengesCollection()
        .where('date', isEqualTo: todayKey)
        .get();
    final currentSnapshot = await _firestoreService
        .dailyChallengeDocument('current')
        .get();
    final todayDocument = todayChallenges.docs
        .where((doc) => doc.data()['status'] != 'inactive')
        .firstOrNull;
    final badgesSnapshot = await _firestoreService
        .collection('user_profiles')
        .doc(userId)
        .collection('badges')
        .limit(4)
        .get();

    final userData = userSnapshot.data();
    final profileData = profileSnapshot.data();
    final progressData = progressSnapshot.data();

    final studentName =
        profileData?['displayName'] as String? ??
        userData?['displayName'] as String? ??
        fallbackName ??
        'Student';

    final totalXp =
        _readInt(profileData?['totalXp']) ??
        _readInt(profileData?['points']) ??
        _readInt(progressData?['totalXp']) ??
        _readInt(progressData?['points']) ??
        0;
    final currentLevel =
        _readInt(profileData?['currentLevel']) ??
        GamificationProfile.resolveLevel(totalXp);
    final streakCount =
        _readInt(profileData?['streakDays']) ??
        _readInt(progressData?['streakDays']) ??
        0;
    final completedLessons = _readInt(progressData?['completedLessons']) ?? 0;
    final completedActivities =
        (_readInt(progressData?['completedQuizzes']) ?? 0) +
        (_readInt(progressData?['completedPuzzles']) ?? 0) +
        completedLessons;
    final learningProgress = _resolveProgress(
      completedLessons: completedLessons,
      completedActivities: completedActivities,
    );

    final challengeData = todayDocument?.data() ?? currentSnapshot.data();
    final challengeId = todayDocument?.id ?? 'current';
    final dailyChallenge = challengeData == null
        ? const DailyChallenge(
            id: 'current',
            title: 'No daily challenge available',
            description:
                'Create a `daily_challenges/current` document in Firestore to publish today\'s challenge.',
            xpReward: 0,
            completionLabel: 'Awaiting content',
          )
        : DailyChallenge.fromMap(challengeId, challengeData);

    final badges = badgesSnapshot.docs.isEmpty
        ? const <DashboardBadge>[]
        : badgesSnapshot.docs
              .map((doc) => DashboardBadge.fromMap(doc.id, doc.data()))
              .toList();

    return StudentDashboardData(
      studentName: studentName,
      currentLevel: currentLevel,
      totalXp: totalXp,
      streakCount: streakCount,
      learningProgress: learningProgress,
      completedLessons: completedLessons,
      completedActivities: completedActivities,
      dailyChallenge: dailyChallenge,
      badges: badges,
    );
  }

  double _resolveProgress({
    required int completedLessons,
    required int completedActivities,
  }) {
    const targetLessons = 12;
    const targetActivities = 30;

    final lessonRatio = completedLessons / targetLessons;
    final activityRatio = completedActivities / targetActivities;
    final progress = ((lessonRatio * 0.55) + (activityRatio * 0.45)).clamp(
      0.0,
      1.0,
    );

    return progress;
  }

  int? _readInt(Object? value) {
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
