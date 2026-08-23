import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/features/quizzes/services/quiz_draft_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('quiz answer draft is isolated, restored, and cleared', () async {
    expect(
      await QuizDraftService.save(
        userId: 'learner-1',
        quizId: 'quiz-1',
        answers: const {'question-1': 'Option B'},
      ),
      isTrue,
    );

    final draft = await QuizDraftService.load(
      userId: 'learner-1',
      quizId: 'quiz-1',
    );
    expect(draft?.answers, const {'question-1': 'Option B'});
    expect(
      await QuizDraftService.load(userId: 'learner-2', quizId: 'quiz-1'),
      isNull,
    );

    await QuizDraftService.clear(userId: 'learner-1', quizId: 'quiz-1');
    expect(
      await QuizDraftService.load(userId: 'learner-1', quizId: 'quiz-1'),
      isNull,
    );
  });
}
