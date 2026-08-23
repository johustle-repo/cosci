import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/puzzle.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PuzzleService {
  PuzzleService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Future<List<Puzzle>> fetchPuzzles() async {
    final snapshot = await _firestoreService.puzzlesCollection().get();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final user = uid == null ? null : await _firestoreService.fetchAppUser(uid);

    final puzzles = snapshot.docs
        .where((doc) => doc.data()['isPublished'] as bool? ?? true)
        .where((doc) => _eligible(doc.data(), user?.program, user?.yearLevel))
        .map((doc) => Puzzle.fromMap(doc.id, doc.data()))
        .toList();

    puzzles.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return puzzles;
  }

  bool _eligible(Map<String, dynamic> data, String? program, String? year) {
    final programs = List<String>.from(
      data['audiencePrograms'] as List? ?? const [],
    );
    final years = List<String>.from(data['yearLevels'] as List? ?? const []);
    return (programs.isEmpty ||
            program == null ||
            programs.contains(program)) &&
        (years.isEmpty || year == null || years.contains(year));
  }

  Future<Map<String, PuzzleProgress>> fetchUserProgress({
    required String userId,
  }) async {
    final snapshot = await _firestoreService
        .userPuzzleProgressCollection(userId)
        .get();

    return {
      for (final doc in snapshot.docs)
        doc.id: PuzzleProgress.fromMap(doc.data()),
    };
  }

  Future<PuzzleSubmissionResult> submitPuzzleAttempt({
    required String userId,
    required Puzzle puzzle,
    required bool isCorrect,
    required int score,
  }) async {
    final progressRef = _firestoreService.userPuzzleProgressDocument(
      userId,
      puzzle.id,
    );
    final globalProgressRef = _firestoreService.progressDocument(userId);

    late PuzzleSubmissionResult result;

    await _firestoreService.instance.runTransaction((transaction) async {
      final progressSnapshot = await transaction.get(progressRef);
      final globalProgressSnapshot = await transaction.get(globalProgressRef);

      final existingData = progressSnapshot.data() ?? <String, dynamic>{};
      final globalProgressData =
          globalProgressSnapshot.data() ?? <String, dynamic>{};

      final attempts = (_readInt(existingData['attempts']) ?? 0) + 1;
      final previousBest = _readInt(existingData['bestScore']) ?? 0;
      final bestScore = score > previousBest ? score : previousBest;
      final wasCompleted = existingData['isCompleted'] as bool? ?? false;
      final firstCompletion = isCorrect && !wasCompleted;

      transaction.set(progressRef, {
        'puzzleId': puzzle.id,
        'title': puzzle.title,
        'type': puzzle.type.firestoreValue,
        'attempts': attempts,
        'bestScore': bestScore,
        'isCompleted': wasCompleted || isCorrect,
        'lastScore': score,
        'updatedAt': FieldValue.serverTimestamp(),
        if (firstCompletion) 'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (firstCompletion) {
        transaction.set(globalProgressRef, {
          'completedPuzzles':
              (_readInt(globalProgressData['completedPuzzles']) ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      result = PuzzleSubmissionResult(
        isCorrect: isCorrect,
        score: score,
        attempts: attempts,
        firstCompletion: firstCompletion,
      );
    });

    return result;
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
