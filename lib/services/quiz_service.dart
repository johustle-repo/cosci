import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/quiz.dart';
import 'package:pseudocode_apk/models/quiz_question.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class QuizEvaluationResult {
  const QuizEvaluationResult({
    required this.scorePercent,
    required this.correct,
    required this.total,
    required this.passed,
    required this.feedback,
  });
  final int scorePercent;
  final int correct;
  final int total;
  final bool passed;
  final Map<String, Map<String, dynamic>> feedback;
}

class QuizAttemptSummary {
  const QuizAttemptSummary({
    required this.scorePercent,
    required this.passed,
    required this.attemptNumber,
    required this.createdAt,
  });
  final int scorePercent;
  final bool passed;
  final int attemptNumber;
  final DateTime? createdAt;
}

class QuizService {
  QuizService({
    required FirestoreService firestoreService,
    String? evaluatorEndpoint,
    http.Client? client,
  }) : _firestoreService = firestoreService,
       _configuredEvaluatorEndpoint = evaluatorEndpoint,
       _client = client;

  final FirestoreService _firestoreService;
  final String? _configuredEvaluatorEndpoint;
  final http.Client? _client;
  static const _evaluatorEndpoint = String.fromEnvironment(
    'QUIZ_EVALUATOR_URL',
    defaultValue: '',
  );

  static String get _resolvedEvaluatorEndpoint {
    if (_evaluatorEndpoint.trim().isNotEmpty) {
      return _evaluatorEndpoint.trim();
    }
    final host = Uri.base.host.toLowerCase();
    final isLocal = host.isEmpty || host == 'localhost' || host == '127.0.0.1';
    return isLocal ? 'http://localhost:8787/quiz/evaluate' : '';
  }

  Future<List<Quiz>> fetchQuizzes() async {
    final snapshot = await _firestoreService.quizzesCollection().get();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final user = uid == null ? null : await _firestoreService.fetchAppUser(uid);

    final quizzes = await Future.wait(
      snapshot.docs
          .where((doc) => doc.data()['isPublished'] as bool? ?? true)
          .where((doc) => _eligible(doc.data(), user?.program, user?.yearLevel))
          .map((doc) async {
            final data = doc.data();
            final count = await _resolveQuestionCount(doc.reference, data);
            return Quiz.fromMap(doc.id, data, questionCount: count);
          }),
    );

    quizzes.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) {
        return order;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return quizzes;
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

  Future<int?> _resolveQuestionCount(
    DocumentReference<Map<String, dynamic>> quizRef,
    Map<String, dynamic> data,
  ) async {
    if (data['questionText'] is String &&
        (data['questionText'] as String).isNotEmpty) {
      return 1;
    }

    try {
      final countSnapshot = await quizRef.collection('questions').count().get();
      return countSnapshot.count;
    } catch (_) {
      return null;
    }
  }

  Future<List<QuizQuestion>> fetchQuizQuestions(Quiz quiz) async {
    final quizRef = _firestoreService.quizDocument(quiz.id);
    final snapshot = await quizRef.collection('questions').get();

    final questions = snapshot.docs
        .map((doc) => QuizQuestion.fromMap(doc.id, doc.data()))
        .where(
          (question) =>
              question.questionText.isNotEmpty &&
              question.options.isNotEmpty &&
              question.options.length >= 2,
        )
        .toList();

    if (questions.isEmpty) {
      final quizSnapshot = await quizRef.get();
      final data = quizSnapshot.data();
      if (data != null && data['questionText'] is String) {
        questions.add(QuizQuestion.fromMap(quiz.id, data));
      }
    }

    questions.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) {
        return order;
      }
      return a.questionText.compareTo(b.questionText);
    });

    if (quiz.shuffleQuestions) {
      final random = Random.secure();
      questions.shuffle(random);
      for (var i = 0; i < questions.length; i++) {
        final options = [...questions[i].options]..shuffle(random);
        questions[i] = questions[i].copyWith(options: options);
      }
    }

    return questions;
  }

  Future<List<QuizAttemptSummary>> fetchAttemptHistory(String quizId) async {
    final grouped = await fetchAttemptHistories({quizId});
    return grouped[quizId] ?? const [];
  }

  Future<Map<String, List<QuizAttemptSummary>>> fetchAttemptHistories(
    Iterable<String> quizIds,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const {};
    final requestedIds = quizIds.toSet();
    if (requestedIds.isEmpty) return const {};
    final snapshot = await FirebaseFirestore.instance
        .collection('quiz_attempts')
        .where('userId', isEqualTo: uid)
        .get();
    final grouped = <String, List<QuizAttemptSummary>>{};
    for (final document in snapshot.docs) {
      final data = document.data();
      final quizId = data['quizId']?.toString() ?? '';
      if (!requestedIds.contains(quizId)) continue;
      final created = data['createdAt'];
      grouped
          .putIfAbsent(quizId, () => [])
          .add(
            QuizAttemptSummary(
              scorePercent: (data['scorePercent'] as num?)?.toInt() ?? 0,
              passed: data['passed'] == true,
              attemptNumber: (data['attemptNumber'] as num?)?.toInt() ?? 1,
              createdAt: created is Timestamp ? created.toDate() : null,
            ),
          );
    }
    for (final attempts in grouped.values) {
      attempts.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    }
    return grouped;
  }

  Future<QuizEvaluationResult> submitQuiz(
    Quiz quiz,
    Map<String, String> answers,
  ) async {
    final endpoint = _configuredEvaluatorEndpoint ?? _resolvedEvaluatorEndpoint;
    if (endpoint.isEmpty) {
      throw StateError(
        'Quiz grading is unavailable. Configure QUIZ_EVALUATOR_URL for this deployment.',
      );
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in before submitting a quiz.');
    final token = await user.getIdToken();
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'quizId': quiz.id, 'answers': answers}),
          )
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic> body = const {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } on FormatException {
        // Preserve the HTTP status below when a proxy returns non-JSON text.
      }
      if (response.statusCode != 200) {
        throw StateError(
          body['message']?.toString() ??
              body['error']?.toString() ??
              'Quiz evaluator returned HTTP ${response.statusCode}.',
        );
      }
      final rawFeedback = body['feedback'] as Map? ?? const {};
      return QuizEvaluationResult(
        scorePercent: (body['scorePercent'] as num?)?.toInt() ?? 0,
        correct: (body['correct'] as num?)?.toInt() ?? 0,
        total: (body['total'] as num?)?.toInt() ?? 0,
        passed: body['passed'] == true,
        feedback: rawFeedback.map(
          (key, value) =>
              MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
        ),
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
