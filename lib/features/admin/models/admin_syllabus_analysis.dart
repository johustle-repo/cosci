import 'package:cloud_firestore/cloud_firestore.dart';

/// A single unit/week extracted from the syllabus.
class SyllabusUnit {
  const SyllabusUnit({
    required this.unitNumber,
    required this.title,
    this.weekReference = '',
    this.topics = const [],
    this.outcomes = const [],
    this.difficulty = 'Easy',
  });

  final int unitNumber;
  final String title;
  final String weekReference;
  final List<String> topics;
  final List<String> outcomes;

  /// Easy | Medium | Hard — inferred from content complexity
  final String difficulty;

  Map<String, dynamic> toMap() => {
    'unitNumber': unitNumber,
    'title': title,
    'weekReference': weekReference,
    'topics': topics,
    'outcomes': outcomes,
    'difficulty': difficulty,
  };

  factory SyllabusUnit.fromMap(Map<String, dynamic> map) {
    return SyllabusUnit(
      unitNumber: (map['unitNumber'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      weekReference: map['weekReference'] as String? ?? '',
      topics: _toStringList(map['topics']),
      outcomes: _toStringList(map['outcomes']),
      difficulty: map['difficulty'] as String? ?? 'Easy',
    );
  }

  static List<String> _toStringList(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : [];
}

/// Structured curriculum data extracted from an uploaded syllabus.
///
/// Uses [syllabusId] as the Firestore document ID for direct lookup.
class AdminSyllabusAnalysis {
  const AdminSyllabusAnalysis({
    required this.id,
    required this.syllabusId,
    this.courseTitle = '',
    this.courseCode = '',
    this.programmingLanguage = '',
    this.programmingLanguageVersion = '',
    this.courseDescription = '',
    this.yearLevel = '',
    this.units = const [],
    this.allTopics = const [],
    this.intendedLearningOutcomes = const [],
    this.conceptProgression = const [],
    this.prerequisiteTopics = const [],
    this.assessmentIndicators = const [],
    this.confidenceFlags = const {},
    this.manualEditsApplied = false,
    this.analyzedAt,
  });

  final String id;
  final String syllabusId;
  final String courseTitle;
  final String courseCode;
  final String programmingLanguage;
  final String programmingLanguageVersion;
  final String courseDescription;
  final String yearLevel;
  final List<SyllabusUnit> units;
  final List<String> allTopics;
  final List<String> intendedLearningOutcomes;
  final List<String> conceptProgression;
  final List<String> prerequisiteTopics;
  final List<String> assessmentIndicators;

  /// Per-field confidence: true = found clearly, false = guessed/missing.
  final Map<String, bool> confidenceFlags;
  final bool manualEditsApplied;
  final DateTime? analyzedAt;

  bool get hasUnits => units.isNotEmpty;
  bool get hasTopics => allTopics.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'syllabusId': syllabusId,
    'courseTitle': courseTitle,
    'courseCode': courseCode,
    'programmingLanguage': programmingLanguage,
    'programmingLanguageVersion': programmingLanguageVersion,
    'courseDescription': courseDescription,
    'yearLevel': yearLevel,
    'units': units.map((u) => u.toMap()).toList(),
    'allTopics': allTopics,
    'intendedLearningOutcomes': intendedLearningOutcomes,
    'conceptProgression': conceptProgression,
    'prerequisiteTopics': prerequisiteTopics,
    'assessmentIndicators': assessmentIndicators,
    'confidenceFlags': confidenceFlags,
    'manualEditsApplied': manualEditsApplied,
    'analyzedAt': FieldValue.serverTimestamp(),
  };

  factory AdminSyllabusAnalysis.fromMap(String id, Map<String, dynamic> map) {
    final rawUnits = map['units'] as List? ?? [];
    final units = rawUnits
        .map(
          (u) => SyllabusUnit.fromMap(
            u is Map ? Map<String, dynamic>.from(u) : {},
          ),
        )
        .toList();

    final rawFlags = map['confidenceFlags'];
    final flags = rawFlags is Map
        ? Map<String, bool>.from(
            rawFlags.map((k, v) => MapEntry(k.toString(), v as bool? ?? false)),
          )
        : <String, bool>{};

    return AdminSyllabusAnalysis(
      id: id,
      syllabusId: map['syllabusId'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      programmingLanguage: map['programmingLanguage'] as String? ?? '',
      programmingLanguageVersion:
          map['programmingLanguageVersion'] as String? ?? '',
      courseDescription: map['courseDescription'] as String? ?? '',
      yearLevel: map['yearLevel'] as String? ?? '',
      units: units,
      allTopics: _toStringList(map['allTopics']),
      intendedLearningOutcomes: _toStringList(map['intendedLearningOutcomes']),
      conceptProgression: _toStringList(map['conceptProgression']),
      prerequisiteTopics: _toStringList(map['prerequisiteTopics']),
      assessmentIndicators: _toStringList(map['assessmentIndicators']),
      confidenceFlags: flags,
      manualEditsApplied: map['manualEditsApplied'] as bool? ?? false,
      analyzedAt: _toDateTime(map['analyzedAt']),
    );
  }

  /// Build from Claude API JSON response.
  factory AdminSyllabusAnalysis.fromAiResponse(
    String syllabusId,
    Map<String, dynamic> json,
  ) {
    final rawUnits = json['units'] as List? ?? [];
    final units = rawUnits.map((u) {
      if (u is Map) return SyllabusUnit.fromMap(Map<String, dynamic>.from(u));
      return const SyllabusUnit(unitNumber: 0, title: 'Unknown Unit');
    }).toList();

    final rawFlags = json['confidenceFlags'];
    final flags = rawFlags is Map
        ? Map<String, bool>.from(
            rawFlags.map((k, v) => MapEntry(k.toString(), v as bool? ?? false)),
          )
        : <String, bool>{};

    return AdminSyllabusAnalysis(
      id: '',
      syllabusId: syllabusId,
      courseTitle: json['courseTitle'] as String? ?? '',
      courseCode: json['courseCode'] as String? ?? '',
      programmingLanguage: json['programmingLanguage'] as String? ?? '',
      programmingLanguageVersion:
          json['programmingLanguageVersion'] as String? ?? '',
      courseDescription: json['courseDescription'] as String? ?? '',
      yearLevel: json['yearLevel'] as String? ?? '',
      units: units,
      allTopics: _toStringList(json['allTopics']),
      intendedLearningOutcomes: _toStringList(json['intendedLearningOutcomes']),
      conceptProgression: _toStringList(json['conceptProgression']),
      prerequisiteTopics: _toStringList(json['prerequisiteTopics']),
      assessmentIndicators: _toStringList(json['assessmentIndicators']),
      confidenceFlags: flags,
    );
  }

  static List<String> _toStringList(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : [];

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
