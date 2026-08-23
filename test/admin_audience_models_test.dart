import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/features/admin/models/admin_lesson.dart';
import 'package:pseudocode_apk/features/admin/models/admin_puzzle.dart';
import 'package:pseudocode_apk/features/admin/models/admin_quiz.dart';

void main() {
  const programs = ['BS Computer Science'];
  const years = ['1st Year'];

  test('lesson audience survives Firestore conversion', () {
    final model = AdminLesson.fromMap('1', {
      'audiencePrograms': programs,
      'yearLevels': years,
    });
    expect(model.toMap()['audiencePrograms'], programs);
    expect(model.toMap()['yearLevels'], years);
  });

  test('structured lesson and compiler evidence survive conversion', () {
    final model = AdminLesson.fromMap('lesson-1', {
      'estimatedMinutes': 20,
      'learningObjective': 'Trace a loop and explain its output.',
      'keyConcepts': ['loop', 'condition'],
      'prerequisites': ['variables'],
      'introduction': 'Loops repeat a controlled task.',
      'workedExample': 'Trace i from 0 to 2.',
      'commonMistakes': 'Using the wrong boundary condition.',
      'summary': 'Check initialization, condition, and update.',
      'errorFocus': 'Syntax and Logic',
      'sourceCode': 'console.log(3);',
      'expectedOutput': '3',
      'algorithmSteps': ['Initialize', 'Check', 'Update'],
      'pseudocode': 'REPEAT until done',
      'compilerValidated': true,
    });

    final map = model.toMap();
    expect(map['estimatedMinutes'], 20);
    expect(map['learningObjective'], contains('Trace'));
    expect(map['algorithmSteps'], hasLength(3));
    expect(map['errorFocus'], 'Syntax and Logic');
    expect(map['compilerValidated'], isTrue);
    expect(
      model.isReadyToPublish,
      isFalse,
      reason: 'Audience targeting is still required',
    );
  });

  test('lesson readiness requires audience, structure, and valid practice', () {
    final lesson = AdminLesson.fromMap('ready', {
      'title': 'Tracing Loops',
      'description': 'A guided lesson.',
      'audiencePrograms': programs,
      'yearLevels': years,
      'learningObjective': 'Trace a loop.',
      'keyConcepts': ['loop'],
      'algorithmSteps': ['Initialize', 'Check', 'Update'],
      'sourceCode': 'console.log(3);',
      'compilerValidated': true,
    });
    expect(lesson.isReadyToPublish, isTrue);
    expect(lesson.readinessPercent, 100);
  });

  test('quiz and puzzle audience survive Firestore conversion', () {
    final quiz = AdminQuiz.fromMap('1', {
      'audiencePrograms': programs,
      'yearLevels': years,
    });
    final puzzle = AdminPuzzle.fromMap('1', {
      'audiencePrograms': programs,
      'yearLevels': years,
    });
    expect(quiz.audiencePrograms, programs);
    expect(puzzle.yearLevels, years);
  });
}
