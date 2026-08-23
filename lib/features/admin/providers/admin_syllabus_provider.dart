import 'dart:typed_data';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_syllabus.dart';
import 'package:pseudocode_apk/features/admin/models/admin_syllabus_analysis.dart';
import 'package:pseudocode_apk/features/admin/services/admin_ai_generation_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_syllabus_service.dart';

/// Manages the list of uploaded syllabi, the currently viewed syllabus,
/// and its extracted analysis. Drives the Upload + Analysis workflow.
class AdminSyllabusProvider extends ChangeNotifier {
  AdminSyllabusService? _service;
  AdminAiGenerationService? _aiService;
  AdminLogService? _logger;

  List<AdminSyllabus> _syllabi = [];
  AdminSyllabus? _currentSyllabus;
  AdminSyllabusAnalysis? _currentAnalysis;

  bool _isLoading = false;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  double _uploadProgress = 0;
  String? _error;
  String? _uploadError;
  String? _analysisError;

  // â”€â”€ Getters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<AdminSyllabus> get syllabi => _syllabi;
  AdminSyllabus? get currentSyllabus => _currentSyllabus;
  AdminSyllabusAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get isAnalyzing => _isAnalyzing;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;
  String? get uploadError => _uploadError;
  String? get analysisError => _analysisError;

  // â”€â”€ Wiring â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void attach(
    AdminSyllabusService service,
    AdminAiGenerationService aiService,
    AdminLogService logger,
  ) {
    if (identical(_service, service)) return;
    _service = service;
    _aiService = aiService;
    _logger = logger;
  }

  /// Call whenever the Anthropic API key changes (e.g. after Settings save).
  void configureApiKey(String key) {
    _aiService?.setApiKey(key);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // LOAD SYLLABI LIST
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> loadSyllabi() async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _notifySafely();
    try {
      _syllabi = await _service!.fetchSyllabi();
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // UPLOAD + CREATE
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Uploads the file to Storage, then creates the Firestore record.
  /// Returns the new syllabus ID on success, null on failure.
  Future<String?> uploadAndCreate({
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
    required String title,
    required String courseCode,
    required String courseName,
    required String programmingLanguage,
    required String yearLevel,
    required String term,
    required String uploadedBy,
    required String uploadedByEmail,
  }) async {
    if (_service == null) return null;
    _isUploading = true;
    _uploadProgress = 0;
    _uploadError = null;
    _notifySafely();
    try {
      final fileUrl = await _service!.uploadSyllabusFile(
        bytes: fileBytes,
        fileName: fileName,
        fileType: fileType,
        onProgress: (p) {
          _uploadProgress = p;
          _notifySafely();
        },
      );

      final syllabus = AdminSyllabus(
        id: '',
        title: title.trim(),
        courseCode: courseCode.trim(),
        courseName: courseName.trim(),
        programmingLanguage: programmingLanguage.trim(),
        yearLevel: yearLevel.trim(),
        term: term.trim(),
        fileUrl: fileUrl,
        fileType: fileType,
        fileName: fileName,
        fileSizeBytes: fileBytes.length,
        uploadedBy: uploadedBy,
        uploadedByEmail: uploadedByEmail,
        analysisStatus: 'pending',
      );

      final id = await _service!.createSyllabus(syllabus);
      await _logger?.logCreate('syllabi', 'Uploaded syllabus: $title');
      await loadSyllabi();
      return id;
    } catch (e) {
      _uploadError = e.toString();
      return null;
    } finally {
      _isUploading = false;
      _uploadProgress = 0;
      _notifySafely();
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // LOAD SYLLABUS DETAIL
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> loadSyllabusDetail(String syllabusId) async {
    if (_service == null) return;
    _isLoading = true;
    _error = null;
    _currentSyllabus = null;
    _currentAnalysis = null;
    _notifySafely();
    try {
      final results = await Future.wait([
        _service!.fetchSyllabus(syllabusId),
        _service!.fetchAnalysis(syllabusId),
      ]);
      _currentSyllabus = results[0] as AdminSyllabus?;
      _currentAnalysis = results[1] as AdminSyllabusAnalysis?;
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // ANALYSE SYLLABUS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Sends the file content to Claude for extraction and stores the result.
  /// [textContent] for TXT; [pdfBytes] for PDF (Claude reads it as a document).
  Future<bool> analyzeSyllabus({
    String? textContent,
    Uint8List? pdfBytes,
  }) async {
    final syllabus = _currentSyllabus;
    if (_service == null || _aiService == null || syllabus == null) {
      return false;
    }

    _isAnalyzing = true;
    _analysisError = null;
    _notifySafely();

    try {
      await _service!.updateAnalysisStatus(syllabus.id, 'analyzing');

      final analysis = await _aiService!.analyzeSyllabus(
        syllabusId: syllabus.id,
        textContent: textContent,
        pdfBytes: pdfBytes,
      );

      await _service!.saveAnalysis(analysis);
      await _service!.updateAnalysisStatus(syllabus.id, 'analyzed');
      await _logger?.log(
        actionType: 'analyze',
        targetModule: 'syllabi',
        description: 'Analyzed syllabus: ${syllabus.title}',
        targetId: syllabus.id,
      );

      // Refresh local state
      _currentAnalysis = await _service!.fetchAnalysis(syllabus.id);
      _currentSyllabus = _currentSyllabus?.copyWith(analysisStatus: 'analyzed');
      // Refresh list entry
      _syllabi = _syllabi
          .map(
            (s) => s.id == syllabus.id
                ? s.copyWith(analysisStatus: 'analyzed')
                : s,
          )
          .toList();
      return true;
    } catch (e) {
      _analysisError = e.toString();
      try {
        await _service!.updateAnalysisStatus(syllabus.id, 'failed');
        _currentSyllabus = _currentSyllabus?.copyWith(analysisStatus: 'failed');
      } catch (_) {}
      return false;
    } finally {
      _isAnalyzing = false;
      _notifySafely();
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DELETE
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<bool> deleteSyllabus(String id, String title) async {
    if (_service == null) return false;
    try {
      await _service!.deleteSyllabus(id);
      await _logger?.logDelete('syllabi', 'Deleted syllabus: $title');
      _syllabi = _syllabi.where((s) => s.id != id).toList();
      if (_currentSyllabus?.id == id) {
        _currentSyllabus = null;
        _currentAnalysis = null;
      }
      _notifySafely();
      return true;
    } catch (e) {
      _error = adminErrorMessage(e);
      _notifySafely();
      return false;
    }
  }

  // â”€â”€ Utilities â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void clearErrors() {
    _error = null;
    _uploadError = null;
    _analysisError = null;
    _notifySafely();
  }

  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) notifyListeners();
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }
}
