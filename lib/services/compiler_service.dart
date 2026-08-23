import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pseudocode_apk/providers/simulation_provider.dart';

enum ExecutionStatus {
  passed,
  syntaxError,
  runtimeError,
  possibleLogicError,
  serviceError,
}

enum CompilerHealth { checking, online, offline, notConfigured }

class ExecutionResult {
  const ExecutionResult({
    required this.status,
    required this.output,
    required this.message,
    this.line,
    this.column,
  });
  final ExecutionStatus status;
  final String output;
  final String message;
  final int? line;
  final int? column;
  bool get succeeded => status == ExecutionStatus.passed;
  String get categoryLabel => switch (status) {
    ExecutionStatus.passed => 'Compiled successfully',
    ExecutionStatus.syntaxError => 'Syntax or compilation error',
    ExecutionStatus.runtimeError => 'Runtime error',
    ExecutionStatus.possibleLogicError => 'Possible logic error',
    ExecutionStatus.serviceError => 'Compiler service problem',
  };
  String get learnerExplanation => switch (status) {
    ExecutionStatus.passed =>
      'The compiler accepted and ran the program. Submit the activity to check whether its logic is correct.',
    ExecutionStatus.syntaxError =>
      'The compiler could not understand part of the code. Check punctuation, spelling, brackets, and the highlighted line.',
    ExecutionStatus.runtimeError =>
      'The program started but stopped unexpectedly. Check input handling, array positions, and operations that may be invalid while running.',
    ExecutionStatus.possibleLogicError =>
      'The program ran, but its result did not match the required behavior.',
    ExecutionStatus.serviceError =>
      'Your code was not evaluated because the compiler service could not respond.',
  };
  String get nextStep => switch (status) {
    ExecutionStatus.passed =>
      'Review the output, then use Submit to run the activity tests.',
    ExecutionStatus.syntaxError =>
      'Fix the first reported error, then run the code again.',
    ExecutionStatus.runtimeError =>
      'Trace the values used near the reported line and retry.',
    ExecutionStatus.possibleLogicError =>
      'Compare each algorithm step with the expected output.',
    ExecutionStatus.serviceError =>
      'Check the compiler connection and use Retry.',
  };
}

class CompilerService {
  const CompilerService({http.Client? client, String? endpoint})
    : _client = client,
      _configuredEndpoint = endpoint;
  final http.Client? _client;
  final String? _configuredEndpoint;
  static const _endpoint = String.fromEnvironment(
    'COMPILER_API_URL',
    defaultValue: '',
  );

  static String get _resolvedDefaultEndpoint {
    if (_endpoint.trim().isNotEmpty) return _endpoint.trim();

    // During local Flutter web development, use the bundled CoSci compiler
    // automatically. Production deployments still require an explicit URL so
    // an HTTPS page never attempts an unsafe mixed-content request.
    final host = Uri.base.host.toLowerCase();
    final isLocal = host.isEmpty || host == 'localhost' || host == '127.0.0.1';
    if (isLocal) return 'http://localhost:8787/api/v2/execute';
    return '';
  }

  static bool get isConfigured => _resolvedDefaultEndpoint.isNotEmpty;

