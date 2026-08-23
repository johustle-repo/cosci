import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_activity_log.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';

class AdminLogsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;

  List<AdminActivityLog> _logs = [];
  bool _isLoading = false;
  String? _error;
  String _filterModule = 'all';
  String _filterAction = 'all';
  String _searchQuery = '';

  List<AdminActivityLog> get logs => _filtered();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterModule => _filterModule;
  String get filterAction => _filterAction;
  String get searchQuery => _searchQuery;

  void attach(AdminFirestoreService service) {
    if (identical(_service, service)) return;
    _service = service;
  }

  Future<void> loadLogs() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      final raw = await _service!.fetchActivityLogs(limit: 200);
      _logs = raw
          .map(
            (m) => AdminActivityLog.fromMap(
              m['id'] as String? ?? '',
              Map<String, dynamic>.from(m),
            ),
          )
          .toList();
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  void setModuleFilter(String module) {
    _filterModule = module;
    _notifySafely();
  }

  void setActionFilter(String action) {
    _filterAction = action;
    _notifySafely();
  }

  void setSearch(String value) {
    _searchQuery = value.trim().toLowerCase();
    _notifySafely();
  }

  List<AdminActivityLog> _filtered() {
    var list = _logs;
    if (_filterModule != 'all') {
      list = list.where((l) => l.targetModule == _filterModule).toList();
    }
    if (_filterAction != 'all') {
      list = list.where((l) => l.actionType == _filterAction).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((log) {
        return log.adminEmail.toLowerCase().contains(_searchQuery) ||
            log.description.toLowerCase().contains(_searchQuery) ||
            log.targetModule.toLowerCase().contains(_searchQuery) ||
            log.actionType.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    return list;
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
