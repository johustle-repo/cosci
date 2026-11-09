import 'package:pseudocode_apk/providers/simulation_provider.dart';

/// Broad class of a failed run, shown as a badge next to the error name.
enum ErrorKind { syntax, compilation, runtime, timeout }

extension ErrorKindX on ErrorKind {
  String get label => switch (this) {
    ErrorKind.syntax => 'Syntax error',
    ErrorKind.compilation => 'Compilation error',
    ErrorKind.runtime => 'Runtime error',
    ErrorKind.timeout => 'Time limit',
  };
}

/// A learner-friendly explanation of the specific mistake in a student's
/// program: which error it is, where it is, what it means, and how to fix it.
class ErrorDiagnosis {
  const ErrorDiagnosis({
    required this.kind,
    required this.title,
    required this.explanation,
    required this.fix,
    this.line,
    this.column,
    this.codeLine,
    this.compilerMessage,
  });

  final ErrorKind kind;

  /// Specific name of the mistake, e.g. "Missing semicolon".
  final String title;

  /// What the error means, in plain words.
  final String explanation;

  /// What the student should change.
  final String fix;

  final int? line;
  final int? column;

  /// The student's own source line at [line], when known.
  final String? codeLine;

  /// The key line of the compiler/runtime message, for reference.
  final String? compilerMessage;
}

/// Turns raw compiler or runtime output into an [ErrorDiagnosis].
class ErrorDiagnoser {
  const ErrorDiagnoser._();

  /// [diagnostic] is the compiler stderr for compile failures, or the program
  /// stderr (or a synthesized exit/signal description) for runtime failures.
  static ErrorDiagnosis diagnose({
    required ProgrammingLanguage language,
    required String sourceCode,
    required String diagnostic,
    required bool compileFailed,
    bool timedOut = false,
  }) {
    final location = locate(language, diagnostic);
    final line = location.$1;
    final codeLine = _sourceLine(sourceCode, line);
    final keyMessage = _keyMessage(diagnostic);

    if (timedOut) {
      return ErrorDiagnosis(
        kind: ErrorKind.timeout,
        title: 'Program took too long (possible infinite loop)',
        explanation:
            'The program did not finish within the time limit. This usually '
            'means a loop whose condition never becomes false, or code that '
            'waits for input that was never provided.',
        fix:
            'Check that every loop updates the variable in its condition '
            '(for example i++ inside a while loop), and add every value the '
            'program reads to Standard input.',
        line: line,
        column: location.$2,
        codeLine: codeLine,
        compilerMessage: keyMessage,
      );
    }

    final rules = compileFailed
        ? _compileRules(language)
        : _runtimeRules(language);
    final text = diagnostic;
    for (final rule in rules) {
      final match = rule.pattern.firstMatch(text);
      if (match == null) continue;
      String fill(String template) =>
          template.replaceAllMapped(RegExp(r'\$(\d)'), (m) {
            final group = int.parse(m.group(1)!);
            return group <= match.groupCount ? (match.group(group) ?? '') : '';
          });
      return ErrorDiagnosis(
        kind:
            rule.kind ??
            (compileFailed ? ErrorKind.compilation : ErrorKind.runtime),
        title: fill(rule.title),
        explanation: fill(rule.explanation),
        fix: fill(rule.fix),
        line: line,
        column: location.$2,
        codeLine: codeLine,
        compilerMessage: keyMessage,
      );
    }

    return ErrorDiagnosis(
      kind: compileFailed ? ErrorKind.compilation : ErrorKind.runtime,
      title: compileFailed
          ? 'The compiler rejected the code'
          : 'The program stopped with an error',
      explanation: compileFailed
          ? 'The code does not follow the rules of ${language.label}, so it '
                'could not be compiled.'
          : 'The program compiled and started, but an operation failed while '
                'it was running.',
      fix: line == null
          ? 'Read the compiler message below and fix the first error it reports.'
          : 'Look at line $line and the compiler message below. Fix the first '
                'error, then run again.',
      line: line,
      column: location.$2,
      codeLine: codeLine,
      compilerMessage: keyMessage,
    );
  }

