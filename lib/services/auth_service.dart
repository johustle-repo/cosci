import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pseudocode_apk/models/app_user.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

class AuthService {
  AuthService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService;
  bool _registrationInProgress = false;
  bool _lastVerificationEmailSent = false;
  FirebaseAuthException? _lastVerificationEmailError;

  bool get lastVerificationEmailSent => _lastVerificationEmailSent;
  FirebaseAuthException? get lastVerificationEmailError =>
      _lastVerificationEmailError;

  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap(_resolveAppUser);
  }

  Future<void> configureSessionPersistence() async {
    if (!kIsWeb) {
      return;
    }

    await _firebaseAuth.setPersistence(Persistence.LOCAL);
  }

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  String? get pendingVerificationEmail {
    final user = currentFirebaseUser;
    if (user == null || user.emailVerified) return null;
    return user.email?.trim().toLowerCase();
  }

  Future<AppUser?> getCurrentUser() async {
    return _resolveAppUser(currentFirebaseUser);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user session was returned after sign in.',
      );
    }

    if (!firebaseUser.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Verify your email before signing in.',
      );
    }

    final existingUser = await _firestoreService.fetchAppUser(firebaseUser.uid);
    if (existingUser == null) {
      await _firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: 'profile-missing',
        message: 'Your CoSci profile is missing. Contact the administrator.',
      );
    }
    _validateAccess(existingUser);
    await _firestoreService.updateLastLogin(firebaseUser.uid);
    return await _resolveAppUser(firebaseUser) ?? existingUser;
  }

  Future<AppUser> register({
    required String email,
    required String password,
    String? displayName,
    required String program,
    required String yearLevel,
  }) async {
    _registrationInProgress = true;
    _lastVerificationEmailSent = false;
    _lastVerificationEmailError = null;
    try {
      UserCredential credential;
      try {
        credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        return _resumeUnverifiedRegistration(
          email: email,
          password: password,
          displayName: displayName,
          program: program,
          yearLevel: yearLevel,
        );
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user session was returned after registration.',
        );
      }

      if (displayName != null && displayName.trim().isNotEmpty) {
        await firebaseUser.updateDisplayName(displayName.trim());
      }

      final normalizedDisplayName = displayName?.trim();
      final appUser = _fallbackAppUser(firebaseUser).copyWith(
        displayName:
            normalizedDisplayName == null || normalizedDisplayName.isEmpty
            ? null
            : normalizedDisplayName,
        program: program,
        yearLevel: yearLevel,
      );

      try {
        await _firestoreService.createUserDocuments(
          user: appUser,
          displayName: appUser.displayName,
        );
      } catch (_) {
        // Do not leave an Auth-only account that can neither register again nor
        // access CoSci when the required profile transaction fails.
        try {
          await firebaseUser.delete();
        } catch (_) {}
        rethrow;
      }

      // The account and profile are already valid at this point. Email sending
      // can be throttled independently, so let the verification screen offer a
      // retry instead of reporting the whole registration as failed.
      await _trySendVerificationEmail(firebaseUser);
      return appUser;
    } finally {
      _registrationInProgress = false;
    }
  }

  Future<AppUser> _resumeUnverifiedRegistration({
    required String email,
    required String password,
    required String? displayName,
    required String program,
    required String yearLevel,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    if (firebaseUser.emailVerified) {
      await _firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'This account is already verified. Sign in instead.',
      );
    }

    final normalizedName = displayName?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      await firebaseUser.updateDisplayName(normalizedName);
    }
    var appUser = await _firestoreService.fetchAppUser(firebaseUser.uid);
    appUser ??= _fallbackAppUser(firebaseUser).copyWith(
      displayName: normalizedName,
      program: program,
      yearLevel: yearLevel,
    );
    if (appUser.uid.isEmpty ||
        appUser.program == null ||
        appUser.yearLevel == null) {
      appUser = appUser.copyWith(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: normalizedName,
        program: program,
        yearLevel: yearLevel,
      );
      await _firestoreService.createUserDocuments(
        user: appUser,
        displayName: appUser.displayName,
      );
    }
    await _trySendVerificationEmail(firebaseUser);
    return appUser;
  }

  Future<void> _trySendVerificationEmail(User firebaseUser) async {
    _lastVerificationEmailSent = false;
    _lastVerificationEmailError = null;
    try {
      await firebaseUser.sendEmailVerification();
      _lastVerificationEmailSent = true;
    } on FirebaseAuthException catch (error) {
      _lastVerificationEmailError = error;
    } catch (error) {
      _lastVerificationEmailError = FirebaseAuthException(
        code: 'verification-send-failed',
        message: error.toString(),
      );
    }
  }

  Future<void> resendCurrentUserVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'verification-session-expired',
        message:
            'Your verification session expired. Sign in to send a new link.',
      );
    }
    await user.reload();
    final refreshed = _firebaseAuth.currentUser;
    if (refreshed?.emailVerified ?? false) return;
    await refreshed!.sendEmailVerification();
    _lastVerificationEmailSent = true;
    _lastVerificationEmailError = null;
  }

  Future<bool> refreshEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _firebaseAuth.currentUser?.emailVerified ?? false;
    if (verified) await _firebaseAuth.signOut();
    return verified;
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<AppUser?> _resolveAppUser(User? firebaseUser) async {
    if (firebaseUser == null || firebaseUser.email == null) {
      return null;
    }

    final firestoreUser = await _firestoreService.fetchAppUser(
      firebaseUser.uid,
    );
    if (firestoreUser == null) {
      if (_registrationInProgress) return null;
      await _firebaseAuth.signOut();
      return null;
    }
    if (!firebaseUser.emailVerified) return null;
    _validateAccess(firestoreUser);
    return firestoreUser;
  }

  void _validateAccess(AppUser user) {
    if (!user.isActive) {
      throw FirebaseAuthException(
        code: 'account-${user.normalizedAccountStatus}',
        message:
            'This account is ${user.normalizedAccountStatus}. Contact the administrator.',
      );
    }
    if (!const {
      'student',
      'instructor',
      'admin',
    }.contains(user.normalizedRole)) {
      throw FirebaseAuthException(
        code: 'unsupported-role',
        message: 'This account has an unsupported role.',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentFirebaseUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: currentPassword),
    );
    await user.updatePassword(newPassword);
  }

  Future<AppUser> updateOwnProfile({
    required String displayName,
    required String program,
    required String yearLevel,
  }) async {
    final user = currentFirebaseUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    await _firestoreService.updateOwnProfile(
      uid: user.uid,
      displayName: displayName,
      program: program,
      yearLevel: yearLevel,
    );
    await user.updateDisplayName(displayName.trim());
    return (await _resolveAppUser(user))!;
  }

  AppUser _fallbackAppUser(User firebaseUser) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }
}
