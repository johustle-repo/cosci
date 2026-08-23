import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:pseudocode_apk/features/admin/models/admin_content_generation_job.dart';
import 'package:pseudocode_apk/features/admin/models/admin_syllabus.dart';
import 'package:pseudocode_apk/features/admin/models/admin_syllabus_analysis.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';

/// Handles Cloudinary uploads and all Firestore CRUD for the
/// syllabus upload + AI generation feature.
class AdminSyllabusService {
  AdminSyllabusService({required FirestoreService firestoreService})
    : _db = firestoreService.instance;

  final FirebaseFirestore _db;

  // Cloudinary Configuration (using your credentials)
  static const String _cloudName = 'dqbhzhqbf';
  static const String _uploadPreset = 'dqbhzhqbf';

  // ── Collection references ──────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _syllabi =>
      _db.collection('syllabi');
  CollectionReference<Map<String, dynamic>> get _analysis =>
      _db.collection('syllabus_analysis');
  CollectionReference<Map<String, dynamic>> get _jobs =>
      _db.collection('content_generation_jobs');

  // ══════════════════════════════════════════════════════════════════════════
  // CLOUDINARY — FILE UPLOAD
  // ══════════════════════════════════════════════════════════════════════════

  /// Uploads a syllabus file (PDF, DOCX, etc.) to Cloudinary.
  /// Returns the secure public URL.
  Future<String> uploadSyllabusFile({
    required Uint8List bytes,
    required String fileName,
    required String fileType,
    void Function(double progress)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final publicId = 'syllabi/${timestamp}_$safeName';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
    );

    // Start progress
    if (onProgress != null) onProgress(0.1);

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = publicId
        ..fields['resource_type'] =
            'auto' // Important for PDF/DOCX
        ..fields['folder'] = 'syllabi'; // Organizes files in Cloudinary

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: safeName,
      );

      request.files.add(multipartFile);

      if (onProgress != null) onProgress(0.4);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (onProgress != null) onProgress(0.8);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final String secureUrl = data['secure_url'] as String;

        if (onProgress != null) onProgress(1.0);

        return secureUrl;
      } else {
        final errorBody = response.body;
        throw Exception('Upload failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SYLLABI CRUD (No changes below)
  // ══════════════════════════════════════════════════════════════════════════

  Future<String> createSyllabus(AdminSyllabus syllabus) async {
    final ref = await _syllabi.add({
      ...syllabus.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<List<AdminSyllabus>> fetchSyllabi() async {
    final snap = await _syllabi.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => AdminSyllabus.fromMap(d.id, d.data())).toList();
  }

  Future<AdminSyllabus?> fetchSyllabus(String id) async {
    final doc = await _syllabi.doc(id).get();
    if (!doc.exists) return null;
    return AdminSyllabus.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateAnalysisStatus(String id, String status) async {
    await _syllabi.doc(id).update({
      'analysisStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSyllabus(String id) async {
    await _syllabi.doc(id).delete();
    try {
      await _analysis.doc(id).delete();
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SYLLABUS ANALYSIS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveAnalysis(AdminSyllabusAnalysis analysis) async {
    await _analysis.doc(analysis.syllabusId).set(analysis.toMap());
  }

  Future<AdminSyllabusAnalysis?> fetchAnalysis(String syllabusId) async {
    final doc = await _analysis.doc(syllabusId).get();
    if (!doc.exists) return null;
    return AdminSyllabusAnalysis.fromMap(doc.id, doc.data()!);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTENT GENERATION JOBS
  // ══════════════════════════════════════════════════════════════════════════

  Future<String> createJob(AdminContentGenerationJob job) async {
    final ref = await _jobs.add(job.toMap());
    return ref.id;
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> updates) async {
    await _jobs.doc(jobId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AdminContentGenerationJob>> fetchJobs({
    String? syllabusId,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> q;
    if (syllabusId != null) {
      q = _jobs
          .where('syllabusId', isEqualTo: syllabusId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    } else {
      q = _jobs.orderBy('createdAt', descending: true).limit(limit);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => AdminContentGenerationJob.fromMap(d.id, d.data()))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVE GENERATED CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Future<String> saveGeneratedLesson(Map<String, dynamic> data) async {
    final ref = await _db.collection('lessons').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> saveGeneratedQuiz(Map<String, dynamic> data) async {
    final ref = await _db.collection('quizzes').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> saveGeneratedPuzzle(Map<String, dynamic> data) async {
    final ref = await _db.collection('puzzles').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<String> saveGeneratedSimulation(Map<String, dynamic> data) async {
    final ref = await _db.collection('simulations').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<Map<String, int>> fetchGeneratedCounts(String syllabusId) async {
    final results = await Future.wait([
      _db
          .collection('lessons')
          .where('syllabusId', isEqualTo: syllabusId)
          .count()
          .get(),
      _db
          .collection('quizzes')
          .where('syllabusId', isEqualTo: syllabusId)
          .count()
          .get(),
      _db
          .collection('puzzles')
          .where('syllabusId', isEqualTo: syllabusId)
          .count()
          .get(),
      _db
          .collection('simulations')
          .where('syllabusId', isEqualTo: syllabusId)
          .count()
          .get(),
    ]);
    return {
      'lessons': results[0].count ?? 0,
      'quizzes': results[1].count ?? 0,
      'puzzles': results[2].count ?? 0,
      'simulations': results[3].count ?? 0,
    };
  }
}
