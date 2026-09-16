import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_masterlist_entry.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';

class AdminMasterlistProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminMasterlistEntry> _entries = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _hasLoaded = false;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  List<AdminMasterlistEntry> get entries {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _entries;
    return _entries
        .where(
          (e) =>
              e.studentNumber.toLowerCase().contains(query) ||
              e.name.toLowerCase().contains(query) ||
              e.program.toLowerCase().contains(query),
        )
        .toList();
  }

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  void setSearch(String value) {
    _searchQuery = value;
    _notifySafely();
  }

  Future<void> loadEntries({bool forceRefresh = false}) async {
    if (_service == null || _isLoading || (!forceRefresh && _hasLoaded)) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _entries = await _service!.fetchMasterlistEntries();
      _hasLoaded = true;
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  bool exists(String studentNumber) =>
      _entries.any((e) => e.studentNumber == studentNumber);

  Future<bool> createEntry(AdminMasterlistEntry entry) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.createMasterlistEntry(entry);
      await _logger?.logCreate(
        'ccs_masterlist',
        'Added ${entry.studentNumber} (${entry.name}) to the CCS masterlist',
      );
      await loadEntries(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateEntry(AdminMasterlistEntry entry) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.updateMasterlistEntry(entry);
      await _logger?.logUpdate(
        'ccs_masterlist',
        'Updated masterlist entry ${entry.studentNumber}',
        id: entry.studentNumber,
      );
      await loadEntries(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteEntry(String studentNumber, String name) async {
    if (_service == null) return false;
    try {
      await _service!.deleteMasterlistEntry(studentNumber);
      await _logger?.logDelete(
        'ccs_masterlist',
        'Removed $studentNumber ($name) from the CCS masterlist',
        id: studentNumber,
      );
      _entries.removeWhere((e) => e.studentNumber == studentNumber);
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
