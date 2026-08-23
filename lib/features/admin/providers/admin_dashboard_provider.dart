import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_activity_log.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  AdminFirestoreService? _service;

  Map<String, int> _counts = {};
  List<AdminActivityLog> _recentLogs = [];
  bool _isLoading = false;
  String? _error;

  Map<String, int> get counts => _counts;
  List<AdminActivityLog> get recentLogs => _recentLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void attach(AdminFirestoreService service) {
    if (identical(_service, service)) return;
    _service = service;
  }

  Future<void> loadDashboard() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();

    final errors = <String>[];
    try {
      _counts = await _service!.fetchDashboardCounts();
    } catch (e) {
      errors.add(adminErrorMessage(e));
    }
    try {
      final rawLogs = await _service!.fetchActivityLogs(limit: 10);
      _recentLogs = rawLogs
          .map(
            (m) => AdminActivityLog.fromMap(
              m['id'] as String? ?? '',
              Map<String, dynamic>.from(m),
            ),
          )
          .toList();
    } catch (e) {
      errors.add(adminErrorMessage(e));
    } finally {
      _error = errors.isEmpty ? null : errors.toSet().join(' ');
      _isLoading = false;
      _notifySafely();
    }
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
