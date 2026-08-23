import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LessonService {
  LessonService({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  Future<List<Lesson>> fetchLessons() async {
    // No orderBy — avoids requiring a composite Firestore index.
    // Filter and sort client-side instead.
    final snapshot = await _firestoreService.lessonsCollection().get();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final user = uid == null ? null : await _firestoreService.fetchAppUser(uid);

    final lessons = snapshot.docs
        .where((doc) => _eligible(doc.data(), user?.program, user?.yearLevel))
        .map((doc) => Lesson.fromMap(doc.id, doc.data()))
        .where((lesson) => lesson.isPublished)
        .toList();

    lessons.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return lessons;
  }

  Future<Set<String>> fetchCompletedLessonIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const {};
    final snapshot = await _firestoreService
        .userLessonProgressCollection(uid)
        .get();
    return snapshot.docs
        .where((doc) => doc.data()['completed'] == true)
        .map((doc) => doc.id)
        .toSet();
  }

  bool _eligible(Map<String, dynamic> data, String? program, String? year) {
    final programs = List<String>.from(
      data['audiencePrograms'] as List? ?? const [],
    );
    final years = List<String>.from(data['yearLevels'] as List? ?? const []);
    return (programs.isEmpty ||
            program == null ||
            programs.contains(program)) &&
        (years.isEmpty || year == null || years.contains(year));
  }
}
