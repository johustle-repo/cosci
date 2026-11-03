# CoSci — Pre-Final Defense Presentation Guide

## Requirements (from the whiteboard)

| Item | Requirement |
| --- | --- |
| **Schedule** | October 14, 2026 (Wednesday) |
| **What to wear** | University uniform |
| **What to prepare** | 1. An **80%–100% working system** (live demo)<br>2. A **presentation** covering **Title**, **Brief Background**, and **Features** |

The working system is the main requirement (it was circled on the board). The slides should be short and lead into the live demo.

---

## Slide 1 — Title

**CoSci: A Gamified Programming Learning System for the Pangasinan State University College of Computing Sciences**

- Presented by: *[Group members]*
- Adviser: *[Adviser name]*
- Pre-Final Defense · October 14, 2026

> The title above is a draft based on the README. Replace it with your approved research title if it is different.

---

## Slide 2 — Brief Background

**The problem**

- First- and second-year computing students often struggle to turn problem-solving steps (algorithms and pseudocode) into working code in C++, Java, or JavaScript.
- Traditional lessons give little hands-on practice and immediate feedback, which lowers engagement and motivation.
- Instructors have limited visibility into which students are falling behind until exams.

**The proposed solution**

CoSci is a role-based, gamified web and mobile learning system. It combines guided lessons, runnable coding activities, quizzes, and puzzles with XP, levels, badges, streaks, and leaderboards. Teachers and administrators can monitor progress and identify students who need help.

**Target users**

- **Students:** BS Computer Science, BS Information Technology, and BS Mathematics-CIT (1st and 2nd year)
- **Instructors:** monitor classes and preview content
- **Administrators:** manage content, users, and analytics

---

## Slide 3 — Objectives

1. Provide structured, step-by-step programming lessons with runnable examples.
2. Give hands-on coding practice with a real compiler and instant feedback.
3. Increase motivation through gamification (XP, levels, badges, streaks, daily challenges, leaderboards).
4. Assess learning through securely graded quizzes and interactive puzzles.
5. Help administrators create content faster from the course syllabus.
6. Allow monitoring of student progress and early identification of students who need help.

---

## Slide 4 — Features: Students

- **Secure sign-up and access:** PSU institutional email, email verification, and student ID verification with OCR.
- **Lessons:**
  - structured content (objectives, key concepts, algorithm steps, worked examples, common mistakes, summary, runnable code);
  - **1st Year students see C++ lessons only**, while 2nd Year students see all languages.
- **One-at-a-time unlocking:** the next lesson, quiz, or puzzle unlocks only after the current one is finished.
- **Code simulation:** write, run, and test C++, Java, and JavaScript code using a hosted compiler, with visible and hidden test cases.
- **Quizzes:** graded on the server with protected answer keys, attempt limits, a passing score, and explanations.
- **Puzzles:** code ordering, output prediction, and bug finding.
- **Gamification:** XP, levels, badges, streaks, daily challenges, and downloadable PDF achievement certificates.
- **Progress tracking:** completion status and recommended next lesson.

---

## Slide 5 — Features: Instructors

- Instructor dashboard
- Student management and class analytics
- Lesson library
- Preview of simulations, quizzes, and puzzles

---

## Slide 6 — Features: Administrators

- **Content management:** create, edit, preview, publish, and delete lessons, simulations, quizzes, and puzzles.
  - Content must pass readiness checks before publishing, e.g. lesson code must pass compiler validation.
- **AI-assisted syllabus processing:** upload a syllabus and extract its units, topics, and outcomes, then generate draft lessons, quizzes, puzzles, and simulations. Every draft is reviewed by an admin before publishing.
- **Student Analytics** (new):
  - **Progress tracking** for every student (lessons, quizzes, puzzles, quiz average, completion percentage)
  - **Needs-help detection:** flags students who are inactive, have no progress, have low quiz scores, fail quizzes repeatedly, or run out of attempts
  - **Leaderboards** by XP, completion, quiz average, or streak
- **Reports:** topic mastery, quiz and simulation analytics.
- **Gamification:** badges and daily challenges.
- **Announcements, settings, and activity logs** (audit trail).

---

## Slide 7 — System Architecture / Technology

| Layer | Technology |
| --- | --- |
| App (web and Android) | Flutter |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore (with role-based security rules) |
| Hosting | Firebase Hosting (https://psueducode-apk.web.app) |
| Server logic | Firebase Cloud Functions (secure quiz grading, account deletion) |
| Code execution | CoSci compiler service on Render (C++, Java, JavaScript) |
| Syllabus file storage | Cloudinary |
| AI content generation | Groq API |

---

## Slide 8 — Live Demo (80–100% Working System)

Suggested demo flow (about 5–8 minutes):

1. **Student:** sign in → dashboard → open the unlocked lesson (other lessons are locked) → complete it → the next lesson unlocks.
2. **Student:** run code in a simulation → take a quiz → solve a puzzle → show XP, badges, and the reward popup.
3. **Admin:** create or publish a lesson (show compiler validation) → syllabus upload and draft generation.
4. **Admin:** Student Analytics → Progress, **Needs help**, and **Leaderboard** tabs.

---

## Slide 9 — Thank You / Q&A

---

## Pre-Defense Checklist

- [ ] University uniform
- [ ] Laptop is charged and the charger and HDMI/adapter are packed
- [ ] Web app opens: https://psueducode-apk.web.app
- [ ] Android APK is installed on a phone (`build/app/outputs/flutter-apk/app-release.apk`)
- [ ] Demo accounts are ready: one student (1st Year), one student (2nd Year), one instructor, one admin
- [ ] Demo data is seeded: published lessons, quizzes, and puzzles, plus a few student attempts so analytics show results
- [ ] The compiler service is awake. Render free instances sleep, so open it a few minutes before the defense.
- [ ] Backup: a screen recording of the demo in case of internet problems

## Possible Panel Questions

- **How is quiz cheating prevented?** Answers are stored in a separate admin-only collection and graded by a Cloud Function.
- **How is AI-generated content checked?** Everything is saved as a draft. An admin reviews it, lesson code must pass the compiler, and readiness checks run before publishing.
- **How do you identify struggling students?** Through the Needs Help rules: inactivity, no progress, quiz average below 60%, repeated failures, and running out of attempts.
- **Why lock content one item at a time?** To make students learn in order and master each topic before moving on.
- **Why are 1st Year students limited to C++?** It matches the first-year curriculum. Java and JavaScript open in 2nd Year.
