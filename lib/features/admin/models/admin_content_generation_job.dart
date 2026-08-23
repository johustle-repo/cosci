import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a single AI content-generation request for a syllabus.
class AdminContentGenerationJob {
  const AdminContentGenerationJob({
    required this.id,
    required this.syllabusId,
    required this.syllabusTitle,
    required this.contentType,
    required this.status,
    this.generatedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.generatedIds = const [],
    this.startedAt,
    this.completedAt,
    this.createdAt,
  });

  final String id;
  final String syllabusId;
  final String syllabusTitle;

  /// lesson | quiz | puzzle | simulation
  final String contentType;

  /// queued | running | completed | failed | partial
  final String status;

  final int generatedCount;
  final int failedCount;
  final String? errorMessage;

  /// Firestore IDs of the generated documents.
  final List<String> generatedIds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  bool get isRunning => status == 'running' || status == 'queued';
  bool get isCompleted => status == 'completed';
  bool get hasFailed => status == 'failed';
  bool get isPartial => status == 'partial';

  Map<String, dynamic> toMap() => {
    'syllabusId': syllabusId,
    'syllabusTitle': syllabusTitle,
    'contentType': contentType,
    'status': status,
    'generatedCount': generatedCount,
    'failedCount': failedCount,
    if (errorMessage != null) 'errorMessage': errorMessage,
    'generatedIds': generatedIds,
    if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
    if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  AdminContentGenerationJob copyWith({
    String? status,
    int? generatedCount,
    int? failedCount,
    String? errorMessage,
    List<String>? generatedIds,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return AdminContentGenerationJob(
      id: id,
      syllabusId: syllabusId,
      syllabusTitle: syllabusTitle,
      contentType: contentType,
      status: status ?? this.status,
      generatedCount: generatedCount ?? this.generatedCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedIds: generatedIds ?? this.generatedIds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }

  factory AdminContentGenerationJob.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return AdminContentGenerationJob(
      id: id,
      syllabusId: map['syllabusId'] as String? ?? '',
      syllabusTitle: map['syllabusTitle'] as String? ?? '',
      contentType: map['contentType'] as String? ?? '',
      status: map['status'] as String? ?? 'queued',
      generatedCount: (map['generatedCount'] as num?)?.toInt() ?? 0,
      failedCount: (map['failedCount'] as num?)?.toInt() ?? 0,
      errorMessage: map['errorMessage'] as String?,
      generatedIds:
          (map['generatedIds'] as List?)?.map((s) => s.toString()).toList() ??
          [],
      startedAt: _toDateTime(map['startedAt']),
      completedAt: _toDateTime(map['completedAt']),
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