  /// Line and column of the first error that points into the student's file.
  static (int?, int?) locate(ProgrammingLanguage language, String text) {
    final patterns = switch (language) {
      ProgrammingLanguage.cpp => [
        RegExp(r'main\.cpp:(\d+):(\d+)'),
        RegExp(r'main\.cpp:(\d+)'),
      ],
      ProgrammingLanguage.java => [
        // javac: Main.java:5: error: ...
        RegExp(r'\b[A-Za-z_$][\w$]*\.java:(\d+):'),
        // runtime stack: at Main.main(Main.java:5)
        RegExp(r'\([A-Za-z_$][\w$]*\.java:(\d+)\)'),
      ],
      ProgrammingLanguage.javascript => [
        RegExp(r'main\.js:(\d+):(\d+)'),
        RegExp(r'main\.js:(\d+)'),
      ],
    };
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return (
          int.tryParse(match.group(1)!),
          match.groupCount >= 2 ? int.tryParse(match.group(2) ?? '') : null,
        );
      }
    }
    final generic = RegExp(
      r'\bline\s+(\d+)\b',
      caseSensitive: false,
    ).firstMatch(text);
    return (generic == null ? null : int.tryParse(generic.group(1)!), null);
  }

  static String? _sourceLine(String source, int? line) {
    if (line == null || line < 1) return null;
    final lines = source.split('\n');
    if (line > lines.length) return null;
    final value = lines[line - 1].trimRight();
    return value.trim().isEmpty ? null : value;
  }

  /// The most informative single line of the raw message.
  static String? _keyMessage(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;
    final errorLine = lines.firstWhere(
      (l) =>
          l.contains('error') ||
          l.contains('Exception') ||
          l.contains('Error:') ||
          l.startsWith('terminate called') ||
          l.startsWith('Program '),
      orElse: () => lines.first,
    );
    return errorLine.length > 240
        ? '${errorLine.substring(0, 240)}…'
        : errorLine;
  }
}

class _Rule {
  const _Rule(
    this.pattern,
    this.title,
    this.explanation,
    this.fix, {
    this.kind,
  });

  final RegExp pattern;
  final String title;
  final String explanation;
  final String fix;
  final ErrorKind? kind;
}

RegExp _r(String source) => RegExp(source, caseSensitive: false);

// Quotes in g++ output may be ASCII ('x') or typographic (‘x’).
const _q = "['‘’\"]";

List<_Rule> _compileRules(ProgrammingLanguage language) => switch (language) {
  ProgrammingLanguage.cpp => _cppCompileRules,
  ProgrammingLanguage.java => _javaCompileRules,
  ProgrammingLanguage.javascript => _jsRules,
};

List<_Rule> _runtimeRules(ProgrammingLanguage language) => switch (language) {
  ProgrammingLanguage.cpp => _cppRuntimeRules,
  ProgrammingLanguage.java => _javaRuntimeRules,
  ProgrammingLanguage.javascript => _jsRules,
};

