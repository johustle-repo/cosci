import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _seenKey = 'onboarding_seen';

  static Future<bool> shouldShow() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return !(preferences.getBool(_seenKey) ?? false);
    } catch (_) {
      // A newly added platform plugin is unavailable until the app is fully
      // restarted. Do not block authentication if local onboarding storage
      // is temporarily unavailable.
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_seenKey, true);
    } catch (_) {
      // Onboarding persistence is optional and must never block navigation.
    }
  }
}
