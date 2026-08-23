import 'package:cloud_firestore/cloud_firestore.dart';

String adminErrorMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Your account cannot perform this action. Refresh your session and verify the assigned role.',
      'unavailable' =>
        'Firebase is temporarily unavailable. Check the connection and try again.',
      'not-found' => 'This item no longer exists. Refresh the page.',
      'already-exists' => 'An item with the same identifier already exists.',
      'failed-precondition' =>
        'This action requires additional setup or a Firestore index.',
      _ => error.message ?? 'The Firebase operation could not be completed.',
    };
  }
  return error
      .toString()
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Exception: ', '');
}
