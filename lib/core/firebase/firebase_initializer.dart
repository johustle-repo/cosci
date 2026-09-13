import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:pseudocode_apk/firebase_options.dart';

class FirebaseInitializer {
  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    const webKey = String.fromEnvironment('APP_CHECK_WEB_RECAPTCHA_KEY');

    // Firebase App Check requires a WebProvider on web. During local debug
    // development or an initial Hosting deployment there may be no reCAPTCHA
    // site key yet. Keep Auth and Firestore available instead of turning an
    // optional protection layer into a fatal application-startup dependency.
    // App Check activates automatically once the key is supplied at build time.
    if (kIsWeb && webKey.isEmpty) {
      return;
    }

    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
      providerWeb: webKey.isEmpty ? null : ReCaptchaV3Provider(webKey),
    );
  }
}
