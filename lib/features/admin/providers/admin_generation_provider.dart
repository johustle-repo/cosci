import 'package:flutter/scheduler.dart';
import 'package:pseudocode_apk/features/admin/utils/admin_error_message.dart';
import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/features/admin/models/admin_content_generation_job.dart';
import 'package:pseudocode_apk/features/admin/models/admin_syllabus_analysis.dart';
import 'package:pseudocode_apk/features/admin/services/admin_ai_generation_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_syllabus_service.dart';

/// Drives the AI content-generation pipeline.
///
/// For each content type (lesson / quiz / puzzle / simulation), it:
///   1. Creates a [AdminContentGenerationJob] in Firestore.
///   2. Iterates each [SyllabusUnit] from the analysis.
///   3. Calls [AdminAiGenerationService] for that unit.
///   4. Saves each result to the appropriate Firestore collection.
///   5. Updates the job status when complete.
class AdminGenerationProvider extends ChangeNotifier {
  AdminSyllabusService? _syllabusService;
  AdminAiGenerationService? _aiService;
  AdminLogService? _logger;

  List<AdminContentGenerationJob> _jobs = [];
  Map<String, int> _generatedCounts = {};

  bool _isLoadingJobs = false;
  bool _isGenerating = false;
  String? _generatingType; // current in-flight content type label
  double _generationProgress = 0; // 0.0 â€“ 1.0
  String? _error;
  String? _generationError;

  // â”€â”€ Getters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<AdminContentGenerationJob> get jobs => _jobs;
  Map<String, int> get generatedCounts => _generatedCounts;
  bool get isLoadingJobs => _isLoadingJobs;
  bool get isGenerating => _isGenerating;
  String? get generatingType => _generatingType;
  double get generationProgress => _generationProgress;
  String? get error => _error;
  String? get generationError => _generationError;

  int countFor(String type) => _generatedCounts[type] ?? 0;

