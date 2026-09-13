import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/models/app_user.dart';

void main() {
  group('student ID verification gate', () {
    test('student with a missing status is grandfathered in', () {
      const user = AppUser(uid: 'student-1', email: 'student@psu.edu.ph');

      expect(user.requiresIdVerification, isFalse);
    });

    test('only an explicitly approved student may continue', () {
      const approved = AppUser(
        uid: 'student-1',
        email: 'student@psu.edu.ph',
        idVerificationStatus: 'approved',
      );
      const required = AppUser(
        uid: 'student-2',
        email: 'student2@psu.edu.ph',
        idVerificationStatus: 'required',
      );

      expect(approved.requiresIdVerification, isFalse);
      expect(required.requiresIdVerification, isTrue);
    });

    test('staff accounts do not require student ID verification', () {
      const instructor = AppUser(
        uid: 'instructor-1',
        email: 'instructor@psu.edu.ph',
        role: 'instructor',
      );

      expect(instructor.requiresIdVerification, isFalse);
    });
  });
}
