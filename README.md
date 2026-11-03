# CoSci System Features and Capabilities

CoSci is a role-based, gamified programming learning system for students of the Pangasinan State University College of Computing Sciences. It provides guided lessons, executable coding activities, assessments, progress monitoring, and content-management tools.

## Shared and Authentication Screens

### Startup and Access Gate

**Purpose:** Determine where a user should go based on authentication, verification, account, and role status.

- Initializes Firebase and application services.
- Restores signed-in sessions.
- Enforces email and Student ID verification.
- Routes each user to the correct workspace.
- Blocks suspended, archived, or incomplete accounts.

### Get Started

**Purpose:** Introduce CoSci and provide a clear entry point into the system.

- Summarizes the main learning capabilities.
- Provides Create Account and Sign In actions.
- Adapts to mobile, tablet, and desktop screens.

### Create Account

**Purpose:** Create a secure student account with the academic information needed to personalize learning.

- Collects full name, program, year level, email, and password.
- Accepts only PSU institutional addresses ending in `@psu.edu.ph`.
- Validates password strength and confirmation.
- Creates authentication, profile, and progress records.
- Sends the student to email verification.

### Sign In

**Purpose:** Authenticate users and open the workspace assigned to their role.

- Signs users in using email and password.
- Resumes verification for unverified accounts.
- Enforces account and role restrictions.
- Redirects students, instructors, and administrators appropriately.

### Email Verification

**Purpose:** Confirm ownership of the registered email before protected access is granted.

- Displays verification instructions and the registered address.
- Resends verification emails.
- Refreshes the verification state.
- Sends verified students to Student ID Verification.

### Student ID Verification

**Purpose:** Restrict student access to eligible CCS students and prevent identity reuse.

- Accepts an ID photo from the camera or gallery.
- Extracts the student name, number, institution, and program through OCR.
- Lets students review and correct extracted information.
- Sets the institution to Pangasinan State University during confirmation.
- Accepts BS Information Technology, BS Computer Science, and BS Mathematics.
- Normalizes common program-name and OCR variations.
- Compares the ID name with the registered account name.
- Prevents one student number from being used by multiple accounts.
- Saves successful verification and redirects to the dashboard.
- Shows review-required and non-CCS rejection messages.

### Forgot Password

**Purpose:** Help users regain account access securely.

- Validates the submitted email.
- Sends password-reset instructions.
- Displays clear success and error feedback.

### Account and Security

**Purpose:** Let users review their identity, profile, and account security.

- Displays name, institutional email, role, and academic details.
- Supports permitted profile updates.
- Allows password changes after confirmation.
- Provides password-reset, privacy, support, and platform information.

## Student Screens

### Student Dashboard

**Purpose:** Give students a simple overview of their learning status and activities.

- Displays XP, level, streak, completion, and recent badges.
- Links to lessons, simulations, quizzes, puzzles, achievements, and progress.
- Provides loading, empty, and retry states.

### Lessons

**Purpose:** Organize guided learning materials available to the student.

- Lists published lessons for the student's program and year level.
- Applies a year-level language rule: 1st Year students see only C++ lessons, while 2nd Year students see lessons in every available language (C++, Java, and JavaScript).
- Unlocks lessons one at a time in lesson order: only the first lesson is open at the start, and each next lesson unlocks after the current one is completed. Completed lessons stay open for review; locked lessons show a lock and cannot be opened.
- Recommends the current unlocked lesson as the next step.
- Displays topic, language, difficulty, and completion information.
- Opens lesson details while hiding unpublished content.

### Lesson Detail

**Purpose:** Teach one programming concept through structured explanations and examples.

- Presents objectives, prerequisites, introduction, and key concepts.
- Displays correctly numbered algorithm steps.
- Includes worked examples, mistakes, error guidance, and summaries.
- Shows optional pseudocode and runnable code.
- Reorganizes content safely on small screens.

### Code Simulation

**Purpose:** Let students edit, run, test, and submit programming solutions.

- Supports C++, Java, and JavaScript.
- Provides starter code, editor, standard input, and console output.
- Runs code through the hosted compiler service.
- Handles terminal-compatible Java `Scanner` input.
- Separates compilation, runtime, timeout, and logic errors.
- Provides reset and copy-output actions.
- Shows a lesson-related engagement task.
- Evaluates public and protected test cases.
- Records attempts, completion, XP, and rewards.

