import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:pseudocode_apk/services/student_id_verification_service.dart';

/// On-device implementation of the flowchart's "OCR: Convert ID Image to
/// Text" step, using ML Kit's on-device text recognizer.
///
/// Only Android and iOS ship a native ML Kit implementation. This file also
/// compiles on Windows/Linux/macOS (they have dart:io, like Android/iOS do)
/// but [isSupported] is false there, so [StudentIdVerificationScreen] falls
/// back to the server's OCR endpoint instead of calling [recognize].
class StudentIdOcrService {
  const StudentIdOcrService();

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<StudentIdOcrResult> recognize({
    required String imagePath,
    String enteredStudentNumber = '',
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return _extractFields(recognized.text, enteredStudentNumber);
    } finally {
      await recognizer.close();
    }
  }

  // Field extraction mirrors compiler_server/server.mjs's OCR pipeline so an
  // on-device read and the server's authoritative re-read reach the same
  // fields for the same ID.

  StudentIdOcrResult _extractFields(
    String rawText,
    String enteredStudentNumber,
  ) {
    final text = _normalized(rawText);
    final hasPsuBranding = RegExp(
      r'\bPSU\b|PANGASINAN\s+STATE\s+UNIVERSITY',
    ).hasMatch(text);
    final extractedProgram = _extractProgramLine(rawText);
    final detectedProgram = _detectEligibleProgram(text);
    final detectedNumbers = _detectedStudentNumbers(text);
    final entered = _canonicalStudentNumber(enteredStudentNumber);
    final studentNumber = entered.isNotEmpty
        ? entered
        : (detectedNumbers.isNotEmpty ? detectedNumbers.first : '');

    final fields = StudentIdFields(
      institution: hasPsuBranding ? 'Pangasinan State University' : '',
      studentName: _extractStudentName(rawText) ?? '',
      studentNumber: studentNumber,
      program: extractedProgram ?? detectedProgram ?? '',
    );
    // Decision: "ID Information Read Clearly?"
    final readable =
        fields.studentName.isNotEmpty &&
        fields.studentNumber.isNotEmpty &&
        fields.program.isNotEmpty;
    return StudentIdOcrResult(fields: fields, readable: readable);
  }

  String _normalized(String value) => value
      .toUpperCase()
      .replaceAll(RegExp(r'[–—]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final _studentNumberPattern = RegExp(r'^(\d{2})([A-Z]{2})(\d{4})$');

  String _canonicalStudentNumber(String value) {
    final compact = _normalized(value).replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final strict = _studentNumberPattern.firstMatch(compact);
    if (strict != null) {
      return '${strict[1]}-${strict[2]}-${strict[3]}';
    }
    // OCR commonly confuses look-alike glyphs (O/0, I/L/1, S/5, B/8, Z/2,
    // G/6). Force each fixed-width slot toward the character class it must
    // be — digits in the year/sequence slots, letters in the program-code
    // slot — before giving up on an 8-character candidate.
    if (compact.length == 8) {
      final corrected =
          _forceDigits(compact.substring(0, 2)) +
          _forceLetters(compact.substring(2, 4)) +
          _forceDigits(compact.substring(4, 8));
      final relaxed = _studentNumberPattern.firstMatch(corrected);
      if (relaxed != null) {
        return '${relaxed[1]}-${relaxed[2]}-${relaxed[3]}';
      }
    }
    return '';
  }

  String _forceDigits(String value) => value
      .replaceAll('O', '0')
      .replaceAll('Q', '0')
      .replaceAll('D', '0')
      .replaceAll('I', '1')
      .replaceAll('L', '1')
      .replaceAll('S', '5')
      .replaceAll('B', '8')
      .replaceAll('Z', '2')
      .replaceAll('G', '6');

  String _forceLetters(String value) => value
      .replaceAll('0', 'O')
      .replaceAll('1', 'I')
      .replaceAll('5', 'S')
      .replaceAll('8', 'B')
      .replaceAll('2', 'Z')
      .replaceAll('6', 'G');

  List<String> _detectedStudentNumbers(String text) {
    final results = <String>{};
    // The candidate scan itself stays permissive — any 8-character run in a
    // 2-2-4 grouping — and lets _canonicalStudentNumber's correction step
    // decide whether it actually decodes to a valid student number.
    for (final m in RegExp(
      r'\b[A-Z0-9]{2}\s*[- ]?\s*[A-Z0-9]{2}\s*[- ]?\s*[A-Z0-9]{4}\b',
    ).allMatches(text)) {
      final normalized = _canonicalStudentNumber(m.group(0)!);
      if (normalized.isNotEmpty) results.add(normalized);
    }
    return results.toList();
  }

  String? _detectEligibleProgram(String text) {
    if (RegExp(
      r'B\s*S\s*(?:INFORMATION\s*TECHNOLOGY|IT)\b|\bBSIT\b|BACHELOR\s+OF\s+SCIENCE\s+(?:IN\s+)?INFORMATION\s+TECHNOLOGY',
    ).hasMatch(text)) {
      return 'BS Information Technology';
    }
    if (RegExp(
      r'B\s*S\s*(?:COMPUTER\s*SCIENCE|CS)\b|\bBSCS\b|BACHELOR\s+OF\s+SCIENCE\s+(?:IN\s+)?COMPUTER\s+SCIENCE',
    ).hasMatch(text)) {
      return 'BS Computer Science';
    }
    if (RegExp(
      r'BS\s*(?:MATHEMATICS|MATH)(?:\s*[-–]?\s*CIT)?\b',
    ).hasMatch(text)) {
      return 'BS Mathematics';
    }
    if (RegExp(
      r'\bBSMATH\b|BACHELOR\s+OF\s+SCIENCE\s+(?:IN\s+)?MATHEMATICS',
    ).hasMatch(text)) {
      return 'BS Mathematics';
    }
    return null;
  }

  String _normalizeProgramText(String value) => value
      .toUpperCase()
      .replaceAll('&', ' AND ')
      .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String? _extractProgramLine(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    for (final line in lines) {
      if (_detectEligibleProgram(_normalizeProgramText(line)) != null) {
        return line;
      }
    }
    final fallback = RegExp(
      r'\bB\.?\s*S\.?\b|BACHELOR\s+OF\s+SCIENCE|\b(NURSING|ARCHITECTURE|EDUCATION|ENGINEERING|CRIMINOLOGY)\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      if (fallback.hasMatch(line)) return line;
    }
    return null;
  }

  String? _extractStudentName(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final exclude = RegExp(
      r'PSU|PANGASINAN|UNIVERSITY|COLLEGE|BACHELOR|\bBS\b|INFORMATION|COMPUTER|MATHEMATICS|TECHNOLOGY|STUDENT|NUMBER|SIGNATURE',
    );
    final onlyNameChars = RegExp(r"^[A-Z .,'-]+$");
    final candidates = lines.where((line) {
      final normalized = _normalizeProgramText(line);
      return normalized.length >= 6 &&
          !exclude.hasMatch(normalized) &&
          !RegExp(r'\d').hasMatch(normalized) &&
          onlyNameChars.hasMatch(normalized);
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }
}

class StudentIdOcrResult {
  const StudentIdOcrResult({required this.fields, required this.readable});
  final StudentIdFields fields;
  final bool readable;
}