final _cppCompileRules = <_Rule>[
  _Rule(
    _r('missing terminating'),
    'Unclosed string or character',
    'A text value was opened with a quote but never closed on the same line.',
    'Add the closing quote. Text uses double quotes ("Hello") and a single '
        'character uses single quotes (\'A\').',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('expected $_q?;$_q?'),
    'Missing semicolon (;)',
    'Every C++ statement must end with a semicolon. The compiler reached the '
        'next part of the code while still waiting for one.',
    'Add ; at the end of the statement on the reported line, or on the line '
        'just above it.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r("expected $_q\\}$_q at end of input"),
    'Missing closing brace }',
    'A block opened with { (a function, loop, or if) was never closed.',
    'Count your { and } braces and add the missing } where the block should end.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r("expected $_q\\)$_q"),
    'Missing closing parenthesis )',
    'A parenthesis was opened with ( but not closed.',
    'Add the missing ) — for example, if (x > 0) or cout << (a + b).',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r("$_q(cout|cin|endl|string|vector)$_q was not declared"),
    "'\$1' is not available",
    "'\$1' belongs to the C++ standard library, which this program cannot see "
        'yet.',
    'Add the matching #include at the top (for example #include <iostream> '
        'for cout and cin) and either write std::\$1 or add '
        'using namespace std;.',
  ),
  _Rule(
    _r("$_q([A-Za-z_]\\w*)$_q was not declared in this scope"),
    "Undeclared variable or function '\$1'",
    "The name '\$1' is used before it was declared, or it is misspelled. C++ "
        'names are case-sensitive.',
    "Declare '\$1' with a type before using it (for example int \$1 = 0;), or "
        'fix the spelling so it matches the declaration.',
  ),
  _Rule(
    _r("$_q([A-Za-z_]\\w*)$_q does not name a type"),
    "Unknown type '\$1'",
    "The compiler does not know the type '\$1'. It may be misspelled or need an "
        '#include.',
    'Check the spelling (int, double, string, bool) and that the needed '
        'header is included.',
  ),
  _Rule(
    _r('(redeclaration|conflicting declaration) of .*?$_q?([A-Za-z_]\\w*)$_q'),
    "Variable '\$2' declared twice",
    "'\$2' is declared more than once in the same block.",
    'Remove the type from the second declaration to reuse the variable, or '
        'give the new variable a different name.',
  ),
  _Rule(
    _r('expected primary-expression before'),
    'Incomplete expression',
    'An operator or value is missing, for example a + with nothing after it, '
        'or a type name used where a value was expected.',
    'Check the expression on the reported line and fill in the missing value '
        'or operator.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r(
      '(invalid conversion|cannot convert) from $_q?(.+?)$_q? to $_q?(.+?)$_q',
    ),
    'Type mismatch',
    'A value of type \$2 is used where \$3 is required.',
    'Use a value of the correct type, or convert it explicitly.',
  ),
  _Rule(
    _r("no match for $_q?operator"),
    'Operator not valid for these types',
    'An operator such as <<, >>, +, or == is used with values that do not '
        'support it.',
    'Check the types on both sides of the operator, e.g. use cout << and '
        'cin >> in the right direction.',
  ),
  _Rule(
    _r('too (few|many) arguments to function'),
    'Wrong number of arguments',
    'A function is called with too \$1 arguments compared with its definition.',
    'Pass exactly the parameters the function declares, in the same order.',
  ),
  _Rule(
    _r('lvalue required'),
    'Invalid assignment',
    'The left side of = must be a variable. You may have written = where '
        '== was intended.',
    'Use == to compare values, and = only to store a value in a variable.',
  ),
  _Rule(
    _r("undefined reference to [`'‘]main"),
    'Missing main function',
    'Every C++ program needs an int main() function where execution starts.',
    'Add int main() { ... return 0; }.',
  ),
  _Rule(
    _r("expected .*? before $_q"),
    'Unexpected symbol',
    'The compiler found a symbol where it expected something else, often '
        'because of a missing ; ) or } just before it.',
    'Check the reported line and the one above it for a missing semicolon, '
        'parenthesis, or brace.',
    kind: ErrorKind.syntax,
  ),
];

final _cppRuntimeRules = <_Rule>[
  _Rule(
    _r("std::out_of_range"),
    'Index out of range',
    'The program used .at() (or similar) with a position that does not '
        'exist in the vector or string.',
    'Valid positions are 0 to size()-1. Check loop bounds such as i <= n '
        '(should usually be i < n).',
  ),
  _Rule(
    _r('std::invalid_argument|stoi|stod'),
    'Invalid number conversion',
    'Text that is not a number was converted to a number (stoi/stod).',
    'Make sure the input is a valid number before converting it.',
  ),
  _Rule(
    _r('std::bad_alloc'),
    'Out of memory',
    'The program tried to allocate more memory than allowed.',
    'Check for very large arrays or vectors, or a loop that keeps adding items.',
  ),
  _Rule(
    _r('SIGFPE|floating point exception|exit code (136|3221225620)'),
    'Division by zero',
    'The program divided an integer by zero (or used % with zero), which '
        'stops it immediately.',
    'Before dividing, check that the divisor is not 0 — for example '
        'if (b != 0) { cout << a / b; }.',
  ),
  _Rule(
    _r('SIGSEGV|segmentation fault|exit code (139|3221225477)'),
    'Invalid memory access (segmentation fault)',
    'The program read or wrote memory it does not own. The usual causes are '
        'an array index outside its size or using an uninitialized pointer.',
    'Check that every array index is between 0 and size-1, and that loops '
        'stop before the end of the array.',
  ),
  _Rule(
    _r('stack overflow|exit code 3221225725'),
    'Stack overflow (infinite recursion)',
    'A function kept calling itself without reaching a stopping case.',
    'Add or fix the base case of the recursive function.',
  ),
  _Rule(
    _r('SIGABRT|aborted|exit code (134|3221226505)'),
    'Program aborted',
    'The program was stopped by a failed check, such as an exception that '
        'was never caught or an invalid memory operation.',
    'Check array and string positions and any values passed to library '
        'functions near the reported line.',
  ),
  _Rule(
    _r('exit code (\\d+)'),
    'Program ended with exit code \$1',
    'main() finished with a non-zero value, which signals an error.',
    'Make sure main() ends with return 0; when the program succeeds.',
  ),
];

