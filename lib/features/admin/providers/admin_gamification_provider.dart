import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_badge.dart';
import 'package:pseudocode_apk/features/admin/models/admin_gamification_rule.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminGamificationProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminBadge> _badges = [];
  List<AdminGamificationRule> _rules = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<AdminBadge> get badges => _badges;
  List<AdminGamificationRule> get rules => _rules;
  List<AdminGamificationRule> get xpRules =>
      _rules.where((r) => r.isXpRule).toList();
  List<AdminGamificationRule> get levelThresholds =>
      _rules.where((r) => r.isLevelThreshold).toList();
  List<AdminGamificationRule> get streakRewards =>
      _rules.where((r) => r.isStreakReward).toList();
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadAll() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    final errors = <String>[];
    await Future.wait([
      () async {
        try {
          _badges = await _service!.fetchBadges();
        } catch (e) {
          errors.add(adminErrorMessage(e));
        }
      }(),
      () async {
        try {
          _rules = await _service!.fetchGamificationRules();
        } catch (e) {
          errors.add(adminErrorMessage(e));
        }
      }(),
    ]);
    _error = errors.isEmpty ? null : errors.toSet().join(' ');
    {
      _isLoading = false;
      _notifySafely();
    }
  }

  // â”€â”€ Badges â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> createBadge(AdminBadge badge) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.createBadge(badge);
      await _logger?.logCreate('badges', 'Created badge: ${badge.title}');
      await loadAll();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> installStarterBadges(List<AdminBadge> badges) async {
    if (_service == null || badges.isEmpty) return false;
    _isSaving = true;
    _error = null;
    _notifySafely();
    try {
      await _service!.installStarterBadges(badges);
      await _logger?.logCreate(
        'badges',
        'Installed ${badges.length} ready-to-use learner badges',
      );
      await loadAll();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateBadge(AdminBadge badge) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.updateBadge(badge);
      await _logger?.logUpdate(
        'badges',
        'Updated badge: ${badge.title}',
        id: badge.id,
      );
      await loadAll();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteBadge(String id, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deleteBadge(id);
      await _logger?.logDelete('badges', 'Deleted badge: $title', id: id);
      _badges.removeWhere((b) => b.id == id);
      _notifySafely();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  // â”€â”€ Rules â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> saveRule(AdminGamificationRule rule) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.saveGamificationRule(rule);
      await _logger?.logUpdate(
        'gamification',
        'Saved rule: ${rule.description}',
        id: rule.id,
      );
      await loadAll();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> installRules(List<AdminGamificationRule> rules) async {
    if (_service == null || rules.isEmpty) return false;
    _isSaving = true;
    _error = null;
    _notifySafely();
    try {
      await _service!.installGamificationRules(rules);
      await _logger?.logCreate(
        'gamification',
        'Installed ${rules.length} recommended gamification rules',
      );
      await loadAll();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteRule(String id) async {
    if (_service == null) return false;
    try {
      await _service!.deleteGamificationRule(id);
      _rules.removeWhere((r) => r.id == id);
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
