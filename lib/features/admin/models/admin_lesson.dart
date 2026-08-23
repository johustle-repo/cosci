import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLesson {
  const AdminLesson({
    required this.id,
    required this.title,
    required this.topic,
    required this.language,
    required this.difficulty,
    required this.description,
    required this.sortOrder,
    required this.isPublished,
    this.createdAt,
    this.updatedAt,
    this.audiencePrograms = const [],
    this.yearLevels = const [],
    this.estimatedMinutes = 15,
    this.learningObjective = '',
    this.keyConcepts = const [],
    this.prerequisites = const [],
    this.introduction = '',
    this.workedExample = '',
    this.commonMistakes = '',
    this.summary = '',
    this.errorFocus = 'Concept',
    this.sourceCode = '',
    this.standardInput = '',
    this.expectedOutput = '',
    this.algorithmSteps = const [],
    this.pseudocode = '',
    this.compilerValidated = false,
    this.compilerValidatedAt,
  });

  final String id;
  final String title;
  final String topic;
  final String language;
  final String difficulty;
  final String description;
  final int sortOrder;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> audiencePrograms;
  final List<String> yearLevels;
  final int estimatedMinutes;
  final String learningObjective;
  final List<String> keyConcepts;
  final List<String> prerequisites;
  final String introduction;
  final String workedExample;
  final String commonMistakes;
  final String summary;
  final String errorFocus;
  final String sourceCode;
  final String standardInput;
  final String expectedOutput;
  final List<String> algorithmSteps;
  final String pseudocode;
  final bool compilerValidated;
  final DateTime? compilerValidatedAt;

  bool get hasAudience => audiencePrograms.isNotEmpty && yearLevels.isNotEmpty;
  bool get hasStructuredContent =>
      learningObjective.trim().isNotEmpty &&
      keyConcepts.isNotEmpty &&
      algorithmSteps.isNotEmpty;
  bool get hasValidPractice => sourceCode.trim().isEmpty || compilerValidated;
  bool get isReadyToPublish =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      hasAudience &&
      hasStructuredContent &&
      hasValidPractice;
  int get readinessPercent {
    final checks = <bool>[
      title.trim().isNotEmpty && description.trim().isNotEmpty,
      hasAudience,
      learningObjective.trim().isNotEmpty,
      keyConcepts.isNotEmpty,
      algorithmSteps.isNotEmpty,
      hasValidPractice,
    ];
    return (checks.where((value) => value).length / checks.length * 100)
        .round();
  }

  factory AdminLesson.fromMap(String id, Map<String, dynamic> map) {
    return AdminLesson(
      id: id,
      title: map['title'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      language: map['language'] as String? ?? 'C++',
      difficulty: map['difficulty'] as String? ?? 'Easy',
      description: map['description'] as String? ?? '',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      audiencePrograms: List<String>.from(
        map['audiencePrograms'] as List? ?? const [],
      ),
      yearLevels: List<String>.from(map['yearLevels'] as List? ?? const []),
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 15,
      learningObjective: map['learningObjective'] as String? ?? '',
      keyConcepts: List<String>.from(map['keyConcepts'] as List? ?? const []),
      prerequisites: List<String>.from(
        map['prerequisites'] as List? ?? const [],
      ),
      introduction: map['introduction'] as String? ?? '',
      workedExample: map['workedExample'] as String? ?? '',
      commonMistakes: map['commonMistakes'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      errorFocus: map['errorFocus'] as String? ?? 'Concept',
      sourceCode: map['sourceCode'] as String? ?? '',
      standardInput: map['standardInput'] as String? ?? '',
      expectedOutput: map['expectedOutput'] as String? ?? '',
      algorithmSteps: List<String>.from(
        map['algorithmSteps'] as List? ?? const [],
      ),
      pseudocode: map['pseudocode'] as String? ?? '',
      compilerValidated: map['compilerValidated'] as bool? ?? false,
      compilerValidatedAt: _toDateTime(map['compilerValidatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'topic': topic,
      'language': language,
      'difficulty': difficulty,
      'description': description,
      'sortOrder': sortOrder,
      'isPublished': isPublished,
      'audiencePrograms': audiencePrograms,
      'yearLevels': yearLevels,
      'estimatedMinutes': estimatedMinutes,
      'learningObjective': learningObjective,
      'keyConcepts': keyConcepts,
      'prerequisites': prerequisites,
      'introduction': introduction,
      'workedExample': workedExample,
      'commonMistakes': commonMistakes,
      'summary': summary,
      'errorFocus': errorFocus,
      'sourceCode': sourceCode,
      'standardInput': standardInput,
      'expectedOutput': expectedOutput,
      'algorithmSteps': algorithmSteps,
      'pseudocode': pseudocode,
      'compilerValidated': compilerValidated,
      if (compilerValidatedAt != null)
        'compilerValidatedAt': Timestamp.fromDate(compilerValidatedAt!),
    };
  }

  AdminLesson copyWith({
    String? id,
    String? title,
    String? topic,
    String? language,
    String? difficulty,
    String? description,
    int? sortOrder,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? audiencePrograms,
    List<String>? yearLevels,
    int? estimatedMinutes,
    String? learningObjective,
    List<String>? keyConcepts,
    List<String>? prerequisites,
    String? introduction,
    String? workedExample,
    String? commonMistakes,
    String? summary,
    String? errorFocus,
    String? sourceCode,
    String? standardInput,
    String? expectedOutput,
    List<String>? algorithmSteps,
    String? pseudocode,
    bool? compilerValidated,
    DateTime? compilerValidatedAt,
  }) {
    return AdminLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      audiencePrograms: audiencePrograms ?? this.audiencePrograms,
      yearLevels: yearLevels ?? this.yearLevels,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      learningObjective: learningObjective ?? this.learningObjective,
      keyConcepts: keyConcepts ?? this.keyConcepts,
      prerequisites: prerequisites ?? this.prerequisites,
      introduction: introduction ?? this.introduction,
      workedExample: workedExample ?? this.workedExample,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      summary: summary ?? this.summary,
      errorFocus: errorFocus ?? this.errorFocus,
      sourceCode: sourceCode ?? this.sourceCode,
      standardInput: standardInput ?? this.standardInput,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      algorithmSteps: algorithmSteps ?? this.algorithmSteps,
      pseudocode: pseudocode ?? this.pseudocode,
      compilerValidated: compilerValidated ?? this.compilerValidated,
      compilerValidatedAt: compilerValidatedAt ?? this.compilerValidatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
