import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/services/lesson_service.dart';

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
  List<Lesson> get recommendedLessons {
    final pending = _lessons
        .where((lesson) => !isCompleted(lesson.id))
        .toList();
    int rank(Lesson lesson) => switch (lesson.difficulty.toLowerCase()) {
      'easy' => 0,
      'medium' => 1,
      _ => 2,
    };
    pending.sort((a, b) {
      final difficulty = rank(a).compareTo(rank(b));
      return difficulty != 0 ? difficulty : a.sortOrder.compareTo(b.sortOrder);
    });
    return pending.take(3).toList();
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
