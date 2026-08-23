import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_action_button.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_feedback_banner.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_shell.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key, required this.email});
  final String email;

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  int _resendSeconds = 0;
  Timer? _timer;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AuthProvider>();
      if (provider.verificationEmailSent) {
        _startCooldown();
      }
      if (!provider.takeRegistrationSuccess()) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Registration successful. Verify ${widget.email} to activate your learner account.',
            ),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
    });
  }

  void _startCooldown() {
    _timer?.cancel();
    _resendSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final provider = context.read<AuthProvider>();
    setState(() => _successMessage = null);
    provider.clearError();
    final sent = await provider.resendEmailVerification();
    if (!mounted) return;
    if (sent) {
      setState(() {
        _successMessage =
            'A new verification link was sent. Use the newest email in your inbox.';
      });
      _startCooldown();
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _successMessage = null);
    context.read<AuthProvider>().clearError();
    final verified = await context
        .read<AuthProvider>()
        .checkEmailVerification();
    if (!mounted || !verified) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email verified. You can now sign in.')),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    return AuthShell(
      headerBadge: 'Account verification',
      title: 'Check your email',
      subtitle: 'Verify your email before opening your CoSci workspace.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthFeedbackBanner(
            message: provider.verificationEmailSent
                ? 'Firebase accepted a verification email for ${widget.email.isEmpty ? 'your registered email address' : widget.email}. Check Inbox, Spam, and Junk.'
                : provider.verificationEmailError ??
                      'Your account is ready for verification, but no email has been confirmed as sent. Select Resend verification email below.',
            backgroundColor: provider.verificationEmailSent
                ? colors.primaryContainer
                : colors.errorContainer,
            foregroundColor: provider.verificationEmailSent
                ? colors.onPrimaryContainer
                : colors.onErrorContainer,
            icon: provider.verificationEmailSent
                ? Icons.mark_email_unread_outlined
                : Icons.warning_amber_rounded,
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            AuthFeedbackBanner(
              message: _successMessage!,
              backgroundColor: const Color(0xFFECFDF5),
              foregroundColor: const Color(0xFF065F46),
              icon: Icons.check_circle_outline_rounded,
            ),
          ] else if (provider.errorMessage != null) ...[
            const SizedBox(height: 12),
            AuthFeedbackBanner(
              message: provider.errorMessage!,
              backgroundColor: colors.errorContainer,
              foregroundColor: colors.onErrorContainer,
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: 20),
          const _Instruction(
            number: '1',
            title: 'Open your inbox',
            description:
                'Look for an email from Firebase or CoSci. Delivery may take a few minutes.',
          ),
          const _Instruction(
            number: '2',
            title: 'Select the verification link',
            description:
                'Open the link using the same browser. If it is missing, check Spam or Junk.',
          ),
          const _Instruction(
            number: '3',
            title: 'Return and confirm',
            description:
                'Come back to this page and select “I verified my email.”',
          ),
          const SizedBox(height: 22),
          AuthActionButton(
            label: 'I verified my email',
            isLoading: provider.isLoading,
            onPressed: _checkVerification,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: provider.isLoading || _resendSeconds > 0
                ? null
                : _resend,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _resendSeconds > 0
                  ? 'Resend available in ${_resendSeconds}s'
                  : 'Resend verification email',
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    await context.read<AuthProvider>().signOut();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
            child: const Text('Return to sign in'),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({
    required this.number,
    required this.title,
    required this.description,
  });
  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: const Color(0xFFDBEAFE),
          foregroundColor: const Color(0xFF1D4ED8),
          child: Text(
            number,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
