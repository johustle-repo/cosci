# Syllabus Upload and Content Creation (Backend)

This document describes what happens behind the admin screens when a syllabus is uploaded and when lessons, quizzes, and puzzles are created. The admin client talks directly to Firebase (Firestore), Cloudinary (file storage), the Groq API (AI generation), and the CoSci compiler service. Firestore security rules allow only administrators to write any of these collections.

## Services Involved

| Layer | File | Responsibility |
| --- | --- | --- |
| Syllabus storage | `lib/features/admin/services/admin_syllabus_service.dart` | Cloudinary upload, syllabus, analysis, and job records, saving generated content |
| AI generation | `lib/features/admin/services/admin_ai_generation_service.dart` | Groq chat-completion prompts for analysis, lessons, quizzes, puzzles, and simulations |
| Upload and analysis workflow | `lib/features/admin/providers/admin_syllabus_provider.dart` | Upload, create record, analyze, update status |
| Generation pipeline | `lib/features/admin/providers/admin_generation_provider.dart` | Per-unit generation loop, job tracking, lesson completion/fallbacks |
| Manual content CRUD | `lib/features/admin/services/admin_firestore_service.dart` | Lessons (with revisions), quizzes (with private answer keys), puzzles |
| Publish rules | `admin_lessons_provider.dart`, `admin_quizzes_provider.dart`, `admin_puzzles_provider.dart` | Readiness checks before anything becomes visible to students |
| Quiz grading | `functions/index.js` (`evaluateQuiz`) | Server-side scoring against private answer keys |

## Firestore Collections

| Collection | Contents |
| --- | --- |
| `syllabi` | One document per uploaded file: course metadata, Cloudinary `fileUrl`, file name/type/size, uploader, `analysisStatus` |
| `syllabus_analysis` | Structured curriculum extracted by AI. The document ID equals the syllabus ID |
| `content_generation_jobs` | One document per generation run: content type, status, counts, generated IDs, errors |
| `lessons` (+ `revisions` subcollection) | Lessons. Each update first stores a snapshot of the previous version |
| `quizzes` (+ `questions` subcollection) | Quiz settings and the public question text/options |
| `quiz_answer_keys/{quizId}/questions` | Correct answers and explanations, readable by admins only |
| `quiz_attempts` | Server-graded attempts written by the `evaluateQuiz` function |
| `puzzles` | Puzzle definitions (`type`: `code_flow`, `output_prediction`, `debug_bug`) |
| `settings/app_settings` | Holds the content-generation (Groq) API key used by the generator |
| `activity_logs` | Audit entries for upload, analyze, generate, create, update, publish, and delete actions |

## 1. Syllabus Upload

1. The admin selects a `.pdf`, `.docx`, or `.txt` file (maximum 10 MB) and enters the course title, code, language, year level, and term. They also paste the syllabus text.
2. The Groq API key is read from `settings/app_settings`. If it is missing, the admin is sent to Settings (or prompted to enter it) before continuing.
3. `uploadSyllabusFile()` sends the file as a multipart `POST` to Cloudinary (`/auto/upload`) with an unsigned upload preset, a sanitized `public_id` of `syllabi/<timestamp>_<filename>`, and the `syllabi` folder. Progress is reported at 10%, 40%, 80%, and 100%.
4. The returned `secure_url` is stored with the metadata in a new `syllabi` document with `analysisStatus: "pending"` and a server `createdAt` timestamp.
5. An activity log entry ("Uploaded syllabus: …") is written and the syllabus list is reloaded.

## 2. Syllabus Analysis

1. `analysisStatus` is set to `analyzing`.
2. The pasted syllabus text is sent to Groq (`openai/gpt-oss-120b`, temperature 0.2, up to 4096 tokens). The uploaded binary file is not sent: Groq chat completions do not accept PDF/DOCX documents, so analysis requires the pasted text.
3. The prompt requires a single JSON object containing `courseTitle`, `courseCode`, `programmingLanguage`, `courseDescription`, `yearLevel`, `units[]` (each with `unitNumber`, `title`, `weekReference`, `topics`, `outcomes`, `difficulty`), `allTopics`, `intendedLearningOutcomes`, `conceptProgression`, `prerequisiteTopics`, `assessmentIndicators`, and per-field `confidenceFlags`.
4. Markdown fences are stripped from the response and the JSON is parsed into `AdminSyllabusAnalysis`.
5. The analysis is saved to `syllabus_analysis/{syllabusId}`, the syllabus status becomes `analyzed`, and the action is logged. If any step fails, the status becomes `failed` and the error is shown.

