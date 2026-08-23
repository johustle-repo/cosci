import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/features/gamification/services/certificate_service.dart';
import 'package:pseudocode_apk/models/achievement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = CertificateService();
  const unlockedBadge = Achievement(
    id: 'first_puzzle',
    title: 'Syntax Builder',
    description: 'Completed a syntax puzzle.',
    iconName: 'puzzle',
    accentHex: '#0EA5E9',
    milestoneLabel: 'Complete 1 syntax puzzle',
    isUnlocked: true,
  );

  test('builds a downloadable PDF for an unlocked badge', () async {
    final bytes = await service.buildBadgeCertificate(
      badge: unlockedBadge,
      learnerName: 'Test Learner',
      learnerId: 'learner-123',
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('rejects certificate generation for a locked badge', () async {
    await expectLater(
      service.buildBadgeCertificate(
        badge: unlockedBadge.copyWith(isUnlocked: false),
        learnerName: 'Test Learner',
        learnerId: 'learner-123',
      ),
      throwsStateError,
    );
  });
}
