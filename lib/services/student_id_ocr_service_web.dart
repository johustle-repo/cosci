import 'package:pseudocode_apk/services/student_id_verification_service.dart';

/// Web build of the OCR service: ML Kit has no web implementation, so
/// [isSupported] is always false and [StudentIdVerificationScreen] falls
/// back to the server's OCR endpoint instead of calling [recognize].
class StudentIdOcrService {
  const StudentIdOcrService();

  static bool get isSupported => false;

  Future<StudentIdOcrResult> recognize({
    required String imagePath,
    String enteredStudentNumber = '',
  }) {
    throw UnsupportedError(
      'On-device ID recognition is not available on this platform.',
    );
  }
}

class StudentIdOcrResult {
  const StudentIdOcrResult({required this.fields, required this.readable});
  final StudentIdFields fields;
  final bool readable;
}
