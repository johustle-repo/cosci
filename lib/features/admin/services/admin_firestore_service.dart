import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pseudocode_apk/features/admin/models/admin_announcement.dart';
import 'package:pseudocode_apk/features/admin/models/admin_badge.dart';
import 'package:pseudocode_apk/features/admin/models/admin_daily_challenge.dart';
import 'package:pseudocode_apk/features/admin/models/admin_gamification_rule.dart';
import 'package:pseudocode_apk/features/admin/models/admin_lesson.dart';
import 'package:pseudocode_apk/features/admin/models/admin_puzzle.dart';
import 'package:pseudocode_apk/features/admin/models/admin_quiz.dart';
import 'package:pseudocode_apk/features/admin/models/admin_settings.dart';
import 'package:pseudocode_apk/features/admin/models/admin_simulation.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_profile.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

/// All admin CRUD operations. Wraps [FirestoreService] for shared references
/// and adds admin-specific collections.
class AdminFirestoreService {
  AdminFirestoreService({required FirestoreService firestoreService})
    : _fs = firestoreService;

  final FirestoreService _fs;

  FirebaseFirestore get _db => _fs.instance;

  // ── Helpers ───────────────────────────────────────────────────────────────
  Map<String, dynamic> _timestamps({bool isNew = true}) => {
    if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD ANALYTICS
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, int>> fetchDashboardCounts() async {
    final studentsFuture = fetchStudents();
    final results = await Future.wait([
      _db.collection('lessons').count().get(),
      _db.collection('simulations').count().get(),
      _db.collection('quizzes').count().get(),
      _db.collection('puzzles').count().get(),
      _db.collection('badge_definitions').count().get(),
      _db.collection('daily_challenges').count().get(),
      _db
          .collection('lessons')
          .where('isPublished', isEqualTo: true)
          .count()
          .get(),
      _db
          .collection('simulations')
          .where('isPublished', isEqualTo: true)
          .count()
          .get(),
      _db
          .collection('quizzes')
          .where('isPublished', isEqualTo: true)
          .count()
          .get(),
      _db
          .collection('puzzles')
          .where('isPublished', isEqualTo: true)
          .count()
          .get(),
    ]);
    return {
      'totalStudents': (await studentsFuture)
          .where((user) => user.role == 'student')
          .length,
      'activeStudents': (await studentsFuture)
          .where((user) => user.role == 'student' && user.isActive)
          .length,
      'totalLessons': results[0].count ?? 0,
      'totalSimulations': results[1].count ?? 0,
      'totalQuizzes': results[2].count ?? 0,
      'totalPuzzles': results[3].count ?? 0,
      'totalBadges': results[4].count ?? 0,
      'totalChallenges': results[5].count ?? 0,
      'publishedLessons': results[6].count ?? 0,
      'publishedSimulations': results[7].count ?? 0,
      'publishedQuizzes': results[8].count ?? 0,
      'publishedPuzzles': results[9].count ?? 0,
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STUDENTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<AdminStudentProfile>> fetchStudents() async {
    // No orderBy — avoids needing a composite Firestore index.
    // Sort client-side after fetching.
    final snapshots = await Future.wait([
      _db.collection('users').get(),
      _db.collection('user_profiles').get(),
      _db.collection('progress').get(),
    ]);
    final usersSnap = snapshots[0];
    final profileMaps = <String, Map<String, dynamic>>{
      for (final document in snapshots[1].docs) document.id: document.data(),
    };
    final progressMaps = <String, Map<String, dynamic>>{
      for (final document in snapshots[2].docs) document.id: document.data(),
    };

    final profilesByIdentity = <String, AdminStudentProfile>{};
    for (final doc in usersSnap.docs) {
      final uid = doc.id;
      final userMap = doc.data();
      final profile = AdminStudentProfile.fromMaps(
        uid: uid,
        userMap: userMap,
        profileMap: profileMaps[uid],
        progressMap: progressMaps[uid],
      );
      final canonicalIdentity = (userMap['uid'] ?? userMap['email'] ?? uid)
          .toString()
          .trim()
          .toLowerCase();
      final existing = profilesByIdentity[canonicalIdentity];
      final isUidDocument = userMap['uid'] == uid;
      if (existing == null || isUidDocument) {
        profilesByIdentity[canonicalIdentity] = profile;
      }
    }
    final profiles = profilesByIdentity.values.toList();
    // Sort newest-first client-side (avoids composite index requirement)
    profiles.sort((a, b) {
      final ta = a.createdAt ?? DateTime(0);
      final tb = b.createdAt ?? DateTime(0);
      return tb.compareTo(ta);
    });
    return profiles;
  }

  Future<AdminStudentProfile?> fetchStudentById(String uid) async {
    final userSnap = await _db.collection('users').doc(uid).get();
    if (!userSnap.exists) return null;
    final profileSnap = await _db.collection('user_profiles').doc(uid).get();
    final progressSnap = await _db.collection('progress').doc(uid).get();
    return AdminStudentProfile.fromMaps(
      uid: uid,
      userMap: userSnap.data() ?? {},
      profileMap: profileSnap.data(),
      progressMap: progressSnap.data(),
    );
  }

  Future<void> setStudentActiveStatus(String uid, bool isActive) async {
    final target = await _db.collection('users').doc(uid).get();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if ((target.id == currentUid || target.data()?['uid'] == currentUid) &&
        !isActive) {
      throw StateError('You cannot suspend your own administrator account.');
    }
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {
      'isActive': isActive,
      'accountStatus': isActive ? 'active' : 'suspended',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activity_logs').doc(), {
      'actionType': 'update',
      'targetModule': 'users',
      'targetId': uid,
      'description':
          '${isActive ? 'Activated' : 'Suspended'} account: '
          '${target.data()?['displayName'] ?? target.data()?['email'] ?? uid}',
      'previousValue': isActive ? 'suspended' : 'active',
      'newValue': isActive ? 'active' : 'suspended',
      'adminUid': currentUid,
      'adminEmail': FirebaseAuth.instance.currentUser?.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateUserRole(String documentId, String role) async {
    if (!const {'student', 'instructor', 'admin'}.contains(role)) {
      throw ArgumentError('Unsupported role.');
    }
    final target = await _db.collection('users').doc(documentId).get();
    final data = target.data();
    if (data == null) throw StateError('User account was not found.');
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (target.id == currentUid || data['uid'] == currentUid) {
      throw StateError('You cannot change your own administrator role.');
    }
    final oldRole = data['role'] as String? ?? 'student';
    if (oldRole == 'admin' && role != 'admin') {
      final admins = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      if (admins.docs.length <= 1) {
        throw StateError('At least one administrator account is required.');
      }
    }
    final batch = _db.batch();
    batch.update(target.reference, {
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activity_logs').doc(), {
      'actionType': 'update',
      'targetModule': 'users',
      'targetId': documentId,
      'description': 'Changed role from $oldRole to $role',
      'previousValue': oldRole,
      'newValue': role,
      'adminUid': FirebaseAuth.instance.currentUser?.uid,
      'adminEmail': FirebaseAuth.instance.currentUser?.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LESSONS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<AdminLesson>> fetchLessons() async {
    final snap = await _fs.lessonsCollection().orderBy('sortOrder').get();
    return snap.docs.map((d) => AdminLesson.fromMap(d.id, d.data())).toList();
  }

  Future<void> createLesson(AdminLesson lesson) async {
    await _fs.lessonsCollection().add({
      ...lesson.toMap(),
      ..._timestamps(isNew: true),
    });
  }

  Future<void> updateLesson(AdminLesson lesson) async {
    final lessonRef = _fs.lessonDocument(lesson.id);
    final current = await lessonRef.get();
    if (current.exists) {
      await lessonRef.collection('revisions').add({
        ...?current.data(),
        'lessonId': lesson.id,
        'snapshotAt': FieldValue.serverTimestamp(),
        'snapshotBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
      });
    }
    await lessonRef.update({...lesson.toMap(), ..._timestamps(isNew: false)});
  }

  Future<List<Map<String, dynamic>>> fetchLessonRevisions(
    String lessonId,
  ) async {
    final snapshot = await _fs
        .lessonDocument(lessonId)
        .collection('revisions')
        .orderBy('snapshotAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, int>> fetchLessonCompletionCounts() async {
    final counts = <String, int>{};
    final users = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .limit(200)
        .get();
    for (final user in users.docs) {
      final progress = await user.reference.collection('lesson_progress').get();
      for (final item in progress.docs) {
        if (item.data()['completed'] == true) {
          counts[item.id] = (counts[item.id] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  Future<void> deleteLesson(String lessonId) async {
    final lesson = _fs.lessonDocument(lessonId);
    final revisions = await lesson.collection('revisions').get();
    await _deleteReferences([
      ...revisions.docs.map((document) => document.reference),
      lesson,
    ]);
  }

  Future<void> toggleLessonPublished(String lessonId, bool isPublished) {
    return _fs.lessonDocument(lessonId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIMULATIONS
  // ══════════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _simulations =>
      _db.collection('simulations');

  bool _privateSimulationTestsAvailable = true;
  bool get privateSimulationTestsAvailable => _privateSimulationTestsAvailable;

  Future<List<AdminSimulation>> fetchSimulations() async {
    _privateSimulationTestsAvailable = true;
    final snap = await _simulations.get();
    final simulations = <AdminSimulation>[];
    for (final document in snap.docs) {
      DocumentSnapshot<Map<String, dynamic>>? private;
      try {
        private = await _db
            .collection('simulation_private_tests')
            .doc(document.id)
            .get();
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') rethrow;
        _privateSimulationTestsAvailable = false;
      }
      final data = {...document.data()};
      final visible = List<dynamic>.from(
        data['testCases'] as List? ?? const [],
      );
      final hidden = List<dynamic>.from(
        private?.data()?['testCases'] as List? ?? const [],
      );
      data['testCases'] = [...visible, ...hidden];
      simulations.add(AdminSimulation.fromMap(document.id, data));
    }
    simulations.sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(0),
      ),
    );
    return simulations;
  }

  Future<void> createSimulation(AdminSimulation sim) async {
    final ref = _simulations.doc();
    final batch = _db.batch();
    batch.set(ref, {...sim.toPublicMap(), ..._timestamps(isNew: true)});
    batch.set(
      _db.collection('simulation_private_tests').doc(ref.id),
      sim.toPrivateTestsMap(),
    );
    await batch.commit();
  }

  Future<void> updateSimulation(AdminSimulation sim) async {
    final current = await _simulations.doc(sim.id).get();
    final currentData = current.data();
    final nextVersion = ((currentData?['version'] as num?)?.toInt() ?? 1) + 1;
    final batch = _db.batch();
    if (currentData != null) {
      final revision = _simulations.doc(sim.id).collection('revisions').doc();
      batch.set(revision, {
        ...currentData,
        'snapshotAt': FieldValue.serverTimestamp(),
        'snapshotBy': FirebaseAuth.instance.currentUser?.email ?? 'admin',
      });
    }
    batch.update(_simulations.doc(sim.id), {
      ...sim.toPublicMap(),
      'version': nextVersion,
      ..._timestamps(isNew: false),
    });
    batch.set(
      _db.collection('simulation_private_tests').doc(sim.id),
      sim.toPrivateTestsMap(),
    );
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> fetchSimulationRevisions(String id) async {
    final snapshot = await _simulations
        .doc(id)
        .collection('revisions')
        .orderBy('snapshotAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> deleteSimulation(String id) async {
    final simulation = _simulations.doc(id);
    final revisions = await simulation.collection('revisions').get();
    await _deleteReferences([
      ...revisions.docs.map((document) => document.reference),
      simulation,
      _db.collection('simulation_private_tests').doc(id),
    ]);
  }

  Future<void> toggleSimulationPublished(String id, bool isPublished) {
    return _simulations.doc(id).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUIZZES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<AdminQuiz>> fetchQuizzes() async {
    final snap = await _fs.quizzesCollection().get();
    final quizzes = snap.docs
        .map((d) => AdminQuiz.fromMap(d.id, d.data()))
        .toList();
    quizzes.sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(0),
      ),
    );
    return quizzes;
  }

  Future<DocumentReference> createQuiz(AdminQuiz quiz) {
    return _fs.quizzesCollection().add({
      ...quiz.toMap(),
      ..._timestamps(isNew: true),
    });
  }

  Future<void> updateQuiz(AdminQuiz quiz) async {
    await _fs.quizDocument(quiz.id).update({
      ...quiz.toMap(),
      ..._timestamps(isNew: false),
    });
  }

  Future<void> deleteQuiz(String quizId) async {
    // Firestore does not cascade-delete subcollections. Remove public questions
    // and private answer keys explicitly so deleted quizzes leave no orphan data.
    final questions = await _fs
        .quizDocument(quizId)
        .collection('questions')
        .get();
    final keys = await _db
        .collection('quiz_answer_keys')
        .doc(quizId)
        .collection('questions')
        .get();
    final refs = <DocumentReference>[
      ...questions.docs.map((d) => d.reference),
      ...keys.docs.map((d) => d.reference),
      _fs.quizDocument(quizId),
      _db.collection('quiz_answer_keys').doc(quizId),
    ];
    await _deleteReferences(refs);
  }

  Future<void> _deleteReferences(List<DocumentReference> refs) async {
    for (var offset = 0; offset < refs.length; offset += 450) {
      final batch = _db.batch();
      for (final ref in refs.skip(offset).take(450)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  Future<void> toggleQuizPublished(String quizId, bool isPublished) {
    return _fs.quizDocument(quizId).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AdminQuizQuestion>> fetchQuizQuestions(String quizId) async {
    final snap = await _fs
        .quizDocument(quizId)
        .collection('questions')
        .orderBy('sortOrder')
        .get();
    final result = <AdminQuizQuestion>[];
    for (final document in snap.docs) {
      final key = await _db
          .collection('quiz_answer_keys')
          .doc(quizId)
          .collection('questions')
          .doc(document.id)
          .get();
      result.add(
        AdminQuizQuestion.fromMap(document.id, {
          ...document.data(),
          ...?key.data(),
        }),
      );
    }
    return result;
  }

  Future<void> saveQuizQuestion(String quizId, AdminQuizQuestion q) async {
    final colRef = _fs.quizDocument(quizId).collection('questions');
    final questionRef = q.id.isEmpty ? colRef.doc() : colRef.doc(q.id);
    final keyRef = _db
        .collection('quiz_answer_keys')
        .doc(quizId)
        .collection('questions')
        .doc(questionRef.id);
    final batch = _db.batch();
    batch.set(questionRef, {
      ...q.toPublicMap(),
      // Remove legacy answer fields whenever a question is migrated.
      'correctAnswer': FieldValue.delete(),
      'explanation': FieldValue.delete(),
    }, SetOptions(merge: true));
    batch.set(keyRef, q.toAnswerKeyMap());
    await batch.commit();
  }

  Future<void> deleteQuizQuestion(String quizId, String questionId) {
    final batch = _db.batch();
    batch.delete(
      _fs.quizDocument(quizId).collection('questions').doc(questionId),
    );
    batch.delete(
      _db
          .collection('quiz_answer_keys')
          .doc(quizId)
          .collection('questions')
          .doc(questionId),
    );
    return batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PUZZLES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<AdminPuzzle>> fetchPuzzles() async {
    final snap = await _fs.puzzlesCollection().get();
    return snap.docs.map((d) => AdminPuzzle.fromMap(d.id, d.data())).toList();
  }

  Future<void> createPuzzle(AdminPuzzle puzzle) async {
    await _fs.puzzlesCollection().add({
      ...puzzle.toMap(),
      ..._timestamps(isNew: true),
    });
  }

  Future<void> updatePuzzle(AdminPuzzle puzzle) async {
    await _fs.puzzleDocument(puzzle.id).update({
      ...puzzle.toMap(),
      ..._timestamps(isNew: false),
    });
  }

  Future<void> deletePuzzle(String id) => _fs.puzzleDocument(id).delete();

  Future<void> togglePuzzlePublished(String id, bool isPublished) {
    return _fs.puzzleDocument(id).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BADGES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<AdminBadge>> fetchBadges() async {
    final snap = await _fs.badgeDefinitionsCollection().get();
    return snap.docs.map((d) => AdminBadge.fromMap(d.id, d.data())).toList();
  }

  Future<void> createBadge(AdminBadge badge) async {
    await _fs.badgeDefinitionsCollection().add({
      ...badge.toMap(),
      'sortOrder': 100,
      ..._timestamps(isNew: true),
    });
  }

  Future<void> installStarterBadges(List<AdminBadge> badges) async {
    final batch = _db.batch();
    for (var index = 0; index < badges.length; index++) {
      final badge = badges[index];
      final ref = _fs.badgeDefinitionDocument(badge.id);
      batch.set(ref, {
        ...badge.toMap(),
        'sortOrder': index + 1,
        ..._timestamps(isNew: true),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> updateBadge(AdminBadge badge) async {
    await _fs.badgeDefinitionDocument(badge.id).update({
      ...badge.toMap(),
      ..._timestamps(isNew: false),
    });
  }

  Future<void> deleteBadge(String id) =>
      _fs.badgeDefinitionDocument(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // GAMIFICATION RULES
  // ══════════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _gamificationRules =>
      _db.collection('gamification_rules');

  Future<List<AdminGamificationRule>> fetchGamificationRules() async {
    final snap = await _gamificationRules.get();
    return snap.docs
        .map((d) => AdminGamificationRule.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> saveGamificationRule(AdminGamificationRule rule) async {
    if (rule.id.isEmpty) {
      await _gamificationRules.add({
        ...rule.toMap(),
        ..._timestamps(isNew: true),
      });
    } else {
      await _gamificationRules.doc(rule.id).update({
        ...rule.toMap(),
        ..._timestamps(isNew: false),
      });
    }
  }

  Future<void> installGamificationRules(
    List<AdminGamificationRule> rules,
  ) async {
    final batch = _db.batch();
    for (final rule in rules) {
      final ref = _gamificationRules.doc(rule.id);
      batch.set(ref, {
        ...rule.toMap(),
        ..._timestamps(isNew: true),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> deleteGamificationRule(String id) =>
      _gamificationRules.doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // DAILY CHALLENGES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<AdminDailyChallenge>> fetchDailyChallenges() async {
    final snap = await _fs.dailyChallengesCollection().get();
    return snap.docs
        .map((d) => AdminDailyChallenge.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> createDailyChallenge(AdminDailyChallenge c) async {
    await _fs.dailyChallengesCollection().add({
      ...c.toMap(),
      ..._timestamps(isNew: true),
    });
  }

  Future<int> installStarterDailyChallenges() async {
    final content = <({String id, String title, String type})>[];
    for (final entry in const [
      ('lessons', 'lesson'),
      ('simulations', 'simulation'),
      ('quizzes', 'quiz'),
      ('puzzles', 'puzzle'),
    ]) {
      final snapshot = await _db
          .collection(entry.$1)
          .where('isPublished', isEqualTo: true)
          .limit(3)
          .get();
      for (final doc in snapshot.docs) {
        final title = (doc.data()['title'] as String?)?.trim();
        if (title != null && title.isNotEmpty) {
          content.add((id: doc.id, title: title, type: entry.$2));
        }
      }
    }
    if (content.isEmpty) return 0;

    final today = DateTime.now();
    final batch = _db.batch();
    const labels = [
      'Start Strong',
      'Logic Sprint',
      'Code Explorer',
      'Knowledge Check',
      'Syntax Quest',
      'Practice Momentum',
      'Weekly Finish',
    ];
    for (var index = 0; index < 7; index++) {
      final item = content[index % content.length];
      final date = today.add(Duration(days: index));
      final isoDate =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final challenge = AdminDailyChallenge(
        id: index == 0 ? 'current' : 'starter_day_${index + 1}',
        title: '${labels[index]}: ${item.title}',
        description:
            'Complete this ${item.type} activity to strengthen your programming skills and keep your learning streak active.',
        challengeType: item.type,
        xpReward: item.type == 'quiz'
            ? 20
            : item.type == 'puzzle'
            ? 15
            : 10,
        status: index == 0 ? 'active' : 'scheduled',
        date: isoDate,
        linkedContentId: item.id,
      );
      batch.set(_fs.dailyChallengeDocument(challenge.id), {
        ...challenge.toMap(),
        'completionLabel': index == 0
            ? 'Ready today'
            : 'Scheduled for $isoDate',
        ..._timestamps(isNew: true),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    return 7;
  }

  Future<void> updateDailyChallenge(AdminDailyChallenge c) async {
    await _fs.dailyChallengeDocument(c.id).update({
      ...c.toMap(),
      ..._timestamps(isNew: false),
    });
  }

  Future<void> deleteDailyChallenge(String id) =>
      _fs.dailyChallengeDocument(id).delete();

  Future<void> toggleChallengeStatus(String id, String status) {
    return _fs.dailyChallengeDocument(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANNOUNCEMENTS
  // ══════════════════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _db.collection('announcements');

  Future<List<AdminAnnouncement>> fetchAnnouncements() async {
    final snap = await _announcements.get();
    return snap.docs
        .map((d) => AdminAnnouncement.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> createAnnouncement(AdminAnnouncement a) async {
    await _announcements.add({...a.toMap(), ..._timestamps(isNew: true)});
  }

  Future<void> updateAnnouncement(AdminAnnouncement a) async {
    await _announcements.doc(a.id).update({
      ...a.toMap(),
      ..._timestamps(isNew: false),
    });
  }

  Future<void> deleteAnnouncement(String id) => _announcements.doc(id).delete();

  Future<void> toggleAnnouncementPublished(String id, bool isPublished) {
    return _announcements.doc(id).update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ══════════════════════════════════════════════════════════════════════════

  Future<AdminSettings> fetchSettings() async {
    try {
      final snap = await _db.collection('settings').doc('app_settings').get();
      if (!snap.exists) return AdminSettings.defaults;
      return AdminSettings.fromMap(snap.data() ?? {});
    } catch (_) {
      return AdminSettings.defaults;
    }
  }

  Future<void> saveSettings(AdminSettings settings) {
    return _db.collection('settings').doc('app_settings').set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> fetchSettingsBackups() async {
    final snapshot = await _db.collection('settings_backups').get();
    final backups = snapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
    backups.sort((a, b) {
      final aTime = a['createdAt'];
      final bTime = b['createdAt'];
      final aDate = aTime is Timestamp ? aTime.toDate() : DateTime(1970);
      final bDate = bTime is Timestamp ? bTime.toDate() : DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return backups.take(10).toList();
  }

  Future<void> createSettingsBackup(AdminSettings settings) {
    final backupSettings = settings.toMap()
      ..remove('groqApiKey')
      ..remove('anthropicApiKey');
    return _db.collection('settings_backups').add({
      'settings': backupSettings,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'configuration',
    });
  }

  Future<AdminSettings> restoreSettingsBackup(String backupId) async {
    final snapshot = await _db
        .collection('settings_backups')
        .doc(backupId)
        .get();
    final data = snapshot.data();
    final rawSettings = data?['settings'];
    if (rawSettings is! Map) {
      throw StateError('The selected backup does not contain valid settings.');
    }
    final currentSettings = await fetchSettings();
    final settings = AdminSettings.fromMap(
      Map<String, dynamic>.from(rawSettings),
    ).copyWith(groqApiKey: currentSettings.groqApiKey);
    await saveSettings(settings);
    return settings;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVITY LOGS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> fetchActivityLogs({
    int limit = 100,
  }) async {
    // Read before sorting so legacy entries that used `createdAt` or an ISO
    // timestamp are not silently excluded by an orderBy query.
    final snap = await _db.collection('activity_logs').limit(limit * 2).get();
    final logs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    logs.sort((a, b) => _logDate(b).compareTo(_logDate(a)));
    final selected = logs.take(limit).toList();
    await _attachReadableTargetTitles(selected);
    return selected;
  }

  Future<void> writeActivityLog(Map<String, dynamic> logData) {
    return _db.collection('activity_logs').add({
      ...logData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  DateTime _logDate(Map<String, dynamic> log) {
    final value = log['timestamp'] ?? log['createdAt'] ?? log['updatedAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(0);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime(0);
  }

  Future<void> _attachReadableTargetTitles(
    List<Map<String, dynamic>> logs,
  ) async {
    const collections = {
      'lessons': 'lessons',
      'simulations': 'simulations',
      'quizzes': 'quizzes',
      'puzzles': 'puzzles',
      'students': 'users',
      'users': 'users',
      'announcements': 'announcements',
      'challenges': 'daily_challenges',
      'badges': 'badge_definitions',
    };
    final cache = <String, String>{};
    for (final log in logs) {
      final id = log['targetId'] as String?;
      final module = log['targetModule'] as String?;
      final collection = collections[module];
      if (id == null || id.isEmpty || collection == null) continue;
      final key = '$collection/$id';
      if (!cache.containsKey(key)) {
        try {
          final data = (await _db.collection(collection).doc(id).get()).data();
          cache[key] =
              (data?['title'] ??
                      data?['displayName'] ??
                      data?['name'] ??
                      data?['email'] ??
                      '')
                  .toString();
        } catch (_) {
          cache[key] = '';
        }
      }
      final title = cache[key]!;
      if (title.isNotEmpty) {
        log['targetTitle'] = title;
        final description = (log['description'] ?? '').toString();
        if (description.isEmpty || description.contains(id)) {
          log['description'] = '${_humanizeAction(log['actionType'])} $title';
        }
      }
    }
  }

  String _humanizeAction(dynamic value) {
    final action = (value ?? 'Updated').toString();
    if (action.isEmpty) return 'Updated';
    return '${action[0].toUpperCase()}${action.substring(1)}';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REPORTS — aggregate queries
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns avg quiz score per topic from quiz_progress subcollections.
  /// Simplified: reads progress docs and aggregates client-side.
  Future<List<Map<String, dynamic>>> fetchTopicScores() async {
    final secureAttempts = await _db
        .collection('quiz_attempts')
        .limit(1000)
        .get();
    if (secureAttempts.docs.isNotEmpty) {
      final topicScores = <String, List<int>>{};
      for (final document in secureAttempts.docs) {
        final data = document.data();
        final topic = (data['topic'] ?? 'General').toString();
        final score = (data['scorePercent'] as num?)?.toInt() ?? 0;
        topicScores.putIfAbsent(topic, () => []).add(score);
      }
      return topicScores.entries.map((entry) {
        final average =
            entry.value.reduce((a, b) => a + b) ~/ entry.value.length;
        final passed = entry.value.where((score) => score >= 80).length;
        return {
          'topic': entry.key,
          'avgScore': average,
          'count': entry.value.length,
          'passRate': (passed * 100 / entry.value.length).round(),
        };
      }).toList()..sort(
        (a, b) => (a['avgScore'] as int).compareTo(b['avgScore'] as int),
      );
    }
    final usersSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .limit(200)
        .get();

    final topicScores = <String, List<int>>{};

    for (final userDoc in usersSnap.docs) {
      final quizProgressSnap = await _db
          .collection('users')
          .doc(userDoc.id)
          .collection('quiz_progress')
          .get();
      for (final qDoc in quizProgressSnap.docs) {
        final data = qDoc.data();
        final topic = data['topic'] as String? ?? 'General';
        final score = (data['scorePercent'] as num?)?.toInt() ?? 0;
        topicScores.putIfAbsent(topic, () => []).add(score);
      }
    }

    return topicScores.entries.map((e) {
        final avg = e.value.isEmpty
            ? 0
            : e.value.reduce((a, b) => a + b) ~/ e.value.length;
        return {'topic': e.key, 'avgScore': avg, 'count': e.value.length};
      }).toList()
      ..sort((a, b) => (a['avgScore'] as int).compareTo(b['avgScore'] as int));
  }

  Future<Map<String, dynamic>> fetchSimulationAnalytics() async {
    final users = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .limit(200)
        .get();
    final attempts = <Map<String, dynamic>>[];
    for (final user in users.docs) {
      final profile = user.data();
      final snapshot = await user.reference
          .collection('simulation_attempts')
          .get();
      attempts.addAll(
        snapshot.docs.map(
          (doc) => {
            ...doc.data(),
            'program': profile['program'] ?? 'Unknown',
            'yearLevel': profile['yearLevel'] ?? 'Unknown',
          },
        ),
      );
    }
    final byLanguage = <String, List<Map<String, dynamic>>>{};
    final byActivity = <String, List<Map<String, dynamic>>>{};
    final errors = <String, int>{};
    for (final attempt in attempts) {
      byLanguage
          .putIfAbsent((attempt['language'] ?? 'Unknown').toString(), () => [])
          .add(attempt);
      byActivity
          .putIfAbsent(
            (attempt['title'] ?? 'Free practice').toString(),
            () => [],
          )
          .add(attempt);
      final error = (attempt['errorCategory'] ?? 'none').toString();
      if (error != 'none' && error != 'passed') {
        errors[error] = (errors[error] ?? 0) + 1;
      }
    }
    int rate(List<Map<String, dynamic>> rows) => rows.isEmpty
        ? 0
        : (rows.where((item) => item['result'] == 'passed').length *
                  100 /
                  rows.length)
              .round();
    final languageRates = byLanguage.entries
        .map(
          (entry) => {
            'label': entry.key,
            'attempts': entry.value.length,
            'passRate': rate(entry.value),
          },
        )
        .toList();
    final mostFailed =
        byActivity.entries
            .map(
              (entry) => {
                'label': entry.key,
                'attempts': entry.value.length,
                'failures': entry.value
                    .where((item) => item['result'] != 'passed')
                    .length,
                'passRate': rate(entry.value),
              },
            )
            .toList()
          ..sort(
            (a, b) => (b['failures'] as int).compareTo(a['failures'] as int),
          );
    final errorRows =
        errors.entries
            .map((entry) => {'label': entry.key, 'count': entry.value})
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return {
      'attempts': attempts.length,
      'passRate': rate(attempts),
      'languages': languageRates,
      'mostFailed': mostFailed.take(5).toList(),
      'errors': errorRows,
    };
  }

  Future<Map<String, dynamic>> fetchQuizAnalytics() async {
    final snapshot = await _db.collection('quiz_attempts').limit(1000).get();
    final attempts = snapshot.docs.map((doc) => doc.data()).toList();
    int rate(List<Map<String, dynamic>> rows) => rows.isEmpty
        ? 0
        : (rows.where((row) => row['passed'] == true).length *
                  100 /
                  rows.length)
              .round();
    final byProgram = <String, List<Map<String, dynamic>>>{};
    final byYear = <String, List<Map<String, dynamic>>>{};
    final missed = <String, int>{};
    for (final attempt in attempts) {
      byProgram
          .putIfAbsent((attempt['program'] ?? 'Unknown').toString(), () => [])
          .add(attempt);
      byYear
          .putIfAbsent((attempt['yearLevel'] ?? 'Unknown').toString(), () => [])
          .add(attempt);
      final outcomes = attempt['questionOutcomes'];
      if (outcomes is Map) {
        for (final entry in outcomes.entries) {
          if (entry.value != true) {
            missed[entry.key.toString()] =
                (missed[entry.key.toString()] ?? 0) + 1;
          }
        }
      }
    }
    List<Map<String, dynamic>> groups(
      Map<String, List<Map<String, dynamic>>> source,
    ) =>
        source.entries
            .map(
              (entry) => {
                'label': entry.key,
                'attempts': entry.value.length,
                'passRate': rate(entry.value),
              },
            )
            .toList()
          ..sort(
            (a, b) => (b['attempts'] as int).compareTo(a['attempts'] as int),
          );
    final missedRows =
        missed.entries
            .map((entry) => {'label': entry.key, 'count': entry.value})
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return {
      'attempts': attempts.length,
      'passRate': rate(attempts),
      'programs': groups(byProgram),
      'years': groups(byYear),
      'mostMissed': missedRows.take(5).toList(),
    };
  }

  /// Fetch most active students by total XP.
  Future<List<Map<String, dynamic>>> fetchTopStudentsByXp({
    int limit = 10,
  }) async {
    final users = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .limit(200)
        .get();
    final rows = <Map<String, dynamic>>[];
    for (final user in users.docs) {
      final profile = await _db.collection('user_profiles').doc(user.id).get();
      final userData = user.data();
      final profileData = profile.data() ?? const <String, dynamic>{};
      rows.add({
        'uid': user.id,
        ...profileData,
        'displayName':
            userData['displayName'] ??
            profileData['displayName'] ??
            userData['email'] ??
            'Learner',
        'email': userData['email'] ?? '',
        'role': 'student',
      });
    }
    rows.sort(
      (a, b) =>
          ((b['totalXp'] as num?) ?? 0).compareTo((a['totalXp'] as num?) ?? 0),
    );
    return rows.take(limit).toList();
  }
}