**API call behavior:** every Groq request has a 120-second timeout. A `429` (rate limit) response is retried up to 3 times with a delay. Any other non-2xx response, empty content, or invalid JSON raises an error.

## 2a. How Each Part of the Syllabus Is Used

Groq reads the syllabus **once**, during analysis. After that, lesson, quiz, and puzzle generation never sees the original syllabus text. Each generation request gets only a small **COURSE CONTEXT** block, built from a few fields of the saved analysis and **one unit** at a time. This means the quality of the generated content depends on how well the syllabus's course outline (units, topics, and outcomes) is extracted.

### Step 1: What Analysis Extracts From the Syllabus

The analysis prompt asks Groq to find these parts of a typical course syllabus:

| Syllabus section (what Groq looks for) | Extracted field | Rule given to Groq |
| --- | --- | --- |
| Course title / header | `courseTitle` | Full title |
| Course code (e.g. CS101) | `courseCode` | Empty string if not found |
| Language named in the description, tools, or requirements | `programmingLanguage`, `programmingLanguageVersion` | Primary language only |
| Course description paragraph | `courseDescription` | Empty string if not found |
| Year level / target students | `yearLevel` | Empty string if not found |
| Course outline, weekly plan, or unit/module list | `units[]` | One entry per unit or week range |
| ↳ Unit/week title | `units[].title` | |
| ↳ Week or unit label (e.g. "Week 1-2") | `units[].weekReference` | |
| ↳ Topics/subtopics listed under the unit | `units[].topics` | |
| ↳ Unit learning outcomes | `units[].outcomes` | |
| ↳ (Not in the syllabus) | `units[].difficulty` | Groq infers Easy/Medium/Hard from how complex the topics are |
| All topics across the course | `allTopics` | Flat list |
| Course Intended Learning Outcomes (ILOs) | `intendedLearningOutcomes` | |
| Order of concepts from basic to advanced | `conceptProgression` | |
| Prerequisites | `prerequisiteTopics` | |
| Grading system / assessment methods | `assessmentIndicators` | e.g. Quiz, Final Exam, Project |
| (How sure Groq is) | `confidenceFlags` | `true` if clearly stated, `false` if inferred or missing |

Sections such as the vision/mission, class policies, references, grading percentages, and instructor details are not extracted.

### Step 2: Which Extracted Fields Each Generator Uses

✅ = sent to Groq in the prompt · ➕ = not sent to Groq, but added to the saved item by the app · — = not used

| Analysis field | Lesson | Quiz | Puzzle | Simulation |
| --- | :---: | :---: | :---: | :---: |
| `courseTitle` | ✅ | ✅ | ✅ | ✅ |
| `programmingLanguage` | ✅ | ✅ | ✅ | ✅ |
| `programmingLanguageVersion` | ✅ (if present) | — | — | — |
| `units[].unitNumber` | ✅ | ➕ | ➕ | ➕ |
| `units[].title` | ✅ | ✅ | ✅ | ✅ |
| `units[].weekReference` | ✅ | — | — | — |
| `units[].topics` | ✅ | ✅ | ✅ | ✅ |
| `units[].outcomes` | ✅ | — | — | — |
| `units[].difficulty` | ✅ | ✅ | ✅ | ✅ |
| `courseCode`, `courseDescription`, `yearLevel` | — | — | — | — |
| `allTopics`, `intendedLearningOutcomes`, `conceptProgression`, `prerequisiteTopics`, `assessmentIndicators` | — | — | — | — |

Key points:

