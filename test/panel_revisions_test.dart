import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/models/language_progress.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/services/error_diagnosis.dart';
import 'package:pseudocode_apk/services/language_tracks.dart';
import 'package:pseudocode_apk/services/sequential_unlock_policy.dart';

void main() {
  group('LanguageTracks', () {
    test('normalizes legacy spellings', () {
      expect(LanguageTracks.normalize('cpp'), 'C++');
      expect(LanguageTracks.normalize(''), 'C++');
      expect(LanguageTracks.normalize('java'), 'Java');
      expect(LanguageTracks.normalize('Javascript'), 'JavaScript');
      expect(LanguageTracks.normalize('js'), 'JavaScript');
    });

    test('lists tracks in display order', () {
      expect(LanguageTracks.available(['java', 'JavaScript', 'c++', 'Java']), [
        'C++',
        'Java',
        'JavaScript',
      ]);
    });

    test('empty selection matches everything', () {
      expect(LanguageTracks.matches({}, 'Java'), isTrue);
      expect(LanguageTracks.matches({'C++'}, 'Java'), isFalse);
      expect(LanguageTracks.matches({'C++', 'Java'}, 'java'), isTrue);
    });
  });

  group('Per-language sequential unlocking', () {
    const ids = ['c1', 'j1', 'c2', 'j2', 'c3'];
    const tracks = ['C++', 'Java', 'C++', 'Java', 'C++'];

    test('the first item of every language is open at the start', () {
      expect(
        SequentialUnlockPolicy.unlockedIdsByTrack(
          ids,
          tracks,
          List.filled(5, false),
        ),
        {'c1', 'j1'},
      );
    });

    test('finishing a C++ item does not affect the Java track', () {
      final finished = [true, false, false, false, false];
      expect(SequentialUnlockPolicy.unlockedIdsByTrack(ids, tracks, finished), {
        'c1',
        'j1',
        'c2',
      });
      expect(
        SequentialUnlockPolicy.currentIndexInTrack('C++', tracks, finished),
        2,
      );
      expect(
        SequentialUnlockPolicy.currentIndexInTrack('Java', tracks, finished),
        1,
      );
    });

    test('a finished track has no current item', () {
      final finished = [false, true, false, true, false];
      expect(
        SequentialUnlockPolicy.currentIndexInTrack('Java', tracks, finished),
        isNull,
      );
    });
  });

  group('LanguageProgressReport', () {
    test('computes per-language and overall percentages', () {
      final report = LanguageProgressReport.build(
        lessons: [
          (language: 'C++', completed: true),
          (language: 'C++', completed: false),
          (language: 'Java', completed: true),
        ],
        quizzes: [(language: 'cpp', completed: true)],
        puzzles: [(language: 'Java', completed: false)],
      );
      expect(report.languages.map((l) => l.language), ['C++', 'Java']);
      final cpp = report.languages.first;
      expect(cpp.lessons.percent, 50);
      expect(cpp.quizzes.percent, 100);
      expect(cpp.overall.completed, 2);
      expect(cpp.overall.total, 3);
      expect(cpp.overall.percent, 67);
      expect(report.overall.overall.completed, 3);
      expect(report.overall.overall.total, 5);
      expect(report.overall.overall.percent, 60);
    });
  });

  group('Lesson objectives', () {
    Lesson lesson(String objective) => Lesson(
      id: 'l1',
      title: 'Loops',
      description: 'About loops.',
      language: 'C++',
      estimatedMinutes: 30,
      sortOrder: 1,
      topic: 'For loops',
      learningObjective: objective,
    );

    test('splits objectives written one per line or as bullets', () {
      expect(
        lesson(
          'By the end of this lesson, learners can:\n- Explain loops\n2. Trace a loop',
        ).objectives,
        ['Explain loops', 'Trace a loop'],
      );
      expect(lesson('Explain loops; Write a loop').objectives, [
        'Explain loops',
        'Write a loop',
      ]);
    });

    test('derives objectives when none are stored', () {
      final objectives = lesson('').objectives;
      expect(objectives, isNotEmpty);
      expect(objectives.first, contains('For loops'));
      expect(lesson('').hasAuthoredObjectives, isFalse);
    });

    test('overview falls back to the description', () {
      expect(lesson('x').overviewText, 'About loops.');
    });
  });

  group('ErrorDiagnoser', () {
    test('names a missing semicolon in C++ and quotes the student line', () {
      final d = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.cpp,
        sourceCode:
            '#include <iostream>\nint main() {\n  int x = 5\n  return 0;\n}',
        diagnostic:
            "main.cpp:3:12: error: expected ',' or ';' before 'return'\n",
        compileFailed: true,
      );
      expect(d.title, 'Unexpected symbol');
      expect(d.line, 3);
      expect(d.codeLine, '  int x = 5');

      final semi = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.cpp,
        sourceCode: 'int main() {\n  int x = 5\n}',
        diagnostic: "main.cpp:2:12: error: expected ‘;’ at end of declaration",
        compileFailed: true,
      );
      expect(semi.title, contains('semicolon'));
      expect(semi.kind, ErrorKind.syntax);
    });

    test('names an undeclared C++ variable', () {
      final d = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.cpp,
        sourceCode: 'int main() {\n  total = 1;\n}',
        diagnostic:
            "main.cpp:2:3: error: ‘total’ was not declared in this scope",
        compileFailed: true,
      );
      expect(d.title, "Undeclared variable or function 'total'");
    });

    test('explains a C++ crash from its signal', () {
      final d = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.cpp,
        sourceCode: 'int main() { int a = 1 / 0; }',
        diagnostic: 'Program terminated by SIGFPE (exit code 1).',
        compileFailed: false,
      );
      expect(d.title, 'Division by zero');
      expect(d.kind, ErrorKind.runtime);
    });

    test('reads Java runtime exceptions and stack-trace line numbers', () {
      final d = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.java,
        sourceCode:
            'public class Main {\n  public static void main(String[] a) {\n    int[] n = new int[3];\n    n[3] = 1;\n  }\n}',
        diagnostic:
            'Exception in thread "main" java.lang.ArrayIndexOutOfBoundsException: Index 3 out of bounds for length 3\n\tat Main.main(Main.java:4)',
        compileFailed: false,
      );
      expect(d.title, 'Array index out of bounds');
      expect(d.explanation, contains('index 3'));
      expect(d.line, 4);
      expect(d.codeLine, '    n[3] = 1;');
    });

    test('reads javac line numbers', () {
      final d = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.java,
        sourceCode: 'public class Main {\n  int x = 1\n}',
        diagnostic:
            "Main.java:2: error: ';' expected\n  int x = 1\n           ^",
        compileFailed: true,
      );
      expect(d.title, contains('semicolon'));
      expect(d.line, 2);
    });

    test('flags JavaScript syntax errors as syntax errors', () {
      final d = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.javascript,
        sourceCode: 'console.log("hi"',
        diagnostic:
            '/tmp/main.js:1\nconsole.log("hi"\n\nSyntaxError: missing ) after argument list',
        compileFailed: false,
      );
      expect(d.kind, ErrorKind.syntax);
      expect(d.line, 1);
    });

    test('JavaScript reference errors name the variable', () {
      final d = ErrorDiagnoser.diagnose(
        language: ProgrammingLanguage.javascript,
        sourceCode: 'console.log(totl);',
        diagnostic:
            'ReferenceError: totl is not defined\n    at Object.<anonymous> (/tmp/main.js:1:13)',
        compileFailed: false,
      );
      expect(d.title, "Undefined variable 'totl'");
      expect(d.line, 1);
      expect(d.column, 13);
    });
  });

  group('Puzzle feedback', () {
    test('code-flow feedback names misplaced positions without the answer', () {
      final message = PuzzlesProvider.codeFlowMistake(
        ['a', 'c', 'b', 'd'],
        ['a', 'b', 'c', 'd'],
      );
      expect(message, contains('2 of 4'));
      expect(message, contains('positions 2 and 3'));
    });
  });
}
