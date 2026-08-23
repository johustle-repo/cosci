class DailyChallenge {
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.completionLabel,
  });

  final String id;
  final String title;
  final String description;
  final int xpReward;
  final String completionLabel;

  factory DailyChallenge.fromMap(String id, Map<String, dynamic> map) {
    return DailyChallenge(
      id: id,
      title: map['title'] as String? ?? 'Daily challenge',
      description:
          map['description'] as String? ??
          'Complete a quick challenge to keep your streak active.',
      xpReward: _readInt(map['xpReward']) ?? 50,
      completionLabel: map['completionLabel'] as String? ?? 'Ready today',
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
