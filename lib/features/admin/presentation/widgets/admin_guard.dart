import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/login_screen.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/shared/widgets/loading_view.dart';

/// Wraps admin screens. Allows only users with role
/// 'admin', 'super_admin', or 'content_manager'.
class AdminGuard extends StatelessWidget {
  const AdminGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const LoadingView(message: 'Checking admin access...');
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        final role = auth.currentUser?.normalizedRole ?? '';
        if (role != 'admin') {
          return _AccessDeniedPage(role: role);
        }

        return child;
      },
    );
  }
}

class _AccessDeniedPage extends StatelessWidget {
  const _AccessDeniedPage({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 56,
                    color: Color(0xFF0E3A8A),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Access Denied',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your account role ("$role") does not have permission to access the Admin Panel.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().signOut();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.startup,
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
