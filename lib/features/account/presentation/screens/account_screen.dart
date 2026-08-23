import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _passwordKey = GlobalKey<FormState>();
  final _profileKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _program = TextEditingController();
  var _year = '1st Year';
  var _initialized = false;
  var _showCurrent = false;
  var _showNext = false;
  var _showConfirm = false;

  @override
  void initState() {
    super.initState();
    for (final field in [_current, _next, _confirm]) {
      field.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final field in [_current, _next, _confirm]) {
      field
        ..removeListener(_refresh)
        ..dispose();
    }
    _name.dispose();
    _program.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (!_initialized && user != null) {
      _name.text = user.displayName ?? '';
      _program.text = user.program ?? '';
      _year = const {'1st Year', '2nd Year'}.contains(user.yearLevel)
          ? user.yearLevel!
          : '1st Year';
      _initialized = true;
    }

    return AppScaffold(
      title: 'Account & Security',
      maxContentWidth: 1120,
      body: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          _Hero(
            name: user?.displayName ?? 'CoSci user',
            email: user?.email ?? '',
            role: _role(user?.normalizedRole),
            program: user?.program,
            year: user?.yearLevel,
            active: user?.isActive ?? false,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final cards = [_profileCard(auth), _securityCard(auth)];
              if (box.maxWidth < 820) {
                return Column(
                  children: [cards[0], const SizedBox(height: 16), cards[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 18),
                  Expanded(child: cards[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _informationCard(),
        ],
      ),
    );
  }

  Widget _profileCard(AuthProvider auth) => _Panel(
    icon: Icons.manage_accounts_outlined,
    title: 'Student profile',
    subtitle: 'Keep your learner information accurate.',
    child: Form(
      key: _profileKey,
      child: Column(
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Enter your full name.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _program,
            decoration: const InputDecoration(
              labelText: 'Academic program',
              hintText: 'e.g. BS Computer Science',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Enter your academic program.'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _year,
            decoration: const InputDecoration(
              labelText: 'Year level',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            items: const [
              DropdownMenuItem(value: '1st Year', child: Text('1st Year')),
              DropdownMenuItem(value: '2nd Year', child: Text('2nd Year')),
            ],
            onChanged: auth.isLoading
                ? null
                : (value) => setState(() => _year = value!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: auth.isLoading ? null : () => _saveProfile(auth),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save profile changes'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _securityCard(AuthProvider auth) {
    final ready =
        _current.text.isNotEmpty &&
        _next.text.length >= 12 &&
        _next.text == _confirm.text;
    return _Panel(
      icon: Icons.lock_outline_rounded,
      title: 'Password & security',
      subtitle: 'Protect your learning progress and submissions.',
      child: Form(
        key: _passwordKey,
        child: Column(
          children: [
            _PasswordField(
              controller: _current,
              label: 'Current password',
              visible: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'Enter your current password.' : null,
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _next,
              label: 'New password',
              visible: _showNext,
              onToggle: () => setState(() => _showNext = !_showNext),
              validator: (v) =>
                  (v?.length ?? 0) < 12 ? 'Use at least 12 characters.' : null,
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _confirm,
              label: 'Confirm new password',
              visible: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) =>
                  v != _next.text ? 'Passwords do not match.' : null,
            ),
            const SizedBox(height: 10),
            _Strength(password: _next.text),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: auth.isLoading || !ready
                    ? null
                    : () => _changePassword(auth),
                icon: const Icon(Icons.password_rounded),
                label: Text(
                  auth.isLoading ? 'Updating password...' : 'Change password',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: auth.isLoading ? null : () => _sendReset(auth),
              icon: const Icon(Icons.mark_email_read_outlined),
              label: const Text('Send password-reset email instead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _informationCard() => _Panel(
    icon: Icons.verified_user_outlined,
    title: 'Account information',
    subtitle: 'Help, privacy, and platform details.',
    child: LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth >= 720
            ? (box.maxWidth - 24) / 3
            : box.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Info(
              width: width,
              icon: Icons.support_agent_rounded,
              title: 'Support',
              text: 'Contact your PSU instructor or CoSci administrator.',
            ),
            _Info(
              width: width,
              icon: Icons.privacy_tip_outlined,
              title: 'Educational privacy',
              text: 'Progress and submissions are stored for educational use.',
            ),
            _Info(
              width: width,
              icon: Icons.info_outline_rounded,
              title: 'CoSci platform',
              text: 'Version 1.0.0 · Firebase-synced learner workspace',
            ),
          ],
        );
      },
    ),
  );

  Future<void> _saveProfile(AuthProvider auth) async {
    if (!(_profileKey.currentState?.validate() ?? false)) return;
    final ok = await auth.updateOwnProfile(
      displayName: _name.text.trim(),
      program: _program.text.trim(),
      yearLevel: _year,
    );
    _message(
      ok
          ? 'Profile updated successfully.'
          : auth.errorMessage ?? 'Profile update failed.',
      ok,
    );
  }

  Future<void> _changePassword(AuthProvider auth) async {
    if (!(_passwordKey.currentState?.validate() ?? false)) return;
    final ok = await auth.changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (ok) {
      _current.clear();
      _next.clear();
      _confirm.clear();
    }
    _message(
      ok
          ? 'Password changed successfully.'
          : auth.errorMessage ?? 'Password was not changed.',
      ok,
    );
  }

  Future<void> _sendReset(AuthProvider auth) async {
    final email = auth.currentUser?.email ?? '';
    final ok =
        email.isNotEmpty && await auth.sendPasswordResetEmail(email: email);
    _message(
      ok
          ? 'Reset instructions were sent to $email.'
          : auth.errorMessage ?? 'Reset email could not be sent.',
      ok,
    );
  }

  void _message(String text, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: success ? const Color(0xFF047857) : null,
      ),
    );
  }

  String _role(String? value) => switch (value) {
    'admin' => 'Administrator',
    'instructor' => 'Instructor',
    _ => 'Student',
  };
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.name,
    required this.email,
    required this.role,
    required this.program,
    required this.year,
    required this.active,
  });
  final String name, email, role;
  final String? program, year;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0B2553), Color(0xFF17479B)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Wrap(
      spacing: 16,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const CircleAvatar(
          radius: 31,
          backgroundColor: Color(0xFFE8F0FF),
          child: Icon(Icons.person_outline_rounded, color: Color(0xFF123D9B)),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 190, maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFCAD8F4)),
              ),
              if ((program ?? '').isNotEmpty)
                Text(
                  '$program${(year ?? '').isNotEmpty ? ' · $year' : ''}',
                  style: const TextStyle(
                    color: Color(0xFFAFC5ED),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        _Chip(icon: Icons.school_outlined, label: '$role workspace'),
        _Chip(
          icon: active ? Icons.verified_rounded : Icons.warning_amber_rounded,
          label: active ? 'Active account' : 'Needs attention',
        ),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final IconData icon;
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD7E2F2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF17479B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.visible,
    required this.onToggle,
    required this.validator,
  });
  final TextEditingController controller;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: !visible,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      suffixIcon: IconButton(
        tooltip: visible ? 'Hide password' : 'Show password',
        onPressed: onToggle,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    ),
  );
}

class _Strength extends StatelessWidget {
  const _Strength({required this.password});
  final String password;
  @override
  Widget build(BuildContext context) {
    final checks = [
      password.length >= 12,
      RegExp('[A-Z]').hasMatch(password),
      RegExp('[0-9]').hasMatch(password),
      RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ];
    final score = checks.where((v) => v).length;
    final color = score >= 4
        ? const Color(0xFF059669)
        : score >= 2
        ? const Color(0xFFD97706)
        : const Color(0xFF94A3B8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 4,
            minHeight: 5,
            color: color,
            backgroundColor: const Color(0xFFE2E8F0),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Strength: ${score >= 4
              ? 'Strong'
              : score >= 2
              ? 'Improving'
              : 'Use 12+ characters, uppercase, number, and symbol'}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.width,
    required this.icon,
    required this.title,
    required this.text,
  });
  final double width;
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF17479B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
