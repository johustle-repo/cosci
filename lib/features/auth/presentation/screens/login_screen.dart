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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_clearError)
      ..dispose();
    _passwordController
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

    final success = await context.read<AuthProvider>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Welcome back to CoSci.')));
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.startup,
        (route) => false,
      );
      return;
    }

    final pendingEmail = context.read<AuthProvider>().pendingVerificationEmail;
    if (pendingEmail != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Your account needs email verification. No additional email was sent automatically.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.verifyEmail,
        (route) => false,
        arguments: pendingEmail,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return AuthShell(
      headerBadge: 'Learner access',
      title: 'Welcome back',
      subtitle: 'Sign in to continue your lessons, quizzes, and coding work.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (authProvider.errorMessage != null) ...[
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
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateEmail,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              onSuffixTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: AuthValidators.validatePassword,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        Navigator.pushNamed(context, AppRoutes.forgotPassword);
                      },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 14),
            AuthActionButton(
              label: 'Sign in',
              isLoading: authProvider.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            AuthFormFooter(
              prompt: 'New to CoSci?',
              actionLabel: 'Create an account',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.register);
              },
            ),
          ],
        ),
      ),
    );
  }
}