final _javaCompileRules = <_Rule>[
  _Rule(
    _r("';' expected"),
    'Missing semicolon (;)',
    'Every Java statement must end with a semicolon.',
    'Add ; at the end of the statement on the reported line.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('reached end of file while parsing'),
    'Missing closing brace }',
    'A class, method, or block was opened with { but never closed.',
    'Count your { and } braces and add the missing }.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r("'\\)' expected"),
    'Missing closing parenthesis )',
    'A parenthesis was opened with ( but not closed.',
    'Add the missing ).',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('unclosed string literal'),
    'Unclosed string',
    'A string was opened with " but never closed on the same line.',
    'Add the closing double quote.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('cannot find symbol[\\s\\S]*?symbol:\\s+variable\\s+(\\w+)'),
    "Undeclared variable '\$1'",
    "The variable '\$1' is used before it was declared, or it is misspelled. "
        'Java names are case-sensitive.',
    "Declare it with a type first (for example int \$1 = 0;) or fix the "
        'spelling.',
  ),
  _Rule(
    _r('cannot find symbol[\\s\\S]*?symbol:\\s+method\\s+(\\w+)'),
    "Unknown method '\$1'",
    "No method named '\$1' with these parameters exists.",
    'Check the spelling, capitalization (println, not PrintLn), and the '
        'arguments you pass.',
  ),
  _Rule(
    _r('cannot find symbol[\\s\\S]*?symbol:\\s+class\\s+(\\w+)'),
    "Unknown class '\$1'",
    "Java cannot find the class '\$1'.",
    'Check the spelling and add the import, e.g. import java.util.Scanner;.',
  ),
  _Rule(
    _r('incompatible types: possible lossy conversion from (\\w+) to (\\w+)'),
    'Lossy conversion from \$1 to \$2',
    'A \$1 value is stored in a \$2 variable, which could lose information.',
    'Use a \$1 variable, or cast explicitly: (\$2) value.',
  ),
  _Rule(
    _r('incompatible types: (.+?) cannot be converted to (.+)'),
    'Type mismatch',
    'A value of type \$1 is used where \$2 is required.',
    'Use a value of the correct type, or convert it (for example '
        'Integer.parseInt(text)).',
  ),
  _Rule(
    _r('variable (\\w+) is already defined'),
    "Variable '\$1' declared twice",
    "'\$1' is declared more than once in the same scope.",
    'Remove the type from the second declaration, or use a different name.',
  ),
  _Rule(
    _r('variable (\\w+) might not have been initialized'),
    "Variable '\$1' has no value yet",
    "'\$1' is read before any value was assigned to it.",
    "Give it a starting value when declaring it, e.g. int \$1 = 0;.",
  ),
  _Rule(
    _r('missing return statement'),
    'Missing return statement',
    'A method that declares a return type does not return a value on every '
        'path.',
    'Add a return statement for every possible path through the method.',
  ),
  _Rule(
    _r('class (\\w+) is public, should be declared in a file named'),
    "Class name '\$1' does not match the file",
    'A public class must have the same name as its file.',
    'Rename the class to Main, or remove the public keyword.',
  ),
  _Rule(
    _r('not a statement'),
    'Not a statement',
    'A line contains a value or expression that does nothing on its own.',
    'Assign the value to a variable or print it, and check for a missing '
        'operator.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r(
      'illegal start of expression|<identifier> expected|class, interface, enum, or record expected',
    ),
    'Code in the wrong place',
    'The compiler found code where it is not allowed, often because a brace '
        'or semicolon is missing just before it.',
    'Check the reported line and the lines above it for missing ; or }.',
    kind: ErrorKind.syntax,
  ),
];

