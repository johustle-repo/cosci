import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/learning_reward.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';
import 'package:pseudocode_apk/services/puzzle_service.dart';

class PuzzlesProvider extends ChangeNotifier {
  PuzzleService? _puzzleService;
  AuthProvider? _authProvider;
  GamificationProvider? _gamificationProvider;
  List<Puzzle> _puzzles = const [];
  Map<String, PuzzleProgress> _progressByPuzzleId = const {};
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusMessage;
  LearningReward? _latestReward;

  List<Puzzle> get puzzles => _puzzles;
  Map<String, PuzzleProgress> get progressByPuzzleId => _progressByPuzzleId;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  LearningReward? get latestReward => _latestReward;

  void attach({
    required PuzzleService puzzleService,
    required AuthProvider authProvider,
    required GamificationProvider gamificationProvider,
  }) {
    _puzzleService = puzzleService;
    _authProvider = authProvider;
    _gamificationProvider = gamificationProvider;
  }

  PuzzleProgress progressFor(String puzzleId) {
    return _progressByPuzzleId[puzzleId] ?? PuzzleProgress.empty;
  }

  Future<void> loadPuzzles({bool forceRefresh = false}) async {
    final userId = _authProvider?.currentUser?.uid;
    if (_puzzleService == null || _isLoading) {
      return;
    }

    if (!forceRefresh && _puzzles.isNotEmpty && _errorMessage == null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _puzzles = await _puzzleService!.fetchPuzzles();
      if (userId != null) {
        _progressByPuzzleId = await _puzzleService!.fetchUserProgress(
          userId: userId,
        );
      }
    } catch (_) {
      _errorMessage = 'Unable to load puzzles right now. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PuzzleSubmissionResult?> submitCodeFlowAttempt({
    required Puzzle puzzle,
    required List<String> currentOrder,
  }) {
    final correctOrder = puzzle.codeFlowData?.correctOrder ?? const <String>[];
    final isCorrect = listEquals(currentOrder, correctOrder);
    final score = isCorrect
        ? 100
        : _calculateSequenceScore(currentOrder, correctOrder);
    return _submitAttempt(puzzle: puzzle, isCorrect: isCorrect, score: score);
  }

  Future<PuzzleSubmissionResult?> submitOutputPredictionAttempt({
    required Puzzle puzzle,
    required String selectedOptionId,
  }) {
    final isCorrect =
        selectedOptionId == puzzle.outputPredictionData?.correctOptionId;
    return _submitAttempt(
      puzzle: puzzle,
      isCorrect: isCorrect,
      score: isCorrect ? 100 : 0,
    );
  }

  Future<PuzzleSubmissionResult?> submitDebugBugAttempt({
    required Puzzle puzzle,
    required int selectedLineIndex,
    required String selectedIssueId,
  }) {
    final debugData = puzzle.debugBugData;
    final isCorrect =
        selectedLineIndex == debugData?.bugLineIndex &&
        selectedIssueId == debugData?.correctIssueId;
    return _submitAttempt(
      puzzle: puzzle,
      isCorrect: isCorrect,
      score: isCorrect ? 100 : 0,
    );
  }

  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  void clearLatestReward() {
    _latestReward = null;
    notifyListeners();
  }

  Future<PuzzleSubmissionResult?> _submitAttempt({
    required Puzzle puzzle,
    required bool isCorrect,
    required int score,
  }) async {
    final userId = _authProvider?.currentUser?.uid;
    if (_puzzleService == null || userId == null || _isSubmitting) {
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final result = await _puzzleService!.submitPuzzleAttempt(
        userId: userId,
        puzzle: puzzle,
        isCorrect: isCorrect,
        score: score,
      );

      _progressByPuzzleId = {
        ..._progressByPuzzleId,
        puzzle.id: PuzzleProgress(
          attempts: result.attempts,
          bestScore: score > progressFor(puzzle.id).bestScore
              ? score
              : progressFor(puzzle.id).bestScore,
          isCompleted: progressFor(puzzle.id).isCompleted || result.isCorrect,
          completedAt: result.firstCompletion
              ? DateTime.now()
              : progressFor(puzzle.id).completedAt,
        ),
      };

      if (result.firstCompletion &&
          result.isCorrect &&
          _gamificationProvider != null) {
        _latestReward = await _gamificationProvider!.completePuzzle(
          puzzleId: puzzle.id,
          title: puzzle.title,
        );
      } else {
        _latestReward = null;
      }

      _statusMessage = result.isCorrect
          ? 'Correct. Score: ${result.score}%'
          : 'Not quite yet. Score: ${result.score}%';
      return result;
    } catch (_) {
      _errorMessage = 'Unable to save puzzle progress right now.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  int _calculateSequenceScore(List<String> current, List<String> correct) {
    if (current.isEmpty || correct.isEmpty) {
      return 0;
    }

    final matches = current.asMap().entries.where((entry) {
      return entry.key < correct.length && entry.value == correct[entry.key];
    }).length;

    return ((matches / correct.length) * 100).round();
  }
}
