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

  /// Per-track unlocking: items are split into independent tracks (one per
  /// programming language) and the one-at-a-time rule applies inside each
  /// track, so a student can progress in several languages at the same time.
  /// [tracks] holds the track label of each item, aligned with [ids].
  static Set<String> unlockedIdsByTrack(
    List<String> ids,
    List<String> tracks,
    List<bool> finished,
  ) {
    assert(ids.length == tracks.length && ids.length == finished.length);
    final blocked = <String>{};
    final unlocked = <String>{};
    for (var i = 0; i < ids.length; i++) {
      final track = tracks[i];
      if (blocked.contains(track)) continue;
      unlocked.add(ids[i]);
      if (!finished[i]) blocked.add(track);
    }
    return unlocked;
  }

  /// Index of the item the student must finish next inside [track], or null
  /// when that track is complete (or has no items).
  static int? currentIndexInTrack(
    String track,
    List<String> tracks,
    List<bool> finished,
  ) {
    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i] == track && !finished[i]) return i;
    }
    return null;
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