  Future<CompilerHealth> checkHealth() async {
    final endpoint = _configuredEndpoint ?? _resolvedDefaultEndpoint;
    if (endpoint.trim().isEmpty) return CompilerHealth.notConfigured;
    final client = _client ?? http.Client();
    try {
      final executeUri = Uri.parse(endpoint);
      final healthUri = executeUri.replace(
        path: executeUri.path.replaceFirst(RegExp(r'execute/?$'), 'runtimes'),
      );
      final response = await client
          .get(healthUri)
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300
          ? CompilerHealth.online
          : CompilerHealth.offline;
    } catch (_) {
      return CompilerHealth.offline;
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<ExecutionResult> execute({
    required ProgrammingLanguage language,
    required String sourceCode,
    String stdin = '',
  }) async {
    final client = _client ?? http.Client();
    final endpoint = _configuredEndpoint ?? _resolvedDefaultEndpoint;
    try {
      if (endpoint.isEmpty) {
        return const ExecutionResult(
          status: ExecutionStatus.serviceError,
          output: '',
          message:
              'Compiler is not configured. Start the CoSci compiler service or provide COMPILER_API_URL.',
        );
      }
      if (sourceCode.trim().isEmpty) {
        return const ExecutionResult(
          status: ExecutionStatus.syntaxError,
          output: '',
          message: 'Enter source code before running the compiler.',
        );
      }
      if (utf8.encode(sourceCode).length > 50000) {
        return const ExecutionResult(
          status: ExecutionStatus.serviceError,
          output: '',
          message: 'Source code exceeds the 50 KB learning-workspace limit.',
        );
      }
      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'language': language.runtimeName,
              'version': '*',
              'files': [
                {
                  'name': _sourceFileName(language, sourceCode),
                  'content': sourceCode,
                },
              ],
              'compile_timeout': 10000,
              'run_timeout': 5000,
              'stdin': stdin,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ExecutionResult(
          status: ExecutionStatus.serviceError,
          output: '',
          message: 'Compiler service returned HTTP ${response.statusCode}.',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final compile = data['compile'] as Map<String, dynamic>?;
      final run = data['run'] as Map<String, dynamic>?;
      final compileCode = (compile?['code'] as num?)?.toInt() ?? 0;
      final runCode = (run?['code'] as num?)?.toInt() ?? 0;
      final compileText =
          '${compile?['stderr'] ?? ''}${compile?['output'] ?? ''}'.trim();
      final output = '${run?['stdout'] ?? ''}'.trimRight();
      final runtimeText = '${run?['stderr'] ?? ''}'.trim();
      if (compileCode != 0 || compileText.isNotEmpty) {
        if (_isMissingRuntime(compileText)) {
          return ExecutionResult(
            status: ExecutionStatus.serviceError,
            output: '',
            message: _missingRuntimeMessage(language),
          );
        }
        final location = _diagnosticLocation(compileText);
        return ExecutionResult(
          status: ExecutionStatus.syntaxError,
          output: compileText,
          message: location.$1 == null
              ? 'Syntax or compilation error detected.'
              : 'Syntax or compilation error near line ${location.$1}${location.$2 == null ? '' : ', column ${location.$2}'}.',
          line: location.$1,
          column: location.$2,
        );
      }
      if (runCode != 0 || runtimeText.isNotEmpty) {
        final location = _diagnosticLocation(runtimeText);
        return ExecutionResult(
          status: ExecutionStatus.runtimeError,
          output: runtimeText,
          message: location.$1 == null
              ? 'Runtime error detected.'
              : 'Runtime error near line ${location.$1}.',
          line: location.$1,
          column: location.$2,
        );
      }
      return ExecutionResult(
        status: ExecutionStatus.passed,
        output: output,
        message: 'Compiled and executed successfully.',
      );
    } catch (error) {
      return ExecutionResult(
        status: ExecutionStatus.serviceError,
        output: '',
        message:
            'Compiler unavailable. Start it with npm.cmd run compiler:start, then retry. ($error)',
      );
    } finally {
      if (_client == null) client.close();
    }
  }
}

bool _isMissingRuntime(String diagnostic) {
  final text = diagnostic.toLowerCase();
  return text.contains('runtime unavailable:') ||
      text.contains('spawn g++ enoent') ||
      text.contains('spawn javac enoent') ||
      text.contains('spawn java enoent') ||
      text.contains('is not recognized as an internal or external command');
}

String _missingRuntimeMessage(
  ProgrammingLanguage language,
) => switch (language) {
  ProgrammingLanguage.cpp =>
    'The CoSci compiler service is online, but its C++ toolchain is missing. Install g++ on the server, restart npm.cmd run compiler:start, then retry.',
  ProgrammingLanguage.java =>
    'The CoSci compiler service is online, but its Java JDK is missing. Install a JDK on the server, restart npm.cmd run compiler:start, then retry.',
  ProgrammingLanguage.javascript =>
    'The CoSci compiler service is online, but its Node.js runtime is unavailable. Install Node.js on the server and restart the compiler service.',
};

String _sourceFileName(ProgrammingLanguage language, String sourceCode) {
  if (language != ProgrammingLanguage.java) return language.fileName;

  final publicType = RegExp(
    r'\bpublic\s+(?:final\s+|abstract\s+)?(?:class|interface|enum|record)\s+([A-Za-z_$][A-Za-z0-9_$]*)',
  ).firstMatch(sourceCode);
  final typeName = publicType?.group(1);
  return typeName == null ? language.fileName : '$typeName.java';
}

(int?, int?) _diagnosticLocation(String text) {
  final match = RegExp(r'(?:[A-Za-z0-9_.-]+:)?(\d+):(\d+)').firstMatch(text);
  if (match != null) {
    return (int.tryParse(match.group(1)!), int.tryParse(match.group(2)!));
  }
  final lineOnly = RegExp(
    r'\bline\s+(\d+)\b',
    caseSensitive: false,
  ).firstMatch(text);
  return (lineOnly == null ? null : int.tryParse(lineOnly.group(1)!), null);
}
