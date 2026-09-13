import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/services/student_identity_service.dart';

void main() {
  const service = StudentIdentityService();

  test('account name accepts an ID with a middle initial', () {
    expect(
      service.namesMatch(
        accountName: 'Jonathan Quiles',
        idName: 'JONATHAN F. QUILES',
      ),
      isTrue,
    );
  });

  test('account name comparison ignores order and punctuation', () {
    expect(
      service.namesMatch(
        accountName: 'Quiles, Jonathan',
        idName: 'JONATHAN F QUILES',
      ),
      isTrue,
    );
  });

  test('different learner names are rejected', () {
    expect(
      service.namesMatch(
        accountName: 'Jonathan Quiles',
        idName: 'Rhuella Untalan',
      ),
      isFalse,
    );
  });

  test('student number receives a stable claim key', () {
    expect(service.normalizeStudentNumber('19-LN-1566'), '19LN1566');
    expect(service.normalizeStudentNumber(' 19 ln 1566 '), '19LN1566');
  });
}
