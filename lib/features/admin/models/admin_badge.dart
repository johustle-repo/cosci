import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBadge {
  const AdminBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.accentHex,
    required this.criteria,
    required this.milestoneLabel,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconName;
  final String accentHex;
  final String criteria;
  final String milestoneLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminBadge.fromMap(String id, Map<String, dynamic> map) {
    return AdminBadge(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'award',
      accentHex: map['accentHex'] as String? ?? '#123D9B',
      criteria: map['criteria'] as String? ?? '',
      milestoneLabel: map['milestoneLabel'] as String? ?? '',
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'iconName': iconName,
    'accentHex': accentHex,
    'criteria': criteria,
    'milestoneLabel': milestoneLabel,
  };

  AdminBadge copyWith({
    String? title,
    String? description,
    String? iconName,
    String? accentHex,
    String? criteria,
    String? milestoneLabel,
  }) {
    return AdminBadge(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      accentHex: accentHex ?? this.accentHex,
      criteria: criteria ?? this.criteria,
      milestoneLabel: milestoneLabel ?? this.milestoneLabel,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
