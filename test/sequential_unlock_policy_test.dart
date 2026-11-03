import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/services/sequential_unlock_policy.dart';

void main() {
  group('SequentialUnlockPolicy', () {
    const ids = ['a', 'b', 'c', 'd'];

    test('only the first item is unlocked at the start', () {
      final finished = [false, false, false, false];
      expect(SequentialUnlockPolicy.currentIndex(finished), 0);
      expect(SequentialUnlockPolicy.unlockedIds(ids, finished), {'a'});
    });

    test('finishing an item unlocks exactly the next one', () {
      final finished = [true, false, false, false];
      expect(SequentialUnlockPolicy.unlockedIds(ids, finished), {'a', 'b'});
      expect(SequentialUnlockPolicy.isUnlocked(2, finished), isFalse);
    });

    test('a later finished item does not skip an unfinished earlier one', () {
      // e.g. content reordered by an admin after the student finished "c".
      final finished = [true, false, true, false];
      expect(SequentialUnlockPolicy.currentIndex(finished), 1);
      expect(SequentialUnlockPolicy.unlockedIds(ids, finished), {'a', 'b'});
    });

    test('everything is unlocked when all items are finished', () {
      final finished = [true, true, true, true];
      expect(SequentialUnlockPolicy.currentIndex(finished), 4);
      expect(SequentialUnlockPolicy.unlockedIds(ids, finished), ids.toSet());
    });

    test('empty list unlocks nothing', () {
      expect(SequentialUnlockPolicy.unlockedIds(const [], const []), isEmpty);
      expect(SequentialUnlockPolicy.isUnlocked(0, const []), isFalse);
    });

    test('quiz is finished when passed or when attempts run out', () {
      expect(
        SequentialUnlockPolicy.isQuizFinished(
          anyAttemptPassed: true,
          attemptsUsed: 1,
          attemptLimit: 3,
        ),
        isTrue,
      );
      expect(
        SequentialUnlockPolicy.isQuizFinished(
          anyAttemptPassed: false,
          attemptsUsed: 2,
          attemptLimit: 3,
        ),
        isFalse,
      );
      expect(
        SequentialUnlockPolicy.isQuizFinished(
          anyAttemptPassed: false,
          attemptsUsed: 3,
          attemptLimit: 3,
        ),
        isTrue,
      );
      expect(
        SequentialUnlockPolicy.isQuizFinished(
          anyAttemptPassed: false,
          attemptsUsed: 0,
          attemptLimit: 3,
        ),
        isFalse,
      );
    });
  });
}
