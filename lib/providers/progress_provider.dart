import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/progress_summary.dart';
import 'package:pseudocode_apk/services/progress_service.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressService? _progressService;
  ProgressSummary _summary = ProgressSummary.empty();
  bool _isLoading = false;
  String? _errorMessage;

  ProgressSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty =>
      !_isLoading &&
      _summary.totalCompletedActivities == 0 &&
      _summary.points == 0 &&
      _summary.earnedBadges.isEmpty &&
      _summary.recentActivities.isEmpty;

  void attach(ProgressService progressService) {
    _progressService = progressService;
  }

  Future<void> loadSummary({String? userId, bool forceRefresh = false}) async {
    if (_progressService == null || _isLoading) {
      return;
    }

    if (!forceRefresh &&
        _errorMessage == null &&
        (_summary.totalCompletedActivities > 0 ||
            _summary.points > 0 ||
            _summary.recentActivities.isNotEmpty)) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _progressService!.fetchProgressSummary(userId: userId);
    } catch (_) {
      _errorMessage = 'Unable to load progress details right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
