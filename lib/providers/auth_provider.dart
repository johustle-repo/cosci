import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/models/app_user.dart';
import 'package:pseudocode_apk/services/auth_service.dart';

enum AuthStatus { initializing, authenticated, unauthenticated, loading, error }

class AuthProvider extends ChangeNotifier {
  AuthService? _authService;
  StreamSubscription<AppUser?>? _authSubscription;
  Timer? _roleRefreshTimer;
  AppUser? _currentUser;
  AuthStatus _status = AuthStatus.initializing;
  String? _errorMessage;
  String? _pendingVerificationEmail;
  bool _registrationJustCompleted = false;
  bool _isAttached = false;
  bool _notificationQueued = false;

  AppUser? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  bool takeRegistrationSuccess() {
    final value = _registrationJustCompleted;
    _registrationJustCompleted = false;
    return value;
  }

  bool get isAuthenticated => _currentUser != null;
  bool get verificationEmailSent =>
      _authService?.lastVerificationEmailSent ?? false;
  String? get verificationEmailError {
    final error = _authService?.lastVerificationEmailError;
    return error == null ? null : _mapFirebaseAuthError(error);
  }

  bool get isLoading =>
      _status == AuthStatus.initializing || _status == AuthStatus.loading;

  void attach(AuthService authService) {
    if (identical(_authService, authService)) {
      return;
    }

    _authService = authService;
    _isAttached = false;
  }

  Future<void> initialize() async {
    if (_authService == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Authentication service is not available.';
      _notifySafely();
      return;
    }

    _status = AuthStatus.initializing;
    _errorMessage = null;
    _notifySafely();

    try {
      await _authService!.configureSessionPersistence();
      // Resolve the persisted session once. Previously the auth listener and
      // this explicit lookup both fetched the same Firestore profile during
      // startup, doubling the critical-path network work.
      _currentUser = await _authService!.getCurrentUser();
      _syncPendingVerificationSession();
      await _attachAuthListenerIfNeeded(skipInitialEvent: true);
      _roleRefreshTimer ??= Timer.periodic(
        const Duration(minutes: 1),
        (_) => refreshSession(),
      );
      _status = _currentUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } on FirebaseAuthException catch (error) {
      if (_isRecoverableStartupError(error)) {
        // A stale browser session can be rate-limited while Firebase tries to
        // restore it. Do not lock the whole application behind the startup
        // error screen; clear the local session and let the user sign in later.
        try {
          await _authService!.signOut();
        } catch (_) {}
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.error;
        _errorMessage = _mapFirebaseAuthError(error);
      }
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Unable to initialize authentication.';
    } finally {
      _notifySafely();
    }
  }

