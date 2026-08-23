enum PuzzleType { codeFlow, outputPrediction, debugBug }

extension PuzzleTypeX on PuzzleType {
  String get firestoreValue {
    switch (this) {
      case PuzzleType.codeFlow:
        return 'code_flow';
      case PuzzleType.outputPrediction:
        return 'output_prediction';
      case PuzzleType.debugBug:
        return 'debug_bug';
    }
  }

  String get label {
    switch (this) {
      case PuzzleType.codeFlow:
        return 'Code Flow';
      case PuzzleType.outputPrediction:
        return 'Output Prediction';
      case PuzzleType.debugBug:
        return 'Debug the Bug';
    }
  }

  static PuzzleType fromFirestore(String? value) {
    switch (value) {
      case 'code_flow':
        return PuzzleType.codeFlow;
      case 'output_prediction':
        return PuzzleType.outputPrediction;
      case 'debug_bug':
        return PuzzleType.debugBug;
      default:
        return PuzzleType.codeFlow;
    }
  }
}

class PuzzleOption {
  const PuzzleOption({required this.id, required this.text});

  final String id;
  final String text;

  factory PuzzleOption.fromMap(Map<String, dynamic> map, {String? fallbackId}) {
    return PuzzleOption(
      id: _readString(map['id'], fallback: fallbackId ?? ''),
      text: _readString(map['text']),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) {
      return value;
    }

    return fallback;
  }
}

class CodeFlowPuzzleData {
  const CodeFlowPuzzleData({
    required this.scrambledLines,
    required this.correctOrder,
  });

  final List<String> scrambledLines;
  final List<String> correctOrder;

  factory CodeFlowPuzzleData.fromMap(Map<String, dynamic> map) {
    return CodeFlowPuzzleData(
      scrambledLines: _stringList(map['scrambledLines']),
      correctOrder: _stringList(map['correctOrder']),
    );
  }
}

class OutputPredictionPuzzleData {
  const OutputPredictionPuzzleData({
    required this.codeSnippet,
    required this.options,
    required this.correctOptionId,
  });

  final String codeSnippet;
  final List<PuzzleOption> options;
  final String correctOptionId;

  factory OutputPredictionPuzzleData.fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'];
    final outputChoicesRaw = map['outputChoices'];
    final options = optionsRaw is List
        ? optionsRaw
              .whereType<Map>()
              .map(
                (item) => PuzzleOption.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : outputChoicesRaw is List
        ? outputChoicesRaw.asMap().entries.map((entry) {
            return PuzzleOption(
              id: entry.key.toString(),
              text: entry.value.toString(),
            );
          }).toList()
        : const <PuzzleOption>[];

    return OutputPredictionPuzzleData(
      codeSnippet: _readString(map['codeSnippet']),
      options: options,
      correctOptionId: _readString(
        map['correctOptionId'],
        fallback: _readString(map['correctOutputId']),
      ),
    );
  }
}

class DebugBugPuzzleData {
  const DebugBugPuzzleData({
    required this.codeLines,
    required this.bugLineIndex,
    required this.issueOptions,
    required this.correctIssueId,
    this.explanationHint,
  });

  final List<String> codeLines;
  final int bugLineIndex;
  final List<PuzzleOption> issueOptions;
  final String correctIssueId;
  final String? explanationHint;

  factory DebugBugPuzzleData.fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['issueOptions'];
    final bugAnswer = _readString(map['bugAnswer']);
    final bugDescription = _readString(map['bugDescription']);
    final options = optionsRaw is List
        ? optionsRaw
              .whereType<Map>()
              .map(
                (item) => PuzzleOption.fromMap(Map<String, dynamic>.from(item)),
              )
              .toList()
        : bugAnswer.isNotEmpty
        ? [
            PuzzleOption(id: '0', text: bugAnswer),
            if (bugDescription.isNotEmpty)
              PuzzleOption(id: '1', text: bugDescription),
          ]
        : const <PuzzleOption>[];
    final codeLines = _stringList(map['codeLines']).isNotEmpty
        ? _stringList(map['codeLines'])
        : _readString(
            map['codeSnippet'],
          ).split('\n').where((line) => line.trim().isNotEmpty).toList();
    final bugLineIndex =
        _readInt(map['bugLineIndex']) ??
        _findBugLineIndex(codeLines, bugAnswer) ??
        0;

    return DebugBugPuzzleData(
      codeLines: codeLines,
      bugLineIndex: bugLineIndex,
      issueOptions: options,
      correctIssueId: _readString(map['correctIssueId'], fallback: '0'),
      explanationHint:
          map['explanationHint'] as String? ?? map['hint'] as String?,
    );
  }
}

class Puzzle {
  const Puzzle({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.language,
    required this.type,
    required this.xpReward,
    this.codeFlowData,
    this.outputPredictionData,
    this.debugBugData,
  });

  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String language;
  final PuzzleType type;
  final int xpReward;
  final CodeFlowPuzzleData? codeFlowData;
  final OutputPredictionPuzzleData? outputPredictionData;
  final DebugBugPuzzleData? debugBugData;

  factory Puzzle.fromMap(String id, Map<String, dynamic> map) {
    final type = PuzzleTypeX.fromFirestore(map['type'] as String?);
    return Puzzle(
      id: id,
      title: _readString(map['title'], fallback: 'Puzzle'),
      description: _readString(
        map['description'],
        fallback: _readString(
          map['topic'],
          fallback: 'Solve this learning puzzle to practice programming logic.',
        ),
      ),
      difficulty: _readString(map['difficulty'], fallback: 'Easy'),
      language: _readString(map['language'], fallback: 'C++'),
      type: type,
      xpReward: _readInt(map['xpReward']) ?? 15,
      codeFlowData: type == PuzzleType.codeFlow
          ? CodeFlowPuzzleData.fromMap(map)
          : null,
      outputPredictionData: type == PuzzleType.outputPrediction
          ? OutputPredictionPuzzleData.fromMap(map)
          : null,
      debugBugData: type == PuzzleType.debugBug
          ? DebugBugPuzzleData.fromMap(map)
          : null,
    );
  }
}

class PuzzleProgress {
  const PuzzleProgress({
    required this.attempts,
    required this.bestScore,
    required this.isCompleted,
    this.completedAt,
  });

  final int attempts;
  final int bestScore;
  final bool isCompleted;
  final DateTime? completedAt;

  factory PuzzleProgress.fromMap(Map<String, dynamic> map) {
    return PuzzleProgress(
      attempts: _readInt(map['attempts']) ?? 0,
      bestScore: _readInt(map['bestScore']) ?? 0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: _parseDate(map['completedAt']),
    );
  }

  static const empty = PuzzleProgress(
    attempts: 0,
    bestScore: 0,
    isCompleted: false,
  );
}

class PuzzleSubmissionResult {
  const PuzzleSubmissionResult({
    required this.isCorrect,
    required this.score,
    required this.attempts,
    required this.firstCompletion,
  });

  final bool isCorrect;
  final int score;
  final int attempts;
  final bool firstCompletion;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }

  return const <String>[];
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }

  return fallback;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

DateTime? _parseDate(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}

int? _findBugLineIndex(List<String> lines, String bugAnswer) {
  if (bugAnswer.isEmpty) {
    return null;
  }
  final needle = bugAnswer.toLowerCase();
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].toLowerCase().contains(needle)) {
      return i;
    }
  }
  return null;
}
