import 'dart:async';
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
    this.reason,
  });

  final String status;
  final String message;
  final StudentIdFields fields;
  final String? normalizedProgram;

  /// Why a `reviewRequired` result was returned: `unclear` (missing/unreadable
  /// fields), `nameMismatch` (ID name vs. registered account), or
  /// `accountMismatch` (ID program vs. the program already on the account).
  final String? reason;

  bool get approved => status == 'approved';
  bool get rejected => status == 'rejected';
  bool get reviewRequired => status == 'reviewRequired';

  /// Decision: "ID Information Read Clearly?" — true only for a `scan` whose
  /// fields were all extracted, meaning the flow can go straight into the
  /// name-match and program checks without a manual review step.
  bool get readClearly => status == 'clear';

  bool get nameMismatch => reason == 'nameMismatch';
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
    String? token;
    try {
      token = await user?.getIdToken().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw StateError(
        'We could not check your sign-in session. Check your connection and try again.',
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') {
        throw StateError(
          'Could not connect to the sign-in service. Check your connection and try again.',
        );
      }
      throw StateError(
        'Your sign-in session could not be validated. Sign out, sign in again, then retry ID verification.',
      );
    }
    if (user == null || token == null) {
      throw StateError('Your session expired. Sign in again.');
    }
    return {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    };
  }

  StudentIdVerificationResult _parseResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw StateError(
        'Your session expired. Sign out and sign in again, then retry ID verification.',
      );
    }
    if ([502, 503, 504].contains(response.statusCode)) {
      throw StateError(
        'The ID verification service is temporarily unavailable. Your photo and entered details have been kept. Please try again shortly.',
      );
    }
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected an object');
      }
      data = decoded;
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
      reason: data['reason'] as String?,
    );
  }

  Future<StudentIdVerificationResult> _submit(
    Map<String, dynamic> payload, {
    required Duration timeout,
  }) async {
    final headers = await _authHeaders();
    final client = http.Client();
    try {
      final response = await client
          .post(_endpoint, headers: headers, body: jsonEncode(payload))
          .timeout(timeout);
      return _parseResponse(response);
    } on TimeoutException {
      throw StateError(
        payload['action'] == 'scan'
            ? 'Reading your ID took too long. Your photo is still selected. Please try again shortly.'
            : 'Verification did not respond in time. Your details have been kept. Please retry confirmation.',
      );
    } on http.ClientException {
      throw StateError(
        'Could not connect to ID verification. Check your connection and try again. Your photo and details have been kept.',
      );
    } finally {
      client.close();
    }
  }

  /// Uploads a fresh photo for OCR extraction and an eligibility preview.
  /// Never marks the account as verified — only `confirm` does that.
  Future<StudentIdVerificationResult> scan({
    required Uint8List imageBytes,
    required String mimeType,
    String studentNumber = '',
  }) async {
    return _submit({
      'action': 'scan',
      'imageBase64': base64Encode(imageBytes),
      'mimeType': mimeType,
      'studentNumber': studentNumber.trim().toUpperCase(),
    }, timeout: const Duration(seconds: 120));
  }

  /// Submits the student-reviewed fields for final server validation.
  /// OCR is intentionally not run again during confirmation.
  Future<StudentIdVerificationResult> confirm({
    required StudentIdFields fields,
  }) async {
    return _submit({
      'action': 'confirm',
      'fields': fields.toMap(),
    }, timeout: const Duration(seconds: 60));
  }
}