### Quizzes

**Purpose:** Measure understanding of lesson concepts.

- Lists published quizzes and their lesson context.
- Unlocks quizzes one at a time: the next quiz unlocks after the current quiz is passed, or after all of its attempts are used so a student is never permanently blocked.
- Provides question navigation and answer selection.
- Grades attempts through the trusted evaluator when configured.
- Displays scores, explanations, and completion feedback.
- Records attempts and updates progress.

### Puzzles

**Purpose:** Reinforce syntax and algorithm sequencing through interactive challenges.

- Lists published puzzles by topic and difficulty.
- Unlocks puzzles one at a time: the next puzzle unlocks after the current puzzle is solved.
- Lets students arrange or select code pieces.
- Validates solutions and displays feedback or hints.
- Updates attempts, XP, streak, and badge progress.

### Gamification and Achievements

**Purpose:** Encourage participation by recognizing milestones and consistency.

- Displays XP, level, rank, streaks, quests, and badges.
- Unlocks achievements when requirements are met.
- Shows badge and milestone details.
- Generates downloadable PDF achievement certificates.

### Progress Tracking

**Purpose:** Help students understand their learning growth and completed work.

- Summarizes lessons, quizzes, puzzles, simulations, badges, XP, and streaks.
- Displays recent learning activity.
- Synchronizes data with instructor and admin reports.

## Instructor Screens

### Instructor Dashboard

**Purpose:** Show participation, learner difficulties, and work needing attention.

- Displays participation and recent attempts.
- Provides an instructor review queue.
- Identifies learners needing intervention.
- Shows coverage by language and weak topics.
- Opens learner attempts for review and feedback.
- Links to analytics and content previews.

### Student Management

**Purpose:** Monitor individual learners and provide targeted support.

- Lists students with program, year level, attempts, and success rate.
- Searches by learner name or email.
- Filters by program and year level.
- Displays recent and unsuccessful attempts.

### Class Analytics

**Purpose:** Turn class activity into useful teaching information.

- Summarizes attempts, pass rates, participation, languages, and topics.
- Identifies weak topics and common failure patterns.
- Uses current learner and attempt records.

### Lesson Library

**Purpose:** Review lessons available to students.

- Lists published lessons.
- Opens student-facing previews without changing content.

### Simulation Preview

**Purpose:** Inspect coding activities before guiding students.

- Displays published tasks, languages, starter code, and expected behavior.
- Prevents previews from affecting student progress.

### Quiz Preview

**Purpose:** Verify assessment coverage and clarity.

- Displays published quizzes and questions in preview mode.
- Does not create student attempts or scores.

### Puzzle Preview

**Purpose:** Review puzzle instructions and learning alignment.

- Displays published puzzle content and interaction design.
- Does not modify student progress.

## Administrator Screens

### Admin Dashboard

**Purpose:** Provide a central overview of users, content, and system activity.

- Displays platform totals and activity statistics.
- Provides shortcuts to management screens.
- Shows recent administrative actions.

### Users

**Purpose:** Manage every account and inspect learning and verification information.

- Displays name, email, date, role, level, XP, streak, and badges.
- Shows Student ID status as Verified, Pending, or Not required.
- Separates identity verification from Active or Inactive status.
- Supports searching and filtering.
- Changes roles and activates, suspends, views, or deletes accounts.

### Student Profile

**Purpose:** Provide a detailed administrative view of one learner.

- Displays account, academic, progress, and activity information.
- Identifies incomplete profile data.
- Allows account activation or suspension.

### Lessons Management

**Purpose:** Create and maintain structured learning material.

- Creates, edits, previews, publishes, unpublishes, and deletes lessons.
- Configures audience, language, difficulty, order, and duration.
- Manages objectives, concepts, algorithms, examples, mistakes, and summaries.
- Stores runnable code, standard input, and expected output.
- Compiles and validates examples before publishing.

### Lesson Generator

**Purpose:** Speed up lesson preparation while keeping administrator review.

