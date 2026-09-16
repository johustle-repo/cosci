class InstitutionalEmailService {
  const InstitutionalEmailService._();

  static const domain = 'psu.edu.ph';
  static const warningMessage =
      'Use your PSU institutional email address ending in @psu.edu.ph.';

  static String normalize(String email) => email.trim().toLowerCase();

  static bool isValid(String email) {
    final normalized = normalize(email);
    return RegExp(
      r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@psu\.edu\.ph$",
      caseSensitive: false,
    ).hasMatch(normalized);
  }
}
