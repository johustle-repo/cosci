import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents either an XP reward rule or a level threshold.
class AdminGamificationRule {
  const AdminGamificationRule({
    required this.id,
    required this.ruleType,
    required this.description,
    this.targetModule,
    this.xpAmount,
    this.level,
    this.xpRequired,
    this.updatedAt,
  });

  /// 'xp_reward' | 'level_threshold' | 'streak_reward'
  final String ruleType;
  final String id;
  final String description;
  final String? targetModule; // lesson | quiz | puzzle | simulation | challenge
  final int? xpAmount;
  final int? level;
  final int? xpRequired;
  final DateTime? updatedAt;

  bool get isXpRule => ruleType == 'xp_reward';
  bool get isLevelThreshold => ruleType == 'level_threshold';
  bool get isStreakReward => ruleType == 'streak_reward';

  factory AdminGamificationRule.fromMap(String id, Map<String, dynamic> map) {
    return AdminGamificationRule(
      id: id,
      ruleType: map['ruleType'] as String? ?? 'xp_reward',
      description: map['description'] as String? ?? '',
      targetModule: map['targetModule'] as String?,
      xpAmount: (map['xpAmount'] as num?)?.toInt(),
      level: (map['level'] as num?)?.toInt(),
      xpRequired: (map['xpRequired'] as num?)?.toInt(),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'ruleType': ruleType,
    'description': description,
    if (targetModule != null) 'targetModule': targetModule,
    if (xpAmount != null) 'xpAmount': xpAmount,
    if (level != null) 'level': level,
    if (xpRequired != null) 'xpRequired': xpRequired,
  };

  AdminGamificationRule copyWith({
    String? ruleType,
    String? description,
    String? targetModule,
    int? xpAmount,
    int? level,
    int? xpRequired,
  }) {
    return AdminGamificationRule(
      id: id,
      ruleType: ruleType ?? this.ruleType,
      description: description ?? this.description,
      targetModule: targetModule ?? this.targetModule,
      xpAmount: xpAmount ?? this.xpAmount,
      level: level ?? this.level,
      xpRequired: xpRequired ?? this.xpRequired,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
