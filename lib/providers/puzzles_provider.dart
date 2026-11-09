import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/learning_reward.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';
import 'package:pseudocode_apk/services/language_tracks.dart';
import 'package:pseudocode_apk/services/puzzle_service.dart';
import 'package:pseudocode_apk/services/sequential_unlock_policy.dart';

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

  // Puzzles unlock one at a time in list order *within each programming
  // language*, so puzzles in different languages can be solved side by side.
  List<bool> get _finished =>
      _puzzles.map((puzzle) => progressFor(puzzle.id).isCompleted).toList();

  List<String> get _tracks => _puzzles
      .map((puzzle) => LanguageTracks.normalize(puzzle.language))
      .toList();

  /// Language tracks that have at least one puzzle, in display order.
  List<String> get languages =>
      LanguageTracks.available(_puzzles.map((puzzle) => puzzle.language));

  Set<String> get unlockedPuzzleIds =>
      SequentialUnlockPolicy.unlockedIdsByTrack(
        _puzzles.map((puzzle) => puzzle.id).toList(),
        _tracks,
        _finished,
      );

  bool isUnlocked(String puzzleId) => unlockedPuzzleIds.contains(puzzleId);

  /// The puzzle the student must solve next in [language], or null when that
  /// language track is solved.
  Puzzle? currentPuzzleFor(String language) {
    final index = SequentialUnlockPolicy.currentIndexInTrack(
      LanguageTracks.normalize(language),
      _tracks,
      _finished,
    );
    return index == null ? null : _puzzles[index];
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
    return _submitAttempt(
      puzzle: puzzle,
      isCorrect: isCorrect,
      score: score,
      mistake: isCorrect ? null : codeFlowMistake(currentOrder, correctOrder),
    );
  }

  Future<PuzzleSubmissionResult?> submitOutputPredictionAttempt({
    required Puzzle puzzle,
    required String selectedOptionId,
  }) {
    final data = puzzle.outputPredictionData;
    final isCorrect = selectedOptionId == data?.correctOptionId;
    final chosen = data?.options
        .where((option) => option.id == selectedOptionId)
        .map((option) => option.text)
        .firstOrNull;
    return _submitAttempt(
      puzzle: puzzle,
      isCorrect: isCorrect,
      score: isCorrect ? 100 : 0,
      mistake: isCorrect
          ? null
          : '${chosen == null ? 'Your prediction' : 'Your prediction "$chosen"'} '
                'is not what this code prints. Trace it line by line and write '
                'down each variable\'s value after every step.',
    );
  }

  Future<PuzzleSubmissionResult?> submitDebugBugAttempt({
    required Puzzle puzzle,
    required int selectedLineIndex,
    required String selectedIssueId,
  }) {
    final debugData = puzzle.debugBugData;
    final lineRight = selectedLineIndex == debugData?.bugLineIndex;
    final issueRight = selectedIssueId == debugData?.correctIssueId;
    final isCorrect = lineRight && issueRight;
    final lineLabel = 'line ${selectedLineIndex + 1}';
    final hint = debugData?.explanationHint;
    return _submitAttempt(
      puzzle: puzzle,
      isCorrect: isCorrect,
      score: isCorrect ? 100 : 0,
      mistake: isCorrect
          ? null
          : [
              if (lineRight && !issueRight)
                'You found the right line ($lineLabel), but the issue type '
                    'you chose is wrong. Look again at what that line does.'
              else if (!lineRight && issueRight)
                'The issue type is right, but the bug is not on $lineLabel. '
                    'Check the other lines for that kind of mistake.'
              else
                'Neither the line nor the issue type is correct. The bug is '
                    'not on $lineLabel.',
              if (hint != null && hint.trim().isNotEmpty) 'Hint: $hint',
            ].join(' '),
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
    String? mistake,
  }) async {
    final userId = _authProvider?.currentUser?.uid;
    if (_puzzleService == null || userId == null || _isSubmitting) {
      return null;
    }

    // A solved puzzle accepts no further attempts.
    if (progressFor(puzzle.id).isCompleted) {
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
          : 'Not quite yet. Score: ${result.score}%. ${mistake ?? ''}'.trim();
      return result;
    } catch (_) {
      _errorMessage = 'Unable to save puzzle progress right now.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Tells the student which of their lines are out of place without
  /// revealing the full correct order.
  @visibleForTesting
  static String codeFlowMistake(List<String> current, List<String> correct) {
    final wrong = <int>[
      for (var i = 0; i < current.length; i++)
        if (i >= correct.length || current[i] != correct[i]) i + 1,
    ];
    if (wrong.isEmpty) {
      return 'The sequence is incomplete. Place every line.';
    }
    final placed = current.length - wrong.length;
    final positions = wrong.length == 1
        ? 'position ${wrong.first}'
        : 'positions ${wrong.take(wrong.length - 1).join(', ')} and ${wrong.last}';
    return '$placed of ${correct.length} lines are in the right place. '
        'The line${wrong.length == 1 ? '' : 's'} at $positions '
        '${wrong.length == 1 ? 'is' : 'are'} out of order.';
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
