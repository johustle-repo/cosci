import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/code_simulation_activity.dart';

class SimulationStep {
  const SimulationStep({
    required this.stepNumber,
    required this.description,
    required this.variableStates,
  });

  final int stepNumber;
  final String description;
  final Map<String, String> variableStates;

  factory SimulationStep.fromMap(Map<String, dynamic> map) {
    final rawStates = map['variableStates'];
    final states = rawStates is Map
        ? Map<String, String>.from(
            rawStates.map((k, v) => MapEntry(k.toString(), v.toString())),
          )
        : <String, String>{};
    return SimulationStep(
      stepNumber: (map['stepNumber'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
      variableStates: states,
    );
  }

  Map<String, dynamic> toMap() => {
    'stepNumber': stepNumber,
    'description': description,
    'variableStates': variableStates,
  };
}

class AdminSimulation {
  const AdminSimulation({
    required this.id,
    required this.title,
    required this.topic,
    required this.language,
    required this.difficulty,
    required this.codeSnippet,
    required this.executionSteps,
    required this.expectedOutput,
    required this.explanation,
    required this.xpReward,
    required this.isPublished,
    this.linkedLessonId,
    this.createdAt,
    this.updatedAt,
    this.stdin = '',
    this.testCases = const [],
    this.audiencePrograms = const [],
    this.yearLevels = const [],
    this.problemGoal = '',
    this.inputsDescription = '',
    this.algorithmSteps = const [],
    this.keyConcepts = const [],
    this.commonMistakes = '',
    this.hints = const [],
    this.errorFocus = 'Logic',
    this.version = 1,
    this.compilerValidated = false,
    this.compilerValidatedAt,
  });

  final String id;
  final String title;
  final String topic;
  final String language;
  final String difficulty;
  final String codeSnippet;
  final List<SimulationStep> executionSteps;
  final String expectedOutput;
  final String explanation;
  final int xpReward;
  final bool isPublished;
  final String? linkedLessonId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String stdin;
  final List<SimulationTestCase> testCases;
  final List<String> audiencePrograms;
  final List<String> yearLevels;
  final String problemGoal;
  final String inputsDescription;
  final List<String> algorithmSteps;
  final List<String> keyConcepts;
  final String commonMistakes;
  final List<String> hints;
  final String errorFocus;
  final int version;
  final bool compilerValidated;
  final DateTime? compilerValidatedAt;

  factory AdminSimulation.fromMap(String id, Map<String, dynamic> map) {
    final rawSteps = map['executionSteps'];
    final steps = rawSteps is List
        ? rawSteps
              .whereType<Map>()
              .map((s) => SimulationStep.fromMap(Map<String, dynamic>.from(s)))
              .toList()
        : <SimulationStep>[];

    return AdminSimulation(
      id: id,
      title: map['title'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      language: _normalizeLanguage(map['language'] as String?),
      difficulty: _normalizeDifficulty(map['difficulty'] as String?),
      codeSnippet: map['codeSnippet'] as String? ?? '',
      executionSteps: steps,
      expectedOutput: map['expectedOutput'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 20,
      isPublished: map['isPublished'] as bool? ?? false,
      linkedLessonId: map['linkedLessonId'] as String?,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      stdin: map['stdin'] as String? ?? '',
      testCases: (map['testCases'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SimulationTestCase.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      audiencePrograms: List<String>.from(
        map['audiencePrograms'] as List? ?? const [],
      ),
      yearLevels: List<String>.from(map['yearLevels'] as List? ?? const []),
      problemGoal: map['problemGoal'] as String? ?? '',
      inputsDescription: map['inputsDescription'] as String? ?? '',
      algorithmSteps: List<String>.from(
        map['algorithmSteps'] as List? ?? const [],
      ),
      keyConcepts: List<String>.from(map['keyConcepts'] as List? ?? const []),
      commonMistakes: map['commonMistakes'] as String? ?? '',
      hints: List<String>.from(map['hints'] as List? ?? const []),
      errorFocus: _normalizeFocus(map['errorFocus'] as String?),
      version: (map['version'] as num?)?.toInt() ?? 1,
      compilerValidated:
          map['compilerValidated'] as bool? ??
          (map['isPublished'] as bool? ?? false),
      compilerValidatedAt: _toDateTime(map['compilerValidatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'topic': topic,
    'language': language,
    'difficulty': difficulty,
    'codeSnippet': codeSnippet,
    'executionSteps': executionSteps.map((s) => s.toMap()).toList(),
    'expectedOutput': expectedOutput,
    'explanation': explanation,
    'xpReward': xpReward,
    'isPublished': isPublished,
    if (linkedLessonId != null) 'linkedLessonId': linkedLessonId,
    'stdin': stdin,
    'testCases': testCases
        .map(
          (test) => {
            'name': test.name,
            'stdin': test.stdin,
            'expectedOutput': test.expectedOutput,
            'isHidden': test.isHidden,
          },
        )
        .toList(),
    'audiencePrograms': audiencePrograms,
    'yearLevels': yearLevels,
    'problemGoal': problemGoal,
    'inputsDescription': inputsDescription,
    'algorithmSteps': algorithmSteps,
    'keyConcepts': keyConcepts,
    'commonMistakes': commonMistakes,
    'hints': hints,
    'errorFocus': errorFocus,
    'version': version,
    'compilerValidated': compilerValidated,
    if (compilerValidatedAt != null)
      'compilerValidatedAt': Timestamp.fromDate(compilerValidatedAt!),
  };

  Map<String, dynamic> toPublicMap() => {
    ...toMap(),
    'testCases': testCases
        .where((test) => !test.isHidden)
        .map(
          (test) => {
            'name': test.name,
            'stdin': test.stdin,
            'expectedOutput': test.expectedOutput,
            'isHidden': false,
          },
        )
        .toList(),
    'hiddenTestCount': testCases.where((test) => test.isHidden).length,
  };

  Map<String, dynamic> toPrivateTestsMap() => {
    'testCases': testCases
        .where((test) => test.isHidden)
        .map(
          (test) => {
            'name': test.name,
            'stdin': test.stdin,
            'expectedOutput': test.expectedOutput,
            'isHidden': true,
          },
        )
        .toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  bool get hasAudience => audiencePrograms.isNotEmpty && yearLevels.isNotEmpty;
  bool get isReadyToPublish => readinessIssues.isEmpty;
  List<String> get readinessIssues => [
    if (linkedLessonId == null || linkedLessonId!.trim().isEmpty)
      'linked lesson',
    if (title.trim().isEmpty) 'title',
    if (topic.trim().isEmpty) 'topic',
    if (codeSnippet.trim().isEmpty) 'source code',
    if (expectedOutput.trim().isEmpty) 'expected output',
    if (explanation.trim().isEmpty) 'learner explanation',
    if (!hasAudience) 'program and year audience',
    if (problemGoal.trim().isEmpty) 'problem goal',
    if (algorithmSteps.isEmpty) 'algorithm steps',
    if (keyConcepts.isEmpty) 'key concepts',
    if (testCases.isEmpty) 'compiler test cases',
    if (!compilerValidated) 'compiler validation',
  ];

  int get readinessPercent {
    const totalChecks = 12;
    return (((totalChecks - readinessIssues.length) / totalChecks) * 100)
        .clamp(0, 100)
        .round();
  }

  AdminSimulation copyWith({
    String? title,
    String? topic,
    String? language,
    String? difficulty,
    String? codeSnippet,
    List<SimulationStep>? executionSteps,
    String? expectedOutput,
    String? explanation,
    int? xpReward,
    bool? isPublished,
    String? linkedLessonId,
    String? stdin,
    List<SimulationTestCase>? testCases,
    List<String>? audiencePrograms,
    List<String>? yearLevels,
    String? problemGoal,
    String? inputsDescription,
    List<String>? algorithmSteps,
    List<String>? keyConcepts,
    String? commonMistakes,
    List<String>? hints,
    String? errorFocus,
    int? version,
    bool? compilerValidated,
    DateTime? compilerValidatedAt,
  }) {
    return AdminSimulation(
      id: id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      executionSteps: executionSteps ?? this.executionSteps,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      explanation: explanation ?? this.explanation,
      xpReward: xpReward ?? this.xpReward,
      isPublished: isPublished ?? this.isPublished,
      linkedLessonId: linkedLessonId ?? this.linkedLessonId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      stdin: stdin ?? this.stdin,
      testCases: testCases ?? this.testCases,
      audiencePrograms: audiencePrograms ?? this.audiencePrograms,
      yearLevels: yearLevels ?? this.yearLevels,
      problemGoal: problemGoal ?? this.problemGoal,
      inputsDescription: inputsDescription ?? this.inputsDescription,
      algorithmSteps: algorithmSteps ?? this.algorithmSteps,
      keyConcepts: keyConcepts ?? this.keyConcepts,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      hints: hints ?? this.hints,
      errorFocus: errorFocus ?? this.errorFocus,
      version: version ?? this.version,
      compilerValidated: compilerValidated ?? this.compilerValidated,
      compilerValidatedAt: compilerValidatedAt ?? this.compilerValidatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _normalizeLanguage(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'c' || 'c++' || 'cpp' => 'C++',
      'java' => 'Java',
      'javascript' || 'java script' || 'js' => 'JavaScript',
      _ => 'C++',
    };
  }

  static String _normalizeDifficulty(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'medium' || 'intermediate' => 'Medium',
      'hard' || 'advanced' => 'Hard',
      _ => 'Easy',
    };
  }

  static String _normalizeFocus(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'syntax' || 'syntax error' => 'Syntax',
      'syntax and logic' || 'syntax & logic' => 'Syntax and Logic',
      _ => 'Logic',
    };
  }
}
