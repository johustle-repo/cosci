import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/services/lesson_service.dart';
import 'package:pseudocode_apk/services/sequential_unlock_policy.dart';

class LessonsProvider extends ChangeNotifier {
  LessonService? _lessonService;
  List<Lesson> _lessons = const [];
  bool _isLoading = false;
  String? _errorMessage;
  Set<String> _completedLessonIds = const {};

  List<Lesson> get lessons => _lessons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => !_isLoading && _lessons.isEmpty && _errorMessage == null;
  Set<String> get completedLessonIds => _completedLessonIds;
  bool isCompleted(String lessonId) => _completedLessonIds.contains(lessonId);

  // Lessons unlock one at a time in sortOrder: a lesson opens only after
  // every lesson before it has been completed.
  List<bool> get _finished =>
      _lessons.map((lesson) => isCompleted(lesson.id)).toList();

  Set<String> get unlockedLessonIds => SequentialUnlockPolicy.unlockedIds(
    _lessons.map((lesson) => lesson.id).toList(),
    _finished,
  );

  bool isUnlocked(String lessonId) => unlockedLessonIds.contains(lessonId);

  /// The lesson the student must finish next, or null when all are complete.
  Lesson? get currentLesson {
    final index = SequentialUnlockPolicy.currentIndex(_finished);
    return index < _lessons.length ? _lessons[index] : null;
  }

  /// With sequential unlocking, the only recommendation is the current lesson.
  List<Lesson> get recommendedLessons {
    final current = currentLesson;
    return current == null ? const [] : [current];
  }

  void attach(LessonService lessonService) {
    _lessonService = lessonService;
  }

  Future<void> loadLessons({bool forceRefresh = false}) async {
    if (_lessonService == null || _isLoading) {
      return;
    }

    if (!forceRefresh && _lessons.isNotEmpty && _errorMessage == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lessons = await _lessonService!.fetchLessons();
      _completedLessonIds = await _lessonService!.fetchCompletedLessonIds();
    } catch (_) {
      _errorMessage = 'Unable to load lessons right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
