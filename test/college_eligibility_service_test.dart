import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/services/college_eligibility_service.dart';

void main() {
  const service = CollegeEligibilityService();

  group('accepted CCS programs', () {
    const cases = <String, String>{
      'BS Information Technology': 'BS Information Technology',
      'BSIT': 'BS Information Technology',
      'Bachelor of Science in Information Technology':
          'BS Information Technology',
      'BS Computer Science': 'BS Computer Science',
      'BSCS': 'BS Computer Science',
      'Bachelor of Science in Computer Science': 'BS Computer Science',
      'BS Mathematics': 'BS Mathematics',
      'BSMATH': 'BS Mathematics',
      'Bachelor of Science in Mathematics': 'BS Mathematics',
      '  b.s.   information   technology  ': 'BS Information Technology',
      'b.s. computer science': 'BS Computer Science',
      'B.S. MATHEMATICS': 'BS Mathematics',
      'bs it': 'BS Information Technology',
      'bs cs': 'BS Computer Science',
    };

    for (final entry in cases.entries) {
      test('${entry.key} -> accepted', () {
        final result = service.evaluate(entry.key);
        expect(result.status, EligibilityStatus.accepted);
        expect(result.normalizedProgram, entry.value);
      });
    }
  });

  group('non-CCS programs', () {
    for (final program in const [
      'BS Business Administration',
      'BS Nursing',
      'BS Architecture',
      'Bachelor of Elementary Education',
    ]) {
      test('$program -> rejected', () {
        final result = service.evaluate(program);
        expect(result.status, EligibilityStatus.rejected);
        expect(result.normalizedProgram, program);
        expect(result.message, contains(program));
      });
    }
  });

  group('uncertain OCR', () {
    for (final program in <String?>[
      null,
      '',
      '   ',
      'unreadable',
      '???',
      'B5 1NF0RMAT10N',
    ]) {
      test('$program -> reviewRequired', () {
        expect(
          service.evaluate(program).status,
          EligibilityStatus.reviewRequired,
        );
      });
    }
  });
}
