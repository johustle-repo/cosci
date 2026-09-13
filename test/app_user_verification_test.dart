import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/models/app_user.dart';

void main() {
  group('student ID verification gate (temporarily disabled)', () {
    test('a verified email is enough regardless of ID status', () {
      const missing = AppUser(uid: 'student-1', email: 'student@psu.edu.ph');
      const required = AppUser(
        uid: 'student-2',
        email: 'student2@psu.edu.ph',
        idVerificationStatus: 'required',
      );
      const approved = AppUser(
        uid: 'student-3',
        email: 'student3@psu.edu.ph',
        idVerificationStatus: 'approved',
      );

      expect(missing.requiresIdVerification, isFalse);
      expect(required.requiresIdVerification, isFalse);
      expect(approved.requiresIdVerification, isFalse);
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
