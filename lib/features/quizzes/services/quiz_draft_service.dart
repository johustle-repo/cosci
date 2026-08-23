import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuizDraft {
  const QuizDraft({required this.answers, required this.savedAt});

  final Map<String, String> answers;
  final DateTime savedAt;
}

class QuizDraftService {
  static const _keyPrefix = 'quiz_answer_draft_v1';

  static String _key({required String userId, required String quizId}) =>
      '$_keyPrefix:$userId:$quizId';

  static Future<QuizDraft?> load({
    required String userId,
    required String quizId,
  }) async {
    if (userId.isEmpty || quizId.isEmpty) return null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(
        _key(userId: userId, quizId: quizId),
      );
      if (encoded == null) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      final rawAnswers = decoded['answers'];
      final savedAt = DateTime.tryParse(decoded['savedAt']?.toString() ?? '');
      if (rawAnswers is! Map || savedAt == null) return null;
      return QuizDraft(
        answers: rawAnswers.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
        savedAt: savedAt,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> save({
    required String userId,
    required String quizId,
    required Map<String, String> answers,
  }) async {
    if (userId.isEmpty || quizId.isEmpty) return false;
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.setString(
        _key(userId: userId, quizId: quizId),
        jsonEncode({
          'answers': answers,
          'savedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear({
    required String userId,
    required String quizId,
  }) async {
    if (userId.isEmpty || quizId.isEmpty) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_key(userId: userId, quizId: quizId));
    } catch (_) {
      // Optional persistence must never block quiz completion.
    }
  }
}