  Future<void> _attachAuthListenerIfNeeded({
    bool skipInitialEvent = false,
  }) async {
    if (_authService == null || _isAttached) {
      return;
    }

    await _authSubscription?.cancel();
    final authChanges = _authService!.authStateChanges();
    _authSubscription = (skipInitialEvent ? authChanges.skip(1) : authChanges)
        .listen(
          (appUser) {
            _syncPendingVerificationSession();
            final nextStatus = appUser == null
                ? AuthStatus.unauthenticated
                : AuthStatus.authenticated;

            final didChange =
                _currentUser?.uid != appUser?.uid ||
                _currentUser?.email != appUser?.email ||
                _currentUser?.displayName != appUser?.displayName ||
                _status != nextStatus ||
                _errorMessage != null;

            _currentUser = appUser;
            _status = nextStatus;
            _errorMessage = null;

            if (didChange) {
              _notifySafely();
            }
          },
          onError: (Object error) {
            _currentUser = null;
            if (error is FirebaseAuthException &&
                _isRecoverableStartupError(error)) {
              _status = AuthStatus.unauthenticated;
              _errorMessage = null;
            } else {
              _status = AuthStatus.error;
              _errorMessage = 'Unable to restore your session right now.';
            }
            _notifySafely();
          },
        );
    _isAttached = true;
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_authService == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Authentication service is not available.';
      _notifySafely();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      _currentUser = await _authService!.signIn(
        email: email,
        password: password,
      );
      _pendingVerificationEmail = null;
      _status = AuthStatus.authenticated;
      return true;
    } on FirebaseAuthException catch (error) {
      _currentUser = null;
      if (error.code == 'email-not-verified') {
        _pendingVerificationEmail = email.trim().toLowerCase();
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
      } else {
        _status = AuthStatus.error;
        _errorMessage = _mapFirebaseAuthError(error);
      }
      return false;
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.error;
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _notifySafely();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
    required String program,
    required String yearLevel,
  }) async {
    if (_authService == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Authentication service is not available.';
      _notifySafely();
      return false;
    }
    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      await _authService!.register(
        email: email,
        password: password,
        displayName: displayName,
        program: program,
        yearLevel: yearLevel,
      );
      _currentUser = null;
      _pendingVerificationEmail = email.trim().toLowerCase();
      _registrationJustCompleted = true;
      _status = AuthStatus.unauthenticated;
      return true;
    } on FirebaseAuthException catch (error) {
      final normalizedEmail = email.trim().toLowerCase();
      final persistedPendingEmail = _authService!.pendingVerificationEmail;
      if (persistedPendingEmail == normalizedEmail) {
        // Firebase may emit email-already-in-use or temporarily throttle a
        // retry after the account was already created. The persisted,
        // unverified Firebase session is authoritative: keep the learner on
        // the verification flow instead of recreating the registration form.
        _currentUser = null;
        _pendingVerificationEmail = persistedPendingEmail;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        return true;
      }
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
      return false;
    } on FirebaseException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = switch (error.code) {
        'permission-denied' =>
          'Firebase created the sign-in request, but Firestore blocked the learner profile. Deploy the current Firestore rules and try again.',
        'unavailable' =>
          'Firestore is temporarily unavailable. Check your connection and try again.',
        _ => error.message ?? 'Unable to save the learner profile.',
      };
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Unable to create your account right now.';
      return false;
    } finally {
      _notifySafely();
    }
  }

  void _syncPendingVerificationSession() {
    final persistedEmail = _authService?.pendingVerificationEmail;
    if (persistedEmail != null) {
      _pendingVerificationEmail = persistedEmail;
    } else if (_currentUser != null) {
      _pendingVerificationEmail = null;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    if (_authService == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Authentication service is not available.';
      _notifySafely();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();

    try {
      await _authService!.sendPasswordResetEmail(email: email);
      _status = _currentUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      return true;
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Unable to send reset instructions right now.';
      return false;
    } finally {
      _notifySafely();
    }
  }

  Future<bool> resendEmailVerification() async {
    if (_authService == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      await _authService!.resendCurrentUserVerification();
      _status = AuthStatus.unauthenticated;
      return true;
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
      return false;
    } finally {
      _notifySafely();
    }
  }

  Future<bool> checkEmailVerification() async {
    if (_authService == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      final verified = await _authService!.refreshEmailVerification();
      if (verified) {
        _pendingVerificationEmail = null;
        _currentUser = await _authService!.getCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage =
            'Your email is not verified yet. Open the link in your inbox, then check again.';
      }
      return verified;
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
      return false;
    } finally {
      _notifySafely();
    }
  }

  Future<void> signOut() async {
    if (_authService == null) {
      return;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();

    try {
      await _authService!.signOut();
      _currentUser = null;
      _pendingVerificationEmail = null;
      _registrationJustCompleted = false;
      _status = AuthStatus.unauthenticated;
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Unable to sign out right now.';
    } finally {
      _notifySafely();
    }
  }

  Future<void> refreshSession() async {
    if (_authService == null || _currentUser == null) return;
    try {
      final refreshed = await _authService!.getCurrentUser();
      if (refreshed == null) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _currentUser = refreshed;
        _status = AuthStatus.authenticated;
      }
    } on FirebaseAuthException catch (error) {
      await _authService!.signOut();
      _currentUser = null;
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
    }
    _notifySafely();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _performVoidAction(
      () => _authService!.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  Future<bool> updateOwnProfile({
    required String displayName,
    required String program,
    required String yearLevel,
  }) async {
    return _performAuthAction(
      () => _authService!.updateOwnProfile(
        displayName: displayName,
        program: program,
        yearLevel: yearLevel,
      ),
    );
  }

  Future<bool> _performVoidAction(Future<void> Function() action) async {
    if (_authService == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();
    try {
      await action();
      _status = AuthStatus.authenticated;
      return true;
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
      return false;
    } finally {
      _notifySafely();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _currentUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    }
    _notifySafely();
  }

  Future<bool> _performAuthAction(Future<AppUser> Function() action) async {
    if (_authService == null) {
      _status = AuthStatus.error;
      _errorMessage = 'Authentication service is not available.';
      _notifySafely();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _notifySafely();

    try {
      _currentUser = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on FirebaseAuthException catch (error) {
      _status = AuthStatus.error;
      _errorMessage = _mapFirebaseAuthError(error);
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _notifySafely();
    }
  }

  void _notifySafely() {
    final binding = SchedulerBinding.instance;
    final phase = binding.schedulerPhase;

    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) {
        notifyListeners();
      }
      return;
    }

    if (_notificationQueued) {
      return;
    }

    _notificationQueued = true;
    binding.addPostFrameCallback((_) {
      _notificationQueued = false;
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'missing-email':
        return 'Enter your email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'That email address is already registered.';
      case 'weak-password':
        return 'Use at least 12 characters with letters and numbers.';
      case 'email-not-verified':
      case 'verification-sent':
      case 'profile-missing':
      case 'unsupported-role':
      case 'account-suspended':
      case 'account-archived':
        return error.message ?? 'This account cannot sign in.';
      case 'verification-session-expired':
        return error.message ?? 'Sign in to request another verification link.';
      case 'verification-send-failed':
        return 'Firebase could not send the verification email. Check your connection and try Resend.';
      case 'network-request-failed':
        return 'Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts were made. Please wait and try again.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  bool _isRecoverableStartupError(FirebaseAuthException error) => const {
    'too-many-requests',
    'network-request-failed',
    'user-token-expired',
    'invalid-user-token',
    'user-not-found',
  }.contains(error.code);

  @override
  void dispose() {
    _roleRefreshTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
