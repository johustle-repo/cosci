import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pseudocode_apk/features/admin/models/admin_syllabus_analysis.dart';

/// Calls the Groq API to analyse syllabi and generate
/// structured educational content (lessons, quizzes, puzzles, simulations).
///
/// Usage:
/// 1. Call [setApiKey] with the admin's Groq API key.
/// 2. Call any generation method; each returns a parsed Dart object.
///
/// Note: Direct browser calls may be subject to CORS. For production,
/// wrap these calls in a Firebase Cloud Function.
class AdminAiGenerationService {
  static const _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  // Groq retired llama-3.3-70b-versatile for free/developer projects on
  // August 16, 2026. GPT-OSS 120B is its recommended production replacement.
  static const _analysisModel = 'openai/gpt-oss-120b';
  static const _generationModel = 'openai/gpt-oss-120b';

  String? _apiKey;

  void setApiKey(String key) => _apiKey = key.trim();
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  // ══════════════════════════════════════════════════════════════════════════
  // SYLLABUS ANALYSIS
  // ══════════════════════════════════════════════════════════════════════════

  /// Sends the syllabus content to Groq and returns structured curriculum
  /// data as [AdminSyllabusAnalysis].
  ///
  /// Provide [textContent] directly. If [pdfBytes] is provided, this service
  /// currently requires extracted text as well because Groq chat completions
  /// do not support Anthropic-style native PDF document parts.
  Future<AdminSyllabusAnalysis> analyzeSyllabus({
    required String syllabusId,
    String? textContent,
    Uint8List? pdfBytes,
  }) async {
    _requireApiKey();

    final cleanedText = textContent?.trim() ?? '';

    if (cleanedText.isEmpty && pdfBytes == null) {
      throw Exception('No syllabus content provided for analysis.');
    }

    if (cleanedText.isEmpty && pdfBytes != null) {
      throw Exception(
        'Groq does not support direct PDF document upload in this workflow. '
        'Please paste or extract the syllabus text first.',
      );
    }

    final prompt =
        '''
$_analysisPrompt

SYLLABUS CONTENT:
$cleanedText
''';

    final json = await _callObject(
      prompt: prompt,
      model: _analysisModel,
      maxTokens: 4096,
    );

    return AdminSyllabusAnalysis.fromAiResponse(syllabusId, json);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTENT GENERATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> generateLessons({
    required AdminSyllabusAnalysis analysis,
    required SyllabusUnit unit,
    int count = 2,
  }) async {
    _requireApiKey();
    return _callArray(
      prompt: _lessonPrompt(analysis, unit, count),
      model: _generationModel,
      // One complete lesson fits comfortably inside this budget while keeping
      // the total request below Groq's free-tier rolling token allowance.
      maxTokens: 4800,
    );
  }

  Future<List<Map<String, dynamic>>> generateQuizzes({
    required AdminSyllabusAnalysis analysis,
    required SyllabusUnit unit,
    int count = 3,
  }) async {
    _requireApiKey();
    return _callArray(
      prompt: _quizPrompt(analysis, unit, count),
      model: _generationModel,
    );
  }

  Future<List<Map<String, dynamic>>> generatePuzzles({
    required AdminSyllabusAnalysis analysis,
    required SyllabusUnit unit,
    int count = 2,
  }) async {
    _requireApiKey();
    return _callArray(
      prompt: _puzzlePrompt(analysis, unit, count),
      model: _generationModel,
    );
  }

  Future<List<Map<String, dynamic>>> generateSimulations({
    required AdminSyllabusAnalysis analysis,
    required SyllabusUnit unit,
    int count = 2,
  }) async {
    _requireApiKey();
    return _callArray(
      prompt: _simulationPrompt(analysis, unit, count),
      model: _generationModel,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HTTP HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _callObject({
    required String prompt,
    required String model,
    int maxTokens = 4096,
  }) async {
    final text = await _callRaw(
      prompt: prompt,
      model: model,
      maxTokens: maxTokens,
    );
    final cleaned = _stripMarkdown(text);
    final decoded = jsonDecode(cleaned);

    if (decoded is Map<String, dynamic>) return decoded;

    throw Exception(
      'Expected a JSON object from AI, got ${decoded.runtimeType}',
    );
  }

  Future<List<Map<String, dynamic>>> _callArray({
    required String prompt,
    required String model,
    int maxTokens = 4096,
  }) async {
    final text = await _callRaw(
      prompt: prompt,
      model: model,
      maxTokens: maxTokens,
    );
    final cleaned = _stripMarkdown(text);
    final decoded = jsonDecode(cleaned);

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw Exception(
      'Expected a JSON array from AI, got ${decoded.runtimeType}',
    );
  }

  Future<String> _callRaw({
    required String prompt,
    required String model,
    required int maxTokens,
  }) async {
    final body = jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an academic curriculum analyst and educational content generator '
              'specialising in IT and programming education. '
              'When asked to return JSON, return JSON only with no markdown fences.',
        },
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.2,
      'max_tokens': maxTokens,
    });

    late http.Response response;
    for (var attempt = 0; attempt < 3; attempt++) {
      response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 429 || attempt == 2) break;

      final delay = _rateLimitDelay(response);
      await Future<void>.delayed(delay);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg;
      try {
        final err = jsonDecode(response.body);
        if (err is Map<String, dynamic>) {
          msg = err['error']?.toString() ?? response.body;
        } else {
          msg = response.body;
        }
      } catch (_) {
        msg = response.body;
      }

      throw Exception('Groq API error (${response.statusCode}): $msg');
    }

