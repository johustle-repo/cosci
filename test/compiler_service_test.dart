import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/services/compiler_service.dart';

void main() {
  test('rejects empty source before sending a request', () async {
    var called = false;
    final service = CompilerService(
      endpoint: 'https://compiler.test/execute',
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );
    final result = await service.execute(
      language: ProgrammingLanguage.cpp,
      sourceCode: '',
    );
    expect(result.status, ExecutionStatus.syntaxError);
    expect(called, isFalse);
  });

  test('classifies compiler failure as syntax error and sends stdin', () async {
    final service = CompilerService(
      endpoint: 'https://compiler.test/execute',
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['stdin'], '7');
        return http.Response(
          jsonEncode({
            'compile': {'code': 1, 'stderr': 'Main.java:1: error'},
            'run': {'code': 0, 'stdout': ''},
          }),
          200,
        );
      }),
    );
    final result = await service.execute(
      language: ProgrammingLanguage.java,
      sourceCode: 'public class Main {',
      stdin: '7',
    );
    expect(result.status, ExecutionStatus.syntaxError);
  });

  test('extracts line and column from compiler diagnostics', () async {
    final service = CompilerService(
      endpoint: 'https://compiler.test/execute',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'compile': {
              'code': 1,
              'stderr': 'main.cpp:8:14: error: expected ;',
            },
            'run': {'code': 0, 'stdout': ''},
          }),
          200,
        ),
      ),
    );
    final result = await service.execute(
      language: ProgrammingLanguage.cpp,
      sourceCode: 'int main() {}',
    );
    expect(result.line, 8);
    expect(result.column, 14);
    expect(result.message, contains('line 8'));
  });

  test('reports compiler runtime health', () async {
    final service = CompilerService(
      endpoint: 'https://compiler.test/api/v2/execute',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v2/runtimes');
        return http.Response('[]', 200);
      }),
    );
    expect(await service.checkHealth(), CompilerHealth.online);
  });

  test('reports a missing C++ toolchain as a service problem', () async {
    final service = CompilerService(
      endpoint: 'https://compiler.test/execute',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'compile': {
              'code': 127,
              'stderr': 'Runtime unavailable: spawn g++ ENOENT',
            },
          }),
          200,
        ),
      ),
    );

    final result = await service.execute(
      language: ProgrammingLanguage.cpp,
      sourceCode: 'int main() { return 0; }',
    );

    expect(result.status, ExecutionStatus.serviceError);
    expect(result.message, contains('C++ toolchain is missing'));
  });

  test('uses the public Java class name as the source filename', () async {
    final service = CompilerService(
      endpoint: 'https://compiler.test/execute',
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final files = body['files'] as List<dynamic>;
        expect((files.first as Map<String, dynamic>)['name'], 'Variables.java');
        return http.Response(
          jsonEncode({
            'compile': {'code': 0, 'stderr': '', 'output': ''},
            'run': {'code': 0, 'stdout': 'Hello'},
          }),
          200,
        );
      }),
    );

    final result = await service.execute(
      language: ProgrammingLanguage.java,
      sourceCode:
          'public class Variables { public static void main(String[] args) {} }',
    );
    expect(result.status, ExecutionStatus.passed);
  });
}
