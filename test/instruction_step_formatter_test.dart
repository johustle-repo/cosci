import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/services/instruction_step_formatter.dart';

void main() {
  test('reassembles sentence and regular-expression fragments', () {
    final result = InstructionStepFormatter.format(const [
      '1. Choose the appropriate quantifier symbol for each occurrence (e.g.',
      '2. {5} for exactly five occurrences).',
      '3. Test the expression against valid and invalid samples',
      '4. observing which characters are captured.',
      '5. If a test fails',
      '6. adjust the quantifier and retest the pattern.',
    ]);

    expect(result, hasLength(3));
    expect(result[0], contains('{5} for exactly five occurrences'));
    expect(result[1], contains('observing which characters are captured'));
    expect(result[2], contains('adjust the quantifier'));
  });

  test('keeps independent imperative instructions separate', () {
    final result = InstructionStepFormatter.format(const [
      'Declare a variable to store the input.',
      'Assign a value to the variable.',
      'Print the value to the console.',
    ]);

    expect(result, hasLength(3));
  });

  test('removes embedded numbering and duplicate steps', () {
    final result = InstructionStepFormatter.format(const [
      'Step 1: Read the input.',
      '2) Validate the input.',
      'Validate the input.',
    ]);

    expect(result, ['Read the input.', 'Validate the input.']);
  });
}
