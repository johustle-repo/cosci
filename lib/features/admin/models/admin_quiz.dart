import 'package:cloud_firestore/cloud_firestore.dart';

class AdminQuizQuestion {
  const AdminQuizQuestion({
    required this.id,
    required this.questionType,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.sortOrder,
    this.codeSnippet,
    this.explanation,
  });

  final String id;
  final String
  questionType; // output_prediction | code_tracing | identify_error | multiple_choice
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final int sortOrder;
  final String? codeSnippet;
  final String? explanation;

  factory AdminQuizQuestion.fromMap(String id, Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final options = rawOptions is List
        ? rawOptions.map((o) => o.toString()).toList()
        : <String>[];
    return AdminQuizQuestion(
      id: id,
      questionType: map['questionType'] as String? ?? 'multiple_choice',
      questionText: map['questionText'] as String? ?? '',
      options: options,
      correctAnswer: map['correctAnswer'] as String? ?? '',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      codeSnippet: map['codeSnippet'] as String?,
      explanation: map['explanation'] as String?,
    );
  }

  Map<String, dynamic> toPublicMap() => {
    'questionType': questionType,
    'questionText': questionText,
    'options': options,
    'sortOrder': sortOrder,
    if (codeSnippet != null) 'codeSnippet': codeSnippet,
    if (explanation != null) 'explanation': explanation,
  };

  Map<String, dynamic> toAnswerKeyMap() => {
    'correctAnswer': correctAnswer,
    if (explanation != null) 'explanation': explanation,
  };
}

class AdminQuiz {
  const AdminQuiz({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.xpReward,
    required this.isPublished,
    this.lessonId,
    this.questions = const [],
    this.createdAt,
    this.updatedAt,
    this.audiencePrograms = const [],
    this.yearLevels = const [],
    this.language = 'C++',
    this.errorFocus = 'concept',
    this.passingScore = 80,
    this.attemptLimit = 3,
    this.simulationId,
    this.shuffleQuestions = true,
  });

  final String id;
  final String title;
  final String topic;
  final String difficulty;
  final int xpReward;
  final bool isPublished;
  final String? lessonId;
  final List<AdminQuizQuestion> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> audiencePrograms;
  final List<String> yearLevels;
  final String language;
  final String errorFocus;
  final int passingScore;
  final int attemptLimit;
  final String? simulationId;
  final bool shuffleQuestions;

  bool get isReadyToPublish =>
      title.trim().isNotEmpty &&
      topic.trim().isNotEmpty &&
      audiencePrograms.isNotEmpty &&
      yearLevels.isNotEmpty &&
      const ['C++', 'Java', 'JavaScript'].contains(language) &&
      const ['concept', 'syntax', 'logic'].contains(errorFocus) &&
      passingScore >= 50 &&
      passingScore <= 100 &&
      attemptLimit > 0;

  List<String> get readinessIssues {
    final issues = <String>[];
    if (title.trim().isEmpty) issues.add('title');
    if (topic.trim().isEmpty) issues.add('topic');
    if (audiencePrograms.isEmpty) issues.add('program audience');
    if (yearLevels.isEmpty) issues.add('year level');
    if (!const ['C++', 'Java', 'JavaScript'].contains(language)) {
      issues.add('language');
    }
    if (!const ['concept', 'syntax', 'logic'].contains(errorFocus)) {
      issues.add('learning focus');
    }
    if (passingScore < 50 || passingScore > 100) issues.add('passing score');
    if (attemptLimit < 1) issues.add('attempt limit');
    return issues;
  }

  factory AdminQuiz.fromMap(String id, Map<String, dynamic> map) {
    return AdminQuiz(
      id: id,
      title: map['title'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'Easy',
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 30,
      isPublished: map['isPublished'] as bool? ?? false,
      lessonId: map['lessonId'] as String?,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      audiencePrograms: List<String>.from(
        map['audiencePrograms'] as List? ?? const [],
      ),
      yearLevels: List<String>.from(map['yearLevels'] as List? ?? const []),
      language: normalizeQuizLanguage(map['language'] as String?),
      errorFocus: map['errorFocus'] as String? ?? 'concept',
      passingScore: (map['passingScore'] as num?)?.toInt() ?? 80,
      attemptLimit: (map['attemptLimit'] as num?)?.toInt() ?? 3,
      simulationId: map['simulationId'] as String?,
      shuffleQuestions: map['shuffleQuestions'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'topic': topic,
    'difficulty': difficulty,
    'xpReward': xpReward,
    'isPublished': isPublished,
    if (lessonId != null) 'lessonId': lessonId,
    'audiencePrograms': audiencePrograms,
    'yearLevels': yearLevels,
    'language': language,
    'errorFocus': errorFocus,
    'passingScore': passingScore,
    'attemptLimit': attemptLimit,
    if (simulationId != null) 'simulationId': simulationId,
    'shuffleQuestions': shuffleQuestions,
  };

  AdminQuiz copyWith({
    String? title,
    String? topic,
    String? difficulty,
    int? xpReward,
    bool? isPublished,
    String? lessonId,
    List<AdminQuizQuestion>? questions,
    List<String>? audiencePrograms,
    List<String>? yearLevels,
    String? language,
    String? errorFocus,
    int? passingScore,
    int? attemptLimit,
    String? simulationId,
    bool? shuffleQuestions,
  }) {
    return AdminQuiz(
      id: id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      xpReward: xpReward ?? this.xpReward,
      isPublished: isPublished ?? this.isPublished,
      lessonId: lessonId ?? this.lessonId,
      questions: questions ?? this.questions,
      createdAt: createdAt,
      updatedAt: updatedAt,
      audiencePrograms: audiencePrograms ?? this.audiencePrograms,
      yearLevels: yearLevels ?? this.yearLevels,
      language: language ?? this.language,
      errorFocus: errorFocus ?? this.errorFocus,
      passingScore: passingScore ?? this.passingScore,
      attemptLimit: attemptLimit ?? this.attemptLimit,
      simulationId: simulationId ?? this.simulationId,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

String normalizeQuizLanguage(String? value) {
  final normalized = (value ?? '').trim().toLowerCase();
  return switch (normalized) {
    'c' || 'c++' || 'cpp' => 'C++',
    'java' => 'Java',
    'javascript' || 'js' || 'node' || 'node.js' => 'JavaScript',
    _ => 'C++',
  };
}
