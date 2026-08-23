class DashboardBadge {
  const DashboardBadge({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.earnedAtLabel,
  });

  final String id;
  final String title;
  final String iconKey;
  final String earnedAtLabel;

  factory DashboardBadge.fromMap(String id, Map<String, dynamic> map) {
    return DashboardBadge(
      id: id,
      title: _readString(map['title'], fallback: 'Badge'),
      iconKey: _readString(
        map['iconKey'],
        fallback: _readString(map['iconName'], fallback: 'award'),
      ),
      earnedAtLabel: _readString(
        map['earnedAtLabel'],
        fallback: (map['isUnlocked'] as bool? ?? true)
            ? 'Recently earned'
            : 'Locked milestone',
      ),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    return fallback;
  }
}
