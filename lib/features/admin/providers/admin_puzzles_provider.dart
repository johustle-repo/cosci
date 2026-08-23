import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_puzzle.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';

class AdminPuzzlesProvider extends ChangeNotifier {
  AdminFirestoreService? _service;
  AdminLogService? _logger;

  List<AdminPuzzle> _puzzles = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _hasLoaded = false;

  List<AdminPuzzle> get puzzles => _puzzles;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  void attach(AdminFirestoreService service, AdminLogService logger) {
    if (identical(_service, service)) return;
    _service = service;
    _logger = logger;
  }

  Future<void> loadPuzzles({bool forceRefresh = false}) async {
    if (_service == null || _isLoading || (!forceRefresh && _hasLoaded)) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _puzzles = await _service!.fetchPuzzles();
      _hasLoaded = true;
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<bool> createPuzzle(AdminPuzzle puzzle) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.createPuzzle(puzzle);
      await _logger?.logCreate('puzzles', 'Created puzzle: ${puzzle.title}');
      await loadPuzzles(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> updatePuzzle(AdminPuzzle puzzle) async {
    if (_service == null) return false;
    _isSaving = true;
    _notifySafely();
    try {
      await _service!.updatePuzzle(puzzle);
      await _logger?.logUpdate(
        'puzzles',
        'Updated puzzle: ${puzzle.title}',
        id: puzzle.id,
      );
      await loadPuzzles(forceRefresh: true);
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      return false;
    } finally {
      _isSaving = false;
      _notifySafely();
    }
  }

  Future<bool> deletePuzzle(String id, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deletePuzzle(id);
      await _logger?.logDelete('puzzles', 'Deleted puzzle: $title', id: id);
      _puzzles.removeWhere((p) => p.id == id);
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
      final puzzle = _puzzles.where((item) => item.id == id).firstOrNull;
      if (isPublished && (puzzle == null || !puzzle.isReadyToPublish)) {
        throw StateError(
          'Cannot publish yet. Complete: ${puzzle?.readinessIssues.join(', ') ?? 'puzzle details'}.',
        );
      }
      await _service!.togglePuzzlePublished(id, isPublished);
      final idx = _puzzles.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _puzzles[idx] = _puzzles[idx].copyWith(isPublished: isPublished);
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
