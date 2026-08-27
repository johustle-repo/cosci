import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class StudentIdVerificationResult {
  const StudentIdVerificationResult({
    required this.status,
    required this.message,
    this.detectedProgram,
  });

  final String status;
  final String message;
  final String? detectedProgram;
  bool get approved => status == 'approved';
}

class StudentIdVerificationService {
  const StudentIdVerificationService();

  static const _configuredBaseUrl = String.fromEnvironment(
    'COSCI_SERVICE_URL',
    defaultValue: 'https://cosci-compiler.onrender.com',
  );

  Future<StudentIdVerificationResult> verify({
    required Uint8List imageBytes,
    required String mimeType,
    required String studentNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken(true);
    if (user == null || token == null) {
      throw StateError('Your session expired. Sign in again.');
    }
    final response = await http
        .post(
          Uri.parse(
            '${_configuredBaseUrl.replaceAll(RegExp(r'/+$'), '')}/student/id/verify',
          ),
          headers: {
            'content-type': 'application/json',
            'authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'imageBase64': base64Encode(imageBytes),
            'mimeType': mimeType,
            'studentNumber': studentNumber.trim().toUpperCase(),
          }),
        )
        .timeout(const Duration(seconds: 45));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(data['message'] as String? ?? 'ID verification failed.');
    }
    return StudentIdVerificationResult(
      status: data['status'] as String? ?? 'resubmission_required',
      message:
          data['message'] as String? ?? 'Please submit a clearer ID image.',
      detectedProgram: data['detectedProgram'] as String?,
    );
  }
}
