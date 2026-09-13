import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Extracted (and possibly student-corrected) fields from a PSU student ID.
class StudentIdFields {
  const StudentIdFields({
    this.institution = '',
    this.studentName = '',
    this.studentNumber = '',
    this.program = '',
  });

  final String institution;
  final String studentName;
  final String studentNumber;
  final String program;

  factory StudentIdFields.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const StudentIdFields();
    String read(String key) => (map[key] ?? '').toString();
    return StudentIdFields(
      institution: read('institution'),
      studentName: read('studentName'),
      studentNumber: read('studentNumber'),
      program: read('program'),
    );
  }

  Map<String, String> toMap() => {
    'institution': institution.trim(),
    'studentName': studentName.trim(),
    'studentNumber': studentNumber.trim().toUpperCase(),
    'program': program.trim(),
  };

  StudentIdFields copyWith({
    String? institution,
    String? studentName,
    String? studentNumber,
    String? program,
  }) => StudentIdFields(
    institution: institution ?? this.institution,
    studentName: studentName ?? this.studentName,
    studentNumber: studentNumber ?? this.studentNumber,
    program: program ?? this.program,
  );
}

/// Outcome of a scan (preview) or confirm (final decision) request against
/// the `/student/id/verify` endpoint.
///
/// `approved` is returned only after a `confirm` action fully passes every
/// check on the server (institution, name match, program eligibility,
/// duplicate student number) and the account has been marked verified in
/// Firestore. `accepted` is a lighter-weight preview status returned by
/// `scan` meaning "the detected program looks CCS-eligible" — it does not
/// mean the account is verified yet.
class StudentIdVerificationResult {
  const StudentIdVerificationResult({
    required this.status,
    required this.message,
    this.fields = const StudentIdFields(),
    this.normalizedProgram,
  });

  final String status;
  final String message;
  final StudentIdFields fields;
  final String? normalizedProgram;

  bool get approved => status == 'approved';
  bool get rejected => status == 'rejected';
  bool get reviewRequired => status == 'reviewRequired';
}

class StudentIdVerificationService {
  const StudentIdVerificationService();

  static const _configuredBaseUrl = String.fromEnvironment(
    'COSCI_SERVICE_URL',
    defaultValue: 'https://cosci-compiler.onrender.com',
  );

  Uri get _endpoint => Uri.parse(
    '${_configuredBaseUrl.replaceAll(RegExp(r'/+$'), '')}/student/id/verify',
  );

  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (user == null || token == null) {
      throw StateError('Your session expired. Sign in again.');
    }
    return {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    };
  }

  StudentIdVerificationResult _parseResponse(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw StateError(
        'The verification service returned an invalid response. Please try again.',
      );
    }
    // Some failure responses (e.g. the OCR analyzer being unavailable) still
    // carry a usable status/fields payload worth showing to the student
    // instead of a bare error.
    if ((response.statusCode < 200 || response.statusCode >= 300) &&
        data['status'] == null) {
      throw StateError(data['message'] as String? ?? 'ID verification failed.');
    }
    return StudentIdVerificationResult(
      status: data['status'] as String? ?? 'reviewRequired',
      message:
          data['message'] as String? ??
          'Please review the extracted information.',
      fields: StudentIdFields.fromMap(data['fields'] as Map<String, dynamic>?),
      normalizedProgram: data['normalizedProgram'] as String?,
    );
  }

  /// Uploads a fresh photo for OCR extraction and an eligibility preview.
  /// Never marks the account as verified — only `confirm` does that.
  Future<StudentIdVerificationResult> scan({
    required Uint8List imageBytes,
    required String mimeType,
    String studentNumber = '',
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          _endpoint,
          headers: headers,
          body: jsonEncode({
            'action': 'scan',
            'imageBase64': base64Encode(imageBytes),
            'mimeType': mimeType,
            'studentNumber': studentNumber.trim().toUpperCase(),
          }),
        )
        .timeout(const Duration(seconds: 60));
    return _parseResponse(response);
  }

  /// Submits the (possibly student-corrected) fields for final validation.
  /// The server currently re-validates against the original photo, so it
  /// must be resent alongside the corrected fields.
  Future<StudentIdVerificationResult> confirm({
    required Uint8List imageBytes,
    required String mimeType,
    required StudentIdFields fields,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          _endpoint,
          headers: headers,
          body: jsonEncode({
            'action': 'confirm',
            'imageBase64': base64Encode(imageBytes),
            'mimeType': mimeType,
            'fields': fields.toMap(),
          }),
        )
        .timeout(const Duration(seconds: 60));
    return _parseResponse(response);
  }
}
