/// Decides which lesson languages a student may see based on year level.
///
/// - 1st Year students see only C++ lessons.
/// - 2nd Year students (and any other or unknown year level) see every
///   available language.
class LessonLanguagePolicy {
  const LessonLanguagePolicy._();

  /// True when [yearLevel] represents a first-year student, accepting
  /// variants such as "1st Year", "1st year", "First Year", or "1".
  static bool isFirstYear(String? yearLevel) {
    final value = (yearLevel ?? '').trim().toLowerCase();
    if (value.isEmpty) return false;
    return value == '1' || value.startsWith('1st') || value.startsWith('first');
  }

  /// True when [language] refers to C++, accepting legacy spellings such as
  /// "c++", "cpp", or "C/C++". A missing language defaults to C++, matching
  /// how lessons are read from Firestore.
  static bool isCpp(String? language) {
    final value = (language ?? '').trim().toLowerCase();
    if (value.isEmpty) return true;
    return value.contains('c++') || value == 'cpp' || value == 'c';
  }

  /// Whether a student with [yearLevel] may see a lesson in [language].
  static bool allows({required String? yearLevel, required String? language}) {
    return !isFirstYear(yearLevel) || isCpp(language);
  }
}
