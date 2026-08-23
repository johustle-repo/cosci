import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_quiz.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminQuizzesProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminQuiz> _quizzes = [];
  AdminQuiz? _selectedQuiz;
  List<AdminQuizQuestion> _questions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isQuestionsLoading = false;
  String? _error;
  bool _hasLoaded = false;

  List<AdminQuiz> get quizzes => _quizzes;
  AdminQuiz? get selectedQuiz => _selectedQuiz;
  List<AdminQuizQuestion> get questions => _questions;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isQuestionsLoading => _isQuestionsLoading;
  String? get error => _error;

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadQuizzes({bool forceRefresh = false}) async {
    if (_service == null || _isLoading || (!forceRefresh && _hasLoaded)) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _quizzes = await _service!.fetchQuizzes();
      _hasLoaded = true;
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> loadQuestions(String quizId) async {
    if (_service == null) return;
    _isQuestionsLoading = true;
    _error = null;
    _notifySafely();
    try {
      _questions = await _service!.fetchQuizQuestions(quizId);
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isQuestionsLoading = false;
      _notifySafely();
    }
  }

  void selectQuiz(AdminQuiz quiz) {
    _selectedQuiz = quiz;
    _questions = [];
    _notifySafely();
    loadQuestions(quiz.id);
  }

  Future<bool> createQuiz(AdminQuiz quiz) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      if (quiz.isPublished) {
        throw StateError(
          'Create the quiz as a draft, add questions, then publish it.',
        );
      }
      final ref = await _service!.createQuiz(quiz);
      await _logger?.logCreate(
        'quizzes',
        'Created quiz: ${quiz.title}',
        id: ref.id,
      );
      await loadQuizzes(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> createQuizWithQuestions(
    AdminQuiz quiz,
    List<AdminQuizQuestion> questions,
  ) async {
    if (_service == null) return false;
    _isSaving = true;
    _error = null;
    _notifySafely();
    DocumentReference? quizRef;
    try {
      if (questions.isEmpty) {
        throw StateError('Generate at least one multiple-choice question.');
      }
      final stems = <String>{};
      for (final question in questions) {
        final stem = question.questionText
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
            .trim();
        final options = question.options
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toList();
        final answer = question.correctAnswer.trim().toLowerCase();
        if (!stems.add(stem)) {
          throw StateError(
            'Quiz generation found a repeated question. Generate the quiz again.',
          );
        }
        if (question.questionText.trim().length < 12 ||
            question.questionText.trim().length > 240) {
          throw StateError(
            'Every quiz question must be a clear sentence between 12 and 240 characters.',
          );
        }
        if (options.length != 4 || options.toSet().length != 4) {
          throw StateError(
            'Every quiz question must have four different answer choices.',
          );
        }
        if (options.where((value) => value == answer).length != 1) {
          throw StateError(
            'Every quiz question must contain its correct answer exactly once.',
          );
        }
      }
      quizRef = await _service!.createQuiz(quiz.copyWith(isPublished: false));
      for (final question in questions) {
        await _service!.saveQuizQuestion(quizRef.id, question);
      }
      await _logger?.logCreate(
        'quizzes',
        'Generated quiz from lesson: ${quiz.title}',
        id: quizRef.id,
      );
      await loadQuizzes(forceRefresh: true);
      return true;
    } catch (e) {
      if (quizRef != null) {
        try {
          await _service!.deleteQuiz(quizRef.id);
        } catch (_) {}
      }
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateQuiz(AdminQuiz quiz) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      if (quiz.isPublished) {
        if (!quiz.isReadyToPublish) {
          throw StateError('Complete all quiz requirements before publishing.');
        }
        final questions = await _service!.fetchQuizQuestions(quiz.id);
        if (questions.isEmpty ||
            questions.any(
              (q) =>
                  q.options.length < 2 ||
                  q.correctAnswer.trim().isEmpty ||
                  !q.options.contains(q.correctAnswer),
            )) {
          throw StateError(
            'Add valid questions and secure answer keys before publishing.',
          );
        }
      }
      await _service!.updateQuiz(quiz);
      await _logger?.logUpdate(
        'quizzes',
        'Updated quiz: ${quiz.title}',
        id: quiz.id,
      );
      await loadQuizzes(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteQuiz(String id, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deleteQuiz(id);
      await _logger?.logDelete('quizzes', 'Deleted quiz: $title', id: id);
      _quizzes.removeWhere((q) => q.id == id);
      _notifySafely();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  Future<void> togglePublished(String id, bool isPublished) async {
    if (_service == null) return;
    try {
      final quiz = _quizzes.where((item) => item.id == id).firstOrNull;
      if (isPublished && (quiz == null || !quiz.isReadyToPublish)) {
        throw StateError(
          'Complete the title, topic, language, focus, audience, year level, passing score, and attempt limit before publishing.',
        );
      }
      if (isPublished) {
        final questions = await _service!.fetchQuizQuestions(id);
        if (questions.isEmpty ||
            questions.any(
              (q) =>
                  q.questionText.trim().isEmpty ||
                  q.options.length < 2 ||
                  q.correctAnswer.trim().isEmpty ||
                  !q.options.contains(q.correctAnswer),
            )) {
          throw StateError(
            'Add valid questions and secure answer keys before publishing.',
          );
        }
      }
      await _service!.toggleQuizPublished(id, isPublished);
      final idx = _quizzes.indexWhere((q) => q.id == id);
      if (idx != -1) {
        _quizzes[idx] = _quizzes[idx].copyWith(isPublished: isPublished);
        _notifySafely();
      }
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
    }
  }

  Future<bool> saveQuestion(String quizId, AdminQuizQuestion question) async {
    if (_service == null) return false;
    try {
      await _service!.saveQuizQuestion(quizId, question);
      await loadQuestions(quizId);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  Future<bool> deleteQuestion(String quizId, String questionId) async {
    if (_service == null) return false;
    try {
      await _service!.deleteQuizQuestion(quizId, questionId);
      _questions.removeWhere((q) => q.id == questionId);
      _notifySafely();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  void clearError() {
    _error = null;
    _notifySafely();
  }

  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }
}
