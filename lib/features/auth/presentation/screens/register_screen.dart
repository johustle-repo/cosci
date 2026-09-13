import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/account_verification_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/utils/auth_validators.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_action_button.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_feedback_banner.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_form_footer.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_shell.dart';
import 'package:pseudocode_apk/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _program = 'BS Information Technology';
  String _yearLevel = '1st Year';

  PasswordStrength get _passwordStrength =>
      AuthValidators.evaluatePasswordStrength(_passwordController.text);

  @override
  void initState() {
    super.initState();
    _displayNameController.addListener(_clearError);
    _emailController.addListener(_clearError);
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_clearError);
  }

  @override
  void dispose() {
    _displayNameController
      ..removeListener(_clearError)
      ..dispose();
    _emailController
      ..removeListener(_clearError)
      ..dispose();
    _passwordController
      ..removeListener(_onPasswordChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_clearError)
      ..dispose();
    super.dispose();
  }

  void _clearError() {
    context.read<AuthProvider>().clearError();
  }

  void _onPasswordChanged() {
    _clearError();
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final currentState = _formKey.currentState;
    if (currentState == null || !currentState.validate()) {
      _showRegistrationSnackBar(
        'Please correct the highlighted registration fields.',
        isError: true,
      );
      return;
    }

    final registeredEmail = _emailController.text.trim();

    final success = await context.read<AuthProvider>().register(
      email: registeredEmail,
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
      program: _program,
      yearLevel: _yearLevel,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      final authProvider = context.read<AuthProvider>();
      _showRegistrationSnackBar(
        authProvider.verificationEmailSent
            ? 'Account created. Check $registeredEmail for the verification link.'
            : 'Account created. Use Resend on the verification page to request the email.',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.verifyEmail),
          builder: (_) => AccountVerificationScreen(email: registeredEmail),
        ),
        (route) => false,
      );
      return;
    }

    _showRegistrationSnackBar(
      context.read<AuthProvider>().errorMessage ??
          'Registration could not be completed. Please try again.',
      isError: true,
    );
  }

  void _showRegistrationSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError
              ? const Color(0xFFB42318)
              : const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return AuthShell(
      headerBadge: 'New learner',
      title: 'Create your account',
      subtitle:
          'Create an academic workspace for lessons, progress, and coding practice.',
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
              controller: _displayNameController,
              label: 'Full name',
              hintText: 'Juan Dela Cruz',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validateDisplayName,
            ),
            const SizedBox(height: 16),
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
            DropdownButtonFormField<String>(
              initialValue: _program,
              isExpanded: true,
              dropdownColor: Colors.white,
              elevation: 10,
              itemHeight: 52,
              menuMaxHeight: 220,
              borderRadius: BorderRadius.circular(16),
              decoration: _dropdownDecoration('Program', Icons.school_outlined),
              items:
                  const [
                        'BS Information Technology',
                        'BS Computer Science',
                        'BS Mathematics-CIT',
                      ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: authProvider.isLoading
                  ? null
                  : (value) => setState(() => _program = value ?? _program),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _yearLevel,
              isExpanded: true,
              dropdownColor: Colors.white,
              elevation: 10,
              itemHeight: 52,
              menuMaxHeight: 160,
              borderRadius: BorderRadius.circular(16),
              decoration: _dropdownDecoration(
                'Year level',
                Icons.calendar_today_outlined,
              ),
              items: const ['1st Year', '2nd Year']
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value, maxLines: 1),
                    ),
                  )
                  .toList(),
              onChanged: authProvider.isLoading
                  ? null
                  : (value) => setState(() => _yearLevel = value ?? _yearLevel),
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
              textInputAction: TextInputAction.next,
              validator: AuthValidators.validatePassword,
            ),
            const SizedBox(height: 10),
            _PasswordStrengthHint(
              strength: _passwordStrength,
              password: _passwordController.text,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              prefixIcon: Icons.verified_user_outlined,
              obscureText: _obscureConfirmPassword,
              suffixIcon: _obscureConfirmPassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              onSuffixTap: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => AuthValidators.validateConfirmPassword(
                value,
                _passwordController.text,
              ),
            ),
            const SizedBox(height: 22),
            AuthActionButton(
              label: 'Create account',
              isLoading: authProvider.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            AuthFormFooter(
              prompt: 'Already have an account?',
              actionLabel: 'Sign in',
              onTap: () {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD5E2F2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.7),
      ),
    );
  }
}

class _PasswordStrengthHint extends StatelessWidget {
  const _PasswordStrengthHint({required this.strength, required this.password});

  final PasswordStrength strength;
  final String password;

  @override
  Widget build(BuildContext context) {
    final color = switch (strength.score) {
      <= 0.25 => const Color(0xFFDC2626),
      < 0.8 => const Color(0xFFD97706),
      _ => const Color(0xFF059669),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: strength.score,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Password strength: ${strength.label}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 12,
          runSpacing: 5,
          children: [
            _Requirement(met: password.length >= 12, label: '12+ characters'),
            _Requirement(
              met: RegExp(r'[A-Za-z]').hasMatch(password),
              label: 'Letter',
            ),
            _Requirement(
              met: RegExp(r'[0-9]').hasMatch(password),
              label: 'Number',
            ),
          ],
        ),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.label});
  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        size: 14,
        color: met ? const Color(0xFF059669) : const Color(0xFF94A3B8),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: met ? const Color(0xFF047857) : const Color(0xFF64748B),
        ),
      ),
    ],
  );
}
