import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/quiz.dart';
import 'package:pseudocode_apk/models/quiz_question.dart';
import 'package:pseudocode_apk/services/quiz_service.dart';
import 'package:pseudocode_apk/services/sequential_unlock_policy.dart';

class QuizzesProvider extends ChangeNotifier {
  QuizService? _quizService;
  List<Quiz> _quizzes = const [];
  final Map<String, List<QuizQuestion>> _questionsByQuizId = {};
  final Map<String, List<QuizAttemptSummary>> _attemptsByQuizId = {};
  bool _isLoading = false;
  bool _isLoadingQuestions = false;
  String? _errorMessage;

  List<Quiz> get quizzes => _quizzes;
  bool get isLoadingQuestions => _isLoadingQuestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _quizzes.isEmpty && _errorMessage == null;

  List<QuizQuestion> questionsFor(String quizId) {
    return _questionsByQuizId[quizId] ?? const [];
  }

  List<QuizAttemptSummary> attemptsFor(String quizId) =>
      _attemptsByQuizId[quizId] ?? const [];

  /// Passed, or every attempt used.
  bool isFinished(Quiz quiz) {
    final attempts = attemptsFor(quiz.id);
    return SequentialUnlockPolicy.isQuizFinished(
      anyAttemptPassed: attempts.any((attempt) => attempt.passed),
      attemptsUsed: attempts.length,
      attemptLimit: quiz.attemptLimit,
    );
  }

  // Quizzes unlock one at a time in list order: a quiz opens only after
  // every quiz before it is finished.
  Set<String> get unlockedQuizIds => SequentialUnlockPolicy.unlockedIds(
    _quizzes.map((quiz) => quiz.id).toList(),
    _quizzes.map(isFinished).toList(),
  );

  bool isUnlocked(String quizId) => unlockedQuizIds.contains(quizId);

  /// The quiz the student must finish next, or null when all are finished.
  Quiz? get currentQuiz {
    final index = SequentialUnlockPolicy.currentIndex(
      _quizzes.map(isFinished).toList(),
    );
    return index < _quizzes.length ? _quizzes[index] : null;
  }

  void attach(QuizService quizService) {
    _quizService = quizService;
  }

  Future<void> loadQuizzes({bool forceRefresh = false}) async {
    if (_quizService == null || _isLoading) {
      return;
    }

    if (!forceRefresh && _quizzes.isNotEmpty && _errorMessage == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _quizzes = await _quizService!.fetchQuizzes();
      final histories = await _quizService!.fetchAttemptHistories(
        _quizzes.map((quiz) => quiz.id),
      );
      _attemptsByQuizId
        ..clear()
        ..addAll(histories);
    } catch (_) {
      _errorMessage = 'Unable to load quizzes right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<QuizQuestion>> loadQuestionsFor(
    Quiz quiz, {
    bool forceRefresh = false,
  }) async {
    if (_quizService == null || _isLoadingQuestions) {
      return questionsFor(quiz.id);
    }

    if (!forceRefresh && _questionsByQuizId.containsKey(quiz.id)) {
      return questionsFor(quiz.id);
    }

    _isLoadingQuestions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final questions = await _quizService!.fetchQuizQuestions(quiz);
      _questionsByQuizId[quiz.id] = questions;
      _attemptsByQuizId[quiz.id] = await _quizService!.fetchAttemptHistory(
        quiz.id,
      );
      return questions;
    } catch (_) {
      _errorMessage = 'Unable to load quiz questions right now.';
      return const [];
    } finally {
      _isLoadingQuestions = false;
      notifyListeners();
    }
  }

  Future<QuizEvaluationResult> submitQuiz(
    Quiz quiz,
    Map<String, String> answers,
  ) {
    if (_quizService == null) throw StateError('Quiz service unavailable.');
    return _quizService!.submitQuiz(quiz, answers).then((result) async {
      _attemptsByQuizId[quiz.id] = await _quizService!.fetchAttemptHistory(
        quiz.id,
      );
      notifyListeners();
      return result;
    });
  }
}
