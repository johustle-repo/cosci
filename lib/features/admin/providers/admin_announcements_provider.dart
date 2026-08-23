import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_announcement.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminAnnouncementsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminAnnouncement> _announcements = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<AdminAnnouncement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<bool> installCommonAnnouncements() async {
    if (_service == null || _isSaving) return false;
    const templates = [
      AdminAnnouncement(
        id: '',
        title: 'Welcome to CoSci',
        message:
            'Welcome, learners! Explore your lessons, complete coding activities, and track your progress from your dashboard.',
        targetAudience: 'students',
        isPublished: false,
      ),
      AdminAnnouncement(
        id: '',
        title: 'Weekly Learning Reminder',
        message:
            'Remember to complete your assigned lesson and practice activities before the end of the week. Consistent practice builds stronger programming skills.',
        targetAudience: 'students',
        isPublished: false,
      ),
      AdminAnnouncement(
        id: '',
        title: 'New Coding Activities Available',
        message:
            'New lessons, simulations, quizzes, and syntax puzzles are now available. Open your learner workspace to continue your learning path.',
        targetAudience: 'students',
        isPublished: false,
      ),
      AdminAnnouncement(
        id: '',
        title: 'Scheduled System Maintenance',
        message:
            'CoSci may be temporarily unavailable during scheduled maintenance. Save your work and complete active attempts before the announced maintenance period.',
        targetAudience: 'all',
        isPublished: false,
      ),
      AdminAnnouncement(
        id: '',
        title: 'Content Review Reminder',
        message:
            'Please review generated lesson drafts and validate compiler activities before publishing them to learners.',
        targetAudience: 'professors',
        isPublished: false,
      ),
    ];
    _isSaving = true;
    _error = null;
    _notifySafely();
    try {
      final existingTitles = _announcements
          .map((item) => item.title.trim().toLowerCase())
          .toSet();
      final pending = templates.where(
        (item) => !existingTitles.contains(item.title.toLowerCase()),
      );
      var created = 0;
      for (final template in pending) {
        await _service!.createAnnouncement(template);
        created++;
      }
      await _logger?.logCreate(
        'announcements',
        'Installed $created common announcement templates',
      );
      await loadAnnouncements();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadAnnouncements() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _announcements = await _service!.fetchAnnouncements();
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<bool> createAnnouncement(AdminAnnouncement a) async {
    if (_service == null) return false;
    if (a.isPublished && !a.isReadyToPublish) {
      _error = 'Add a clear title and message before publishing.';
      _notifySafely();
      return false;
    }
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.createAnnouncement(a);
      await _logger?.logCreate(
        'announcements',
        'Created announcement: ${a.title}',
      );
      await loadAnnouncements();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateAnnouncement(AdminAnnouncement a) async {
    if (_service == null) return false;
    if (a.isPublished && !a.isReadyToPublish) {
      _error = 'Add a clear title and message before publishing.';
      _notifySafely();
      return false;
    }
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.updateAnnouncement(a);
      await _logger?.logUpdate(
        'announcements',
        'Updated announcement: ${a.title}',
        id: a.id,
      );
      await loadAnnouncements();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteAnnouncement(String id, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deleteAnnouncement(id);
      await _logger?.logDelete(
        'announcements',
        'Deleted announcement: $title',
        id: id,
      );
      _announcements.removeWhere((a) => a.id == id);
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
    final current = _announcements.where((a) => a.id == id).firstOrNull;
    if (isPublished && (current == null || !current.isReadyToPublish)) {
      _error = 'This announcement is incomplete and cannot be published.';
      _notifySafely();
      return;
    }
    try {
      await _service!.toggleAnnouncementPublished(id, isPublished);
      final idx = _announcements.indexWhere((a) => a.id == id);
      if (idx != -1) {
        _announcements[idx] = _announcements[idx].copyWith(
          isPublished: isPublished,
        );
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
