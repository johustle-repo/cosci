import 'dart:typed_data';
import 'package:pseudocode_apk/services/college_eligibility_service.dart';
import 'package:pseudocode_apk/services/student_id_models.dart';
import 'package:pseudocode_apk/services/student_id_ocr_service.dart';
import 'package:pseudocode_apk/services/student_id_parser_service.dart';

class StudentIdVerificationService {
  const StudentIdVerificationService();

  Future<StudentIdVerificationResult> scan({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (imageBytes.isEmpty) {
      return const StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message: 'No ID image was selected.',
        fields: StudentIdExtractedFields(),
      );
    }

    try {
      final rawText = await const StudentIdOcrService().extractText(
        imageBytes: imageBytes,
        mimeType: mimeType,
      );

      if (rawText.trim().isEmpty) {
        return const StudentIdVerificationResult(
          status: EligibilityStatus.reviewRequired,
          message:
              'No readable text was detected. Please take another clear photo of the student ID.',
          fields: StudentIdExtractedFields(),
        );
      }

      final fields = const StudentIdParserService().parse(rawText);

      if (!fields.hasAnyData) {
        return StudentIdVerificationResult(
          status: EligibilityStatus.reviewRequired,
          message:
              'Student information could not be identified. Please scan the ID again.',
          fields: const StudentIdExtractedFields(),
          rawText: rawText,
        );
      }

      final eligibility = const CollegeEligibilityService().evaluate(
        fields.program,
      );

      final normalizedFields = eligibility.status == EligibilityStatus.accepted
          ? fields.copyWith(
              program: eligibility.normalizedProgram ?? fields.program,
            )
          : fields;

      // Always review OCR before final acceptance.
      return StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message:
            'Student ID information extracted. Please review the information before verification.',
        fields: normalizedFields,
        normalizedProgram: eligibility.normalizedProgram,
        rawText: rawText,
      );
    } catch (error) {
      return StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message: 'The ID could not be analyzed. ${_cleanError(error)}',
        fields: const StudentIdExtractedFields(),
      );
    }
  }

  Future<StudentIdVerificationResult> confirm({
    required StudentIdExtractedFields fields,
  }) async {
    if (fields.institution.trim().isEmpty) {
      return StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message: 'Institution is required.',
        fields: fields,
      );
    }

    if (fields.studentName.trim().isEmpty) {
      return StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message: 'Student name is required.',
        fields: fields,
      );
    }

    if (fields.studentNumber.trim().isEmpty) {
      return StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message: 'Student number is required.',
        fields: fields,
      );
    }

    if (fields.program.trim().isEmpty) {
      return StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message: CollegeEligibilityService.reviewMessage,
        fields: fields,
      );
    }

    final eligibility = const CollegeEligibilityService().evaluate(
      fields.program,
    );

    if (eligibility.status == EligibilityStatus.rejected) {
      return StudentIdVerificationResult(
        status: EligibilityStatus.rejected,
        message: eligibility.message,
        fields: fields,
        normalizedProgram: eligibility.normalizedProgram,
      );
    }

    if (eligibility.status == EligibilityStatus.reviewRequired) {
      return StudentIdVerificationResult(
        status: EligibilityStatus.reviewRequired,
        message: eligibility.message,
        fields: fields,
        normalizedProgram: eligibility.normalizedProgram,
      );
    }

    final normalizedFields = fields.copyWith(
      program: eligibility.normalizedProgram ?? fields.program,
    );

    return StudentIdVerificationResult(
      status: EligibilityStatus.accepted,
      message: CollegeEligibilityService.acceptedMessage,
      fields: normalizedFields,
      normalizedProgram: eligibility.normalizedProgram,
    );
  }

  static String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst('Unsupported operation: ', '')
        .trim();
  }
}
