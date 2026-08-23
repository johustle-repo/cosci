class AuthValidators {
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }

    const emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 12) {
      return 'Password must be at least 12 characters.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain letters and numbers.';
    }

    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required.';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != password) {
      return 'Passwords do not match.';
    }

    return null;
  }

  static PasswordStrength evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrength(
        label: 'Use at least 12 characters.',
        score: 0,
      );
    }

    var score = 0;

    if (password.length >= 12) {
      score++;
    }
    if (password.length >= 10) {
      score++;
    }
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }

    if (score <= 1) {
      return const PasswordStrength(label: 'Weak', score: 0.25);
    }
    if (score <= 3) {
      return const PasswordStrength(label: 'Moderate', score: 0.55);
    }
    if (score == 4) {
      return const PasswordStrength(label: 'Strong', score: 0.8);
    }

    return const PasswordStrength(label: 'Very strong', score: 1);
  }
}

class PasswordStrength {
  const PasswordStrength({required this.label, required this.score});

  final String label;
  final double score;
}
