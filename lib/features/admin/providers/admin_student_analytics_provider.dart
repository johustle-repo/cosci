import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_analytics.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';

/// Drives the admin Student Analytics page: per-student progress,
/// students needing help, and leaderboards.
class AdminStudentAnalyticsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;

  List<StudentAnalyticsRow> _rows = const [];
  ContentTotals _totals = const ContentTotals();
  bool _isLoading = false;
  String? _error;

  String _search = '';
  String? _program;
  String? _yearLevel;
  LeaderboardMetric _metric = LeaderboardMetric.xp;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ContentTotals get totals => _totals;
  String get search => _search;
  String? get program => _program;
  String? get yearLevel => _yearLevel;
  LeaderboardMetric get metric => _metric;
  bool get hasData => _rows.isNotEmpty;

  List<String> get programs =>
      (_rows.map((row) => row.profile.course.trim()).toSet()
            ..removeWhere((value) => value.isEmpty))
          .toList()
        ..sort();

  List<String> get yearLevels =>
      (_rows.map((row) => (row.profile.yearLevel ?? '').trim()).toSet()
            ..removeWhere((value) => value.isEmpty))
          .toList()
        ..sort();

  /// Rows after the search, program, and year-level filters.
  List<StudentAnalyticsRow> get rows {
    final query = _search.trim().toLowerCase();
    final filtered = _rows.where((row) {
      final profile = row.profile;
      if (_program != null && profile.course.trim() != _program) return false;
      if (_yearLevel != null &&
          (profile.yearLevel ?? '').trim() != _yearLevel) {
        return false;
      }
      if (query.isEmpty) return true;
      return profile.displayName.toLowerCase().contains(query) ||
          profile.email.toLowerCase().contains(query);
    }).toList();
    filtered.sort(
      (a, b) => a.profile.displayName.toLowerCase().compareTo(
        b.profile.displayName.toLowerCase(),
      ),
    );
    return filtered;
  }

  List<StudentAnalyticsRow> get needsHelp =>
      StudentAnalyticsCalculator.needsHelp(rows);

  List<StudentAnalyticsRow> get leaderboard =>
      StudentAnalyticsCalculator.leaderboard(rows, _metric);

  // Summary figures for the filtered group.
  int get activeThisWeek => rows
      .where(
        (row) =>
            row.lastActiveAt != null &&
            DateTime.now().difference(row.lastActiveAt!) <=
                StudentAnalyticsCalculator.inactiveAfter,
      )
      .length;

  int get averageCompletion {
    final list = rows;
    if (list.isEmpty) return 0;
    return (list.map((row) => row.completionPercent).reduce((a, b) => a + b) /
            list.length)
        .round();
  }

  int? get averageQuizScore {
    final scored = rows.where((row) => row.quizAverage != null).toList();
    if (scored.isEmpty) return null;
    return (scored.map((row) => row.quizAverage!).reduce((a, b) => a + b) /
            scored.length)
        .round();
  }

  void attach(AdminFirestoreService service) {
    if (identical(_service, service)) return;
    _service = service;
  }

  Future<void> load() async {
    if (_service == null || _isLoading) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      final studentsFuture = _service!.fetchStudents();
      final dataFuture = _service!.fetchStudentAnalyticsData();
      final students = (await studentsFuture)
          .where((profile) => profile.normalizedRole == 'student')
          .toList();
      final data = await dataFuture;
      _totals = data.totals;
      _rows = StudentAnalyticsCalculator.build(
        students: students,
        attempts: data.attempts,
        totals: data.totals,
        now: DateTime.now(),
      );
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  void setSearch(String value) {
    _search = value;
    _notifySafely();
  }

  void setProgram(String? value) {
    _program = value;
    _notifySafely();
  }

  void setYearLevel(String? value) {
    _yearLevel = value;
    _notifySafely();
  }

  void setMetric(LeaderboardMetric value) {
    _metric = value;
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
