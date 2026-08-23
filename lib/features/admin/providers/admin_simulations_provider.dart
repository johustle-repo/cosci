import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_simulation.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminSimulationsProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminSimulation> _simulations = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String? _accessWarning;
  bool _hasLoaded = false;

  List<AdminSimulation> get simulations => _simulations;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String? get accessWarning => _accessWarning;

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadSimulations({bool forceRefresh = false}) async {
    if (_service == null || _isLoading || (!forceRefresh && _hasLoaded)) return;
    _isLoading = true;
    _error = null;
    _accessWarning = null;
    _notifySafely();
    try {
      _simulations = await _service!.fetchSimulations();
      _hasLoaded = true;
      if (!_service!.privateSimulationTestsAvailable) {
        _accessWarning =
            'Public simulations loaded, but hidden test cases are unavailable. Deploy the current Firestore rules and verify this account has the admin role before editing or publishing simulations.';
      }
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<bool> createSimulation(AdminSimulation sim) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      if (sim.isPublished && !sim.isReadyToPublish) {
        throw StateError(
          'Complete: ${sim.readinessIssues.join(', ')} before publishing.',
        );
      }
      await _service!.createSimulation(sim);
      await _logger?.logCreate(
        'simulations',
        'Created simulation: ${sim.title}',
      );
      await loadSimulations(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updateSimulation(AdminSimulation sim) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      if (sim.isPublished && !sim.isReadyToPublish) {
        throw StateError(
          'Complete: ${sim.readinessIssues.join(', ')} before publishing.',
        );
      }
      await _service!.updateSimulation(sim);
      await _logger?.logUpdate(
        'simulations',
        'Updated simulation: ${sim.title}',
        id: sim.id,
      );
      await loadSimulations(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deleteSimulation(String id, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deleteSimulation(id);
      await _logger?.logDelete(
        'simulations',
        'Deleted simulation: $title',
        id: id,
      );
      _simulations.removeWhere((s) => s.id == id);
      _notifySafely();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  Future<void> togglePublished(String id, bool isPublished) async {
    if (_service == null) return;
    try {
      final simulation = _simulations
          .where((item) => item.id == id)
          .firstOrNull;
      if (isPublished && (simulation == null || !simulation.isReadyToPublish)) {
        throw StateError(
          'Complete: ${simulation?.readinessIssues.join(', ') ?? 'simulation details'} before publishing.',
        );
      }
      await _service!.toggleSimulationPublished(id, isPublished);
      final idx = _simulations.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _simulations[idx] = _simulations[idx].copyWith(
          isPublished: isPublished,
        );
        _notifySafely();
      }
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
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