- **Lessons get the most syllabus context.** They are the only items that receive the unit's **learning outcomes** and **week reference**. Groq uses the outcomes to write `learningObjective` and to decide how deep the lesson goes.
- **Quizzes and puzzles get only the unit title, topic list, and difficulty**, plus the course title and language. They do not see the unit's learning outcomes.
- **Topic-level fields** (`allTopics`, `conceptProgression`, `prerequisiteTopics`, ILOs) and **course-level details** (code, description, year level) are saved and shown to the admin, but are not sent to any generator. For example, a lesson's `prerequisites` are written by Groq from the unit alone, not from the syllabus's prerequisite list.
- **Language** comes from what Groq extracted from the syllabus text, not from the language the admin selected on the upload form. The upload-form value is only stored on the `syllabi` record.
- **Audience** (`audiencePrograms`, `yearLevels`) is fixed by the prompt (BS CS, BS IT, BS Math-CIT; 1st and 2nd Year), not taken from the syllabus `yearLevel`.

### Step 3: The Prompt Context Each Generator Receives

The `${...}` values are filled in from the analysis (`a`) and the current unit (`u`).

**Lesson** (1 per unit):

```text
COURSE CONTEXT:
Course: ${a.courseTitle}
Language: ${a.programmingLanguage} ${a.programmingLanguageVersion}
Unit ${u.unitNumber}: ${u.title} (${u.weekReference})
Topics: ${u.topics joined by ", "}
Learning Outcomes: ${u.outcomes joined by "; "}
Difficulty: ${u.difficulty}
```

**Quiz** (3 questions per unit) and **Puzzle** (2 per unit):

```text
COURSE CONTEXT:
Course: ${a.courseTitle} | Language: ${a.programmingLanguage}
Unit: ${u.title} | Topics: ${u.topics joined by ", "} | Difficulty: ${u.difficulty}
```

### Step 4: How the Syllabus Shapes Each Generated Field

**Lesson**

| Generated field | Syllabus source |
| --- | --- |
| `title` | Unit title + topics |
| `topic` | Groq must choose **one specific topic from the unit's topic list** |
| `language` | `programmingLanguage` (normalized to C++, Java, or JavaScript; C/C++ becomes C++) |
| `difficulty` | Copied from the unit's inferred `difficulty` |
| `learningObjective` | Unit learning outcomes, rewritten as 2–3 measurable outcomes |
| `description`, `introduction`, `keyConcepts`, `algorithmSteps`, `workedExample`, `commonMistakes`, `summary` | Written by Groq for the chosen topic at the unit's difficulty, for 1st–2nd year learners |
| `prerequisites` | Written by Groq from the unit (not from the syllabus prerequisites) |
| `sourceCode`, `standardInput`, `expectedOutput` | A runnable program in the extracted language that demonstrates the topic |
| `sortOrder` | Position of the unit in the syllabus outline (Unit 1 → 1, Unit 2 → 2, …) |
| `syllabusId`, `syllabusTitle`, `unitNumber`, `unitTitle` | Added by the app to link the lesson back to its syllabus unit |

If Groq leaves a field empty, `_completeLesson()` fills it from the syllabus: the `topic` falls back to the **first topic of the unit** (or the unit title), the `difficulty` to the unit difficulty, and the language to the extracted `programmingLanguage`.

**Quiz** (each Groq item is one question)

| Generated field | Syllabus source |
| --- | --- |
| `topic`, `questionText`, `codeSnippet` | One of the unit's topics; the snippet is 3–8 lines in the extracted language |
| `questionType` | Mix of `output_prediction`, `code_tracing`, `identify_error`, `multiple_choice` |
| `options`, `correctAnswer`, `explanation` | Written by Groq; distractors must be plausible beginner mistakes about the topic |
| `difficulty` | Unit difficulty |
| `xpReward` | Fixed at 20 |

**Puzzle**

| Generated field | Syllabus source |
| --- | --- |
| `topic`, `codeSnippet` | One of the unit's topics, in the extracted language |
| `puzzleType` | Groq picks `code_flow`, `output_prediction`, or `debug_bug` |
| `scrambledLines`/`correctOrder`, `outputChoices`/`correctOutputId`, `bugDescription`/`bugAnswer` | Built from the code snippet for the chosen type |
| `hint`, `explanation` | Written by Groq for the topic |
| `difficulty` | Unit difficulty |
| `xpReward` | Fixed at 25 |

