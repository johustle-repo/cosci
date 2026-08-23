import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_settings.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminSettingsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  AdminSettings _settings = AdminSettings.defaults;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  List<Map<String, dynamic>> _backups = [];

  AdminSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<Map<String, dynamic>> get backups => _backups;

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service) && identical(_logger, logger)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadSettings() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      final results = await Future.wait([
        _service!.fetchSettings(),
        _service!.fetchSettingsBackups(),
      ]);
      _settings = results[0] as AdminSettings;
      _backups = List<Map<String, dynamic>>.from(results[1] as List);
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<bool> saveSettings(AdminSettings updated) async {
    if (_service == null) return false;
    _isSaving = true;
    _error = null;
    _notifySafely();

    try {
      await _service!.saveSettings(updated);
      await _logger?.logUpdate('settings', 'Updated app settings');
      _settings = updated;
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> addTopic(String topic) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return false;

    final exists = _settings.topics.any(
      (t) => t.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return false;

    final updated = _settings.copyWith(topics: [..._settings.topics, trimmed]);
    return saveSettings(updated);
  }

  Future<bool> removeTopic(String topic) async {
    final updated = _settings.copyWith(
      topics: _settings.topics.where((t) => t != topic).toList(),
    );
    return saveSettings(updated);
  }

  Future<bool> toggleModuleVisibility(String module, bool visible) async {
    final newVisibility = Map<String, bool>.from(_settings.moduleVisibility)
      ..[module] = visible;
    final updated = _settings.copyWith(moduleVisibility: newVisibility);
    return saveSettings(updated);
  }

  Future<bool> setAllModuleVisibility(
    Iterable<String> modules,
    bool visible,
  ) async {
    final newVisibility = Map<String, bool>.from(_settings.moduleVisibility);
    for (final module in modules) {
      newVisibility[module] = visible;
    }
    return saveSettings(_settings.copyWith(moduleVisibility: newVisibility));
  }

  Future<bool> restoreDefaultTopics() {
    return saveSettings(
      _settings.copyWith(
        topics: List<String>.from(AdminSettings.defaults.topics),
      ),
    );
  }

  Future<bool> createConfigurationBackup() async {
    if (_service == null || _isSaving) return false;
    _isSaving = true;
    _error = null;
    _notifySafely();
    try {
      await _service!.createSettingsBackup(_settings);
      _backups = await _service!.fetchSettingsBackups();
      await _logger?.logCreate('settings', 'Created configuration backup');
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> restoreConfigurationBackup(String backupId) async {
    if (_service == null || _isSaving) return false;
    _isSaving = true;
    _error = null;
    _notifySafely();
    try {
      _settings = await _service!.restoreSettingsBackup(backupId);
      await _logger?.logUpdate('settings', 'Restored configuration backup');
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateMaintenanceMode({
    required bool enabled,
    required String message,
  }) {
    return saveSettings(
      _settings.copyWith(
        maintenanceMode: enabled,
        maintenanceMessage: message.trim(),
      ),
    );
  }

  Future<bool> updateGroqApiKey(String apiKey) async {
    final updated = _settings.copyWith(groqApiKey: apiKey.trim());
    return saveSettings(updated);
  }

  Future<bool> clearGroqApiKey() async {
    final updated = _settings.copyWith(groqApiKey: '');
    return saveSettings(updated);
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
