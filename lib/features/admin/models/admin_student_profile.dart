import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';

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
    final profileXp = _readInt(p['totalXp'] ?? p['points']);
    final progressXp = _readInt(pr['totalXp'] ?? pr['points']);
    final totalXp = profileXp > progressXp ? profileXp : progressXp;
    final storedLevel = _readInt(
      p['currentLevel'] ?? pr['currentLevel'],
      fallback: 1,
    );
    final derivedLevel = GamificationProfile.resolveLevel(totalXp);
    final profileStreak = _readInt(p['streakDays']);
    final progressStreak = _readInt(pr['streakDays']);
    final streakDays = profileStreak > progressStreak
        ? profileStreak
        : progressStreak;
    final profileActivity = _toDateTime(p['lastActivityAt']);
    final progressActivity = _toDateTime(pr['lastActivityAt']);
    final email = _firstText([userMap['email'], p['email']]);
    final displayName = _firstText([
      userMap['displayName'],
      userMap['fullName'],
      userMap['full_name'],
      userMap['name'],
      userMap['idVerifiedName'],
      p['displayName'],
      p['fullName'],
      p['full_name'],
      p['name'],
      p['idVerifiedName'],
    ]);
    return AdminStudentProfile(
      uid: uid,
      email: email,
      displayName: displayName.isNotEmpty ? displayName : _nameFromEmail(email),
      role: userMap['role'] as String? ?? 'student',
      isActive: (userMap['accountStatus'] as String?) == null
          ? userMap['isActive'] as bool? ?? true
          : userMap['accountStatus'] == 'active',
      course: p['course'] as String? ?? 'BSIT',
      yearLevel: p['yearLevel'] as String?,
      photoUrl: p['photoUrl'] as String?,
      totalXp: totalXp,
      currentLevel: storedLevel > derivedLevel ? storedLevel : derivedLevel,
      streakDays: streakDays,
      badgesEarned: _readInt(p['badgesEarned']),
      completedLessons: _readInt(pr['completedLessons']),
      completedQuizzes: _readInt(pr['completedQuizzes']),
      completedPuzzles: _readInt(pr['completedPuzzles']),
      completedChallenges: _readInt(pr['completedChallenges']),
      lastLoginAt: _toDateTime(userMap['lastLoginAt']),
      createdAt: _toDateTime(userMap['createdAt']),
      lastActivityAt: _latestDate(profileActivity, progressActivity),
    );
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _firstText(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'student') return text;
    }
    return '';
  }

  static String _nameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'Unnamed account';
    final words = localPart
        .replaceAll(RegExp(r'\d+$'), '')
        .split(RegExp(r'[._\-]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .toList();
    return words.isEmpty ? 'Unnamed account' : words.join(' ');
  }

  static DateTime? _latestDate(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
