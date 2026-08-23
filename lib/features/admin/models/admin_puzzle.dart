import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPuzzle {
  const AdminPuzzle({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.puzzleType,
    required this.xpReward,
    required this.isPublished,
    this.codeSnippet,
    this.hint,
    this.explanation,
    // Code Flow fields
    this.scrambledLines = const [],
    this.correctOrder = const [],
    // Output Prediction fields
    this.outputChoices = const [],
    this.correctOutputId,
    // Debug the Bug fields
    this.bugDescription,
    this.bugAnswer,
    this.createdAt,
    this.updatedAt,
    this.audiencePrograms = const [],
    this.yearLevels = const [],
    this.lessonId,
    this.language = 'C++',
  });

  final String id;
  final String title;
  final String topic;
  final String difficulty;
  final String puzzleType; // code_flow | output_prediction | debug_bug
  final int xpReward;
  final bool isPublished;
  final String? codeSnippet;
  final String? hint;
  final String? explanation;
  final List<String> scrambledLines;
  final List<String> correctOrder;
  final List<String> outputChoices;
  final String? correctOutputId;
  final String? bugDescription;
  final String? bugAnswer;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> audiencePrograms;
  final List<String> yearLevels;
  final String? lessonId;
  final String language;

  List<String> get readinessIssues {
    final issues = <String>[];
    if (title.trim().isEmpty) issues.add('title');
    if (topic.trim().isEmpty) issues.add('topic');
    if (audiencePrograms.isEmpty) issues.add('program audience');
    if (yearLevels.isEmpty) issues.add('year level');
    switch (puzzleType) {
      case 'code_flow':
        if (scrambledLines.length < 2 || correctOrder.length < 2) {
          issues.add('code-flow lines');
        }
        break;
      case 'output_prediction':
        if (outputChoices.length < 2 || (correctOutputId ?? '').isEmpty) {
          issues.add('output choices and answer');
        }
        break;
      case 'debug_bug':
        if ((bugDescription ?? '').trim().isEmpty ||
            (bugAnswer ?? '').trim().isEmpty) {
          issues.add('bug description and answer');
        }
        break;
      default:
        issues.add('supported puzzle type');
    }
    return issues;
  }

  bool get isReadyToPublish => readinessIssues.isEmpty;

  factory AdminPuzzle.fromMap(String id, Map<String, dynamic> map) {
    return AdminPuzzle(
      id: id,
      title: map['title'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'Easy',
      puzzleType: map['type'] as String? ?? 'code_flow',
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 25,
      isPublished: map['isPublished'] as bool? ?? false,
      codeSnippet: map['codeSnippet'] as String?,
      hint: map['hint'] as String?,
      explanation: map['explanation'] as String?,
      scrambledLines: _stringList(map['scrambledLines']),
      correctOrder: _stringList(map['correctOrder']),
      outputChoices: _stringList(map['outputChoices']),
      // AI may store this as int (0, 1, …) or String — normalise to String
      correctOutputId: map['correctOutputId']?.toString(),
      bugDescription: map['bugDescription'] as String?,
      bugAnswer: map['bugAnswer'] as String?,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      audiencePrograms: _stringList(map['audiencePrograms']),
      yearLevels: _stringList(map['yearLevels']),
      lessonId: map['lessonId'] as String?,
      language: map['language'] as String? ?? 'C++',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'topic': topic,
    'difficulty': difficulty,
    'type': puzzleType,
    'xpReward': xpReward,
    'isPublished': isPublished,
    if (codeSnippet != null) 'codeSnippet': codeSnippet,
    if (hint != null) 'hint': hint,
    if (explanation != null) 'explanation': explanation,
    if (scrambledLines.isNotEmpty) 'scrambledLines': scrambledLines,
    if (correctOrder.isNotEmpty) 'correctOrder': correctOrder,
    if (outputChoices.isNotEmpty) 'outputChoices': outputChoices,
    if (correctOutputId != null) 'correctOutputId': correctOutputId,
    if (bugDescription != null) 'bugDescription': bugDescription,
    if (bugAnswer != null) 'bugAnswer': bugAnswer,
    'audiencePrograms': audiencePrograms,
    'yearLevels': yearLevels,
    if (lessonId != null) 'lessonId': lessonId,
    'language': language,
  };

  AdminPuzzle copyWith({
    String? title,
    String? topic,
    String? difficulty,
    String? puzzleType,
    int? xpReward,
    bool? isPublished,
    String? codeSnippet,
    String? hint,
    String? explanation,
    List<String>? scrambledLines,
    List<String>? correctOrder,
    List<String>? outputChoices,
    String? correctOutputId,
    String? bugDescription,
    String? bugAnswer,
    List<String>? audiencePrograms,
    List<String>? yearLevels,
    String? lessonId,
    String? language,
  }) {
    return AdminPuzzle(
      id: id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      puzzleType: puzzleType ?? this.puzzleType,
      xpReward: xpReward ?? this.xpReward,
      isPublished: isPublished ?? this.isPublished,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      hint: hint ?? this.hint,
      explanation: explanation ?? this.explanation,
      scrambledLines: scrambledLines ?? this.scrambledLines,
      correctOrder: correctOrder ?? this.correctOrder,
      outputChoices: outputChoices ?? this.outputChoices,
      correctOutputId: correctOutputId ?? this.correctOutputId,
      bugDescription: bugDescription ?? this.bugDescription,
      bugAnswer: bugAnswer ?? this.bugAnswer,
      createdAt: createdAt,
      updatedAt: updatedAt,
      audiencePrograms: audiencePrograms ?? this.audiencePrograms,
      yearLevels: yearLevels ?? this.yearLevels,
      lessonId: lessonId ?? this.lessonId,
      language: language ?? this.language,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
