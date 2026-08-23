class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.sortOrder,
    this.questionType = 'multiple_choice',
    this.codeSnippet,
    this.explanation,
  });

  final String id;
  final String questionText;
  final List<String> options;
  final int sortOrder;
  final String questionType;
  final String? codeSnippet;
  final String? explanation;

  factory QuizQuestion.fromMap(String id, Map<String, dynamic> map) {
    return QuizQuestion(
      id: id,
      questionText: _readString(map['questionText'], fallback: 'Question'),
      options: _readStringList(map['options']),
      sortOrder: _readInt(map['sortOrder']) ?? 0,
      questionType: _readString(
        map['questionType'],
        fallback: 'multiple_choice',
      ),
      codeSnippet: _nullableString(map['codeSnippet']),
      explanation: _nullableString(map['explanation']),
    );
  }

  QuizQuestion copyWith({List<String>? options}) => QuizQuestion(
    id: id,
    questionText: questionText,
    options: options ?? this.options,
    sortOrder: sortOrder,
    questionType: questionType,
    codeSnippet: codeSnippet,
    explanation: explanation,
  );
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return fallback;
}

String? _nullableString(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
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
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
