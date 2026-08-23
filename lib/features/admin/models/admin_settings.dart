import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettings {
  const AdminSettings({
    required this.topics,
    required this.adminRoles,
    required this.moduleVisibility,
    this.anthropicApiKey = '',
    this.maintenanceMode = false,
    this.maintenanceMessage =
        'CoSci is temporarily unavailable while scheduled maintenance is completed. Please try again later.',
    this.updatedAt,
  });

  final List<String> topics;
  final List<String> adminRoles;
  final Map<String, bool> moduleVisibility;

  /// Existing stored API key field.
  /// Kept for backward compatibility with older code and Firestore docs.
  final String anthropicApiKey;
  final bool maintenanceMode;
  final String maintenanceMessage;

  final DateTime? updatedAt;

  /// New compatibility getter so code using `settings.groqApiKey`
  /// works immediately without changing your Firestore schema yet.
  String get groqApiKey => anthropicApiKey;

  factory AdminSettings.fromMap(Map<String, dynamic> map) {
    final rawTopics = map['topics'];
    final topics = rawTopics is List
        ? rawTopics.map((t) => t.toString()).toList()
        : _defaultTopics;

    final rawRoles = map['adminRoles'];
    final roles = rawRoles is List
        ? rawRoles.map((r) => r.toString()).toList()
        : _defaultRoles;

    final rawVisibility = map['moduleVisibility'];
    final visibility = rawVisibility is Map
        ? Map<String, bool>.from(
            rawVisibility.map(
              (k, v) => MapEntry(k.toString(), v as bool? ?? true),
            ),
          )
        : _defaultVisibility;

    return AdminSettings(
      topics: topics,
      adminRoles: roles,
      moduleVisibility: visibility,
      // Supports both old and new stored field names.
      anthropicApiKey:
          (map['groqApiKey'] ?? map['anthropicApiKey'] ?? '') as String,
      maintenanceMode: map['maintenanceMode'] as bool? ?? false,
      maintenanceMessage:
          map['maintenanceMessage'] as String? ??
          'CoSci is temporarily unavailable while scheduled maintenance is completed. Please try again later.',
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  static AdminSettings get defaults => const AdminSettings(
    topics: _defaultTopics,
    adminRoles: _defaultRoles,
    moduleVisibility: _defaultVisibility,
  );

  Map<String, dynamic> toMap() => {
    'topics': topics,
    'adminRoles': adminRoles,
    'moduleVisibility': moduleVisibility,
    // Save using the new key name.
    'groqApiKey': groqApiKey,
    'maintenanceMode': maintenanceMode,
    'maintenanceMessage': maintenanceMessage,
  };

  AdminSettings copyWith({
    List<String>? topics,
    List<String>? adminRoles,
    Map<String, bool>? moduleVisibility,
    String? anthropicApiKey,
    String? groqApiKey,
    bool? maintenanceMode,
    String? maintenanceMessage,
    DateTime? updatedAt,
  }) {
    return AdminSettings(
      topics: topics ?? this.topics,
      adminRoles: adminRoles ?? this.adminRoles,
      moduleVisibility: moduleVisibility ?? this.moduleVisibility,
      anthropicApiKey: groqApiKey ?? anthropicApiKey ?? this.anthropicApiKey,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage: maintenanceMessage ?? this.maintenanceMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const List<String> _defaultTopics = [
    'Variables',
    'Loops',
    'Functions',
    'Arrays',
    'Strings',
    'Conditionals',
    'OOP',
    'Recursion',
    'File I/O',
    'Data Structures',
  ];

  static const List<String> _defaultRoles = [
    'admin',
    'super_admin',
    'content_manager',
  ];

  static const Map<String, bool> _defaultVisibility = {
    'lessons': true,
    'quizzes': true,
    'puzzles': true,
    'simulations': true,
    'challenges': true,
    'gamification': true,
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