### Example

Suppose the syllabus outline contains:

```text
Week 3-4: Control Structures
  Topics: if-else statements, switch statements, nested conditions
  Outcomes: Apply selection statements to solve decision problems.
```

Analysis stores it as a unit:

```json
{
  "unitNumber": 2,
  "title": "Control Structures",
  "weekReference": "Week 3-4",
  "topics": ["if-else statements", "switch statements", "nested conditions"],
  "outcomes": ["Apply selection statements to solve decision problems."],
  "difficulty": "Medium"
}
```

Generation for this unit then produces:

- **1 lesson** on one of the three topics (e.g. "if-else statements"), with a learning objective based on "Apply selection statements to solve decision problems." and `sortOrder: 2`.
- **3 quiz questions** across the three topics, at Medium difficulty.
- **2 puzzles** (e.g. ordering the lines of a `switch` statement, or fixing a bug in a nested `if`).

All items are tagged with `unitNumber: 2` and `unitTitle: "Control Structures"`.

### Tips for Better Results

- Paste the **course outline / weekly topics** section, with the topics listed under each week or unit. This is the only section that drives lesson, quiz, and puzzle content.
- Include the **learning outcomes for each unit**, so lessons get specific learning objectives.
- State the **programming language** clearly (C++, Java, or JavaScript). Other languages are converted to C++ for lessons.
- After analysis, check every field whose `confidenceFlags` value is `false` (for example `units` or `outcomes`). Groq guessed those fields instead of finding them in the syllabus.

## 3. Content Generation Pipeline (Lessons, Quizzes, Puzzles, Simulations)

`AdminGenerationProvider.generateContent()` runs for one content type at a time:

1. A `content_generation_jobs` document is created with `status: "running"`.
2. If the analysis has no units, the job is marked `failed` immediately.
3. For each syllabus unit, one Groq request is made with that unit's title, topics, outcomes, and difficulty:

   | Content type | Items per unit | Output |
   | --- | --- | --- |
   | Lesson | 1 | Full structured lesson with runnable code (4800-token budget) |
   | Quiz | 3 | Questions of type `output_prediction`, `code_tracing`, `identify_error`, or `multiple_choice` |
   | Puzzle | 2 | `code_flow`, `output_prediction`, or `debug_bug` puzzles |
   | Simulation | 2 | Step-by-step execution traces with visible and hidden test cases |

4. Each returned item is tagged with `syllabusId`, `syllabusTitle`, `unitNumber`, and `unitTitle` and saved to its collection (`lessons`, `quizzes`, `puzzles`, or `simulations`) with `createdAt`/`updatedAt`.
5. When a unit fails, the error is recorded and the loop continues with the next unit.
6. The job is finalized with `generatedCount`, `failedCount`, `generatedIds`, up to three error messages, and a status:
   - `completed`: every unit succeeded
   - `partial`: some units failed but at least one item was saved
   - `failed`: nothing was saved
7. The run is logged, and per-syllabus generated counts and the job history are refreshed.

All generated items are saved as drafts (`isPublished: false`, `generatedByAi: true`, `approvalStatus: "generated"`, `compilerValidated: false`). Nothing reaches students until an admin reviews and publishes it.

## 4. Lesson Creation

**From a syllabus (Lesson Generator):** the generator runs upload → analysis → lesson generation as one flow. Before saving, each AI lesson goes through `_completeLesson()`, which:

- Normalizes the language to `C++`, `Java`, or `JavaScript`.
- Fills missing or too-short sections (description, introduction, worked example, common mistakes, summary) with topic-based fallback text, and ensures at least 5 key concepts, 2 prerequisites, and 6 algorithm steps.
- Clamps `estimatedMinutes` to 35–50 and sets default audience programs and year levels.
- Replaces JavaScript that uses APIs unsupported on Node.js (mock files, browser file pickers, `using` declarations) with a safe starter program and resets the expected output to match.
- Sets `sortOrder` from the unit position and forces `isPublished: false`.

