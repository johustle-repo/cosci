/// Programming-language "tracks" used to group lessons, quizzes, and puzzles.
///
/// Content documents store the language as free text ("C++", "cpp", "java",
/// "JavaScript", ...). Every screen groups, filters, and tracks progress by the
/// normalized label returned by [normalize], so legacy spellings land in the
/// same track.
class LanguageTracks {
  const LanguageTracks._();

  static const cpp = 'C++';
  static const java = 'Java';
  static const javascript = 'JavaScript';

  /// Display order for the known tracks. Unknown languages follow
  /// alphabetically.
  static const ordered = [cpp, java, javascript];

  /// Maps a stored language string to its track label. A missing language
  /// defaults to C++, matching how content is read from Firestore.
  static String normalize(String? raw) {
    final value = (raw ?? '').trim();
    final lower = value.toLowerCase();
    if (lower.isEmpty ||
        lower.contains('c++') ||
        lower == 'cpp' ||
        lower == 'c') {
      return cpp;
    }
    if (lower == 'js' || lower.contains('javascript')) return javascript;
    if (lower.contains('java')) return java;
    return value;
  }

  /// Distinct track labels for [languages], in display order.
  static List<String> available(Iterable<String> languages) {
    final tracks = languages.map(normalize).toSet().toList()
      ..sort((a, b) {
        final ia = ordered.indexOf(a);
        final ib = ordered.indexOf(b);
        if (ia != -1 && ib != -1) return ia.compareTo(ib);
        if (ia != -1) return -1;
        if (ib != -1) return 1;
        return a.compareTo(b);
      });
    return tracks;
  }

  /// Whether [language] passes a filter of [selected] tracks. An empty
  /// selection means "all languages".
  static bool matches(Set<String> selected, String? language) =>
      selected.isEmpty || selected.contains(normalize(language));
}
