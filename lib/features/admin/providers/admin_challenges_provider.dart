import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_daily_challenge.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminChallengesProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminDailyChallenge> _challenges = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<AdminDailyChallenge> get challenges => _challenges;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadChallenges() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _challenges = await _service!.fetchDailyChallenges();
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<bool> createChallenge(AdminDailyChallenge c) async {
    if (_service == null) return false;
    if (c.status == 'active' && !c.isReadyToActivate) {
      _error =
          'Add a title, description, date, and linked activity before activation.';
      _notifySafely();
      return false;
    }
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.createDailyChallenge(c);
      await _logger?.logCreate('challenges', 'Created challenge: ${c.title}');
      await loadChallenges();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<int> installStarterChallenges() async {
    if (_service == null) return 0;
    _isSaving = true;
    _error = null;
    _notifySafely();
    try {
      final count = await _service!.installStarterDailyChallenges();
      if (count == 0) {
        _error =
            'Publish at least one lesson, simulation, quiz, or puzzle before installing challenges.';
        return 0;
      }
      await _logger?.logCreate(
        'challenges',
        'Installed a $count-day ready-to-use challenge plan',
      );
      await loadChallenges();
      return count;
    } catch (e) {
      _error = adminErrorMessage(e);
      return 0;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateChallenge(AdminDailyChallenge c) async {
    if (_service == null) return false;
    if (c.status == 'active' && !c.isReadyToActivate) {
      _error = 'Complete all required challenge details before activation.';
      _notifySafely();
      return false;
    }
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.updateDailyChallenge(c);
      await _logger?.logUpdate(
        'challenges',
        'Updated challenge: ${c.title}',
        id: c.id,
      );
      await loadChallenges();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteChallenge(String id, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deleteDailyChallenge(id);
      await _logger?.logDelete(
        'challenges',
        'Deleted challenge: $title',
        id: id,
      );
      _challenges.removeWhere((c) => c.id == id);
      _notifySafely();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  Future<void> toggleStatus(String id, String status) async {
    if (_service == null) return;
    final current = _challenges.where((c) => c.id == id).firstOrNull;
    if (status == 'active' && (current == null || !current.isReadyToActivate)) {
      _error = 'This challenge is incomplete and cannot be activated.';
      _notifySafely();
      return;
    }
    try {
      await _service!.toggleChallengeStatus(id, status);
      final idx = _challenges.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _challenges[idx] = _challenges[idx].copyWith(status: status);
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
