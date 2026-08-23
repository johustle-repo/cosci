import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/models/app_user.dart';

/// Writes a structured entry to the `activity_logs` Firestore collection.
class AdminLogService {
  AdminLogService({required AdminFirestoreService adminFirestoreService})
    : _adminFs = adminFirestoreService;

  final AdminFirestoreService _adminFs;

  AppUser? _currentAdmin;

  void setAdmin(AppUser? admin) {
    _currentAdmin = admin;
  }

  Future<void> log({
    required String actionType,
    required String targetModule,
    required String description,
    String? targetId,
  }) async {
    if (_currentAdmin == null) return;
    try {
      await _adminFs.writeActivityLog({
        'adminUid': _currentAdmin!.uid,
        'adminEmail': _currentAdmin!.email,
        'actionType': actionType,
        'targetModule': targetModule,
        'description': description,
        'targetId': targetId,
        // The Firestore service replaces this with a server timestamp. Keeping
        // the key here makes the log payload schema explicit.
        'timestamp': null,
      });
    } catch (_) {
      // Logging failure should never break core operations.
    }
  }

  Future<void> logCreate(String module, String description, {String? id}) =>
      log(
        actionType: 'create',
        targetModule: module,
        description: description,
        targetId: id,
      );

  Future<void> logUpdate(String module, String description, {String? id}) =>
      log(
        actionType: 'update',
        targetModule: module,
        description: description,
        targetId: id,
      );

  Future<void> logDelete(String module, String description, {String? id}) =>
      log(
        actionType: 'delete',
        targetModule: module,
        description: description,
        targetId: id,
      );

  Future<void> logPublish(String module, String description, {String? id}) =>
      log(
        actionType: 'publish',
        targetModule: module,
        description: description,
        targetId: id,
      );

  Future<void> logUnpublish(String module, String description, {String? id}) =>
      log(
        actionType: 'unpublish',
        targetModule: module,
        description: description,
        targetId: id,
      );

  Future<void> logLogin() => log(
    actionType: 'login',
    targetModule: 'auth',
    description: 'Admin signed in',
  );

  Future<void> logLogout() => log(
    actionType: 'logout',
    targetModule: 'auth',
    description: 'Admin signed out',
  );
}