  // â”€â”€ Wiring â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void attach(
    AdminSyllabusService syllabusService,
    AdminAiGenerationService aiService,
    AdminLogService logger,
  ) {
    if (identical(_syllabusService, syllabusService)) return;
    _syllabusService = syllabusService;
    _aiService = aiService;
    _logger = logger;
  }

  void configureApiKey(String key) {
    _aiService?.setApiKey(key);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // JOBS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Future<void> loadJobs({String? syllabusId}) async {
    if (_syllabusService == null) return;
    _isLoadingJobs = true;
    _error = null;
    _notifySafely();
    try {
      _jobs = await _syllabusService!.fetchJobs(syllabusId: syllabusId);
    } catch (e) {
      _error = adminErrorMessage(e);
    } finally {
      _isLoadingJobs = false;
      _notifySafely();
    }
  }

  Future<void> loadGeneratedCounts(String syllabusId) async {
    if (_syllabusService == null) return;
    try {
      _generatedCounts = await _syllabusService!.fetchGeneratedCounts(
        syllabusId,
      );
      _notifySafely();
    } catch (_) {}
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // GENERATE CONTENT
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Generates content of [contentType] for every unit in [analysis].
  /// Returns true when at least one item was successfully saved.
  Future<bool> generateContent({
    required AdminSyllabusAnalysis analysis,
    required String contentType, // lesson | quiz | puzzle | simulation
  }) async {
    if (_syllabusService == null || _aiService == null) return false;
    if (_isGenerating) return false;

    _isGenerating = true;
    _generatingType = contentType;
    _generationProgress = 0;
    _generationError = null;
    _notifySafely();

    // Create job record
    final job = AdminContentGenerationJob(
      id: '',
      syllabusId: analysis.syllabusId,
      syllabusTitle: analysis.courseTitle.isNotEmpty
          ? analysis.courseTitle
          : analysis.syllabusId,
      contentType: contentType,
      status: 'running',
      startedAt: DateTime.now(),
    );

    String jobId;
    try {
      jobId = await _syllabusService!.createJob(job);
    } catch (e) {
      _generationError = 'Failed to create job: $e';
      _isGenerating = false;
      _generatingType = null;
      _notifySafely();
      return false;
    }

    final units = analysis.units;
    if (units.isEmpty) {
      await _finaliseJob(
        jobId: jobId,
        status: 'failed',
        generatedCount: 0,
        failedCount: 0,
        error: 'No units found in syllabus analysis.',
        generatedIds: [],
      );
      _isGenerating = false;
      _generatingType = null;
      _generationError = 'No units found in syllabus analysis.';
      _notifySafely();
      return false;
    }

    final generatedIds = <String>[];
    final failureMessages = <String>[];
    int failedCount = 0;

    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      _generationProgress = i / units.length;
      _notifySafely();

      try {
        final items = await _generateForUnit(
          analysis: analysis,
          unit: unit,
          contentType: contentType,
        );

        for (final item in items) {
          final generated = contentType == 'lesson'
              ? _completeLesson(item, analysis, unit, i)
              : item;
          final withMeta = {
            ...generated,
            'syllabusId': analysis.syllabusId,
            'syllabusTitle': analysis.courseTitle,
            'unitNumber': unit.unitNumber,
            'unitTitle': unit.title,
          };
          final id = await _saveItem(contentType, withMeta);
          if (id.isNotEmpty) generatedIds.add(id);
        }
      } catch (error) {
        failedCount++;
        final detail = error.toString().replaceFirst('Exception: ', '').trim();
        failureMessages.add(
          '${unit.title}: ${detail.isEmpty ? 'Unknown generation error' : detail}',
        );
      }
    }

    _generationProgress = 1.0;
    _notifySafely();

    final finalStatus = failedCount == units.length
        ? 'failed'
        : generatedIds.isEmpty
        ? 'failed'
        : failedCount > 0
        ? 'partial'
        : 'completed';

    await _finaliseJob(
      jobId: jobId,
      status: finalStatus,
      generatedCount: generatedIds.length,
      failedCount: failedCount,
      error: failureMessages.isNotEmpty
          ? failureMessages.take(3).join(' | ')
          : null,
      generatedIds: generatedIds,
    );

    await _logger?.log(
      actionType: 'generate',
      targetModule: '${contentType}s',
      description:
          'Generated ${generatedIds.length} ${contentType}s from syllabus: '
          '${analysis.courseTitle}',
      targetId: analysis.syllabusId,
    );

    // Refreshing management summaries must not turn successful generation
    // into a stuck loading state when an optional read is unavailable.
    try {
      await loadGeneratedCounts(analysis.syllabusId);
      await loadJobs(syllabusId: analysis.syllabusId);
    } catch (_) {}

    _isGenerating = false;
    _generatingType = null;
    _generationProgress = 0;
    _generationError = failureMessages.isEmpty
        ? null
        : generatedIds.isEmpty
        ? 'Lesson generation failed. ${failureMessages.take(3).join(' | ')}'
        : 'Some syllabus units were skipped. ${failureMessages.take(3).join(' | ')}';
    _notifySafely();

    return generatedIds.isNotEmpty;
  }

  // â”€â”€ Private helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<List<Map<String, dynamic>>> _generateForUnit({
    required AdminSyllabusAnalysis analysis,
    required SyllabusUnit unit,
    required String contentType,
  }) {
    switch (contentType) {
      case 'lesson':
        return _aiService!.generateLessons(
          analysis: analysis,
          unit: unit,
          count: 1,
        );
      case 'quiz':
        return _aiService!.generateQuizzes(
          analysis: analysis,
          unit: unit,
          count: 3,
        );
      case 'puzzle':
        return _aiService!.generatePuzzles(
          analysis: analysis,
          unit: unit,
          count: 2,
        );
      case 'simulation':
        return _aiService!.generateSimulations(
          analysis: analysis,
          unit: unit,
          count: 2,
        );
      default:
        throw Exception('Unknown content type: $contentType');
    }
  }

  Future<String> _saveItem(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'lesson':
        return _syllabusService!.saveGeneratedLesson(data);
      case 'quiz':
        return _syllabusService!.saveGeneratedQuiz(data);
      case 'puzzle':
        return _syllabusService!.saveGeneratedPuzzle(data);
      case 'simulation':
        return _syllabusService!.saveGeneratedSimulation(data);
      default:
        throw Exception('Unknown content type: $type');
    }
  }

  Map<String, dynamic> _completeLesson(
    Map<String, dynamic> item,
    AdminSyllabusAnalysis analysis,
    SyllabusUnit unit,
    int unitIndex,
  ) {
    String value(String key, String fallback) {
      final raw = item[key]?.toString().trim() ?? '';
      return raw.isEmpty ? fallback : raw;
    }

    String substantive(String key, String fallback, {required int minChars}) {
      final raw = item[key]?.toString().trim() ?? '';
      if (raw.isEmpty) return fallback;
      return raw.length >= minChars ? raw : '$raw\n\n$fallback';
    }

    List<String> list(String key, List<String> fallback) {
      final raw = item[key];
      if (raw is List) {
        final values = raw
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList();
        if (values.isNotEmpty) return values;
      }
      return fallback;
    }

    List<String> extendedList(
      String key,
      List<String> fallback, {
      required int minimum,
    }) {
      final values = List<String>.from(list(key, const []));
      for (final entry in fallback) {
        if (values.length >= minimum) break;
        if (!values.contains(entry)) values.add(entry);
      }
      return values.isEmpty ? fallback : values;
    }

    final topic = value(
      'topic',
      unit.topics.isNotEmpty ? unit.topics.first : unit.title,
    );
    final languageRaw = value('language', analysis.programmingLanguage);
    final language = languageRaw.toLowerCase() == 'java'
        ? 'Java'
        : languageRaw.toLowerCase().contains('javascript')
        ? 'JavaScript'
        : 'C++';
    final description = substantive(
      'description',
      'To understand $topic, begin by identifying the problem it solves and the information the program must process. Connect each new rule to a small example, then predict what the program will do before running it. This prediction-and-check cycle helps separate syntax problems from mistakes in the planned logic.\n\nAs you study the example, trace values in order and explain why each statement is needed. Afterward, change one input or condition and predict the new result. This turns $topic from a definition into a technique you can reuse in larger $language programs.',
      minChars: 500,
    );
    final generatedCode = value('sourceCode', _starterCode(language, topic));
    final code = _safeGeneratedCode(language, generatedCode, topic);
    final codeWasReplaced = code != generatedCode;

    return {
      ...item,
      'title': value('title', 'Introduction to $topic in $language'),
      'topic': topic,
      'language': language,
      'difficulty': value('difficulty', unit.difficulty),
      'description': description,
      'audiencePrograms': list('audiencePrograms', const [
        'BS Computer Science',
        'BS Information Technology',
        'BS Mathematics-CIT',
      ]),
      'yearLevels': list('yearLevels', const ['1st Year', '2nd Year']),
      'estimatedMinutes': item['estimatedMinutes'] is num
          ? (item['estimatedMinutes'] as num).toInt().clamp(35, 50)
          : 40,
      'learningObjective': value(
        'learningObjective',
        'By the end of this lesson, learners can explain $topic and apply it in a simple $language program.',
      ),
      'keyConcepts': extendedList('keyConcepts', [
        topic,
        'algorithm design',
        '$language syntax',
        'code tracing',
        'input and output',
      ], minimum: 5),
      'prerequisites': extendedList('prerequisites', const [
        'Basic programming concepts',
        'Reading simple program statements',
      ], minimum: 2),
      'introduction': substantive(
        'introduction',
        'Imagine you must explain the solution to a classmate who has never seen the code. What information would they need first, and which decision or operation should happen next? In this lesson, you will build that explanation using $topic, translate it into $language, and check the result one step at a time. Before reading the example, predict where $topic will affect the program output and write down your reason.',
        minChars: 300,
      ),
      'algorithmSteps': extendedList('algorithmSteps', [
        'Identify the input and the result required by the problem.',
        'Write a small example and predict its result before coding.',
        'Break the solution into ordered operations using $topic.',
        'Trace the important values or decisions after every operation.',
        'Implement the operations in $language.',
        'Run the program and compare the actual result with the expected output.',
        'Change one input or condition and explain how the result changes.',
      ], minimum: 6),
      'workedExample': substantive(
        'workedExample',
        'Start by reading the problem without looking at the finished output. List the input, the expected result, and the role of $topic. Then trace the runnable example line by line: record each important value, explain every decision, and predict the next state before continuing. Run the program only after completing the trace and compare the actual output with your prediction. If they differ, locate the first step where your recorded state no longer matches the program. Finally, modify one value or condition, predict the new output, and run the revised program to test your reasoning.',
        minChars: 450,
      ),
      'commonMistakes': substantive(
        'commonMistakes',
        'Watch for four patterns: skipping a planned step, writing invalid $language syntax, tracing values in the wrong order, and assuming the output without testing. A syntax error normally points to a malformed statement; inspect the reported line and the line immediately before it. A logic error may compile but produce the wrong result; use a small input and record the program state after each step. Correct one issue at a time and rerun the same test so you can tell which change solved the problem.',
        minChars: 350,
      ),
      'summary': substantive(
        'summary',
        'You learned how $topic moves from a problem statement to an ordered algorithm, then into runnable $language code. The most reliable workflow is to predict, trace, run, and compare. Before continuing, answer these checks: What problem does $topic solve? Which program state should you monitor while tracing it? How would you distinguish a syntax error from a logic error in this example?',
        minChars: 250,
      ),
      'errorFocus': value('errorFocus', 'Concept'),
      'sourceCode': code,
      'standardInput': value('standardInput', ''),
      'expectedOutput': codeWasReplaced
          ? 'Lesson example: $topic'
          : value('expectedOutput', 'Lesson example: $topic'),
      'pseudocode': value('pseudocode', ''),
      'compilerValidated': false,
      'sortOrder': item['sortOrder'] is num
          ? (item['sortOrder'] as num).toInt()
          : unitIndex + 1,
      'isPublished': false,
    };
  }

  String _starterCode(String language, String topic) {
    final message = 'Lesson example: $topic';
    if (language == 'Java') {
      return 'public class Main {\n  public static void main(String[] args) {\n    System.out.println("$message");\n  }\n}';
    }
    if (language == 'JavaScript') return 'console.log("$message");';
    return '#include <iostream>\nusing namespace std;\n\nint main() {\n  cout << "$message" << endl;\n  return 0;\n}';
  }

  String _safeGeneratedCode(String language, String source, String topic) {
    if (language != 'JavaScript') return source;
    final lower = source.toLowerCase();
    final usesUnsupportedFileApi =
        lower.contains('mockfile') ||
        RegExp(
          r'(^|\n)\s*(await\s+)?using\s+[a-z_$][\w$]*\s*=',
        ).hasMatch(source) ||
        lower.contains('filesystemaccess') ||
        lower.contains('showopenfilepicker') ||
        lower.contains('showsavefilepicker');
    return usesUnsupportedFileApi ? _starterCode(language, topic) : source;
  }

  Future<void> _finaliseJob({
    required String jobId,
    required String status,
    required int generatedCount,
    required int failedCount,
    String? error,
    required List<String> generatedIds,
  }) async {
    try {
      await _syllabusService!.updateJob(jobId, {
        'status': status,
        'generatedCount': generatedCount,
        'failedCount': failedCount,
        'errorMessage': error,
        'generatedIds': generatedIds,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    _generationError = null;
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
