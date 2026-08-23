class LearningActivityRecord {
  const LearningActivityRecord({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.title,
    required this.xpAwarded,
    required this.completedAt,
    this.scorePercent,
  });

  final String id;
  final String type;
  final String sourceId;
  final String title;
  final int xpAwarded;
  final DateTime completedAt;
  final int? scorePercent;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'sourceId': sourceId,
      'title': title,
      'xpAwarded': xpAwarded,
      'completedAt': completedAt.toIso8601String(),
      'scorePercent': scorePercent,
    };
  }
}
