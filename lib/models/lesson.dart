class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.estimatedMinutes,
    required this.sortOrder,
    this.isPublished = true,
    this.topic = '',
    this.difficulty = 'Easy',
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
  });

  final String id;
  final String title;
  final String description;
  final String language;
  final int estimatedMinutes;
  final int sortOrder;
  final bool isPublished;
  final String topic;
  final String difficulty;
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

  factory Lesson.fromMap(String id, Map<String, dynamic> map) {
    return Lesson(
      id: id,
      title: _readString(map['title'], fallback: 'Untitled lesson'),
      description: _readString(
        map['description'],
        fallback: 'Lesson description is not available.',
      ),
      language: _readString(map['language'], fallback: 'C++'),
      estimatedMinutes: _readInt(map['estimatedMinutes']) ?? 10,
      sortOrder: _readInt(map['sortOrder']) ?? 0,
      isPublished: map['isPublished'] as bool? ?? true,
      topic: _readString(map['topic']),
      difficulty: _readString(map['difficulty'], fallback: 'Easy'),
      learningObjective: _readString(map['learningObjective']),
      keyConcepts: _readStringList(map['keyConcepts']),
      prerequisites: _readStringList(map['prerequisites']),
      introduction: _readString(map['introduction']),
      workedExample: _readString(map['workedExample']),
      commonMistakes: _readString(map['commonMistakes']),
      summary: _readString(map['summary']),
      errorFocus: _readString(map['errorFocus'], fallback: 'Concept'),
      sourceCode: _readString(map['sourceCode']),
      standardInput: _readString(map['standardInput']),
      expectedOutput: _readString(map['expectedOutput']),
      algorithmSteps: _readStringList(map['algorithmSteps']),
      pseudocode: _readString(map['pseudocode']),
      compilerValidated: map['compilerValidated'] as bool? ?? false,
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

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}
