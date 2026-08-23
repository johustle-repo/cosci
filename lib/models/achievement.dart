class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.accentHex,
    required this.milestoneLabel,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconName;
  final String accentHex;
  final String milestoneLabel;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    String? accentHex,
    String? milestoneLabel,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      accentHex: accentHex ?? this.accentHex,
      milestoneLabel: milestoneLabel ?? this.milestoneLabel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'accentHex': accentHex,
      'milestoneLabel': milestoneLabel,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: _readString(map['id']),
      title: _readString(map['title'], fallback: 'Badge'),
      description: _readString(
        map['description'],
        fallback: 'Milestone unlocked.',
      ),
      iconName: _readString(
        map['iconName'],
        fallback: _readString(map['iconKey'], fallback: 'award'),
      ),
      accentHex: _readString(map['accentHex'], fallback: '#123D9B'),
      milestoneLabel: _readString(
        map['milestoneLabel'],
        fallback: _readString(map['earnedAtLabel']),
      ),
      isUnlocked: map['isUnlocked'] as bool? ?? true,
      unlockedAt: _parseDate(map['unlockedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    return fallback;
  }
}

class AchievementCatalog {
  static const List<Achievement> definitions = [
    Achievement(
      id: 'first_simulation',
      title: 'Simulation Starter',
      description: 'Complete your first code simulation lesson.',
      iconName: 'terminal',
      accentHex: '#1D4ED8',
      milestoneLabel: 'Finish 1 simulation lesson',
    ),
    Achievement(
      id: 'quiz_master',
      title: 'Quiz Master',
      description: 'Score at least 80% on a graded quiz.',
      iconName: 'spark',
      accentHex: '#2563EB',
      milestoneLabel: 'Reach 80%+ in 1 quiz',
    ),
    Achievement(
      id: 'first_puzzle',
      title: 'Puzzle Pathfinder',
      description: 'Complete your first logic puzzle.',
      iconName: 'puzzle',
      accentHex: '#0EA5E9',
      milestoneLabel: 'Finish 1 puzzle',
    ),
    Achievement(
      id: 'challenge_committed',
      title: 'Daily Challenger',
      description: 'Finish a daily learning challenge.',
      iconName: 'target',
      accentHex: '#0284C7',
      milestoneLabel: 'Complete 1 daily challenge',
    ),
    Achievement(
      id: 'streak_week',
      title: 'Consistency Week',
      description: 'Study for 7 educational days in a row.',
      iconName: 'flame',
      accentHex: '#EA580C',
      milestoneLabel: 'Reach a 7-day streak',
    ),
  ];

  static Achievement definitionById(String id) {
    return definitions.firstWhere(
      (achievement) => achievement.id == id,
      orElse: () => Achievement(
        id: id,
        title: id,
        description: 'Milestone unlocked.',
        iconName: 'award',
        accentHex: '#123D9B',
        milestoneLabel: 'Milestone reached',
      ),
    );
  }
}
