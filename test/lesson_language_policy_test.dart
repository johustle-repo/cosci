import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/services/lesson_language_policy.dart';

void main() {
  group('LessonLanguagePolicy', () {
    test('1st Year students see only C++ lessons', () {
      for (final year in ['1st Year', '1st year', 'First Year', ' 1 ']) {
        expect(
          LessonLanguagePolicy.allows(yearLevel: year, language: 'C++'),
          isTrue,
          reason: year,
        );
        expect(
          LessonLanguagePolicy.allows(yearLevel: year, language: 'Java'),
          isFalse,
          reason: year,
        );
        expect(
          LessonLanguagePolicy.allows(yearLevel: year, language: 'JavaScript'),
          isFalse,
          reason: year,
        );
      }
    });

    test('1st Year accepts legacy C++ spellings and missing language', () {
      for (final language in ['c++', 'cpp', 'C/C++', 'C', '', null]) {
        expect(
          LessonLanguagePolicy.allows(
            yearLevel: '1st Year',
            language: language,
          ),
          isTrue,
          reason: '$language',
        );
      }
    });

    test('2nd Year students see every language', () {
      for (final language in ['C++', 'Java', 'JavaScript']) {
        expect(
          LessonLanguagePolicy.allows(
            yearLevel: '2nd Year',
            language: language,
          ),
          isTrue,
        );
      }
    });

    test('unknown year level is not restricted', () {
      expect(
        LessonLanguagePolicy.allows(yearLevel: null, language: 'Java'),
        isTrue,
      );
      expect(
        LessonLanguagePolicy.allows(yearLevel: '', language: 'JavaScript'),
        isTrue,
      );
    });
  });
}
