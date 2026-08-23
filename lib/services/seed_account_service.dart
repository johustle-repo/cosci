import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pseudocode_apk/firebase_options.dart';
import 'package:pseudocode_apk/models/app_user.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

class SeedAccountService {
  SeedAccountService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  static const List<SeedAccountSpec> defaultAccounts = [
    SeedAccountSpec(
      role: 'admin',
      email: 'admin@psu-educode.app',
      displayName: 'PSU Admin',
      bio: 'System administrator account for CoSci.',
      yearLevel: 'Faculty',
      course: 'Administration',
      startingPoints: 500,
      streakDays: 30,
    ),
    SeedAccountSpec(
      role: 'admin',
      email: 'admin@psu.edu.ph',
      displayName: 'PSU Admin',
      bio: 'System administrator account for CoSci.',
      yearLevel: 'Faculty',
      course: 'Administration',
      startingPoints: 500,
      streakDays: 30,
    ),
    SeedAccountSpec(
      role: 'student',
      email: 'student@psu-educode.app',
      displayName: 'Demo Student',
      bio: 'Student seed account for testing the learner experience.',
      yearLevel: '1st Year',
      course: 'BS Information Technology',
      startingPoints: 120,
      streakDays: 5,
    ),
    SeedAccountSpec(
      role: 'instructor',
      email: 'professor@psu-educode.app',
      displayName: 'Professor Account',
      bio: 'Instructor seed account for classroom demonstrations.',
      yearLevel: 'Faculty',
      course: 'Computer Science',
      startingPoints: 250,
      streakDays: 12,
    ),
  ];

  Future<List<SeedAccountResult>> seedAccounts({
    required Map<String, String> passwordsByRole,
  }) async {
    final results = <SeedAccountResult>[];

    for (final spec in defaultAccounts) {
      final password = passwordsByRole[spec.role];
      if (password == null || password.isEmpty) {
        results.add(
          SeedAccountResult(
            role: spec.role,
            email: spec.email,
            status: SeedAccountStatus.failed,
            message: 'Missing password for ${spec.role}.',
          ),
        );
        continue;
      }

      results.add(await _seedSingleAccount(spec: spec, password: password));
    }

    return results;
  }

  Future<SeedAccountResult> _seedSingleAccount({
    required SeedAccountSpec spec,
    required String password,
  }) async {
    final appName =
        'seed-${spec.role}-${DateTime.now().millisecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instanceFor(app: secondaryApp);

    try {
      var status = SeedAccountStatus.created;
      UserCredential credential;

      try {
        credential = await auth.createUserWithEmailAndPassword(
          email: spec.email,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') {
          rethrow;
        }

        credential = await auth.signInWithEmailAndPassword(
          email: spec.email,
          password: password,
        );
        status = SeedAccountStatus.updated;
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return SeedAccountResult(
          role: spec.role,
          email: spec.email,
          status: SeedAccountStatus.failed,
          message: 'No Firebase user was returned for ${spec.role}.',
        );
      }

      if ((firebaseUser.displayName ?? '') != spec.displayName) {
        await firebaseUser.updateDisplayName(spec.displayName);
      }

      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: spec.email,
        displayName: spec.displayName,
        role: spec.role,
      );

      await _firestoreService.createUserDocuments(
        user: appUser,
        displayName: spec.displayName,
      );

      await _firestoreService.userDocument(firebaseUser.uid).set({
        'role': spec.role,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestoreService.userProfileDocument(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'displayName': spec.displayName,
        'bio': spec.bio,
        'course': spec.course,
        'yearLevel': spec.yearLevel,
        'points': spec.startingPoints,
        'streakDays': spec.streakDays,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestoreService.collection('progress').doc(firebaseUser.uid).set({
        'completedLessons': 0,
        'completedQuizzes': 0,
        'completedPuzzles': 0,
        'points': spec.startingPoints,
        'streakDays': spec.streakDays,
      }, SetOptions(merge: true));

      return SeedAccountResult(
        role: spec.role,
        email: spec.email,
        status: status,
        message: status == SeedAccountStatus.created
            ? 'Created successfully.'
            : 'Already existed and profile data was refreshed.',
      );
    } on FirebaseAuthException catch (error) {
      return SeedAccountResult(
        role: spec.role,
        email: spec.email,
        status: SeedAccountStatus.failed,
        message: error.message ?? error.code,
      );
    } catch (error) {
      return SeedAccountResult(
        role: spec.role,
        email: spec.email,
        status: SeedAccountStatus.failed,
        message: error.toString(),
      );
    } finally {
      await auth.signOut();
      await secondaryApp.delete();
    }
  }
}

class SeedAccountSpec {
  const SeedAccountSpec({
    required this.role,
    required this.email,
    required this.displayName,
    required this.bio,
    required this.yearLevel,
    required this.course,
    required this.startingPoints,
    required this.streakDays,
  });

  final String role;
  final String email;
  final String displayName;
  final String bio;
  final String yearLevel;
  final String course;
  final int startingPoints;
  final int streakDays;
}

enum SeedAccountStatus { created, updated, failed }

class SeedAccountResult {
  const SeedAccountResult({
    required this.role,
    required this.email,
    required this.status,
    required this.message,
  });

  final String role;
  final String email;
  final SeedAccountStatus status;
  final String message;
}
