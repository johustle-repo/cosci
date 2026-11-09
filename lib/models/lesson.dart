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
    this.overview = '',
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

  /// Optional short overview. When absent, [overviewText] falls back to the
  /// lesson description.
  final String overview;
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
      learningObjective: _readObjectiveText(map['learningObjective']),
      overview: _readString(map['overview']),
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

extension LessonContent on Lesson {
  /// Text for the "Lesson Overview" section.
  String get overviewText =>
      overview.trim().isNotEmpty ? overview.trim() : description;

  /// Learning objectives as a list, parsed from [Lesson.learningObjective]
  /// (one per line, bullet, number, or semicolon). Lessons without stored
  /// objectives get objectives derived from their title and key concepts,
  /// so every lesson shows what the learner will achieve.
  List<String> get objectives {
    final parsed = parseObjectives(learningObjective);
    if (parsed.isNotEmpty) return parsed;
    final subject = topic.trim().isNotEmpty ? topic.trim() : title;
    return [
      'Explain what $subject is and when it is used.',
      if (keyConcepts.isNotEmpty)
        'Describe the key ideas: ${keyConcepts.take(3).join(', ')}.',
      'Trace a $language program that uses $subject and predict its output.',
      'Write and debug a short $language program that applies $subject.',
    ];
  }

  /// True when [objectives] came from the lesson itself, not the fallback.
  bool get hasAuthoredObjectives =>
      parseObjectives(learningObjective).isNotEmpty;
}

/// Splits an objectives text into individual objectives.
List<String> parseObjectives(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  final bullet = RegExp(r'^\s*(?:[-*\u2022\u25CF]|\d+[.)]|[a-z][.)])\s*');
  var parts = trimmed
      .split(RegExp(r'\r?\n'))
      .map((line) => line.replaceFirst(bullet, '').trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (parts.length == 1 && parts.first.contains(';')) {
    parts = parts.first
        .split(';')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
  // Drop a lead-in such as "By the end of this lesson, learners can:".
  if (parts.length > 1 && parts.first.endsWith(':')) {
    parts = parts.sublist(1);
  }
  return parts;
}

String _readObjectiveText(Object? value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .join('\n');
  }
  return _readString(value);
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