    final resp = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = resp['choices'];

    if (choices is! List || choices.isEmpty) {
      throw Exception('Empty response from Groq API.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      throw Exception('Invalid response format from Groq API.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw Exception('Missing message object in Groq response.');
    }

    final content = message['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content;
    }

    throw Exception('Empty content from Groq API.');
  }

  Duration _rateLimitDelay(http.Response response) {
    final retryAfter = response.headers['retry-after'];
    final secondsFromHeader = double.tryParse(retryAfter ?? '');
    if (secondsFromHeader != null) {
      return Duration(
        milliseconds: (secondsFromHeader * 1000).ceil().clamp(1000, 35000),
      );
    }

    // Groq also reports messages such as "Please try again in 22.495s".
    final match = RegExp(
      r'try again in\s+([0-9]+(?:\.[0-9]+)?)s',
      caseSensitive: false,
    ).firstMatch(response.body);
    final secondsFromBody = double.tryParse(match?.group(1) ?? '');
    if (secondsFromBody != null) {
      return Duration(
        milliseconds: ((secondsFromBody + 1) * 1000).ceil().clamp(1000, 35000),
      );
    }

    return const Duration(seconds: 12);
  }

  /// Remove ```json ... ``` markdown fences that the model sometimes adds.
  String _stripMarkdown(String raw) {
    var text = raw.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }

