import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_profile.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_user_management_service.dart';

class AdminStudentsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  final AdminUserManagementService _userManagementService =
      const AdminUserManagementService();

  List<AdminStudentProfile> _students = [];
  AdminStudentProfile? _selectedStudent;
  bool _isLoading = false;
  bool _isDetailLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all | active | inactive
  DateTime? _lastLoadedAt;

  List<AdminStudentProfile> get students => _filtered();
  AdminStudentProfile? get selectedStudent => _selectedStudent;
  bool get isLoading => _isLoading;
  bool get isDetailLoading => _isDetailLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;

  void attach(AdminFirestoreService service, AdminLogService _) {
    if (identical(_service, service)) return;
    _service = service;
  }

  Future<void> loadStudents({bool forceRefresh = false}) async {
    if (_service == null) return;
    if (_isLoading) return;
    final loadedAt = _lastLoadedAt;
    if (!forceRefresh &&
        _students.isNotEmpty &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(minutes: 1)) {
      return;
    }
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _students = await _service!.fetchStudents();
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> loadStudentDetail(String uid) async {
    if (_service == null) return;
    _isDetailLoading = true;
    _selectedStudent = null;
    _error = null;
    _notifySafely();
    try {
      _selectedStudent = await _service!.fetchStudentById(uid);
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isDetailLoading = false;
      _notifySafely();
    }
  }

  Future<void> toggleStudentStatus(String uid, bool isActive) async {
    if (_service == null) return;
    try {
      await _service!.setStudentActiveStatus(uid, isActive);
      final idx = _students.indexWhere((s) => s.uid == uid);
      if (idx != -1) {
        _students[idx] = _students[idx].copyWith(isActive: isActive);
      }
      if (_selectedStudent?.uid == uid) {
        _selectedStudent = _selectedStudent!.copyWith(isActive: isActive);
      }
      _notifySafely();
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
    }
  }

  Future<void> changeUserRole(String uid, String role) async {
    if (_service == null) return;
    try {
      await _service!.updateUserRole(uid, role);
      await loadStudents(forceRefresh: true);
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
    }
  }

  Future<String?> deleteUser(String uid) async {
    _error = null;
    _notifySafely();
    try {
      await _userManagementService.deleteUser(uid);
      _students.removeWhere((student) => student.uid == uid);
      if (_selectedStudent?.uid == uid) _selectedStudent = null;
      _notifySafely();
      return null;
    } catch (e) {
      final message = adminErrorMessage(e);
      _error = message;
      _notifySafely();
      return message;
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    _notifySafely();
  }

  void setFilter(String status) {
    _filterStatus = status;
    _notifySafely();
  }

  List<AdminStudentProfile> _filtered() {
    var list = _students;
    if (_filterStatus == 'active') {
      list = list.where((s) => s.isActive).toList();
    }
    if (_filterStatus == 'inactive') {
      list = list.where((s) => !s.isActive).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (s) =>
                s.displayName.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q),
          )
          .toList();
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
