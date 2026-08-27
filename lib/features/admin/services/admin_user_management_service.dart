import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Performs privileged account operations through trusted Cloud Functions.
class AdminUserManagementService {
  const AdminUserManagementService({http.Client? client}) : _client = client;

  final http.Client? _client;

  static const _configuredEndpoint = String.fromEnvironment(
    'ADMIN_DELETE_USER_URL',
    defaultValue: '',
  );

  static String get _resolvedEndpoint {
    if (_configuredEndpoint.trim().isNotEmpty) {
      return _configuredEndpoint.trim();
    }
    return 'https://cosci-compiler.onrender.com/admin/users/delete';
  }

  Future<void> deleteUser(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in again before deleting a user.');

    final projectId = Firebase.app().options.projectId;
    if (projectId.trim().isEmpty) {
      throw StateError('Firebase project configuration is incomplete.');
    }
    final token = await user.getIdToken(true);
    final endpoint = Uri.parse(_resolvedEndpoint);
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'uid': uid}),
          )
          .timeout(const Duration(seconds: 30));
      final body = response.body.isEmpty
          ? const <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          body['message'] as String? ??
              'The account could not be deleted (HTTP ${response.statusCode}).',
        );
      }
    } on http.ClientException {
      throw StateError(
        'The CoSci account service is unavailable. Wait for the online '
        'service to start, then try again.',
      );
    } on FormatException {
      throw StateError(
        'The account deletion service returned an invalid response.',
      );
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError(
        'Could not reach the account deletion service. Check the connection '
        'and backend configuration, then try again.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}
