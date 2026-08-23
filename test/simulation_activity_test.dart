import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/models/code_simulation_activity.dart';
import 'package:pseudocode_apk/features/admin/models/admin_simulation.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/services/code_simulation_service.dart';

void main() {
  test('legacy simulation becomes one visible test case', () {
    final activity = CodeSimulationActivity.fromMap('legacy', {
      'expectedOutput': 'Hello',
      'stdin': '1',
    });
    expect(activity.effectiveTestCases, hasLength(1));
    expect(activity.effectiveTestCases.single.expectedOutput, 'Hello');
    expect(activity.effectiveTestCases.single.isHidden, isFalse);
  });

  test('reads visible and hidden Firestore test cases', () {
    final activity = CodeSimulationActivity.fromMap('new', {
      'expectedOutput': '2',
      'testCases': [
        {'name': 'Example', 'stdin': '1', 'expectedOutput': '2'},
        {'name': 'Edge', 'stdin': '0', 'expectedOutput': '0', 'isHidden': true},
      ],
    });
    expect(activity.effectiveTestCases, hasLength(2));
    expect(activity.effectiveTestCases.last.isHidden, isTrue);
  });

  test('admin serialization keeps hidden tests out of public documents', () {
    const simulation = AdminSimulation(
      id: 'secure',
      title: 'Secure task',
      topic: 'loops',
      language: 'C++',
      difficulty: 'Easy',
      codeSnippet: 'int main(){}',
      executionSteps: [],
      expectedOutput: '1',
      explanation: 'Task',
      xpReward: 10,
      isPublished: false,
      testCases: [
        SimulationTestCase(name: 'Visible', expectedOutput: '1'),
        SimulationTestCase(
          name: 'Secret edge case',
          expectedOutput: 'SECRET_OUTPUT',
          isHidden: true,
        ),
      ],
    );
    final publicCases = simulation.toPublicMap()['testCases'] as List;
    final privateCases = simulation.toPrivateTestsMap()['testCases'] as List;
    expect(publicCases, hasLength(1));
    expect(privateCases, hasLength(1));
    expect(simulation.toPublicMap()['hiddenTestCount'], 1);
    expect(publicCases.toString(), isNot(contains('SECRET_OUTPUT')));
  });

  test('reads algorithm guidance, hints, and execution trace', () {
    final activity = CodeSimulationActivity.fromMap('guided', {
      'problemGoal': 'Count from one to three.',
      'inputsDescription': 'No input',
      'algorithmSteps': ['Initialize counter', 'Repeat while counter <= 3'],
      'keyConcepts': ['loop', 'counter'],
      'hints': ['Check the initial value', 'Check the loop condition'],
      'errorFocus': 'Logic',
      'executionSteps': [
        {
          'stepNumber': 1,
          'description': 'Initialize',
          'variableStates': {'counter': '1'},
        },
      ],
    });
    expect(activity.algorithmSteps, hasLength(2));
    expect(activity.hints, hasLength(2));
    expect(activity.executionSteps.single.variableStates['counter'], '1');
  });

  test('mastery separates compiler and logic outcomes', () {
    final mastery = SimulationMastery.fromAttempts([
      const SimulationAttemptSummary(
        title: 'A',
        language: 'C++',
        result: 'syntaxError',
        feedback: '',
        createdAt: null,
        topic: 'loops',
        errorCategory: 'syntaxError',
      ),
      const SimulationAttemptSummary(
        title: 'A',
        language: 'C++',
        result: 'passed',
        feedback: '',
        createdAt: null,
        topic: 'loops',
        errorCategory: 'none',
        passedTests: 2,
        totalTests: 2,
      ),
    ]);
    expect(mastery.compilerRate, 50);
    expect(mastery.logicRate, 100);
    expect(mastery.averageAttemptsToPass, 1);
  });
}
