class Quiz {
  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.totalItems,
    required this.language,
    required this.difficulty,
    required this.passingScore,
    required this.sortOrder,
    required this.topic,
    required this.xpReward,
    this.isPublished = true,
    this.attemptLimit = 3,
    this.errorFocus = 'concept',
    this.simulationId,
    this.shuffleQuestions = true,
  });

  final String id;
  final String title;
  final String description;
  final int totalItems;
  final String language;
  final String difficulty;
  final int passingScore;
  final int sortOrder;
  final String topic;
  final int xpReward;
  final bool isPublished;
  final int attemptLimit;
  final String errorFocus;
  final String? simulationId;
  final bool shuffleQuestions;

  factory Quiz.fromMap(
    String id,
    Map<String, dynamic> map, {
    int? questionCount,
  }) {
    final topic = _readString(map['topic']);
    final description = _readString(map['description']);
    final questionText = _readString(map['questionText']);

    return Quiz(
      id: id,
      title: _readString(map['title'], fallback: 'Untitled quiz'),
      description: description.isNotEmpty
          ? description
          : topic.isNotEmpty
          ? 'Practice questions for $topic.'
          : 'Quiz description is not available.',
      totalItems:
          questionCount ??
          _readInt(map['totalItems']) ??
          _readInt(map['questionCount']) ??
          (questionText.isNotEmpty ? 1 : 0),
      language: _readString(map['language'], fallback: 'C++'),
      difficulty: _readString(map['difficulty'], fallback: 'Easy'),
      passingScore: _readInt(map['passingScore']) ?? 80,
      sortOrder: _readInt(map['sortOrder']) ?? 0,
      topic: topic,
      xpReward: _readInt(map['xpReward']) ?? 20,
      isPublished: map['isPublished'] as bool? ?? true,
      attemptLimit: _readInt(map['attemptLimit']) ?? 3,
      errorFocus: _readString(map['errorFocus'], fallback: 'concept'),
      simulationId: _readString(map['simulationId']).isEmpty
          ? null
          : _readString(map['simulationId']),
      shuffleQuestions: map['shuffleQuestions'] as bool? ?? true,
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
