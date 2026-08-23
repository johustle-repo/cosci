import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_lesson.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminLessonsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminLesson> _lessons = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Map<String, int> _completionCounts = const {};
  bool _hasLoaded = false;

  List<AdminLesson> get lessons => _lessons;
  List<AdminLesson> get recentDrafts {
    final drafts = _lessons.where((lesson) => !lesson.isPublished).toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? a.updatedAt ?? DateTime(1970);
        final bDate = b.createdAt ?? b.updatedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return drafts.take(4).toList(growable: false);
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Map<String, int> get completionCounts => _completionCounts;

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadLessons({bool forceRefresh = false}) async {
    if (_service == null || _isLoading || (!forceRefresh && _hasLoaded)) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _lessons = await _service!.fetchLessons();
      _hasLoaded = true;
    } catch (e) {
      _error = adminErrorMessage(e);
    }
    try {
      _completionCounts = await _service!.fetchLessonCompletionCounts();
    } catch (e) {
      _error ??= adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<List<Map<String, dynamic>>> loadRevisions(String lessonId) async {
    if (_service == null) return const [];
    return _service!.fetchLessonRevisions(lessonId);
  }

  Future<bool> createLesson(AdminLesson lesson) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.createLesson(lesson);
      await _logger?.logCreate('lessons', 'Created lesson: ${lesson.title}');
      await loadLessons(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateLesson(AdminLesson lesson) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.updateLesson(lesson);
      await _logger?.logUpdate(
        'lessons',
        'Updated lesson: ${lesson.title}',
        id: lesson.id,
      );
      await loadLessons(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteLesson(String lessonId, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deleteLesson(lessonId);
      await _logger?.logDelete(
        'lessons',
        'Deleted lesson: $title',
        id: lessonId,
      );
      _lessons.removeWhere((l) => l.id == lessonId);
      _notifySafely();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  Future<void> togglePublished(String lessonId, bool isPublished) async {
    if (_service == null) return;
    try {
      final lesson = _lessons.where((item) => item.id == lessonId).firstOrNull;
      if (isPublished && (lesson == null || !lesson.isReadyToPublish)) {
        throw StateError(
          'Complete the audience, structured lesson content, algorithm, and compiler validation before publishing.',
        );
      }
      await _service!.toggleLessonPublished(lessonId, isPublished);
      final action = isPublished ? 'Published' : 'Unpublished';
      await _logger?.logPublish(
        'lessons',
        '$action lesson: $lessonId',
        id: lessonId,
      );
      final idx = _lessons.indexWhere((l) => l.id == lessonId);
      if (idx != -1) {
        _lessons[idx] = _lessons[idx].copyWith(isPublished: isPublished);
        _notifySafely();
      }
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
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
