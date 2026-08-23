import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pseudocode_apk/features/auth/services/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('onboarding is shown once for a new installation', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await OnboardingService.shouldShow(), isTrue);
    await OnboardingService.markSeen();
    expect(await OnboardingService.shouldShow(), isFalse);
  });
}
