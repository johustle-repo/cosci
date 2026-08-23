import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

class InstructorAttempt {
  const InstructorAttempt({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.program,
    required this.yearLevel,
    required this.title,
    required this.topic,
    required this.language,
    required this.result,
    required this.createdAt,
    required this.feedback,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String program;
  final String yearLevel;
  final String title;
  final String topic;
  final String language;
  final String result;
  final DateTime? createdAt;
  final String feedback;

  bool get passed => result == 'passed';
}

class InstructorStudent {
  const InstructorStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.program,
    required this.yearLevel,
    required this.isActive,
  });

  final String id;
  final String name;
  final String email;
  final String program;
  final String yearLevel;
  final bool isActive;
}

class InstructorOverview {
  const InstructorOverview({
    required this.studentCount,
    required this.students,
    required this.attempts,
    required this.hasMore,
  });

  final int studentCount;
  final List<InstructorStudent> students;
  final List<InstructorAttempt> attempts;
  final bool hasMore;

  int get passedAttempts => attempts.where((attempt) => attempt.passed).length;
  int get needsReview => attempts.where((attempt) => !attempt.passed).length;
  int get successRate =>
      attempts.isEmpty ? 0 : (passedAttempts * 100 / attempts.length).round();
  int get reviewedAttempts =>
      attempts.where((attempt) => attempt.feedback.trim().isNotEmpty).length;
  int get pendingFeedback => attempts
      .where((attempt) => !attempt.passed && attempt.feedback.trim().isEmpty)
      .length;

  Map<String, int> get attemptsByLanguage {
    final result = <String, int>{};
    for (final attempt in attempts) {
      final language = attempt.language.trim().isEmpty
          ? 'Not specified'
          : attempt.language.trim();
      result[language] = (result[language] ?? 0) + 1;
    }
    return result;
  }

  List<String> get learnersNeedingSupport {
    final totals = <String, int>{};
    final failures = <String, int>{};
    final names = <String, String>{};
    for (final attempt in attempts) {
      totals[attempt.studentId] = (totals[attempt.studentId] ?? 0) + 1;
      if (!attempt.passed) {
        failures[attempt.studentId] = (failures[attempt.studentId] ?? 0) + 1;
      }
      names[attempt.studentId] = attempt.studentName;
    }
    final ids = totals.keys.where((id) {
      final total = totals[id] ?? 0;
      return total > 0 && (failures[id] ?? 0) / total >= .5;
    }).toList()..sort((a, b) => (failures[b] ?? 0).compareTo(failures[a] ?? 0));
    return ids.map((id) => names[id] ?? 'Learner').take(5).toList();
  }

  List<MapEntry<String, int>> get weakestTopics {
    final failures = <String, int>{};
    for (final attempt in attempts.where((attempt) => !attempt.passed)) {
      final topic = attempt.topic.trim().isEmpty
          ? 'General practice'
          : attempt.topic.trim();
      failures[topic] = (failures[topic] ?? 0) + 1;
    }
    final values = failures.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return values.take(4).toList();
  }
}

class InstructorAnalyticsService {
  InstructorAnalyticsService({required FirestoreService firestoreService})
    : _firestore = firestoreService.instance;

  final FirebaseFirestore _firestore;

  Future<InstructorOverview> loadOverview({int attemptLimit = 25}) async {
    final usersSnapshot = await _firestore.collection('users').get();
    final students = <String, Map<String, dynamic>>{};
    for (final document in usersSnapshot.docs) {
      final data = document.data();
      if ((data['role'] as String? ?? 'student').toLowerCase() != 'student') {
        continue;
      }
      final uid = data['uid'] as String? ?? document.id;
      students[uid] = data;
    }

    // Read only the known learner paths. This is compatible with the scoped
    // instructor rules and includes legacy attempts that have no createdAt.
    final attemptSnapshots = await Future.wait(
      students.keys.map(
        (uid) => _firestore
            .collection('users')
            .doc(uid)
            .collection('simulation_attempts')
            .get(),
      ),
    );
    final allAttemptDocs = attemptSnapshots.expand((snapshot) => snapshot.docs);
    final attempts =
        allAttemptDocs.map((document) {
          final data = document.data();
          final uid = document.reference.parent.parent?.id ?? '';
          final student = students[uid] ?? const <String, dynamic>{};
          final timestamp = data['createdAt'];
          return InstructorAttempt(
            id: document.id,
            studentId: uid,
            studentName:
                student['displayName'] as String? ??
                student['email'] as String? ??
                'Learner',
            program: student['program'] as String? ?? 'Program not set',
            yearLevel: student['yearLevel'] as String? ?? 'Year not set',
            title: data['title'] as String? ?? 'Free practice',
            topic: data['topic'] as String? ?? '',
            language: data['language'] as String? ?? '',
            result: data['result'] as String? ?? 'unknown',
            createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
            feedback: data['instructorFeedback'] as String? ?? '',
          );
        }).toList()..sort(
          (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
            a.createdAt ?? DateTime(1970),
          ),
        );
    final visibleAttempts = attempts.take(attemptLimit).toList();
    final studentProfiles = students.entries.map((entry) {
      final data = entry.value;
      final email = data['email'] as String? ?? '';
      return InstructorStudent(
        id: entry.key,
        name:
            data['displayName'] as String? ??
            (email.isEmpty ? 'Learner' : email.split('@').first),
        email: email,
        program: data['program'] as String? ?? 'Program not set',
        yearLevel: data['yearLevel'] as String? ?? 'Year not set',
        isActive:
            data['isActive'] as bool? ??
            (data['status'] as String? ?? 'active').toLowerCase() == 'active',
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return InstructorOverview(
      studentCount: students.length,
      students: studentProfiles,
      attempts: visibleAttempts,
      hasMore: attempts.length > visibleAttempts.length,
    );
  }

  Future<void> saveFeedback({
    required InstructorAttempt attempt,
    required String instructorId,
    required String feedback,
  }) {
    return _firestore
        .collection('users')
        .doc(attempt.studentId)
        .collection('simulation_attempts')
        .doc(attempt.id)
        .update({
          'instructorFeedback': feedback.trim(),
          'reviewedBy': instructorId,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
  }
}
