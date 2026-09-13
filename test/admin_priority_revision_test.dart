import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/features/admin/models/admin_activity_log.dart';
import 'package:pseudocode_apk/features/admin/models/admin_announcement.dart';
import 'package:pseudocode_apk/features/admin/models/admin_daily_challenge.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_profile.dart';
import 'package:pseudocode_apk/features/admin/models/admin_simulation.dart';

void main() {
  group('admin priority revisions', () {
    test('legacy ISO activity timestamps remain readable', () {
      final log = AdminActivityLog.fromMap('log-1', {
        'timestamp': '2026-08-13T10:30:00.000Z',
        'adminUid': 'admin-1',
        'adminEmail': 'admin@psu.edu.ph',
        'actionType': 'update',
        'targetModule': 'settings',
        'description': 'Updated settings',
      });

      expect(log.timestamp, DateTime.utc(2026, 8, 13, 10, 30));
    });

    test('legacy createdAt timestamps are used as a fallback', () {
      final createdAt = Timestamp.fromDate(DateTime.utc(2026, 8, 13));
      final log = AdminActivityLog.fromMap('log-2', {
        'createdAt': createdAt,
        'adminUid': 'admin-1',
        'adminEmail': 'admin@psu.edu.ph',
        'actionType': 'update',
        'targetModule': 'users',
        'description': 'Updated user',
      });

      expect(log.timestamp, createdAt.toDate());
    });

    test('incomplete learner profile exposes a useful warning', () {
      final learner = AdminStudentProfile.fromMaps(
        uid: 'student-1',
        userMap: {
          'email': 'student@psu.edu.ph',
          'displayName': 'Learner',
          'role': 'student',
        },
      );

      expect(learner.hasCompleteAcademicProfile, isFalse);
      expect(learner.profileWarning, 'Missing year level');
    });

    test('legacy announcement audiences normalize to dropdown-safe values', () {
      final announcement = AdminAnnouncement.fromMap('a1', {
        'title': 'Class notice',
        'message': 'Compiler activity is available.',
        'targetAudience': 'Instructor',
        'isPublished': true,
      });

      expect(announcement.targetAudience, 'professors');
      expect(announcement.isReadyToPublish, isTrue);
    });

    test('daily challenge activation requires a linked learning activity', () {
      final challenge = AdminDailyChallenge.fromMap('c1', {
        'title': 'Debug today',
        'description': 'Find and correct the syntax error.',
        'challengeType': 'QUIZ',
        'status': 'ACTIVE',
        'date': '2026-08-13',
      });

      expect(challenge.challengeType, 'quiz');
      expect(challenge.status, 'active');
      expect(challenge.isReadyToActivate, isFalse);
    });

    test('status updates can preserve the complete learner profile', () {
      final learner = AdminStudentProfile.fromMaps(
        uid: 'student-2',
        userMap: {
          'email': 'learner@psu.edu.ph',
          'displayName': 'Learner Two',
          'role': 'student',
        },
        profileMap: {
          'course': 'BS Computer Science',
          'yearLevel': '2nd Year',
          'totalXp': 180,
          'streakDays': 4,
        },
      );

      final disabled = learner.copyWith(isActive: false);
      expect(disabled.isActive, isFalse);
      expect(disabled.course, learner.course);
      expect(disabled.yearLevel, learner.yearLevel);
      expect(disabled.totalXp, learner.totalXp);
      expect(disabled.streakDays, learner.streakDays);
    });

    test('legacy simulation options normalize and expose readiness gaps', () {
      final simulation = AdminSimulation.fromMap('s1', {
        'title': 'Loop tracing',
        'topic': 'Loops',
        'language': 'js',
        'difficulty': 'advanced',
        'errorFocus': 'syntax error',
      });

      expect(simulation.language, 'JavaScript');
      expect(simulation.difficulty, 'Hard');
      expect(simulation.errorFocus, 'Syntax');
      expect(simulation.isReadyToPublish, isFalse);
      expect(simulation.readinessIssues, contains('compiler test cases'));
    });
  });
}
