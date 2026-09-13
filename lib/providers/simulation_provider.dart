import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:pseudocode_apk/models/code_simulation_activity.dart';
import 'package:pseudocode_apk/services/code_simulation_service.dart';
import 'package:pseudocode_apk/services/compiler_service.dart';
import 'package:pseudocode_apk/services/trusted_simulation_evaluator.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

enum ProgrammingLanguage { cpp, java, javascript }

extension ProgrammingLanguageX on ProgrammingLanguage {
  String get label {
    switch (this) {
      case ProgrammingLanguage.cpp:
        return 'C++';
      case ProgrammingLanguage.java:
        return 'Java';
      case ProgrammingLanguage.javascript:
        return 'Javascript';
    }
  }

  String get fileName {
    switch (this) {
      case ProgrammingLanguage.cpp:
        return 'main.cpp';
      case ProgrammingLanguage.java:
        return 'Main.java';
      case ProgrammingLanguage.javascript:
        return 'main.js';
    }
  }

  String get statusLabel {
    switch (this) {
      case ProgrammingLanguage.cpp:
        return 'Compiled C++';
      case ProgrammingLanguage.java:
        return 'Java Runtime';
      case ProgrammingLanguage.javascript:
        return 'JS Runtime';
    }
  }

  String get starterCode {
    switch (this) {
      case ProgrammingLanguage.cpp:
        return '#include <iostream>\nusing namespace std;\n\nint main() {\n  cout << "Hello, CoSci!" << endl;\n  return 0;\n}';
      case ProgrammingLanguage.java:
        return 'public class Main {\n  public static void main(String[] args) {\n    System.out.println("Hello, CoSci!");\n  }\n}';
      case ProgrammingLanguage.javascript:
        return 'function main() {\n  console.log("Hello, CoSci!");\n}\n\nmain();';
    }
  }

  static ProgrammingLanguage fromLabel(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'c++' || 'cpp' => ProgrammingLanguage.cpp,
      'java' => ProgrammingLanguage.java,
      'javascript' || 'js' => ProgrammingLanguage.javascript,
      _ => ProgrammingLanguage.cpp,
    };
  }

  String get runtimeName => switch (this) {
    ProgrammingLanguage.cpp => 'c++',
    ProgrammingLanguage.java => 'java',
    ProgrammingLanguage.javascript => 'javascript',
  };
}

class SimulationProvider extends ChangeNotifier {
  CodeSimulationService? _simulationService;
  AuthProvider? _authProvider;
  ProgrammingLanguage _selectedLanguage = ProgrammingLanguage.cpp;
  String _sampleCode = ProgrammingLanguage.cpp.starterCode;
  String _consoleOutput =
      'Console ready.\nSelect a language, then press "Run Code" to inspect the simulated output.';
  List<CodeSimulationActivity> _activities = const [];
  CodeSimulationActivity? _selectedActivity;
  String? _activityFeedback;
  bool _isLoadingActivities = false;
  bool _isRunning = false;
  bool _lastRunSuccessful = false;
  bool _lastSubmissionCorrect = false;
  bool _hasSubmittedActivity = false;
  ExecutionResult? _lastExecutionResult;
  List<SimulationCaseResult> _caseResults = const [];
  Timer? _draftTimer;
  bool _draftSaved = false;
  List<SimulationAttemptSummary> _attemptHistory = const [];
  CompilerHealth _compilerHealth = CompilerHealth.checking;
  int _revealedHintCount = 0;
  bool _fromLesson = false;
  String? _lessonPracticeTitle;

