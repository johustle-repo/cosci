import 'package:pseudocode_apk/models/code_simulation_activity.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CodeSimulationService {
  CodeSimulationService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Future<List<CodeSimulationActivity>> fetchActivities() async {
    final snapshot = await _firestoreService.simulationsCollection().get();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final user = uid == null ? null : await _firestoreService.fetchAppUser(uid);

    final activities = snapshot.docs
        .where((doc) => _eligible(doc.data(), user?.program, user?.yearLevel))
        .where((doc) => doc.data()['isPublished'] as bool? ?? true)
        .map((doc) => CodeSimulationActivity.fromMap(doc.id, doc.data()))
        .where((activity) => activity.expectedOutput.trim().isNotEmpty)
        .toList();

    activities.sort((a, b) {
      final topicCompare = a.topic.toLowerCase().compareTo(
        b.topic.toLowerCase(),
      );
      if (topicCompare != 0) {
        return topicCompare;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return activities;
  }

  bool _eligible(Map<String, dynamic> data, String? program, String? year) {
    final programs = List<String>.from(
      data['audiencePrograms'] as List? ?? const [],
    );
    final years = List<String>.from(data['yearLevels'] as List? ?? const []);
    return (programs.isEmpty ||
            program == null ||
            programs.contains(program)) &&
        (years.isEmpty || year == null || years.contains(year));
  }

  Future<void> recordAttempt({
    required String userId,
    required CodeSimulationActivity? activity,
    required String language,
    required String sourceCode,
    required String output,
    required String result,
    String submissionStatus = 'notSubmitted',
    int passedTests = 0,
    int totalTests = 0,
    int executionTimeMs = 0,
    String errorCategory = 'none',
    int activityVersion = 1,
  }) {
    return _firestoreService
        .userDocument(userId)
        .collection('simulation_attempts')
        .add({
          'activityId': activity?.id,
          'title': activity?.title ?? 'Free practice',
          'topic': activity?.topic,
          'language': language,
          'sourceCode': sourceCode,
          'output': output,
          'result': result,
          'compilerStatus': result,
          'submissionStatus': submissionStatus,
          'passedTests': passedTests,
          'totalTests': totalTests,
          'executionTimeMs': executionTimeMs,
          'errorCategory': errorCategory,
          'activityVersion': activityVersion,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<SimulationAttemptSummary>> fetchAttemptHistory(
    String userId,
  ) async {
    final snapshot = await _firestoreService
        .userDocument(userId)
        .collection('simulation_attempts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map((document) {
      final data = document.data();
      final timestamp = data['createdAt'];
      return SimulationAttemptSummary(
        title: data['title'] as String? ?? 'Free practice',
        language: data['language'] as String? ?? '',
        result: data['result'] as String? ?? 'unknown',
        feedback: data['instructorFeedback'] as String? ?? '',
        createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
        topic: data['topic'] as String? ?? '',
        errorCategory: data['errorCategory'] as String? ?? 'none',
        passedTests: (data['passedTests'] as num?)?.toInt() ?? 0,
        totalTests: (data['totalTests'] as num?)?.toInt() ?? 0,
        executionTimeMs: (data['executionTimeMs'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<void> saveDraft({
    required String userId,
    required String workspaceId,
    required String language,
    required String sourceCode,
  }) {
    return _firestoreService
        .userDocument(userId)
        .collection('code_drafts')
        .doc(workspaceId)
        .set({
          'language': language,
          'sourceCode': sourceCode,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<String?> loadDraft({
    required String userId,
    required String workspaceId,
  }) async {
    final snapshot = await _firestoreService
        .userDocument(userId)
        .collection('code_drafts')
        .doc(workspaceId)
        .get();
    return snapshot.data()?['sourceCode'] as String?;
  }
}

class SimulationAttemptSummary {
  const SimulationAttemptSummary({
    required this.title,
    required this.language,
    required this.result,
    required this.feedback,
    required this.createdAt,
    this.topic = '',
    this.errorCategory = 'none',
    this.passedTests = 0,
    this.totalTests = 0,
    this.executionTimeMs = 0,
  });
  final String title;
  final String language;
  final String result;
  final String feedback;
  final DateTime? createdAt;
  final String topic;
  final String errorCategory;
  final int passedTests;
  final int totalTests;
  final int executionTimeMs;
  bool get passed => result == 'passed';
}
