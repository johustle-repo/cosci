import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pseudocode_apk/providers/simulation_provider.dart';

class TrustedEvaluationResult {
  const TrustedEvaluationResult({
    required this.available,
    required this.passed,
    required this.passedTests,
    required this.totalTests,
    required this.message,
  });

  final bool available;
  final bool passed;
  final int passedTests;
  final int totalTests;
  final String message;
}

class TrustedSimulationEvaluator {
  const TrustedSimulationEvaluator({http.Client? client, String? endpoint})
    : _client = client,
      _configuredEndpoint = endpoint;

  final http.Client? _client;
  final String? _configuredEndpoint;
  static const _endpoint = String.fromEnvironment(
    'SIMULATION_EVALUATOR_URL',
    defaultValue: '',
  );

  static bool get isConfigured => _endpoint.trim().isNotEmpty;

  Future<TrustedEvaluationResult> evaluate({
    required String activityId,
    required ProgrammingLanguage language,
    required String sourceCode,
  }) async {
    final endpoint = _configuredEndpoint ?? _endpoint;
    if (endpoint.trim().isEmpty) {
      return const TrustedEvaluationResult(
        available: false,
        passed: false,
        passedTests: 0,
        totalTests: 0,
        message: 'Trusted hidden-test evaluator is not configured.',
      );
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      return const TrustedEvaluationResult(
        available: false,
        passed: false,
        passedTests: 0,
        totalTests: 0,
        message: 'Sign in again before submitting this activity.',
      );
    }
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'activityId': activityId,
              'language': language.runtimeName,
              'sourceCode': sourceCode,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return TrustedEvaluationResult(
          available: false,
          passed: false,
          passedTests: 0,
          totalTests: 0,
          message:
              'Trusted evaluation failed with HTTP ${response.statusCode}.',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TrustedEvaluationResult(
        available: true,
        passed: data['passed'] as bool? ?? false,
        passedTests: (data['passedTests'] as num?)?.toInt() ?? 0,
        totalTests: (data['totalTests'] as num?)?.toInt() ?? 0,
        message: data['message'] as String? ?? 'Trusted evaluation completed.',
      );
    } catch (_) {
      return const TrustedEvaluationResult(
        available: false,
        passed: false,
        passedTests: 0,
        totalTests: 0,
        message: 'Trusted evaluator is unavailable. Try again later.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
