import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug web App Check key defaults to empty', () {
    const key = String.fromEnvironment('APP_CHECK_WEB_RECAPTCHA_KEY');
    expect(key, isEmpty);
  });
}