  void _requireApiKey() {
    if (!hasApiKey) {
      throw Exception(
        'Groq API key is not configured. '
        'Go to Settings → AI Configuration to enter your key.',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROMPT TEMPLATES
  // ══════════════════════════════════════════════════════════════════════════

  static const _analysisPrompt = '''
You are an academic curriculum analyst specialising in IT and programming education.
Analyse the provided programming course syllabus and extract structured information.

Return ONLY a JSON object — no markdown fences, no extra text — with this exact structure:
{
  "courseTitle": "Full course title string",
  "courseCode": "e.g. CS101, or empty string if not found",
  "programmingLanguage": "e.g. Python, Java, C++ — primary language only",
  "programmingLanguageVersion": "e.g. Python 3.x, or empty string",
  "courseDescription": "Course description paragraph or empty string",
  "yearLevel": "e.g. 1st Year, 2nd Year, or empty string",
  "units": [
    {
      "unitNumber": 1,
      "title": "Unit or week title",
      "weekReference": "e.g. Week 1-2, Unit 1",
      "topics": ["topic1", "topic2"],
      "outcomes": ["Outcome sentence 1"],
      "difficulty": "Easy"
    }
  ],
  "allTopics": ["Flat list of every topic across all units"],
  "intendedLearningOutcomes": ["Overall course ILOs"],
  "conceptProgression": ["Earliest concept", "...", "Most advanced concept"],
  "prerequisiteTopics": ["Topics students should already know"],
  "assessmentIndicators": ["Quiz", "Final Exam", "Project"],
  "confidenceFlags": {
    "courseTitle": true,
    "courseCode": false,
    "programmingLanguage": true,
    "units": true,
    "outcomes": false
  }
}

Rules:
- difficulty for each unit: infer from topic complexity (Easy/Medium/Hard).
- confidenceFlags.X = true when clearly stated; false when inferred or missing.
- If a field is missing, use an empty string or empty array — never omit the key.
''';

  String _lessonPrompt(AdminSyllabusAnalysis a, SyllabusUnit u, int count) =>
      '''
You are an educational content creator for IT students.
Generate exactly $count lesson entries based on the course unit below.

COURSE CONTEXT:
Course: ${a.courseTitle}
Language: ${a.programmingLanguage}${a.programmingLanguageVersion.isNotEmpty ? ' ${a.programmingLanguageVersion}' : ''}
Unit ${u.unitNumber}: ${u.title} (${u.weekReference})
Topics: ${u.topics.join(', ')}
Learning Outcomes: ${u.outcomes.join('; ')}
Difficulty: ${u.difficulty}

Return ONLY a JSON array — no markdown, no extra text:
[
  {
    "title": "Descriptive lesson title",
    "topic": "One specific topic from the unit's topic list",
    "language": "${a.programmingLanguage}",
    "difficulty": "${u.difficulty}",
    "description": "A substantial 2-3 paragraph concept explanation (180-260 words) that explains what, why, and when the topic is used",
    "audiencePrograms": ["BS Computer Science", "BS Information Technology", "BS Mathematics-CIT"],
    "yearLevels": ["1st Year", "2nd Year"],
    "estimatedMinutes": 40,
    "learningObjective": "2-3 measurable outcomes stating what learners can explain, trace, and implement",
    "keyConcepts": ["5-7 specific concepts or terms used in this lesson"],
    "prerequisites": ["2-4 concrete ideas learners should know first"],
    "introduction": "A 120-180 word learner-friendly hook using a relatable campus, daily-life, or software scenario and two guiding questions.",
    "algorithmSteps": ["6-10 detailed, ordered steps. Each step explains the action and the reason for it."],
    "workedExample": "A 220-320 word worked example. State the problem and input, trace the important variables or decisions step by step, then explain the result.",
    "commonMistakes": "Describe at least 4 beginner mistakes. For each, identify the symptom, likely cause, and a practical correction.",
    "summary": "A 100-150 word recap followed by three self-check questions learners can answer before continuing.",
    "errorFocus": "Concept|Syntax|Logic|Syntax and Logic",
    "sourceCode": "A complete runnable ${a.programmingLanguage} program. Use \\n for line breaks.",
    "standardInput": "Input required by the program, or an empty string",
    "expectedOutput": "Exact output produced by the runnable program",
    "pseudocode": "Optional language-neutral steps when they materially clarify the algorithm, otherwise empty",
    "compilerValidated": false,
    "sortOrder": 1,
    "isPublished": false,
    "generatedByAi": true,
    "approvalStatus": "generated"
  }
]

Requirements:
- Fill every key. Do not return placeholder text such as "Step 1", "concept1", or "Required prior concept".
- Keep explanations appropriate for first- and second-year programming learners.
- Each lesson must support 35-50 minutes of learning and must not read like a short definition.
- Teach progressively: activate prior knowledge, explain the idea, model it, trace it, let the learner predict, then recap it.
- Use short paragraphs, concrete analogies, and guiding questions. Avoid unnecessary jargon and define every new technical term.
- Include at least one prediction prompt in the introduction or worked example, such as asking what a variable or output will be before revealing it.
- The worked example must explain the code line by line or decision by decision instead of merely presenting a finished answer.
- Make examples distinct across generated lessons and directly relevant to the selected topic.
- sourceCode must be complete and runnable, and expectedOutput must exactly match it for the supplied standardInput.
- Use only C++, Java, or JavaScript. Normalize C/C++ syllabus content to C++.
- Prefer Concept for introductory theory; use Syntax, Logic, or Syntax and Logic when error detection is central.
- Keep lessons as drafts. Compiler validation is performed by CoSci after generation.
''';

  String _quizPrompt(AdminSyllabusAnalysis a, SyllabusUnit u, int count) =>
      '''
You are an educational quiz creator for programming students.
Generate exactly $count quiz questions from the unit below.
Mix question types: output_prediction, code_tracing, identify_error, multiple_choice.

COURSE CONTEXT:
Course: ${a.courseTitle} | Language: ${a.programmingLanguage}
Unit: ${u.title} | Topics: ${u.topics.join(', ')} | Difficulty: ${u.difficulty}

Return ONLY a JSON array — no markdown:
[
  {
    "title": "Quiz on [topic]",
    "topic": "Specific topic",
    "language": "${a.programmingLanguage}",
    "questionType": "output_prediction|code_tracing|identify_error|multiple_choice",
    "questionText": "Clear question text",
    "codeSnippet": "Short ${a.programmingLanguage} code (3-8 lines). Use \\\\n for line breaks.",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": "Exact text of the correct option",
    "explanation": "Why this answer is correct (1-2 sentences)",
    "difficulty": "${u.difficulty}",
    "xpReward": 20,
    "isPublished": false,
    "generatedByAi": true,
    "approvalStatus": "generated"
  }
]

QUALITY RULES:
- Every question must assess a different learning point or reasoning skill. Do not paraphrase or repeat an earlier question.
- Use a balanced mix of concept understanding, code tracing, output prediction, error diagnosis, and application scenarios.
- Write one direct question per item. Avoid double negatives, trick wording, vague pronouns, and "all/none of the above" choices.
- Keep the question understandable without hidden context. Define any uncommon term needed to answer it.
- Provide exactly four concise, grammatically parallel, mutually exclusive options.
- Include exactly one defensibly correct option. Distractors must be plausible beginner mistakes, not absurd unrelated answers.
- Do not reveal the answer through noticeably longer wording, repeated keywords, or grammatical mismatch.
- Keep code snippets complete enough to trace and use only syntax valid for ${a.programmingLanguage}.
- correctAnswer must match one option exactly, including capitalization and punctuation.
- explanation must state why the answer is correct and briefly clarify the likely misconception.
- Before returning JSON, compare every pair of questionText values and replace any exact, paraphrased, or conceptually duplicate item.
''';

  String _puzzlePrompt(AdminSyllabusAnalysis a, SyllabusUnit u, int count) =>
      '''
You are an educational puzzle creator for programming students.
Generate exactly $count programming puzzles from the unit below.

Types:
- code_flow: student arranges scrambled lines in correct order
- output_prediction: student picks the correct output
- debug_bug: student finds and fixes the bug

COURSE CONTEXT:
Course: ${a.courseTitle} | Language: ${a.programmingLanguage}
Unit: ${u.title} | Topics: ${u.topics.join(', ')} | Difficulty: ${u.difficulty}

Return ONLY a JSON array — no markdown:
[
  {
    "title": "Puzzle title",
    "topic": "Specific topic",
    "language": "${a.programmingLanguage}",
    "puzzleType": "code_flow|output_prediction|debug_bug",
    "difficulty": "${u.difficulty}",
    "xpReward": 25,
    "hint": "Helpful hint for students",
    "explanation": "Explanation of the solution",
    "codeSnippet": "The correct full code (use \\\\n for line breaks)",
    "scrambledLines": ["line1", "line2"],
    "correctOrder": [0, 1],
    "outputChoices": ["A", "B", "C", "D"],
    "correctOutputId": 0,
    "bugDescription": "What the bug is",
    "bugAnswer": "The corrected code/line",
    "isPublished": false,
    "generatedByAi": true,
    "approvalStatus": "generated"
  }
]

For code_flow: populate scrambledLines (shuffled) and correctOrder (correct 0-based indices).
For output_prediction: populate outputChoices (4 options) and correctOutputId.
For debug_bug: populate bugDescription and bugAnswer. Set other type-specific fields to empty.
''';

  String _simulationPrompt(
    AdminSyllabusAnalysis a,
    SyllabusUnit u,
    int count,
  ) =>
      '''
You are an educational code simulation designer for programming students.
Generate exactly $count code simulation activities from the unit below.

These are step-by-step execution traces — NOT a live compiler.
Each simulation shows a short program running line-by-line with variable states.

COURSE CONTEXT:
Course: ${a.courseTitle} | Language: ${a.programmingLanguage}
Unit: ${u.title} | Topics: ${u.topics.join(', ')} | Difficulty: ${u.difficulty}

Return ONLY a JSON array — no markdown:
[
  {
    "title": "e.g. Tracing Variable Assignment in ${a.programmingLanguage}",
    "topic": "Specific topic",
    "language": "${a.programmingLanguage}",
    "difficulty": "${u.difficulty}",
    "codeSnippet": "Short program, 4-8 lines. Use \\\\n for line breaks.",
    "expectedOutput": "Final printed output",
    "explanation": "What this simulation demonstrates (1-2 sentences)",
    "learningObjective": "Students will understand [concept]",
    "problemGoal": "A clear learner-facing programming goal",
    "inputsDescription": "Describe the input and important constraints, or state that no input is required",
    "algorithmSteps": ["Concrete step 1", "Concrete step 2", "Concrete step 3"],
    "keyConcepts": ["concept1", "concept2", "concept3"],
    "commonMistakes": "Likely syntax or logic mistakes and how learners can recognize them",
    "hints": ["General hint", "More specific hint", "Final directional hint"],
    "errorFocus": "Syntax|Logic|Syntax and Logic",
    "audiencePrograms": ["BS Computer Science", "BS Information Technology", "BS Mathematics-CIT"],
    "yearLevels": ["1st Year", "2nd Year"],
    "stdin": "Visible input, or empty string",
    "testCases": [
      {"name": "Visible example", "stdin": "", "expectedOutput": "Exact visible output", "isHidden": false},
      {"name": "Hidden edge case", "stdin": "Alternative input", "expectedOutput": "Exact hidden output", "isHidden": true}
    ],
    "executionSteps": [
      {
        "stepNumber": 1,
        "description": "Brief description of what happens",
        "lineIndex": 0,
        "variableStates": {"varName": "value"}
      }
    ],
    "xpReward": 20,
    "isPublished": false,
    "generatedByAi": true,
    "approvalStatus": "generated"
  }
]

Keep executionSteps to 3-6 steps. lineIndex is 0-based into the code lines.
variableStates shows ALL variables and their current values at that step.
Fill every key with topic-specific content; never return placeholders such as concept1 or Concrete step 1.
The program must be complete and runnable in C++, Java, or JavaScript. Normalize C/C++ content to C++.
Every test case must match the program exactly. Keep generated content as a draft with compilerValidated false.
''';
}