**Manually (Lessons Management):** `createLesson()` adds the document with timestamps. `updateLesson()` first copies the current document into `lessons/{id}/revisions` (with `snapshotAt` and `snapshotBy`), then applies the update. The 20 most recent revisions can be viewed. Deleting a lesson also removes its revisions in batches.

**Compiler validation:** the admin runs the lesson's source code through the compiler service (`/api/v2/execute`). `compilerValidated` becomes `true` only when execution succeeds and the output matches `expectedOutput`. Editing the code clears the validation.

**Publish check:** a lesson can be published only when it has a title, description, audience (programs and year levels), learning objective, key concepts, and algorithm steps, and its source code (if any) is compiler-validated.

## 5. Quiz Creation

**From a syllabus:** AI quiz items are saved to `quizzes` as drafts by the pipeline above.

**From a lesson (Quizzes Management):** the quiz draft is built from the lesson without AI. Multiple-choice questions are generated from the lesson's algorithm steps and key concepts, using other steps/concepts and unrelated distractors as wrong options. The quiz inherits the lesson's topic, language, audience, and error focus, with an 80% passing score, 3 attempts, shuffled questions, and an XP reward based on difficulty (25/30/35). `createQuizWithQuestions()` rejects the set if:

- there are no questions, or any question repeats;
- a question is shorter than 12 or longer than 240 characters;
- a question does not have exactly four different options;
- the correct answer does not appear exactly once among the options.

If saving any question fails, the partially created quiz is deleted.

**Answer-key separation:** `saveQuizQuestion()` writes in one batch:

- the public question (text, options, order) to `quizzes/{quizId}/questions/{questionId}`, removing any legacy `correctAnswer`/`explanation` fields;
- the correct answer and explanation to `quiz_answer_keys/{quizId}/questions/{questionId}`, which only admins can read.

Deleting a quiz removes its questions, answer keys, and both parent documents.

**Publish check:** a quiz needs a title, topic, audience, a supported language, an error focus (`concept`, `syntax`, or `logic`), a passing score from 50 to 100, and an attempt limit above 0. Every question must have a correct answer that matches one of its options.

**Grading:** students submit answers to the `evaluateQuiz` Cloud Function. It verifies the Firebase ID token, confirms the quiz is published, enforces the attempt limit (HTTP 429 when reached), requires an answer for every question, and compares each answer to the private key (case- and whitespace-insensitive). It stores a `quiz_attempts` record with score, pass/fail, per-question outcomes, and the student's program/year, then returns feedback with correct answers and explanations.

## 6. Puzzle Creation

**From a syllabus:** the AI returns puzzles with type-specific fields, saved to `puzzles` as drafts:

| Puzzle type | Required fields |
| --- | --- |
| `code_flow` | `scrambledLines` (shuffled) and `correctOrder` (0-based indices) |
| `output_prediction` | `outputChoices` (4 options) and `correctOutputId` |
| `debug_bug` | `bugDescription` and `bugAnswer` |

Each puzzle also has a title, topic, language, difficulty, `codeSnippet`, hint, explanation, and XP reward (default 25).

**Manually (Puzzles Management):** puzzles are created, updated, and deleted through `admin_firestore_service.dart`, and each action is logged.

**Publish check:** a puzzle needs a title, topic, program audience, year level, and a supported type with its required fields: at least 2 lines and order indices for `code_flow`, at least 2 choices and a correct answer for `output_prediction`, and a bug description and answer for `debug_bug`.

## End-to-End Flow

```text
Admin selects file + pastes text
        │
        ▼
Cloudinary upload ──► syllabi/{id}  (analysisStatus: pending)
        │
        ▼
Groq analysis ──► syllabus_analysis/{id}  (status: analyzing → analyzed | failed)
        │
        ▼
content_generation_jobs/{jobId}  (running)
        │  for each unit
        ▼
Groq generation ──► lessons / quizzes / puzzles / simulations  (drafts)
        │
        ▼
Job finalized (completed | partial | failed) + activity log
        │
        ▼
Admin review → compiler validation (lessons) → readiness check → publish
        │
        ▼
Students see published content; quizzes graded by evaluateQuiz
```