  List<CodeSimulationActivity> get activities => _activities;
  CodeSimulationActivity? get selectedActivity => _selectedActivity;
  String? get activityFeedback => _activityFeedback;
  bool get isLoadingActivities => _isLoadingActivities;
  ProgrammingLanguage get selectedLanguage => _selectedLanguage;
  String get sampleCode => _sampleCode;
  String get consoleOutput => _consoleOutput;
  bool get isRunning => _isRunning;
  bool get lastRunSuccessful => _lastRunSuccessful;
  bool get lastSubmissionCorrect => _lastSubmissionCorrect;
  bool get hasSubmittedActivity => _hasSubmittedActivity;
  ExecutionResult? get lastExecutionResult => _lastExecutionResult;
  List<SimulationCaseResult> get caseResults => _caseResults;
  bool get compilerConfigured => CompilerService.isConfigured;
  bool get draftSaved => _draftSaved;
  List<SimulationAttemptSummary> get attemptHistory => _attemptHistory;
  CompilerHealth get compilerHealth => _compilerHealth;
  int get revealedHintCount => _revealedHintCount;
  bool get fromLesson => _fromLesson;
  String? get lessonPracticeTitle => _lessonPracticeTitle;
  List<String> get revealedHints =>
      (_selectedActivity?.hints ?? const []).take(_revealedHintCount).toList();
  bool get canRevealHint =>
      _revealedHintCount < (_selectedActivity?.hints.length ?? 0);
  int get feedbackNotificationCount =>
      _attemptHistory.where((attempt) => attempt.feedback.isNotEmpty).length;
  String get masteryRecommendation {
    if (_attemptHistory.isEmpty) {
      return 'Complete a simulation to generate a recommendation.';
    }
    final rate =
        _attemptHistory.where((attempt) => attempt.passed).length /
        _attemptHistory.length;
    if (rate >= .8) {
      return 'Strong mastery. Try a harder simulation or move to a new topic.';
    }
    if (rate >= .5) {
      return 'Developing mastery. Repeat one guided activity before advancing.';
    }
    return 'Focus on the current topic and compiler feedback before trying a harder task.';
  }

  Future<void> refreshCompilerHealth() async {
    if (_compilerHealth == CompilerHealth.checking) return;
    _compilerHealth = CompilerHealth.checking;
    notifyListeners();
    _compilerHealth = await const CompilerService().checkHealth();
    notifyListeners();
  }

