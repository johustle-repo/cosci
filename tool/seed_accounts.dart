import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/firebase_options.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';
import 'package:pseudocode_apk/services/seed_account_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final passwordsByRole = <String, String>{
    'admin': _readSecret(
      envKey: 'PSU_ADMIN_PASSWORD',
      defineKey: 'PSU_ADMIN_PASSWORD',
    ),
    'student': _readSecret(
      envKey: 'PSU_STUDENT_PASSWORD',
      defineKey: 'PSU_STUDENT_PASSWORD',
    ),
    'professor': _readSecret(
      envKey: 'PSU_PROFESSOR_PASSWORD',
      defineKey: 'PSU_PROFESSOR_PASSWORD',
    ),
  };

  final service = SeedAccountService(firestoreService: FirestoreService());
  final results = await service.seedAccounts(passwordsByRole: passwordsByRole);

  for (final result in results) {
    debugPrint(
      '[${result.status.name.toUpperCase()}] ${result.role} '
      '(${result.email}) - ${result.message}',
    );
  }

  final hasFailures = results.any(
    (result) => result.status == SeedAccountStatus.failed,
  );
  debugPrint(
    hasFailures ? 'Seed finished with failures.' : 'Seed completed.',
  );
}

String _readSecret({required String envKey, required String defineKey}) {
  const adminDefine = String.fromEnvironment('PSU_ADMIN_PASSWORD');
  const studentDefine = String.fromEnvironment('PSU_STUDENT_PASSWORD');
  const professorDefine = String.fromEnvironment('PSU_PROFESSOR_PASSWORD');

  if (kIsWeb) {
    switch (defineKey) {
      case 'PSU_ADMIN_PASSWORD':
        return adminDefine;
      case 'PSU_STUDENT_PASSWORD':
        return studentDefine;
      case 'PSU_PROFESSOR_PASSWORD':
        return professorDefine;
      default:
        return '';
    }
  }

  switch (envKey) {
    case 'PSU_ADMIN_PASSWORD':
      return adminDefine;
    case 'PSU_STUDENT_PASSWORD':
      return studentDefine;
    case 'PSU_PROFESSOR_PASSWORD':
      return professorDefine;
    default:
      return '';
  }
}
