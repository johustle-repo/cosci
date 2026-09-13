import 'package:pseudocode_apk/services/student_id_models.dart';

class StudentIdParserService {
  const StudentIdParserService();

  StudentIdExtractedFields parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const StudentIdExtractedFields();
    }

    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_cleanLine)
        .where((line) => line.isNotEmpty)
        .toList();

    return StudentIdExtractedFields(
      institution: _findInstitution(lines),
      studentName: _findStudentName(lines),
      studentNumber: _findStudentNumber(lines),
      program: _findProgram(lines),
    );
  }

  String _findInstitution(List<String> lines) {
    final combined = lines.join(' ').toUpperCase();

    if (combined.contains('PANGASINAN STATE UNIVERSITY')) {
      return 'Pangasinan State University';
    }

    if (RegExp(r'\bPSU\b').hasMatch(combined)) {
      return 'Pangasinan State University';
    }

    return '';
  }

  String _findStudentNumber(List<String> lines) {
    for (final line in lines) {
      final result = _parseStudentNumber(line);

      if (result != null) {
        return result;
      }
    }

    return _parseStudentNumber(lines.join(' ')) ?? '';
  }

  String? _parseStudentNumber(String value) {
    final text = value
        .toUpperCase()
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('−', '-');

    final pattern = RegExp(
      r'\b([0-9OIL]{2})\s*-?\s*([A-Z0-9]{2})\s*-?\s*([0-9OIL]{4})\b',
    );

    final match = pattern.firstMatch(text);

    if (match == null) {
      return null;
    }

    final first = _fixNumbers(match.group(1)!);

    var middle = match.group(2)!.toUpperCase();

    final last = _fixNumbers(match.group(3)!);

    middle = middle.replaceAll('1', 'I').replaceAll('0', 'O');

    if (!RegExp(r'^\d{2}$').hasMatch(first)) {
      return null;
    }

    if (!RegExp(r'^[A-Z]{2}$').hasMatch(middle)) {
      return null;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(last)) {
      return null;
    }

    return '$first-$middle-$last';
  }

  String _fixNumbers(String value) {
    return value
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1');
  }

  String _findProgram(List<String> lines) {
    final combined = _normalizeProgram(lines.join(' '));

    final compact = combined.replaceAll(' ', '');

    if (compact.contains('BSINFORMATIONTECHNOLOGY') ||
        compact.contains('BACHELOROFSCIENCEININFORMATIONTECHNOLOGY') ||
        RegExp(r'\bBSIT\b').hasMatch(combined)) {
      return 'BS Information Technology';
    }

    if (compact.contains('BSCOMPUTERSCIENCE') ||
        compact.contains('BACHELOROFSCIENCEINCOMPUTERSCIENCE') ||
        RegExp(r'\bBSCS\b').hasMatch(combined)) {
      return 'BS Computer Science';
    }

    if (compact.contains('BSMATHEMATICS') ||
        compact.contains('BACHELOROFSCIENCEINMATHEMATICS') ||
        RegExp(r'\bBS\s*MATH(?:EMATICS)?\b').hasMatch(combined) ||
        RegExp(r'\bBSMATH\b').hasMatch(combined)) {
      return 'BS Mathematics';
    }

    // Find non-CCS degree programs.
    for (final line in lines) {
      final normalized = _normalizeProgram(line);

      if (_looksLikeProgramLine(normalized)) {
        return line;
      }
    }

    return '';
  }

  bool _looksLikeProgramLine(String value) {
    if (value.startsWith('BACHELOR OF')) {
      return true;
    }

    return RegExp(r'^(BS|BA|AB|BSA|BEED|BSED|BSN)\b').hasMatch(value);
  }

  String _findStudentName(List<String> lines) {
    final studentNumberIndex = lines.indexWhere(
      (line) => _parseStudentNumber(line) != null,
    );

    if (studentNumberIndex > 0) {
      for (
        var index = studentNumberIndex - 1;
        index >= 0 && index >= studentNumberIndex - 3;
        index--
      ) {
        final candidate = lines[index];

        if (_looksLikeName(candidate)) {
          return candidate.toUpperCase();
        }
      }
    }

    for (final line in lines) {
      if (_looksLikeName(line)) {
        return line.toUpperCase();
      }
    }

    return '';
  }

  bool _looksLikeName(String value) {
    final normalized = value.trim().toUpperCase();

    if (normalized.length < 5 || normalized.length > 70) {
      return false;
    }

    if (RegExp(r'\d').hasMatch(normalized)) {
      return false;
    }

    const excluded = [
      'PSU',
      'PANGASINAN',
      'STATE UNIVERSITY',
      'UNIVERSITY',
      'COLLEGE',
      'STUDENT',
      'INFORMATION TECHNOLOGY',
      'COMPUTER SCIENCE',
      'MATHEMATICS',
      'BACHELOR',
      'PROGRAM',
      'COURSE',
    ];

    for (final term in excluded) {
      if (normalized.contains(term)) {
        return false;
      }
    }

    final words = normalized.split(RegExp(r'\s+'));

    if (words.length < 2 || words.length > 8) {
      return false;
    }

    return RegExp(r"^[A-ZÑÀ-ÖØ-Ý .,'\-]+$").hasMatch(normalized);
  }

  String _normalizeProgram(String value) {
    return value
        .toUpperCase()
        .replaceAll('TECHN0LOGY', 'TECHNOLOGY')
        .replaceAll('C0MPUTER', 'COMPUTER')
        .replaceAll('SC1ENCE', 'SCIENCE')
        .replaceAll('INFORMAT1ON', 'INFORMATION')
        .replaceAll('MATHEMAT1CS', 'MATHEMATICS')
        .replaceAll(RegExp(r'\b8S\b'), 'BS')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanLine(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
