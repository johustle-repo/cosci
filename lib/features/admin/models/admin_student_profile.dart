import 'package:cloud_firestore/cloud_firestore.dart';

/// Combined view of a student used in the admin panel.
/// Merges data from `users`, `user_profiles`, and `progress` collections.
class AdminStudentProfile {
  const AdminStudentProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.course,
    required this.totalXp,
    required this.currentLevel,
    required this.streakDays,
    required this.badgesEarned,
    required this.completedLessons,
    required this.completedQuizzes,
    required this.completedPuzzles,
    required this.completedChallenges,
    this.yearLevel,
    this.photoUrl,
    this.lastLoginAt,
    this.createdAt,
    this.lastActivityAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String role;
  String get normalizedRole {
    final value = role.toLowerCase();
    return const {'professor', 'teacher', 'faculty'}.contains(value)
        ? 'instructor'
        : value;
  }

  final bool isActive;
  final String course;
  final int totalXp;
  final int currentLevel;
  final int streakDays;
  final int badgesEarned;
  final int completedLessons;
  final int completedQuizzes;
  final int completedPuzzles;
  final int completedChallenges;
  final String? yearLevel;
  final String? photoUrl;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;

  AdminStudentProfile copyWith({bool? isActive, String? role}) {
    return AdminStudentProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      course: course,
      totalXp: totalXp,
      currentLevel: currentLevel,
      streakDays: streakDays,
      badgesEarned: badgesEarned,
      completedLessons: completedLessons,
      completedQuizzes: completedQuizzes,
      completedPuzzles: completedPuzzles,
      completedChallenges: completedChallenges,
      yearLevel: yearLevel,
      photoUrl: photoUrl,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
    );
  }

  bool get hasCompleteAcademicProfile =>
      normalizedRole != 'student' ||
      (email.isNotEmpty &&
          displayName.trim().isNotEmpty &&
          course.trim().isNotEmpty &&
          yearLevel != null &&
          yearLevel!.trim().isNotEmpty);

  String? get profileWarning {
    if (email.isEmpty) return 'Missing email address';
    if (displayName.trim().isEmpty || displayName == 'Student') {
      return 'Missing learner name';
    }
    if (normalizedRole == 'student' &&
        (yearLevel == null || yearLevel!.trim().isEmpty)) {
      return 'Missing year level';
    }
    return null;
  }

  /// Build from user doc + profile doc + progress doc (all merged).
  factory AdminStudentProfile.fromMaps({
    required String uid,
    required Map<String, dynamic> userMap,
    Map<String, dynamic>? profileMap,
    Map<String, dynamic>? progressMap,
  }) {
    final p = profileMap ?? {};
    final pr = progressMap ?? {};
    return AdminStudentProfile(
      uid: uid,
      email: userMap['email'] as String? ?? '',
      displayName:
          userMap['displayName'] as String? ??
          p['displayName'] as String? ??
          'Student',
      role: userMap['role'] as String? ?? 'student',
      isActive: (userMap['accountStatus'] as String?) == null
          ? userMap['isActive'] as bool? ?? true
          : userMap['accountStatus'] == 'active',
      course: p['course'] as String? ?? 'BSIT',
      yearLevel: p['yearLevel'] as String?,
      photoUrl: p['photoUrl'] as String?,
      totalXp: (p['totalXp'] as num?)?.toInt() ?? 0,
      currentLevel: (p['currentLevel'] as num?)?.toInt() ?? 1,
      streakDays: (p['streakDays'] as num?)?.toInt() ?? 0,
      badgesEarned: (p['badgesEarned'] as num?)?.toInt() ?? 0,
      completedLessons: (pr['completedLessons'] as num?)?.toInt() ?? 0,
      completedQuizzes: (pr['completedQuizzes'] as num?)?.toInt() ?? 0,
      completedPuzzles: (pr['completedPuzzles'] as num?)?.toInt() ?? 0,
      completedChallenges: (pr['completedChallenges'] as num?)?.toInt() ?? 0,
      lastLoginAt: _toDateTime(userMap['lastLoginAt']),
      createdAt: _toDateTime(userMap['createdAt']),
      lastActivityAt: _toDateTime(p['lastActivityAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
