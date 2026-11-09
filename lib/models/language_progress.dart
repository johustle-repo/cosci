import 'package:pseudocode_apk/services/language_tracks.dart';

/// Completed / total counts for one kind of content.
class CompletionCount {
  const CompletionCount(this.completed, this.total);

  final int completed;
  final int total;

  double get ratio => total == 0 ? 0 : completed / total;
  int get percent => (ratio * 100).round();

  CompletionCount operator +(CompletionCount other) =>
      CompletionCount(completed + other.completed, total + other.total);
}

/// Progress of one programming-language track (or of all tracks combined).
class LanguageProgress {
  const LanguageProgress({
    required this.language,
    required this.lessons,
    required this.quizzes,
    required this.puzzles,
  });

  final String language;
  final CompletionCount lessons;
  final CompletionCount quizzes;
  final CompletionCount puzzles;

  /// Every lesson, quiz, and puzzle counts as one item.
  CompletionCount get overall => lessons + quizzes + puzzles;
}

/// One content item reduced to what progress tracking needs.
typedef TrackedItem = ({String language, bool completed});

class LanguageProgressReport {
  const LanguageProgressReport({
    required this.languages,
    required this.overall,
  });

  /// One entry per language track that has content, in display order.
  final List<LanguageProgress> languages;

  /// All languages combined.
  final LanguageProgress overall;

  bool get isEmpty => overall.overall.total == 0;

  factory LanguageProgressReport.build({
    required List<TrackedItem> lessons,
    required List<TrackedItem> quizzes,
    required List<TrackedItem> puzzles,
  }) {
    CompletionCount count(List<TrackedItem> items, String? language) {
      final scoped = language == null
          ? items
          : items.where(
              (i) => LanguageTracks.normalize(i.language) == language,
            );
      return CompletionCount(
        scoped.where((i) => i.completed).length,
        scoped.length,
      );
    }

    final tracks = LanguageTracks.available([
      for (final item in [...lessons, ...quizzes, ...puzzles]) item.language,
    ]);

    return LanguageProgressReport(
      languages: [
        for (final language in tracks)
          LanguageProgress(
            language: language,
            lessons: count(lessons, language),
            quizzes: count(quizzes, language),
            puzzles: count(puzzles, language),
          ),
      ],
      overall: LanguageProgress(
        language: 'Overall',
        lessons: count(lessons, null),
        quizzes: count(quizzes, null),
        puzzles: count(puzzles, null),
      ),
    );
  }
}