final _javaRuntimeRules = <_Rule>[
  _Rule(
    _r('ArithmeticException: / by zero'),
    'Division by zero',
    'The program divided an integer by zero, which Java does not allow.',
    'Check that the divisor is not 0 before dividing.',
  ),
  _Rule(
    _r(
      'ArrayIndexOutOfBoundsException: Index (-?\\d+) out of bounds for length (\\d+)',
    ),
    'Array index out of bounds',
    'The program used index \$1, but the array only has \$2 elements '
        '(valid indexes are 0 to \$2 - 1).',
    'Check the loop condition: use i < array.length, not i <= array.length.',
  ),
  _Rule(
    _r('ArrayIndexOutOfBoundsException'),
    'Array index out of bounds',
    'The program used a position that does not exist in the array.',
    'Valid indexes are 0 to length-1. Check loop bounds.',
  ),
  _Rule(
    _r('StringIndexOutOfBoundsException'),
    'String index out of bounds',
    'The program used a character position that does not exist in the string.',
    'Valid positions are 0 to length()-1. Check charAt and substring calls.',
  ),
  _Rule(
    _r('NullPointerException'),
    'Null reference',
    'A variable that points to no object (null) was used as if it had one.',
    'Create the object (with new) or assign a value before calling its '
        'methods.',
  ),
  _Rule(
    _r('NumberFormatException: For input string: "(.*?)"'),
    'Invalid number format',
    "The text \"\$1\" cannot be converted to a number.",
    'Check the input value, or validate it before calling Integer.parseInt.',
  ),
  _Rule(
    _r('InputMismatchException'),
    'Wrong input type',
    'The program expected one type of input (for example a number) but '
        'received another.',
    'Check Standard input: put each value on its own line in the order and '
        'type the program reads them.',
  ),
  _Rule(
    _r('NoSuchElementException'),
    'Missing input',
    'The program tried to read input, but there was none left.',
    'Add one line in Standard input for every Scanner read.',
  ),
  _Rule(
    _r('StackOverflowError'),
    'Stack overflow (infinite recursion)',
    'A method kept calling itself without reaching a stopping case.',
    'Add or fix the base case of the recursive method.',
  ),
  _Rule(
    _r('OutOfMemoryError'),
    'Out of memory',
    'The program used more memory than allowed.',
    'Check for very large arrays or loops that keep adding items.',
  ),
  _Rule(
    _r('ClassCastException'),
    'Invalid type cast',
    'An object was cast to a type it is not.',
    'Check the object type before casting.',
  ),
  _Rule(
    _r('Exception in thread "main" ([\\w.]+)'),
    'Unhandled exception: \$1',
    'The program threw \$1 and nothing caught it, so it stopped.',
    'Read the line number in the stack trace and check the values used there.',
  ),
];

final _jsRules = <_Rule>[
  _Rule(
    _r('SyntaxError: missing \\) after argument list'),
    'Missing closing parenthesis )',
    'A function call was opened with ( but not closed.',
    'Add the missing ).',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('SyntaxError: Unexpected end of input'),
    'Missing closing brace } or bracket',
    'The file ended while a block, array, or call was still open.',
    'Count your braces, brackets, and parentheses and close the open one.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('SyntaxError: Invalid or unexpected token'),
    'Invalid character or unclosed string',
    'The code contains a character JavaScript does not understand, often an '
        'unclosed string.',
    'Check quotes and remove stray characters on the reported line.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r("SyntaxError: Unexpected token '?([^'\\n]+)'?"),
    "Unexpected '\$1'",
    "JavaScript found '\$1' where it did not expect it.",
    'Check the reported line for a missing comma, operator, or bracket before '
        'this symbol.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r("SyntaxError: Identifier '(\\w+)' has already been declared"),
    "Variable '\$1' declared twice",
    "'\$1' is declared more than once with let or const.",
    'Remove the second let/const to reuse the variable, or rename it.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('SyntaxError: (.+)'),
    'Syntax error: \$1',
    'The code does not follow JavaScript grammar.',
    'Fix the reported line, then run again.',
    kind: ErrorKind.syntax,
  ),
  _Rule(
    _r('ReferenceError: (\\w+) is not defined'),
    "Undefined variable '\$1'",
    "'\$1' is used but was never declared, or it is misspelled.",
    "Declare it first (let \$1 = ...;) or fix the spelling.",
  ),
  _Rule(
    _r('TypeError: Assignment to constant variable'),
    'Changing a const variable',
    'A variable declared with const cannot be given a new value.',
    'Declare it with let if its value needs to change.',
  ),
  _Rule(
    _r(
      "TypeError: Cannot read propert(?:y|ies) of (undefined|null)(?: \\(reading '(\\w+)'\\))?",
    ),
    "Reading '\$2' from \$1",
    "The program tried to read a property of a value that is \$1.",
    'Make sure the variable holds an object or array before using it, and '
        'check array indexes.',
  ),
  _Rule(
    _r('TypeError: ([\\w.]+) is not a function'),
    "'\$1' is not a function",
    "'\$1' was called like a function, but it is not one.",
    'Check the spelling of the function name and that it is defined.',
  ),
  _Rule(
    _r('RangeError: Maximum call stack size exceeded'),
    'Stack overflow (infinite recursion)',
    'A function kept calling itself without reaching a stopping case.',
    'Add or fix the base case of the recursive function.',
  ),
  _Rule(
    _r('(\\w*Error): (.+)'),
    '\$1: \$2',
    'The program stopped because of a \$1.',
    'Check the values used on the reported line.',
  ),
];
