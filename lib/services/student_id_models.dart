import 'package:pseudocode_apk/services/college_eligibility_service.dart';

class StudentIdExtractedFields {
  const StudentIdExtractedFields({
    this.institution = '',
    this.studentName = '',
    this.studentNumber = '',
    this.program = '',
  });

  final String institution;
  final String studentName;
  final String studentNumber;
  final String program;

  bool get hasInstitution => institution.trim().isNotEmpty;
  bool get hasStudentName => studentName.trim().isNotEmpty;
  bool get hasStudentNumber => studentNumber.trim().isNotEmpty;
  bool get hasProgram => program.trim().isNotEmpty;

  bool get hasAnyData =>
      hasInstitution || hasStudentName || hasStudentNumber || hasProgram;

  StudentIdExtractedFields copyWith({
    String? institution,
    String? studentName,
    String? studentNumber,
    String? program,
  }) {
    return StudentIdExtractedFields(
      institution: institution ?? this.institution,
      studentName: studentName ?? this.studentName,
      studentNumber: studentNumber ?? this.studentNumber,
      program: program ?? this.program,
    );
  }

  Map<String, String> toJson() {
    return {
      'institution': institution.trim(),
      'studentName': studentName.trim(),
      'studentNumber': studentNumber.trim().toUpperCase(),
      'program': program.trim(),
    };
  }

  factory StudentIdExtractedFields.fromJson(Object? value) {
    if (value is! Map) {
      return const StudentIdExtractedFields();
    }

    return StudentIdExtractedFields(
      institution: value['institution']?.toString().trim() ?? '',
      studentName: value['studentName']?.toString().trim() ?? '',
      studentNumber:
          value['studentNumber']?.toString().trim().toUpperCase() ?? '',
      program: value['program']?.toString().trim() ?? '',
    );
  }
}

class StudentIdVerificationResult {
  const StudentIdVerificationResult({
    required this.status,
    required this.message,
    required this.fields,
    this.normalizedProgram,
    this.rawText = '',
  });

  final EligibilityStatus status;
  final String message;
  final StudentIdExtractedFields fields;
  final String? normalizedProgram;
  final String rawText;

  bool get accepted => status == EligibilityStatus.accepted;
  bool get rejected => status == EligibilityStatus.rejected;

  bool get reviewRequired => status == EligibilityStatus.reviewRequired;
}
