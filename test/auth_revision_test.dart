import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/features/auth/presentation/utils/auth_validators.dart';
import 'package:pseudocode_apk/models/app_user.dart';

void main() {
  test('legacy professor accounts normalize to instructor', () {
    const user = AppUser(
      uid: '1',
      email: 'faculty@psu.edu.ph',
      role: 'professor',
    );
    expect(user.normalizedRole, 'instructor');
    expect(user.isInstructor, isTrue);
  });

  test('password requires 12 characters with letters and numbers', () {
    expect(AuthValidators.validatePassword('short1'), isNotNull);
    expect(AuthValidators.validatePassword('abcdefghijkl'), isNotNull);
    expect(AuthValidators.validatePassword('SecurePass12'), isNull);
  });

  test('inactive legacy accounts normalize to suspended', () {
    final user = AppUser.fromMap({
      'uid': '1',
      'email': 'x@psu.edu.ph',
      'isActive': false,
    });
    expect(user.normalizedAccountStatus, 'suspended');
    expect(user.isActive, isFalse);
  });
}
