import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/achievement.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';
import 'package:pseudocode_apk/models/learning_activity_record.dart';
import 'package:pseudocode_apk/models/learning_reward.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

class GamificationService {
  GamificationService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Future<GamificationProfile> fetchProfile({required String userId}) async {
    final configuredThresholds = await _configuredLevelThresholds();
    final profileSnapshot = await _firestoreService
        .userProfileDocument(userId)
        .get();
    final progressSnapshot = await _firestoreService
        .progressDocument(userId)
        .get();
    final badgeSnapshot = await _firestoreService
        .userBadgesCollection(userId)
        .get();
    final badgeDefinitionSnapshot = await _firestoreService
        .badgeDefinitionsCollection()
        .orderBy('sortOrder')
        .get();

    final unlockedBadges = {
      for (final doc in badgeSnapshot.docs)
        doc.id: Achievement.fromMap(doc.data()),
    };

    final definitions = badgeDefinitionSnapshot.docs
        .map((doc) => Achievement.fromMap({'id': doc.id, ...doc.data()}))
        .toList();

    final allBadges = definitions
        .map(
          (badge) =>
              unlockedBadges[badge.id]?.copyWith(isUnlocked: true) ??
              badge.copyWith(isUnlocked: false),
        )
        .toList();

    return GamificationProfile.fromFirestore(
      profileData: profileSnapshot.data(),
      progressData: progressSnapshot.data(),
      badges: allBadges,
      configuredLevelThresholds: configuredThresholds,
    );
  }

  Future<LearningReward?> recordSimulationLessonCompletion({
    required String userId,
    required String lessonId,
    required String title,
  }) async {
    final xp = await _configuredXp('xp_simulation', 10);
    return _recordEducationalReward(
      userId: userId,
      activityId: 'simulation_$lessonId',
      sourceId: lessonId,
      title: title,
      type: 'simulation',
      xpAwarded: xp,
      progressUpdates: const {'completedLessons': 1},
      successMessage: 'Simulation lesson completed. +$xp XP earned.',
    );
  }

  Future<LearningReward?> recordLessonCompletion({
    required String userId,
    required String lessonId,
    required String title,
  }) async {
    final xp = await _configuredXp('xp_lesson', 10);
    return _recordEducationalReward(
      userId: userId,
      activityId: 'lesson_$lessonId',
      sourceId: lessonId,
      title: title,
      type: 'lesson',
      xpAwarded: xp,
      progressUpdates: const {'completedLessons': 1},
      successMessage: 'Lesson completed. +$xp XP earned.',
    );
  }

  Future<LearningReward?> recordQuizCompletion({
    required String userId,
    required String quizId,
    required String title,
    required int scorePercent,
  }) async {
    if (scorePercent < 80) {
      return Future.value(null);
    }

    final xp = await _configuredXp('xp_quiz', 20);
    return _recordEducationalReward(
      userId: userId,
      activityId: 'quiz_high_score_$quizId',
      sourceId: quizId,
      title: title,
      type: 'quiz',
      xpAwarded: xp,
      progressUpdates: const {'completedQuizzes': 1, 'highScoreQuizCount': 1},
      scorePercent: scorePercent,
      successMessage:
          'Excellent work. You scored $scorePercent% and earned +$xp XP.',
    );
  }

  Future<LearningReward?> recordPuzzleCompletion({
    required String userId,
    required String puzzleId,
    required String title,
  }) async {
    final xp = await _configuredXp('xp_puzzle', 15);
    return _recordEducationalReward(
      userId: userId,
      activityId: 'puzzle_$puzzleId',
      sourceId: puzzleId,
      title: title,
      type: 'puzzle',
      xpAwarded: xp,
      progressUpdates: const {'completedPuzzles': 1},
      successMessage: 'Puzzle solved. +$xp XP added to your progress.',
    );
  }

  Future<LearningReward?> recordDailyChallengeCompletion({
    required String userId,
    required String challengeId,
    required String title,
    int xpAwarded = 15,
  }) async {
    final configuredXp = await _configuredXp('xp_challenge', xpAwarded);
    return _recordEducationalReward(
      userId: userId,
      activityId: 'daily_challenge_$challengeId',
      sourceId: challengeId,
      title: title,
      type: 'daily_challenge',
      xpAwarded: configuredXp,
      progressUpdates: const {'completedChallenges': 1},
      successMessage: 'Daily challenge finished. +$configuredXp XP secured.',
    );
  }