  SimulationMastery get mastery =>
      SimulationMastery.fromAttempts(_attemptHistory);
  CodeSimulationActivity? get recommendedActivity {
    if (_activities.isEmpty) return null;
    final failures = <String, int>{};
    for (final attempt in _attemptHistory.where((item) => !item.passed)) {
      if (attempt.topic.isNotEmpty) {
        failures[attempt.topic] = (failures[attempt.topic] ?? 0) + 1;
      }
    }
    final weakest = failures.entries.isEmpty
        ? null
        : (failures.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    final candidates = weakest == null
        ? _activities
        : _activities.where((item) => item.topic == weakest).toList();
    candidates.sort((a, b) {
      int rank(String value) => switch (value.toLowerCase()) {
        'easy' => 0,
        'medium' => 1,
        _ => 2,
      };
      return rank(a.difficulty).compareTo(rank(b.difficulty));
    });
    return candidates.firstOrNull;
  }

  void attach(
    CodeSimulationService simulationService,
    AuthProvider authProvider,
  ) {
    _simulationService = simulationService;
    _authProvider = authProvider;
  }

  Future<void> loadActivities({bool forceRefresh = false}) async {
    if (_simulationService == null || _isLoadingActivities) {
      return;
    }
    if (!forceRefresh && _activities.isNotEmpty) {
      return;
    }

    _isLoadingActivities = true;
    notifyListeners();

    try {
      _compilerHealth = await const CompilerService().checkHealth();
      _activities = await _simulationService!.fetchActivities();
      if (_selectedActivity == null && _activities.isNotEmpty) {
        selectActivity(_activities.first);
        await restoreDraft();
      }
      await loadAttemptHistory();
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }

  Future<void> loadAttemptHistory() async {
    final userId = _authProvider?.currentUser?.uid;
    if (userId == null || _simulationService == null) return;
    try {
      _attemptHistory = await _simulationService!.fetchAttemptHistory(userId);
      notifyListeners();
    } catch (_) {
      // Attempt history should not block the compiler workspace.
    }
  }

  void selectActivity(CodeSimulationActivity activity) {
    _selectedActivity = activity;
    _selectedLanguage = ProgrammingLanguageX.fromLabel(activity.language);
    _sampleCode = activity.starterCode.isNotEmpty
        ? activity.starterCode
        : _selectedLanguage.starterCode;
    _consoleOutput =
        '${activity.title} loaded.\nRun your code, then submit the task.';
    _lastRunSuccessful = false;
    _lastSubmissionCorrect = false;
    _hasSubmittedActivity = false;
    _activityFeedback = null;
    _caseResults = const [];
    _lastExecutionResult = null;
    _draftSaved = false;
    _revealedHintCount = 0;
    _fromLesson = false;
    _lessonPracticeTitle = null;
    notifyListeners();
  }

  void selectLanguage(ProgrammingLanguage language) {
    if (_selectedLanguage == language) {
      return;
    }

    _selectedLanguage = language;
    _selectedActivity = null;
    _sampleCode = language.starterCode;
    _consoleOutput =
        '${language.label} workspace loaded.\nPress "Run Code" to inspect the simulated output.';
    _lastRunSuccessful = false;
    _caseResults = const [];
    _lastExecutionResult = null;
    _revealedHintCount = 0;
    _fromLesson = false;
    _lessonPracticeTitle = null;
    notifyListeners();
  }

  void updateSampleCode(String value) {
    _sampleCode = value;
    _hasSubmittedActivity = false;
    _activityFeedback = null;
    _draftSaved = false;
    _draftTimer?.cancel();
    final workspaceId = _workspaceId;
    final language = _selectedLanguage.label;
    final sourceCode = _sampleCode;
    _draftTimer = Timer(
      const Duration(milliseconds: 900),
      () => _saveDraft(workspaceId, language, sourceCode),
    );
    notifyListeners();
  }

  void prepareLessonPractice({
    required String language,
    required String sourceCode,
    String stdin = '',
    String? lessonTitle,
  }) {
    _selectedActivity = null;
    _selectedLanguage = ProgrammingLanguageX.fromLabel(language);
    _sampleCode = sourceCode.trim().isEmpty
        ? _selectedLanguage.starterCode
        : sourceCode;
    _consoleOutput = stdin.trim().isEmpty
        ? 'Lesson practice loaded. Press "Run Code" to inspect the result.'
        : 'Lesson practice loaded. Use this input when prompted:\n$stdin';
    _lastExecutionResult = null;
    _caseResults = const [];
    _lastRunSuccessful = false;
    _fromLesson = true;
    _lessonPracticeTitle = lessonTitle;
    notifyListeners();
  }

  void revealNextHint() {
    if (!canRevealHint) return;
    _revealedHintCount += 1;
    notifyListeners();
  }

  String get _workspaceId =>
      _selectedActivity?.id ?? 'free_${_selectedLanguage.name}';

  Future<void> restoreDraft() async {
    final userId = _authProvider?.currentUser?.uid;
    if (userId == null || _simulationService == null) return;
    try {
      final draft = await _simulationService!.loadDraft(
        userId: userId,
        workspaceId: _workspaceId,
      );
      if (draft != null && draft.trim().isNotEmpty) {
        _sampleCode = draft;
        _draftSaved = true;
        notifyListeners();
      }
    } catch (_) {
      // Draft recovery is helpful but must not block the coding workspace.
    }
  }

  Future<void> _saveDraft(
    String workspaceId,
    String language,
    String sourceCode,
  ) async {
    final userId = _authProvider?.currentUser?.uid;
    if (userId == null || _simulationService == null) return;
    try {
      await _simulationService!.saveDraft(
        userId: userId,
        workspaceId: workspaceId,
        language: language,
        sourceCode: sourceCode,
      );
      _draftSaved = true;
      notifyListeners();
    } catch (_) {
      _draftSaved = false;
      notifyListeners();
    }
  }

  Future<void> runCode() async {
    if (_isRunning) {
      return;
    }

    _isRunning = true;
    notifyListeners();

    final timer = Stopwatch()..start();
    final result = await const CompilerService().execute(
      language: _selectedLanguage,
      sourceCode: _sampleCode,
      stdin: _selectedActivity?.stdin ?? '',
    );
    timer.stop();
    final label = switch (result.status) {
      ExecutionStatus.syntaxError => 'SYNTAX ERROR',
      ExecutionStatus.runtimeError => 'RUNTIME ERROR',
      ExecutionStatus.serviceError => 'SERVICE ERROR',
      _ => 'OUTPUT',
    };
    _consoleOutput =
        '> Compiling ${_selectedLanguage.fileName}\n> ${result.message}\n$label: ${result.output}';
    _lastExecutionResult = result;
    _lastRunSuccessful = result.succeeded;
    _compilerHealth = result.status == ExecutionStatus.serviceError
        ? CompilerHealth.offline
        : CompilerHealth.online;
    final userId = _authProvider?.currentUser?.uid;
    if (userId != null) {
      try {
        await _simulationService?.recordAttempt(
          userId: userId,
          activity: _selectedActivity,
          language: _selectedLanguage.label,
          sourceCode: _sampleCode,
          output: result.output,
          result: result.succeeded ? 'compiled' : result.status.name,
          executionTimeMs: timer.elapsedMilliseconds,
          errorCategory: result.status.name,
          activityVersion: _selectedActivity?.version ?? 1,
        );
      } catch (_) {
        // A telemetry write must not hide a valid compiler result.
      }
    }
    _isRunning = false;
    notifyListeners();
  }

  void resetWorkspace() {
    _sampleCode = _selectedActivity?.starterCode.isNotEmpty == true
        ? _selectedActivity!.starterCode
        : _selectedLanguage.starterCode;
    _consoleOutput =
        '${_selectedLanguage.label} workspace reset.\nPress "Run Code" to inspect the simulated output.';
    _lastRunSuccessful = false;
    _lastSubmissionCorrect = false;
    _hasSubmittedActivity = false;
    _activityFeedback = null;
    _caseResults = const [];
    _lastExecutionResult = null;
    notifyListeners();
  }

  void clearConsole() {
    _consoleOutput = 'Console cleared. Run your code when ready.';
    _lastExecutionResult = null;
    _caseResults = const [];
    notifyListeners();
  }

  Future<bool> submitSelectedActivity() async {
    final activity = _selectedActivity;
    if (activity == null || _isRunning) {
      _activityFeedback = 'Choose a task first.';
      notifyListeners();
      return false;
    }

    _isRunning = true;
    _caseResults = const [];
    notifyListeners();
    final results = <SimulationCaseResult>[];
    final timer = Stopwatch()..start();
    for (final testCase in activity.effectiveTestCases) {
      final execution = await const CompilerService().execute(
        language: _selectedLanguage,
        sourceCode: _sampleCode,
        stdin: testCase.stdin,
      );
      final passed =
          execution.succeeded &&
          _normalizeOutput(execution.output) ==
              _normalizeOutput(testCase.expectedOutput);
      results.add(
        SimulationCaseResult(
          testCase: testCase,
          execution: execution,
          passed: passed,
        ),
      );
      if (!execution.succeeded) break;
    }
    _caseResults = results;
    _lastExecutionResult = results.isEmpty ? null : results.last.execution;
    _lastRunSuccessful =
        results.isNotEmpty &&
        results.every((result) => result.execution.succeeded);
    var isCorrect =
        results.length == activity.effectiveTestCases.length &&
        results.every((result) => result.passed);

    var trustedPassed = activity.hiddenTestCount == 0;
    var trustedAvailable = activity.hiddenTestCount == 0;
    var trustedMessage = '';
    var trustedPassedTests = 0;
    var trustedTotalTests = activity.hiddenTestCount;
    if (isCorrect && activity.hiddenTestCount > 0) {
      final trusted = await const TrustedSimulationEvaluator().evaluate(
        activityId: activity.id,
        language: _selectedLanguage,
        sourceCode: _sampleCode,
      );
      trustedAvailable = trusted.available;
      trustedPassed = trusted.available && trusted.passed;
      trustedMessage = trusted.message;
      if (trusted.available) {
        trustedPassedTests = trusted.passedTests;
        trustedTotalTests = trusted.totalTests == 0
            ? activity.hiddenTestCount
            : trusted.totalTests;
        isCorrect = trustedPassed;
      } else {
        // Local/self-hosted compiler installations can still validate all
        // public cases. Hidden tests become mandatory only when their trusted
        // evaluator endpoint is available.
        trustedPassedTests = 0;
        trustedTotalTests = 0;
      }
    }
    timer.stop();
    _isRunning = false;

    _lastSubmissionCorrect = isCorrect;
    _hasSubmittedActivity = true;
    _activityFeedback = isCorrect
        ? activity.hiddenTestCount > 0 && !trustedAvailable
              ? 'Passed all available test cases. Hidden-test verification is currently offline.'
              : 'Correct. Your output matches the expected result.'
        : trustedMessage.isNotEmpty
        ? trustedMessage
        : _submissionFailureMessage(
            results,
            activity.effectiveTestCases.length,
          );
    final userId = _authProvider?.currentUser?.uid;
    if (userId != null) {
      try {
        await _simulationService?.recordAttempt(
          userId: userId,
          activity: activity,
          language: _selectedLanguage.label,
          sourceCode: _sampleCode,
          output: results.isEmpty ? '' : results.last.execution.output,
          result: isCorrect ? 'passed' : 'possibleLogicError',
          submissionStatus: isCorrect ? 'passed' : 'failed',
          passedTests:
              results.where((item) => item.passed).length + trustedPassedTests,
          totalTests: activity.effectiveTestCases.length + trustedTotalTests,
          executionTimeMs: timer.elapsedMilliseconds,
          errorCategory: results.any((item) => !item.execution.succeeded)
              ? (results
                    .firstWhere((item) => !item.execution.succeeded)
                    .execution
                    .status
                    .name)
              : (!trustedAvailable || trustedPassed
                    ? 'none'
                    : 'possibleLogicError'),
          activityVersion: activity.version,
        );
        await loadAttemptHistory();
      } catch (_) {
        // The evaluation result remains valid if history syncing fails.
      }
    }
    notifyListeners();
    return isCorrect;
  }

  String _submissionFailureMessage(
    List<SimulationCaseResult> results,
    int total,
  ) {
    if (results.isEmpty) return 'The compiler could not run the test cases.';
    final failed = results.where((result) => !result.passed).first;
    if (!failed.execution.succeeded) return failed.execution.message;
    return 'Possible logic error. ${results.where((item) => item.passed).length} of $total test cases passed.';
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    super.dispose();
  }
}

class SimulationMastery {
  const SimulationMastery({
    required this.attempts,
    required this.compilerRate,
    required this.logicRate,
    required this.firstAttemptRate,
    required this.averageAttemptsToPass,
  });
  final int attempts;
  final int compilerRate;
  final int logicRate;
  final int firstAttemptRate;
  final double averageAttemptsToPass;

  factory SimulationMastery.fromAttempts(
    List<SimulationAttemptSummary> attempts,
  ) {
    if (attempts.isEmpty) {
      return const SimulationMastery(
        attempts: 0,
        compilerRate: 0,
        logicRate: 0,
        firstAttemptRate: 0,
        averageAttemptsToPass: 0,
      );
    }
    final compilerSuccess = attempts
        .where(
          (item) => ![
            'syntaxError',
            'runtimeError',
            'serviceError',
          ].contains(item.errorCategory),
        )
        .length;
    final submissions = attempts.where((item) => item.totalTests > 0).toList();
    final passed = submissions.where((item) => item.passed).length;
    final grouped = <String, List<SimulationAttemptSummary>>{};
    for (final item in submissions.reversed) {
      grouped.putIfAbsent('${item.topic}|${item.title}', () => []).add(item);
    }
    final attemptsToPass = grouped.values.map((items) {
      final index = items.indexWhere((item) => item.passed);
      return index < 0 ? items.length : index + 1;
    }).toList();
    final firstPasses = grouped.values
        .where((items) => items.isNotEmpty && items.first.passed)
        .length;
    return SimulationMastery(
      attempts: attempts.length,
      compilerRate: (compilerSuccess * 100 / attempts.length).round(),
      logicRate: submissions.isEmpty
          ? 0
          : (passed * 100 / submissions.length).round(),
      firstAttemptRate: grouped.isEmpty
          ? 0
          : (firstPasses * 100 / grouped.length).round(),
      averageAttemptsToPass: attemptsToPass.isEmpty
          ? 0
          : attemptsToPass.reduce((a, b) => a + b) / attemptsToPass.length,
    );
  }
}

class SimulationCaseResult {
  const SimulationCaseResult({
    required this.testCase,
    required this.execution,
    required this.passed,
  });

  final SimulationTestCase testCase;
  final ExecutionResult execution;
  final bool passed;
}

String _normalizeOutput(String value) {
  return value
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n')
      .toLowerCase();
}
