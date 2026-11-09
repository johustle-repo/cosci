import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/services/language_tracks.dart';
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

  // Lessons unlock one at a time in sortOrder *within each programming
  // language*, so a student can take C++ and Java lessons at the same time.
  List<bool> get _finished =>
      _lessons.map((lesson) => isCompleted(lesson.id)).toList();

  List<String> get _tracks => _lessons
      .map((lesson) => LanguageTracks.normalize(lesson.language))
      .toList();

  /// Language tracks that have at least one lesson, in display order.
  List<String> get languages =>
      LanguageTracks.available(_lessons.map((lesson) => lesson.language));

  Set<String> get unlockedLessonIds =>
      SequentialUnlockPolicy.unlockedIdsByTrack(
        _lessons.map((lesson) => lesson.id).toList(),
        _tracks,
        _finished,
      );

  bool isUnlocked(String lessonId) => unlockedLessonIds.contains(lessonId);

  /// The lesson the student must finish next in [language], or null when
  /// that language track is complete.
  Lesson? currentLessonFor(String language) {
    final index = SequentialUnlockPolicy.currentIndexInTrack(
      LanguageTracks.normalize(language),
      _tracks,
      _finished,
    );
    return index == null ? null : _lessons[index];
  }

  /// One recommendation per language track: its current lesson. Only tracks
  /// in [selected] are included (an empty selection means all languages).
  List<Lesson> recommendedLessons([Set<String> selected = const {}]) => [
    for (final language in languages)
      if (LanguageTracks.matches(selected, language))
        ?currentLessonFor(language),
  ];

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
