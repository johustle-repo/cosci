import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDailyChallenge {
  const AdminDailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.challengeType,
    required this.xpReward,
    required this.status,
    required this.date,
    this.linkedContentId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String challengeType; // puzzle | quiz | lesson | simulation
  final int xpReward;
  final String status; // active | inactive | scheduled
  final String date; // ISO date string: 'YYYY-MM-DD'
  final String? linkedContentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';
  bool get isReadyToActivate =>
      title.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      linkedContentId?.trim().isNotEmpty == true &&
      DateTime.tryParse(date) != null;

  factory AdminDailyChallenge.fromMap(String id, Map<String, dynamic> map) {
    return AdminDailyChallenge(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      challengeType: _normalizeType(map['challengeType'] as String?),
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 50,
      status: _normalizeStatus(map['status'] as String?),
      date: map['date'] as String? ?? '',
      linkedContentId: map['linkedContentId'] as String?,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'challengeType': challengeType,
    'xpReward': xpReward,
    'status': status,
    'date': date,
    if (linkedContentId != null) 'linkedContentId': linkedContentId,
  };

  AdminDailyChallenge copyWith({
    String? title,
    String? description,
    String? challengeType,
    int? xpReward,
    String? status,
    String? date,
    String? linkedContentId,
  }) {
    return AdminDailyChallenge(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      challengeType: challengeType ?? this.challengeType,
      xpReward: xpReward ?? this.xpReward,
      status: status ?? this.status,
      date: date ?? this.date,
      linkedContentId: linkedContentId ?? this.linkedContentId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _normalizeType(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return const {'puzzle', 'quiz', 'lesson', 'simulation'}.contains(normalized)
        ? normalized
        : 'puzzle';
  }

  static String _normalizeStatus(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return const {'active', 'inactive', 'scheduled'}.contains(normalized)
        ? normalized
        : 'inactive';
  }
}
