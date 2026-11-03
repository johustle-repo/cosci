/// One-at-a-time unlocking for an ordered list of learning items
/// (lessons, quizzes, or puzzles).
///
/// Only the first unfinished item is available. Every item before it is
/// finished (and stays open for review); every item after it stays locked
/// until the current one is finished.
class SequentialUnlockPolicy {
  const SequentialUnlockPolicy._();

  /// Index of the item the student must finish next, or `finished.length`
  /// when everything is finished.
  static int currentIndex(List<bool> finished) {
    final index = finished.indexOf(false);
    return index == -1 ? finished.length : index;
  }

  /// Whether the item at [index] can be opened.
  static bool isUnlocked(int index, List<bool> finished) {
    if (index < 0 || index >= finished.length) return false;
    return index <= currentIndex(finished);
  }

  /// Ids of every item that can be opened, in the same order as [ids].
  static Set<String> unlockedIds(List<String> ids, List<bool> finished) {
    assert(ids.length == finished.length);
    final current = currentIndex(finished);
    return {for (var i = 0; i < ids.length && i <= current; i++) ids[i]};
  }

  /// A quiz counts as finished once it is passed, or once every attempt has
  /// been used, so a student is never permanently blocked by one quiz.
  static bool isQuizFinished({
    required bool anyAttemptPassed,
    required int attemptsUsed,
    required int attemptLimit,
  }) {
    return anyAttemptPassed ||
        (attemptLimit > 0 && attemptsUsed >= attemptLimit);
  }
}
