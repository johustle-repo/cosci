import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/auth/presentation/utils/auth_validators.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_action_button.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_feedback_banner.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_form_footer.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_shell.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_clearError)
      ..dispose();
    super.dispose();
  }

  void _clearError() {
    context.read<AuthProvider>().clearError();
  }

  Future<void> _submit() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      return;
    }

    final success = await context.read<AuthProvider>().sendPasswordResetEmail(
      email: _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _emailSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset instructions have been sent.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return AuthShell(
      headerBadge: 'Account recovery',
      title: 'Reset your password',
      subtitle: 'Enter your email and we will send a reset link.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_emailSent) ...[
              AuthFeedbackBanner(
                message:
                    'Check your inbox for the password reset link. If you do not see it, check your spam folder.',
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                icon: Icons.mark_email_read_outlined,
              ),
              const SizedBox(height: 16),
            ] else if (authProvider.errorMessage != null) ...[
              AuthFeedbackBanner(
                message: authProvider.errorMessage!,
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                icon: Icons.error_outline,
              ),
              const SizedBox(height: 16),
            ],
            AuthTextField(
              controller: _emailController,
              label: 'Email address',
              hintText: 'student@psu.edu.ph',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: AuthValidators.validateEmail,
            ),
            const SizedBox(height: 22),
            AuthActionButton(
              label: 'Send reset link',
              isLoading: authProvider.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            AuthFormFooter(
              prompt: 'Remembered your password?',
              actionLabel: 'Back to sign in',
              onTap: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
