import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';
import 'package:pseudocode_apk/models/learning_reward.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/services/gamification_service.dart';

class GamificationProvider extends ChangeNotifier {
  GamificationService? _gamificationService;
  AuthProvider? _authProvider;
  GamificationProfile _profile = GamificationProfile.empty();
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusMessage;
  LearningReward? _latestReward;
  String? _lastLoadedUserId;

  GamificationProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  LearningReward? get latestReward => _latestReward;

  void attach({
    required GamificationService gamificationService,
    required AuthProvider authProvider,
  }) {
    _gamificationService = gamificationService;
    _authProvider = authProvider;
  }

  Future<void> loadProfile({bool forceRefresh = false}) async {
    final userId = _authProvider?.currentUser?.uid;
    if (_gamificationService == null || userId == null || _isLoading) {
      return;
    }

    if (!forceRefresh &&
        _lastLoadedUserId == userId &&
        _profile.badges.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _gamificationService!.fetchProfile(userId: userId);
      _lastLoadedUserId = userId;
    } catch (_) {
      _errorMessage =
          'Unable to load gamification progress right now. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LearningReward?> completeSimulationLesson({
    required String lessonId,
    required String title,
  }) {
    return _executeRewardAction(
      action: (userId) =>
          _gamificationService!.recordSimulationLessonCompletion(
            userId: userId,
            lessonId: lessonId,
            title: title,
          ),
      duplicateMessage: 'This simulation lesson was already credited.',
    );
  }

  Future<LearningReward?> completeLesson({
    required String lessonId,
    required String title,
  }) {
    return _executeRewardAction(
      action: (userId) => _gamificationService!.recordLessonCompletion(
        userId: userId,
        lessonId: lessonId,
        title: title,
      ),
      duplicateMessage: 'This lesson was already completed.',
    );
  }

  Future<LearningReward?> completeQuiz({
    required String quizId,
    required String title,
    required int scorePercent,
    int passingScore = 80,
  }) async {
    if (scorePercent < passingScore) {
      _statusMessage =
          'A score of $passingScore% or higher is required to earn quiz XP and badges.';
      notifyListeners();
      return null;
    }

    return _executeRewardAction(
      action: (userId) => _gamificationService!.recordQuizCompletion(
        userId: userId,
        quizId: quizId,
        title: title,
        scorePercent: scorePercent,
      ),
      duplicateMessage: 'This quiz high-score reward has already been claimed.',
    );
  }

  Future<LearningReward?> completePuzzle({
    required String puzzleId,
    required String title,
  }) {
    return _executeRewardAction(
      action: (userId) => _gamificationService!.recordPuzzleCompletion(
        userId: userId,
        puzzleId: puzzleId,
        title: title,
      ),
      duplicateMessage: 'This puzzle completion was already rewarded.',
    );
  }

  Future<LearningReward?> completeDailyChallenge({
    required String challengeId,
    required String title,
    int xpAwarded = 15,
  }) {
    return _executeRewardAction(
      action: (userId) => _gamificationService!.recordDailyChallengeCompletion(
        userId: userId,
        challengeId: challengeId,
        title: title,
        xpAwarded: xpAwarded,
      ),
      duplicateMessage: 'Today\'s challenge reward has already been claimed.',
    );
  }

  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  void clearLatestReward() {
    if (_latestReward == null) {
      return;
    }

    _latestReward = null;
    notifyListeners();
  }

  Future<LearningReward?> _executeRewardAction({
    required Future<LearningReward?> Function(String userId) action,
    required String duplicateMessage,
  }) async {
    final userId = _authProvider?.currentUser?.uid;
    if (_gamificationService == null || userId == null || _isSubmitting) {
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      final reward = await action(userId);
      if (reward == null) {
        _statusMessage = duplicateMessage;
        return null;
      }

      _latestReward = reward;
      _statusMessage = reward.message;
      _profile = await _gamificationService!.fetchProfile(userId: userId);
      _lastLoadedUserId = userId;
      return reward;
    } on FirebaseException catch (error) {
      _errorMessage = switch (error.code) {
        'permission-denied' =>
          'Your progress could not be saved because access was denied. Please sign in again or ask the administrator to deploy the latest Firestore rules.',
        'unavailable' =>
          'Your progress service is temporarily unavailable. Check your connection and try again.',
        'aborted' =>
          'Your progress changed on another device. Please press Done Reading again.',
        _ =>
          'Your lesson progress could not be saved (${error.code}). Please try again.',
      };
      debugPrint(
        'Gamification action failed: ${error.code} ${error.message ?? ''}',
      );
      return null;
    } catch (error, stackTrace) {
      _errorMessage =
          'Your lesson progress could not be saved. Please try again.';
      debugPrint('Gamification action failed: $error\n$stackTrace');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
