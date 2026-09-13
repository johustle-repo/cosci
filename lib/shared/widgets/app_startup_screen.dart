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
  const AppStartupScreen({super.key, this.startupError});

  final String? startupError;

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
    if (widget.startupError != null) {
      return;
    }

    // SharedPreferences and Firebase Auth are independent, so do not make one
    // wait for the other on the startup critical path.
    final onboardingFuture = OnboardingService.shouldShow();
    await context.read<AuthProvider>().initialize();
    _showOnboarding = await onboardingFuture;
  }

  void _retryStartup() {
    setState(() {
      _startupFuture = _initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView(message: 'Checking your session...');
        }

        final startupError = widget.startupError ?? snapshot.error?.toString();
        if (startupError != null) {
          return _StartupErrorView(
            message: startupError,
            onRetry: _retryStartup,
          );
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
            // Only failures thrown by _initializeAuth above belong on the
            // fatal startup recovery screen.
            return _showOnboarding
                ? const GetStartedScreen()
                : const LoginScreen();
          },
        );
      },
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CoSci could not finish starting',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A required service did not initialize. Fully restart the app after adding or updating Flutter plugins, then try again.',
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry startup'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
