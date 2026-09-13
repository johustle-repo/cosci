import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get instance => _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> userProfileDocument(String uid) {
    return _firestore.collection('user_profiles').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> progressDocument(String uid) {
    return _firestore.collection('progress').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> userBadgesCollection(String uid) {
    return userProfileDocument(uid).collection('badges');
  }

  DocumentReference<Map<String, dynamic>> userBadgeDocument(
    String uid,
    String badgeId,
  ) {
    return userBadgesCollection(uid).doc(badgeId);
  }

  CollectionReference<Map<String, dynamic>> userActivityCollection(String uid) {
    return userDocument(uid).collection('learning_activity');
  }

  DocumentReference<Map<String, dynamic>> userActivityDocument(
    String uid,
    String activityId,
  ) {
    return userActivityCollection(uid).doc(activityId);
  }

  CollectionReference<Map<String, dynamic>> puzzlesCollection() {
    return _firestore.collection('puzzles');
  }

  DocumentReference<Map<String, dynamic>> puzzleDocument(String puzzleId) {
    return puzzlesCollection().doc(puzzleId);
  }

  CollectionReference<Map<String, dynamic>> lessonsCollection() {
    return _firestore.collection('lessons');
  }

  DocumentReference<Map<String, dynamic>> lessonDocument(String lessonId) {
    return lessonsCollection().doc(lessonId);
  }

  CollectionReference<Map<String, dynamic>> quizzesCollection() {
    return _firestore.collection('quizzes');
  }

  DocumentReference<Map<String, dynamic>> quizDocument(String quizId) {
    return quizzesCollection().doc(quizId);
  }

  CollectionReference<Map<String, dynamic>> simulationsCollection() {
    return _firestore.collection('simulations');
  }

  CollectionReference<Map<String, dynamic>> dailyChallengesCollection() {
    return _firestore.collection('daily_challenges');
  }

  DocumentReference<Map<String, dynamic>> dailyChallengeDocument(
    String challengeId,
  ) {
    return dailyChallengesCollection().doc(challengeId);
  }

  CollectionReference<Map<String, dynamic>> badgeDefinitionsCollection() {
    return _firestore.collection('badge_definitions');
  }

  DocumentReference<Map<String, dynamic>> badgeDefinitionDocument(
    String badgeId,
  ) {
    return badgeDefinitionsCollection().doc(badgeId);
  }

  CollectionReference<Map<String, dynamic>> userPuzzleProgressCollection(
    String uid,
  ) {
    return userDocument(uid).collection('puzzle_progress');
  }

  DocumentReference<Map<String, dynamic>> userPuzzleProgressDocument(
    String uid,
    String puzzleId,
  ) {
    return userPuzzleProgressCollection(uid).doc(puzzleId);
  }

  CollectionReference<Map<String, dynamic>> userLessonProgressCollection(
    String uid,
  ) {
    return userDocument(uid).collection('lesson_progress');
  }

  DocumentReference<Map<String, dynamic>> userLessonProgressDocument(
    String uid,
    String lessonId,
  ) {
    return userLessonProgressCollection(uid).doc(lessonId);
  }

  CollectionReference<Map<String, dynamic>> userQuizProgressCollection(
    String uid,
  ) {
    return userDocument(uid).collection('quiz_progress');
  }

  DocumentReference<Map<String, dynamic>> userQuizProgressDocument(
    String uid,
    String quizId,
  ) {
    return userQuizProgressCollection(uid).doc(quizId);
  }

  CollectionReference<Map<String, dynamic>> userChallengeProgressCollection(
    String uid,
  ) {
    return userDocument(uid).collection('challenge_progress');
  }

  DocumentReference<Map<String, dynamic>> userChallengeProgressDocument(
    String uid,
    String challengeId,
  ) {
    return userChallengeProgressCollection(uid).doc(challengeId);
  }

  Future<void> createUserDocuments({
    required AppUser user,
    String? displayName,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(userDocument(user.uid), {
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName ?? user.displayName,
      'role': user.role,
      'isActive': true,
      'accountStatus': 'active',
      'program': user.program,
      'yearLevel': user.yearLevel,
      'idVerificationStatus': user.isStudent
          ? (user.idVerificationStatus ?? 'required')
          : 'not_required',
      'createdAt': now,
      'updatedAt': now,
      'lastLoginAt': now,
    }, SetOptions(merge: true));

    batch.set(userProfileDocument(user.uid), {
      'uid': user.uid,
      'displayName': displayName ?? user.displayName,
      'photoUrl': user.photoUrl,
      'bio': null,
      'course': user.program,
      'yearLevel': user.yearLevel,
      'totalXp': 0,
      'points': 0,
      'currentLevel': 1,
      'streakDays': 0,
      'completedChallenges': 0,
      'badgesEarned': 0,
      'lastActivityAt': null,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    batch.set(progressDocument(user.uid), {
      'uid': user.uid,
      'completedLessons': 0,
      'completedQuizzes': 0,
      'completedPuzzles': 0,
      'completedChallenges': 0,
      'highScoreQuizCount': 0,
      'totalEducationalActions': 0,
      'totalXp': 0,
      'points': 0,
      'streakDays': 0,
      'lastActivityAt': null,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> updateLastLogin(String uid) {
    return _resolveUserDocument(uid).then(
      (document) => document.set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Future<AppUser?> fetchAppUser(String uid) async {
    final snapshot = await userDocument(uid).get();
    var data = snapshot.data();

    if (data == null) {
      final legacy = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      data = legacy.docs.isEmpty ? null : legacy.docs.first.data();
    }

    if (data == null) {
      return null;
    }

    return AppUser.fromMap(data);
  }

  Future<DocumentReference<Map<String, dynamic>>> _resolveUserDocument(
    String uid,
  ) async {
    final direct = userDocument(uid);
    if ((await direct.get()).exists) return direct;
    final legacy = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    return legacy.docs.isEmpty ? direct : legacy.docs.first.reference;
  }

  Future<void> updateOwnProfile({
    required String uid,
    required String displayName,
    required String program,
    required String yearLevel,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    batch.update(userDocument(uid), {
      'displayName': displayName.trim(),
      'program': program,
      'yearLevel': yearLevel,
      'updatedAt': now,
    });
    batch.set(userProfileDocument(uid), {
      'displayName': displayName.trim(),
      'course': program,
      'yearLevel': yearLevel,
      'updatedAt': now,
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
