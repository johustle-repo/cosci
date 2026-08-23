class CodeSimulationActivity {
  const CodeSimulationActivity({
    required this.id,
    required this.title,
    required this.topic,
    required this.language,
    required this.difficulty,
    required this.starterCode,
    required this.expectedOutput,
    required this.instructions,
    required this.xpReward,
    this.stdin = '',
    this.testCases = const [],
    this.hiddenTestCount = 0,
    this.problemGoal = '',
    this.inputsDescription = '',
    this.algorithmSteps = const [],
    this.keyConcepts = const [],
    this.commonMistakes = '',
    this.hints = const [],
    this.errorFocus = 'Logic',
    this.executionSteps = const [],
    this.version = 1,
  });

  final String id;
  final String title;
  final String topic;
  final String language;
  final String difficulty;
  final String starterCode;
  final String expectedOutput;
  final String instructions;
  final int xpReward;
  final String stdin;
  final List<SimulationTestCase> testCases;
  final int hiddenTestCount;
  final String problemGoal;
  final String inputsDescription;
  final List<String> algorithmSteps;
  final List<String> keyConcepts;
  final String commonMistakes;
  final List<String> hints;
  final String errorFocus;
  final List<ActivityExecutionStep> executionSteps;
  final int version;

  List<SimulationTestCase> get effectiveTestCases => testCases.isNotEmpty
      ? testCases
      : [
          SimulationTestCase(
            name: 'Main test',
            stdin: stdin,
            expectedOutput: expectedOutput,
          ),
        ];

  factory CodeSimulationActivity.fromMap(String id, Map<String, dynamic> map) {
    final title = _readString(map['title'], fallback: 'Code Simulation Task');
    final topic = _readString(map['topic']);
    return CodeSimulationActivity(
      id: id,
      title: title,
      topic: topic,
      language: _readString(map['language'], fallback: 'C++'),
      difficulty: _readString(map['difficulty'], fallback: 'Easy'),
      starterCode: _readString(map['codeSnippet']),
      expectedOutput: _readString(map['expectedOutput']),
      instructions: _readString(
        map['explanation'],
        fallback: topic.isNotEmpty
            ? 'Write code that solves the task for $topic.'
            : 'Write code that produces the expected output.',
      ),
      xpReward: _readInt(map['xpReward']) ?? 10,
      stdin: _readString(map['stdin']),
      testCases: (map['testCases'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SimulationTestCase.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.expectedOutput.trim().isNotEmpty)
          .toList(),
      hiddenTestCount: _readInt(map['hiddenTestCount']) ?? 0,
      problemGoal: _readString(map['problemGoal']),
      inputsDescription: _readString(map['inputsDescription']),
      algorithmSteps: _readStringList(map['algorithmSteps']),
      keyConcepts: _readStringList(map['keyConcepts']),
      commonMistakes: _readString(map['commonMistakes']),
      hints: _readStringList(map['hints']),
      errorFocus: _readString(map['errorFocus'], fallback: 'Logic'),
      executionSteps: (map['executionSteps'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ActivityExecutionStep.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      version: _readInt(map['version']) ?? 1,
    );
  }
}

class ActivityExecutionStep {
  const ActivityExecutionStep({
    required this.number,
    required this.description,
    required this.variableStates,
  });
  final int number;
  final String description;
  final Map<String, String> variableStates;
  factory ActivityExecutionStep.fromMap(Map<String, dynamic> map) =>
      ActivityExecutionStep(
        number: _readInt(map['stepNumber']) ?? 0,
        description: _readString(map['description']),
        variableStates: (map['variableStates'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      );
}

class SimulationTestCase {
  const SimulationTestCase({
    required this.name,
    required this.expectedOutput,
    this.stdin = '',
    this.isHidden = false,
  });

  final String name;
  final String stdin;
  final String expectedOutput;
  final bool isHidden;

  factory SimulationTestCase.fromMap(Map<String, dynamic> map) {
    return SimulationTestCase(
      name: _readString(map['name'], fallback: 'Test case'),
      stdin: _readString(map['stdin']),
      expectedOutput: _readString(map['expectedOutput']),
      isHidden: map['isHidden'] as bool? ?? false,
    );
  }
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

List<String> _readStringList(Object? value) => value is List
    ? value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList()
    : const [];
