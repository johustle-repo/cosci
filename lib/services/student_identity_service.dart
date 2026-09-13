class StudentIdentityService {
  const StudentIdentityService();

  String normalizeStudentNumber(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  bool namesMatch({required String accountName, required String idName}) {
    final accountTokens = _nameTokens(accountName);
    final idTokens = _nameTokens(idName);
    if (accountTokens.length < 2 || idTokens.length < 2) return false;

    // Middle initials and additional middle names are allowed. Every meaningful
    // name stored on the account must still be present on the ID.
    return accountTokens.every(idTokens.contains);
  }

  List<String> _nameTokens(String value) {
    return value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1)
        .toSet()
        .toList(growable: false);
  }
}
