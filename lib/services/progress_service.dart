import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/dashboard_badge.dart';
import 'package:pseudocode_apk/models/progress_summary.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

class ProgressService {
  ProgressService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Future<ProgressSummary> fetchProgressSummary({String? userId}) async {
    if (userId == null || userId.isEmpty) {
      return ProgressSummary.empty();
    }

    final progressFuture = _firestoreService.progressDocument(userId).get();
    final profileFuture = _firestoreService.userProfileDocument(userId).get();
    final badgesFuture = _firestoreService
        .userBadgesCollection(userId)
        .limit(6)
        .get();
    final activityFuture = _firestoreService
        .userActivityCollection(userId)
        .orderBy('completedAt', descending: true)
        .limit(8)
        .get();
    final quizProgressFuture = _firestoreService
        .userQuizProgressCollection(userId)
        .get();
    final quizContentFuture = _firestoreService.quizzesCollection().get();

    final results = await Future.wait<Object>([
      progressFuture,
      profileFuture,
      badgesFuture,
      activityFuture,
      quizProgressFuture,
      quizContentFuture,
    ]);

    final progressSnapshot =
        results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final profileSnapshot =
        results[1] as DocumentSnapshot<Map<String, dynamic>>;
    final badgesSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final activitySnapshot = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final quizProgressSnapshot =
        results[4] as QuerySnapshot<Map<String, dynamic>>;
    final quizContentSnapshot =
        results[5] as QuerySnapshot<Map<String, dynamic>>;

    final progressData = progressSnapshot.data();
    final profileData = profileSnapshot.data();

    final earnedBadges = badgesSnapshot.docs
        .map((doc) => DashboardBadge.fromMap(doc.id, doc.data()))
        .toList();

    final recentActivities = activitySnapshot.docs
        .map((doc) => RecentLearningActivity.fromMap(doc.data()))
        .toList();

    final quizMetadata = {
      for (final doc in quizContentSnapshot.docs)
        doc.id: {
          'title': doc.data()['title'],
          'topic': doc.data()['topic'],
          'language': doc.data()['language'],
        },
    };

    final weakTopics =
        quizProgressSnapshot.docs
            .map((doc) {
              final data = doc.data();
              final quizInfo = quizMetadata[doc.id];
              final averageScore =
                  _readInt(data['lastScore']) ??
                  _readInt(data['bestScore']) ??
                  _readInt(data['averageScore']) ??
                  0;
              final attempts = _readInt(data['attempts']) ?? 0;
              final title =
                  _readString(data['topic']) ??
                  _readString(quizInfo?['topic']) ??
                  _readString(quizInfo?['title']) ??
                  'Quiz topic';

              return WeakTopic(
                title: title,
                averageScore: averageScore,
                attempts: attempts,
                recommendation: _recommendationForScore(averageScore),
              );
            })
            .where((topic) => topic.attempts > 0 && topic.averageScore < 80)
            .toList()
          ..sort((a, b) => a.averageScore.compareTo(b.averageScore));

    return ProgressSummary.fromFirestore(
      progressData: progressData,
      profileData: profileData,
      earnedBadges: earnedBadges,
      weakTopics: weakTopics.take(4).toList(),
      recentActivities: recentActivities,
    );
  }

  String _recommendationForScore(int score) {
    if (score < 50) {
      return 'Needs focused review';
    }
    if (score < 70) {
      return 'Practice with guided examples';
    }
    return 'Review once more to strengthen retention';
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

  String? _readString(Object? value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    return null;
  }
}
