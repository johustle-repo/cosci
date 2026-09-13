enum EligibilityStatus { accepted, rejected, reviewRequired }

class CollegeEligibilityResult {
  const CollegeEligibilityResult({
    required this.status,
    required this.normalizedProgram,
    required this.message,
  });

  final EligibilityStatus status;
  final String? normalizedProgram;
  final String message;
}

class CollegeEligibilityService {
  const CollegeEligibilityService();

  static const String collegeName = 'College of Computing Sciences';

  static const String acceptedMessage =
      'Student ID verified. The student belongs to the College of Computing Sciences.';

  static const String rejectedMessage =
      'This student is not enrolled in a program under the College of Computing Sciences. '
      'Only BS Information Technology, BS Computer Science, and BS Mathematics students are eligible.';

  static const String reviewMessage =
      "We could not clearly verify the student's program. "
      "Please review the extracted information or scan the ID again.";

  static const List<String> acceptedPrograms = [
    'BS Information Technology',
    'BS Computer Science',
    'BS Mathematics',
  ];

  CollegeEligibilityResult evaluate(String? program) {
    final normalized = _normalizeInput(program);

    if (normalized.isEmpty || _looksUnreadable(normalized)) {
      return const CollegeEligibilityResult(
        status: EligibilityStatus.reviewRequired,
        normalizedProgram: null,
        message: reviewMessage,
      );
    }

    final acceptedProgram = _acceptedProgram(normalized);

    if (acceptedProgram != null) {
      return CollegeEligibilityResult(
        status: EligibilityStatus.accepted,
        normalizedProgram: acceptedProgram,
        message: acceptedMessage,
      );
    }

    // A value that still contains several OCR-style digit substitutions after
    // normalization is not reliable enough to classify as a real non-CCS
    // program. Keep it in manual review instead of falsely rejecting it.
    if (_hasAmbiguousOcrCharacters(program)) {
      return CollegeEligibilityResult(
        status: EligibilityStatus.reviewRequired,
        normalizedProgram: program == null ? null : _displayValue(program),
        message: reviewMessage,
      );
    }

    if (_looksLikeProgram(normalized)) {
      final display = _displayValue(program ?? normalized);

      return CollegeEligibilityResult(
        status: EligibilityStatus.rejected,
        normalizedProgram: display,
        message: '$rejectedMessage Detected program: $display.',
      );
    }

    return CollegeEligibilityResult(
      status: EligibilityStatus.reviewRequired,
      normalizedProgram: program == null ? null : _displayValue(program),
      message: reviewMessage,
    );
  }

  String? _acceptedProgram(String value) {
    final compact = value.replaceAll(' ', '');

    const bsit = {
      'BSIT',
      'BSINFORMATIONTECHNOLOGY',
      'BACHELOROFSCIENCEININFORMATIONTECHNOLOGY',
      'BACHELOROFSCIENCEINFORMATIONTECHNOLOGY',
    };

    if (bsit.contains(compact)) {
      return 'BS Information Technology';
    }

    const bscs = {
      'BSCS',
      'BSCOMPUTERSCIENCE',
      'BACHELOROFSCIENCEINCOMPUTERSCIENCE',
      'BACHELOROFSCIENCECOMPUTERSCIENCE',
    };

    if (bscs.contains(compact)) {
      return 'BS Computer Science';
    }

    const bsMath = {
      'BSMATH',
      'BSMATHS',
      'BSMATHEMATICS',
      'BACHELOROFSCIENCEINMATHEMATICS',
      'BACHELOROFSCIENCEMATHEMATICS',
    };

    if (bsMath.contains(compact)) {
      return 'BS Mathematics';
    }

    return null;
  }

  String _normalizeInput(String? value) {
    if (value == null) {
      return '';
    }

    return value
        .toUpperCase()
        .replaceAll(RegExp(r'\bTECHN0LOGY\b'), 'TECHNOLOGY')
        .replaceAll(RegExp(r'\bTECHNOL0GY\b'), 'TECHNOLOGY')
        .replaceAll(RegExp(r'\bC0MPUTER\b'), 'COMPUTER')
        .replaceAll(RegExp(r'\bSC1ENCE\b'), 'SCIENCE')
        .replaceAll(RegExp(r'\bINFORMAT1ON\b'), 'INFORMATION')
        .replaceAll(RegExp(r'\bMATHEMAT1CS\b'), 'MATHEMATICS')
        .replaceAll(RegExp(r'\b8S\b'), 'BS')
        .replaceAll(RegExp(r'\bB5\b'), 'BS')
        .replaceAll('&', ' AND ')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _looksUnreadable(String value) {
    if (value.length < 4) {
      return true;
    }

    final letters = RegExp(r'[A-Z]').allMatches(value).length;

    if (letters < 3) {
      return true;
    }

    const unreadableValues = {
      'UNKNOWN',
      'UNREADABLE',
      'NOT DETECTED',
      'NOT FOUND',
      'NO PROGRAM',
      'NONE',
      'N A',
      'NA',
    };

    return unreadableValues.contains(value);
  }

  bool _hasAmbiguousOcrCharacters(String? value) {
    if (value == null) return false;
    return RegExp(r'[0158]').allMatches(value.toUpperCase()).length >= 2;
  }

  bool _looksLikeProgram(String value) {
    if (value.contains('BACHELOR OF')) {
      return true;
    }

    if (RegExp(
      r'^(BS|BA|AB|BSA|BEED|BSED|BSE|BSEE|BSCE|BSME|BSN)\b',
    ).hasMatch(value)) {
      return true;
    }

    return RegExp(
      r'\b('
      r'NURSING|'
      r'ARCHITECTURE|'
      r'BUSINESS ADMINISTRATION|'
      r'ACCOUNTANCY|'
      r'ACCOUNTING|'
      r'CRIMINOLOGY|'
      r'CIVIL ENGINEERING|'
      r'MECHANICAL ENGINEERING|'
      r'ELECTRICAL ENGINEERING|'
      r'ELECTRONICS ENGINEERING|'
      r'ENGINEERING|'
      r'ELEMENTARY EDUCATION|'
      r'SECONDARY EDUCATION|'
      r'HOSPITALITY MANAGEMENT|'
      r'TOURISM MANAGEMENT|'
      r'PSYCHOLOGY|'
      r'COMMUNICATION|'
      r'ENGLISH LANGUAGE|'
      r'AGRICULTURE|'
      r'FISHERIES'
      r')\b',
    ).hasMatch(value);
  }

  String _displayValue(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
