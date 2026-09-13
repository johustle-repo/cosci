class InstructionStepFormatter {
  const InstructionStepFormatter._();

  static List<String> format(Iterable<String> rawSteps) {
    final cleaned = rawSteps
        .expand((step) => step.split(RegExp(r'[\r\n]+')))
        .map(_clean)
        .where((step) => step.isNotEmpty)
        .toList();
    final result = <String>[];

    for (final fragment in cleaned) {
      if (result.isEmpty) {
        result.add(fragment);
        continue;
      }

      final previous = result.last;
      if (_continues(previous, fragment)) {
        result[result.length - 1] = _join(previous, fragment);
      } else if (!_sameMeaning(previous, fragment)) {
        result.add(fragment);
      }
    }

    return result;
  }

  static String _clean(String value) {
    return value
        .trim()
        .replaceFirst(
          RegExp(r'^(?:step\s*)?\d+\s*[.)\-:]\s*', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  static bool _continues(String previous, String current) {
    final firstLetter = RegExp(r'[A-Za-z]').firstMatch(current)?.group(0);
    final startsLowercase =
        firstLetter != null &&
        firstLetter == firstLetter.toLowerCase() &&
        !current.startsWith(RegExp(r'[A-Z]'));
    final startsWithFragment =
        RegExp(r'^[,.;:)}\]]').hasMatch(current) ||
        RegExp(r'^[{(\[]\s*\d').hasMatch(current);
    final previousInvitesContinuation = RegExp(
      r'(?:\(|\{|\[|,|;|:|\be\.g\.?|\bi\.e\.?|\bfor example|\bsuch as|\band|\bor)$',
      caseSensitive: false,
    ).hasMatch(previous.trim());

    return startsLowercase ||
        startsWithFragment ||
        previousInvitesContinuation ||
        _hasUnclosedDelimiter(previous);
  }

  static bool _hasUnclosedDelimiter(String value) {
    int difference(RegExp open, RegExp close) =>
        open.allMatches(value).length - close.allMatches(value).length;

    return difference(RegExp(r'\('), RegExp(r'\)')) > 0 ||
        difference(RegExp(r'\{'), RegExp(r'\}')) > 0 ||
        difference(RegExp(r'\['), RegExp(r'\]')) > 0;
  }

  static String _join(String previous, String current) {
    if (RegExp(r'[(\[{]$').hasMatch(previous) ||
        RegExp(r'^[,.;:)}\]]').hasMatch(current)) {
      return '$previous$current';
    }
    return '$previous $current';
  }

  static bool _sameMeaning(String first, String second) {
    String normalized(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

    return normalized(first) == normalized(second);
  }
}
