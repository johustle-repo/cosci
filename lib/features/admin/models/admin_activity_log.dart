import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActivityLog {
  const AdminActivityLog({
    required this.id,
    required this.adminUid,
    required this.adminEmail,
    required this.actionType,
    required this.targetModule,
    required this.description,
    this.targetId,
    this.timestamp,
  });

  final String id;
  final String adminUid;
  final String adminEmail;
  final String
  actionType; // login | logout | create | update | delete | publish | unpublish
  final String
  targetModule; // lessons | quizzes | puzzles | simulations | badges | challenges | announcements | settings | auth
  final String description;
  final String? targetId;
  final DateTime? timestamp;

  factory AdminActivityLog.fromMap(String id, Map<String, dynamic> map) {
    return AdminActivityLog(
      id: id,
      adminUid: map['adminUid'] as String? ?? '',
      adminEmail: map['adminEmail'] as String? ?? '',
      actionType: map['actionType'] as String? ?? '',
      targetModule: map['targetModule'] as String? ?? '',
      description: map['description'] as String? ?? '',
      targetId: map['targetId'] as String?,
      timestamp: _toDateTime(
        map['timestamp'] ?? map['createdAt'] ?? map['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'adminUid': adminUid,
    'adminEmail': adminEmail,
    'actionType': actionType,
    'targetModule': targetModule,
    'description': description,
    if (targetId != null) 'targetId': targetId,
    'timestamp': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