  Future<LearningReward?> _recordEducationalReward({
    required String userId,
    required String activityId,
    required String sourceId,
    required String title,
    required String type,
    required int xpAwarded,
    required Map<String, int> progressUpdates,
    required String successMessage,
    int? scorePercent,
  }) async {
    final configuredThresholds = await _configuredLevelThresholds();
    final profileRef = _firestoreService.userProfileDocument(userId);
    final progressRef = _firestoreService.progressDocument(userId);
    final activityRef = _firestoreService.userActivityDocument(
      userId,
      activityId,
    );

    LearningReward? reward;

    await _firestoreService.instance.runTransaction((transaction) async {
      final existingActivity = await transaction.get(activityRef);
      if (existingActivity.exists) {
        reward = null;
        return;
      }

      final profileSnapshot = await transaction.get(profileRef);
      final progressSnapshot = await transaction.get(progressRef);

      final profileData = profileSnapshot.data() ?? <String, dynamic>{};
      final progressData = progressSnapshot.data() ?? <String, dynamic>{};

      final previousXp =
          _readInt(profileData['totalXp']) ??
          _readInt(profileData['points']) ??
          _readInt(progressData['totalXp']) ??
          _readInt(progressData['points']) ??
          0;
      final previousLevel = GamificationProfile.resolveLevel(
        previousXp,
        thresholds: configuredThresholds,
      );
      final nextXp = previousXp + xpAwarded;
      final nextLevel = GamificationProfile.resolveLevel(
        nextXp,
        thresholds: configuredThresholds,
      );
      final previousStreak =
          _readInt(profileData['streakDays']) ??
          _readInt(progressData['streakDays']) ??
          0;
      final lastActivityAt = _parseTimestamp(
        progressData['lastActivityAt'] ?? profileData['lastActivityAt'],
      );
      final currentStreak = _resolveStreak(
        previousStreak: previousStreak,
        lastActivityAt: lastActivityAt,
      );

      final nextCompletedLessons =
          (_readInt(progressData['completedLessons']) ?? 0) +
          (progressUpdates['completedLessons'] ?? 0);
      final nextCompletedQuizzes =
          (_readInt(progressData['completedQuizzes']) ?? 0) +
          (progressUpdates['completedQuizzes'] ?? 0);
      final nextCompletedPuzzles =
          (_readInt(progressData['completedPuzzles']) ?? 0) +
          (progressUpdates['completedPuzzles'] ?? 0);
      final nextCompletedChallenges =
          (_readInt(progressData['completedChallenges']) ?? 0) +
          (progressUpdates['completedChallenges'] ?? 0);
      final nextHighScoreCount =
          (_readInt(progressData['highScoreQuizCount']) ?? 0) +
          (progressUpdates['highScoreQuizCount'] ?? 0);

      final unlockedBadges = <Achievement>[];
      final badgeWrites =
          <DocumentReference<Map<String, dynamic>>, Achievement>{};
      for (final badgeId in _managedBadgeIds) {
        final definitionRef = _firestoreService.badgeDefinitionDocument(
          badgeId,
        );
        final definitionSnapshot = await transaction.get(definitionRef);
        if (!definitionSnapshot.exists) {
          continue;
        }

        final achievement = Achievement.fromMap({
          'id': badgeId,
          ...?definitionSnapshot.data(),
        });
        final badgeRef = _firestoreService.userBadgeDocument(
          userId,
          achievement.id,
        );
        final badgeSnapshot = await transaction.get(badgeRef);
        if (badgeSnapshot.exists) {
          continue;
        }

        if (!_shouldUnlockBadge(
          badgeId: achievement.id,
          completedLessons: nextCompletedLessons,
          completedPuzzles: nextCompletedPuzzles,
          completedChallenges: nextCompletedChallenges,
          highScoreQuizCount: nextHighScoreCount,
          streakDays: currentStreak,
          totalXp: nextXp,
        )) {
          continue;
        }

        final unlockedBadge = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        unlockedBadges.add(unlockedBadge);
        badgeWrites[badgeRef] = unlockedBadge;
      }

      // Firestore transactions must finish all reads before the first write.
      for (final entry in badgeWrites.entries) {
        transaction.set(entry.key, {
          ...entry.value.toMap(),
          'unlockedAt': FieldValue.serverTimestamp(),
        });
      }

      final activityRecord = LearningActivityRecord(
        id: activityId,
        type: type,
        sourceId: sourceId,
        title: title,
        xpAwarded: xpAwarded,
        completedAt: DateTime.now(),
        scorePercent: scorePercent,
      );

      transaction.set(activityRef, {
        ...activityRecord.toMap(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (type == 'lesson') {
        transaction.set(
          _firestoreService.userLessonProgressDocument(userId, sourceId),
          {
            'lessonId': sourceId,
            'title': title,
            'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      transaction.set(profileRef, {
        'totalXp': nextXp,
        'points': nextXp,
        'currentLevel': nextLevel,
        'streakDays': currentStreak,
        'completedChallenges': nextCompletedChallenges,
        'badgesEarned':
            (_readInt(profileData['badgesEarned']) ?? 0) +
            unlockedBadges.length,
        'lastActivityAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(progressRef, {
        'completedLessons': nextCompletedLessons,
        'completedQuizzes': nextCompletedQuizzes,
        'completedPuzzles': nextCompletedPuzzles,
        'completedChallenges': nextCompletedChallenges,
        'highScoreQuizCount': nextHighScoreCount,
        'totalEducationalActions':
            (_readInt(progressData['totalEducationalActions']) ?? 0) + 1,
        'totalXp': nextXp,
        'points': nextXp,
        'streakDays': currentStreak,
        'lastActivityAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      reward = LearningReward(
        activityTitle: title,
        activityType: type,
        xpAwarded: xpAwarded,
        newTotalXp: nextXp,
        previousLevel: previousLevel,
        newLevel: nextLevel,
        currentStreak: currentStreak,
        unlockedBadges: unlockedBadges,
        message: successMessage,
      );
    });

    return reward;
  }

  bool _shouldUnlockBadge({
    required String badgeId,
    required int completedLessons,
    required int completedPuzzles,
    required int completedChallenges,
    required int highScoreQuizCount,
    required int streakDays,
    required int totalXp,
  }) {
    switch (badgeId) {
      case 'first_simulation':
        return completedLessons >= 1;
      case 'quiz_master':
        return highScoreQuizCount >= 1;
      case 'first_puzzle':
        return completedPuzzles >= 1;
      case 'challenge_committed':
        return completedChallenges >= 1;
      case 'streak_week':
        return streakDays >= 7;
      case 'rank_beginner':
        return totalXp >= 10;
      case 'rank_apprentice':
        return totalXp >= 60;
      case 'rank_intermediate':
        return totalXp >= 150;
      case 'rank_advanced':
        return totalXp >= 280;
      case 'rank_professional':
        return totalXp >= 450;
      default:
        return false;
    }
  }

  int _resolveStreak({
    required int previousStreak,
    required DateTime? lastActivityAt,
  }) {
    final today = _dateOnly(DateTime.now());
    if (lastActivityAt == null) {
      return 1;
    }

    final previousDay = _dateOnly(lastActivityAt);
    final difference = today.difference(previousDay).inDays;

    if (difference <= 0) {
      return previousStreak <= 0 ? 1 : previousStreak;
    }

    if (difference == 1) {
      return previousStreak + 1;
    }

    return 1;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _parseTimestamp(Object? value) {
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

  Future<int> _configuredXp(String ruleId, int fallback) async {
    try {
      final snapshot = await _firestoreService.instance
          .collection('gamification_rules')
          .doc(ruleId)
          .get();
      final value = _readInt(snapshot.data()?['xpAmount']);
      return value != null && value > 0 ? value : fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<List<int>?> _configuredLevelThresholds() async {
    try {
      final snapshot = await _firestoreService.instance
          .collection('gamification_rules')
          .where('ruleType', isEqualTo: 'level_threshold')
          .get();
      final values =
          snapshot.docs
              .map((doc) => _readInt(doc.data()['xpRequired']))
              .whereType<int>()
              .where((value) => value >= 0)
              .toSet()
              .toList()
            ..sort();
      return values.length >= 2 ? values : null;
    } catch (_) {
      return null;
    }
  }

  List<String> get _managedBadgeIds => const [
    'first_simulation',
    'quiz_master',
    'first_puzzle',
    'challenge_committed',
    'streak_week',
    'rank_beginner',
    'rank_apprentice',
    'rank_intermediate',
    'rank_advanced',
    'rank_professional',
  ];
}
