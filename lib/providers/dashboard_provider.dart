import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/student_dashboard_data.dart';
import 'package:pseudocode_apk/services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardService? _dashboardService;
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  StudentDashboardData? _dashboardData;
  String? _lastLoadedUserId;

  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StudentDashboardData? get dashboardData => _dashboardData;
  bool get hasDashboardData => _dashboardData != null;

  void attach(DashboardService dashboardService) {
    _dashboardService = dashboardService;
  }

  void setIndex(int index) {
    if (_selectedIndex == index) {
      return;
    }

    _selectedIndex = index;
    notifyListeners();
  }

  Future<void> loadDashboard({
    required String userId,
    String? fallbackName,
    bool forceRefresh = false,
  }) async {
    if (_dashboardService == null || _isLoading) {
      return;
    }

    if (!forceRefresh &&
        _lastLoadedUserId == userId &&
        _dashboardData != null &&
        _errorMessage == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardData = await _dashboardService!.fetchDashboardData(
        userId: userId,
        fallbackName: fallbackName,
      );
      _lastLoadedUserId = userId;
    } catch (_) {
      _errorMessage =
          'Unable to load your dashboard right now. Please try again.';
      _dashboardData = StudentDashboardData.empty(
        studentName: fallbackName ?? 'Student',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
