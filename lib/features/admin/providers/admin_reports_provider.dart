import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';

class AdminReportsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;

  List<Map<String, dynamic>> _topicScores = [];
  List<Map<String, dynamic>> _topStudents = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _simulationAnalytics = const {};
  Map<String, dynamic> _quizAnalytics = const {};

  List<Map<String, dynamic>> get topicScores => _topicScores;
  List<Map<String, dynamic>> get topStudents => _topStudents;
  // Weakest = lowest avg score (already sorted ascending by service)
  List<Map<String, dynamic>> get weakestTopics => _topicScores.take(5).toList();
  // Strongest = highest avg score
  List<Map<String, dynamic>> get strongestTopics =>
      _topicScores.reversed.take(5).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get simulationAnalytics => _simulationAnalytics;
  Map<String, dynamic> get quizAnalytics => _quizAnalytics;

  void attach(AdminFirestoreService service) {
    if (identical(_service, service)) return;
    _service = service;
  }

  Future<void> loadReports() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    final errors = <String>[];
    Future<void> capture(Future<void> Function() load) async {
      try {
        await load();
      } catch (e) {
        errors.add(adminErrorMessage(e));
      }
    }

    await Future.wait([
      capture(() async => _topicScores = await _service!.fetchTopicScores()),
      capture(
        () async => _topStudents = await _service!.fetchTopStudentsByXp(),
      ),
      capture(
        () async =>
            _simulationAnalytics = await _service!.fetchSimulationAnalytics(),
      ),
      capture(
        () async => _quizAnalytics = await _service!.fetchQuizAnalytics(),
      ),
    ]);
    _error = errors.isEmpty ? null : errors.toSet().join(' ');
    {
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
