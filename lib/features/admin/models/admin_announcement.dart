import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnnouncement {
  const AdminAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.targetAudience,
    required this.isPublished,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String message;
  final String targetAudience; // all | students | professors
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isReadyToPublish =>
      title.trim().length >= 4 && message.trim().length >= 10;

  factory AdminAnnouncement.fromMap(String id, Map<String, dynamic> map) {
    return AdminAnnouncement(
      id: id,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      targetAudience: _normalizeAudience(map['targetAudience'] as String?),
      isPublished: map['isPublished'] as bool? ?? false,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'message': message,
    'targetAudience': targetAudience,
    'isPublished': isPublished,
  };

  AdminAnnouncement copyWith({
    String? title,
    String? message,
    String? targetAudience,
    bool? isPublished,
  }) {
    return AdminAnnouncement(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      targetAudience: targetAudience ?? this.targetAudience,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _normalizeAudience(String? value) {
    return switch ((value ?? '').trim().toLowerCase()) {
      'student' || 'students' || 'learner' || 'learners' => 'students',
      'professor' ||
      'professors' ||
      'instructor' ||
      'instructors' ||
      'faculty' => 'professors',
      _ => 'all',
    };
  }
}
