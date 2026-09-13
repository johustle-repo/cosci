import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/get_started_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/utils/role_redirect.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/shared/widgets/loading_view.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/login_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/account_verification_screen.dart';
import 'package:pseudocode_apk/features/auth/services/onboarding_service.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  late Future<void> _startupFuture;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // SharedPreferences and Firebase Auth are independent, so do not make one
    // wait for the other on the startup critical path.
    final onboardingFuture = OnboardingService.shouldShow();
    try {
      await context.read<AuthProvider>().initialize();
    } catch (_) {
      // A service initialization problem must not replace the entire app with
      // a fatal startup card. Authentication screens provide scoped feedback
      // if a user action cannot be completed.
    }
    _showOnboarding = await onboardingFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView(message: 'Checking your session...');
        }

        return Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const LoadingView(message: 'Restoring your account...');
            }

            if (authProvider.isAuthenticated) {
              return RoleRedirect.buildHome(authProvider.currentUser);
            }

            final pendingEmail = authProvider.pendingVerificationEmail;
            if (pendingEmail != null) {
              return AccountVerificationScreen(email: pendingEmail);
            }

            // Authentication failures (for example, an incorrect password)
            // are normal user-facing form errors. LoginScreen reads the
            // provider's errorMessage and displays it in its feedback banner.
            return _showOnboarding
                ? const GetStartedScreen()
                : const LoginScreen();
          },
        );
      },
    );
  }
}
