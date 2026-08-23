import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/login_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/account_verification_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/utils/role_redirect.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/shared/widgets/loading_view.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

/// Protects student routes.
///
/// - Not authenticated → shows [LoginScreen].
/// - Authenticated as admin/super_admin/content_manager → redirects to
///   [AppRoutes.adminHome] so admin users are never shown the student UI.
/// - Authenticated as student/professor → renders [child].
class AuthGuard extends StatefulWidget {
  const AuthGuard({
    super.key,
    required this.child,
    this.allowedRole = 'student',
  });

  final Widget child;
  final String allowedRole;

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const LoadingView(message: 'Checking your session...');
        }

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        final user = authProvider.currentUser!;
        if (user.normalizedRole != widget.allowedRole) {
          // Admin user landed on a student route — redirect to admin panel.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoleRedirect.homeRoute(user),
                (route) => false,
              );
            }
          });
          return const LoadingView(message: 'Opening your workspace...');
        }

        return _MaintenanceGate(child: widget.child);
      },
    );
  }
}

class _MaintenanceGate extends StatefulWidget {
  const _MaintenanceGate({required this.child});
  final Widget child;

  @override
  State<_MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<_MaintenanceGate> {
  Future<Map<String, dynamic>?>? _settingsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsFuture ??= _fetchSettings();
  }

  Future<Map<String, dynamic>?> _fetchSettings() => context
      .read<FirestoreService>()
      .collection('settings')
      .doc('app_settings')
      .get()
      .then((snapshot) => snapshot.data())
      .catchError((_) => null);

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: _settingsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingView(message: 'Checking platform availability...');
      }
      final settings = snapshot.data;
      if (settings?['maintenanceMode'] != true) return widget.child;
      final message = (settings?['maintenanceMessage'] as String?)?.trim();
      return Scaffold(
        backgroundColor: const Color(0xFFF2F6FC),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD8E2EF)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      color: Color(0xFFD97706),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'CoSci is under maintenance',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message?.isNotEmpty == true
                        ? message!
                        : 'Please try again later while scheduled maintenance is completed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _settingsFuture = _fetchSettings();
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Check again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Protects guest-only routes (login, register, etc.).
///
/// - Authenticated → renders [RoleRedirect.buildHome] so the user never
///   sees the login page while already signed in.
/// - Not authenticated → renders [child].
class GuestGuard extends StatelessWidget {
  const GuestGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return RoleRedirect.buildHome(authProvider.currentUser);
        }

        final pendingEmail = authProvider.pendingVerificationEmail;
        if (pendingEmail != null) {
          return AccountVerificationScreen(email: pendingEmail);
        }

        // Keep guest forms mounted while their own submit action is loading.
        // Replacing the form here disposes its State before the awaited auth
        // call can navigate or show feedback.
        return child;
      },
    );
  }
}

class SignedInGuard extends StatelessWidget {
  const SignedInGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const LoadingView(message: 'Checking your session...');
        }
        if (!auth.isAuthenticated) return const LoginScreen();
        return child;
      },
    );
  }
}