- Builds structured lesson drafts from topic or syllabus data.
- Allows every field to be reviewed and edited before saving.

### Simulations Management

**Purpose:** Build practical coding exercises with verifiable behavior.

- Creates, edits, previews, publishes, and deletes simulations.
- Configures lessons, languages, tasks, starter code, hints, and output.
- Manages public and protected test cases.
- Validates code through the compiler service.

### Quizzes Management

**Purpose:** Create and control lesson-based assessments.

- Creates quizzes manually or drafts them from lessons.
- Manages questions, choices, correct answers, explanations, and scores.
- Previews, publishes, unpublishes, and deletes quizzes.

### Puzzles Management

**Purpose:** Create interactive syntax and code-order exercises.

- Creates, edits, previews, publishes, and deletes puzzles.
- Configures language, topic, difficulty, code pieces, solution, hints, and rewards.

### Gamification Management

**Purpose:** Define how participation and achievement are rewarded.

- Manages badge definitions and milestone requirements.
- Configures activity and rank achievements.
- Installs the starter badge collection.

### Daily Challenges

**Purpose:** Provide scheduled activities that encourage regular practice.

- Creates and schedules challenges.
- Links challenges to valid learning activities.
- Controls draft, active, and archived states.
- Prevents activation when linked content is missing.

### Announcements

**Purpose:** Communicate updates to selected user groups.

- Creates, edits, publishes, and removes announcements.
- Selects the audience, visibility dates, and status.

### Reports and Analytics

**Purpose:** Evaluate system use and learner performance.

- Displays strongest and weakest topics.
- Shows learner rankings with XP, level, streak, and badges.
- Includes registered learners without activity.
- Compares quiz results across programs.
- Identifies questions, simulations, and error categories needing review.

### Student Analytics

**Purpose:** Track each learner's progress, find students who need support, and rank learners.

- Summarizes students, active learners this week, students needing help, average completion, and average quiz score.
- Filters by name or email, program, and year level.
- **Progress:** lists every student's completed lessons, passed quizzes, and solved puzzles against published totals, plus quiz average, completion percentage, XP and level, last activity, and status. Selecting a student opens their profile.
- **Needs help:** flags students who have been inactive for 7+ days, have no completed activity, have a quiz average below 60%, failed the same quiz at least twice, or used every quiz attempt without passing. Students with two or more reasons, or who ran out of quiz attempts, are marked high priority. Accounts younger than 7 days are not flagged for inactivity or lack of progress.
- **Leaderboard:** ranks students by total XP, completion, quiz average, or streak, with a top-three podium and a full ranked table.

### Settings

**Purpose:** Control reusable configuration and system behavior.

- Manages course topics and module visibility.
- Reviews administrative roles and permissions.
- Supports backup and restore workflows.
- Configures maintenance mode and its message.

### Activity Logs

**Purpose:** Maintain accountability for administrative changes.

- Records the administrator, action, target, and timestamp.
- Supports searching and reviewing historical actions.

### Supporting Syllabus and Content Screens

**Purpose:** Turn syllabus information into editable content drafts.

- Uploads documents or accepts pasted syllabus content.
- Extracts units, topics, and learning outcomes.
- Creates draft lessons, quizzes, puzzles, and simulations.
- Tracks completed, skipped, and failed generation work.
- These routes are retained but hidden from the main admin sidebar.

## Backend Process: Syllabus Upload and Content Creation

See [syllabus_process.md](syllabus_process.md) for the backend flow of syllabus uploading and lesson, quiz, and puzzle creation.

## System-Wide Capabilities

- Role-based access for students, instructors, and administrators.
- Firebase Authentication, verified-email gating, and account-state enforcement.
- Firestore persistence for profiles, content, attempts, progress, and logs.
- OCR-assisted ID extraction, CCS eligibility, name matching, and duplicate-ID prevention.
- Hosted C++, Java, and JavaScript compilation with safe timeouts.
- Trusted quiz and simulation evaluation using protected data.
- Progress synchronization across student, instructor, and admin views.
- PDF achievement certificates and web/native downloads.
- Responsive mobile, tablet, and desktop interfaces.
- Loading, empty, offline, error, retry, and recovery states.
