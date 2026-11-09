# Expert Validation Form: Sequential (Step-by-Step) Unlocking of Learning Content

**System:** CoSci Gamified Programming Learning App
**Feature under validation:** One-at-a-time unlocking of lessons, quizzes, and puzzles
**Date of validation:** ____________________

---

## Part I. Description of the Design

The app does not show every lesson, quiz, and puzzle at once. Each kind of content is ordered like the course syllabus and unlocks in sequence:

1. **Separate path per programming language.** C++, Java, and JavaScript each have their own sequence. A student can work on several languages at the same time. A C++ quiz never blocks a Java quiz.
2. **One open item per path.** Within a language, only the first unfinished item can be opened. Finished items stay open for review.
3. **What counts as finished:**
   - *Lesson:* the student marks it "Done Reading".
   - *Quiz:* the student passes it (meets the passing score) **or** uses every allowed attempt, so no student is permanently blocked.
   - *Puzzle:* the student solves it (100%).
4. **Ordering** follows the `sortOrder` the instructor/admin assigns, which comes from the course syllabus outline (units and topics).
5. Students can open **"Why do these unlock step by step?"** in the app to read this rationale.

## Part II. Pedagogical Rationale

| Principle | How the design applies it |
| --- | --- |
| **Mastery learning** (Bloom, 1968) | A student moves to the next item only after passing the current one (or using every attempt), so learning gaps are found early. |
| **Learning hierarchy / prerequisite sequencing** (Gagné, 1985) | Programming concepts depend on earlier ones (variables → conditions → loops → arrays → functions). The order follows the syllabus. |
| **Scaffolding / Zone of Proximal Development** (Vygotsky, 1978; Wood, Bruner & Ross, 1976) | Each item builds a little on the one before, with hints and feedback, before harder material is introduced. |
| **Cognitive Load Theory** (Sweller, 1988) | One active topic per language keeps the number of new concepts the student handles at once small. |
| **Gamification: progression / level design** (Deterding et al., 2011) | Unlocking acts as a progression mechanic, gives clear next goals, and supports motivation. |

## Part III. Validation Criteria

Rate each statement: **4** Strongly Agree · **3** Agree · **2** Disagree · **1** Strongly Disagree

| # | Statement | 4 | 3 | 2 | 1 |
| --- | --- | :-: | :-: | :-: | :-: |
| 1 | Unlocking content one at a time is appropriate for introductory programming students. | ☐ | ☐ | ☐ | ☐ |
| 2 | The order of lessons, quizzes, and puzzles follows a logical concept progression consistent with the course syllabus. | ☐ | ☐ | ☐ | ☐ |
| 3 | Requiring a passing quiz score before the next quiz opens supports mastery of prerequisite concepts. | ☐ | ☐ | ☐ | ☐ |
| 4 | Treating a quiz as finished after all attempts are used is a fair way to keep students from being permanently blocked. | ☐ | ☐ | ☐ | ☐ |
| 5 | Keeping separate paths per programming language lets students study more than one language without unnecessary restriction. | ☐ | ☐ | ☐ | ☐ |
| 6 | Keeping completed items open for review supports retention. | ☐ | ☐ | ☐ | ☐ |
| 7 | The in-app explanation of why content unlocks step by step is clear to students. | ☐ | ☐ | ☐ | ☐ |
| 8 | The sequential design does not harm student motivation or engagement. | ☐ | ☐ | ☐ | ☐ |
| 9 | The passing score and number of attempts per quiz are reasonable. | ☐ | ☐ | ☐ | ☐ |
| 10 | Overall, the sequential unlocking design is pedagogically sound and acceptable for use. | ☐ | ☐ | ☐ | ☐ |

**Interpretation of the mean score:** 3.25 – 4.00 Highly Acceptable · 2.50 – 3.24 Acceptable · 1.75 – 2.49 Slightly Acceptable · 1.00 – 1.74 Not Acceptable

## Part IV. Comments and Recommendations

Which content, if any, should **not** be sequential (lessons / quizzes / puzzles)? ______________________________________________

Suggested changes to ordering, passing score, or attempt limits: ______________________________________________

Other comments: ______________________________________________

______________________________________________________________________________

## Part V. Validator's Certification

I have reviewed the sequential unlocking design of the CoSci Gamified Programming Learning App described above, and my ratings and comments are my independent professional judgment.

| | Validator 1 | Validator 2 | Validator 3 |
| --- | --- | --- | --- |
| Name | | | |
| Position / Designation | | | |
| Institution | | | |
| Field of expertise | | | |
| Years of teaching programming | | | |
| Verdict (Approved / Approved with revisions / Not approved) | | | |
| **Signature** | | | |
| Date | | | |

---

### References

- Bloom, B. S. (1968). Learning for mastery. *Evaluation Comment, 1*(2).
- Deterding, S., Dixon, D., Khaled, R., & Nacke, L. (2011). From game design elements to gamefulness: Defining "gamification". *Proceedings of MindTrek '11*, 9–15.
- Gagné, R. M. (1985). *The conditions of learning and theory of instruction* (4th ed.). Holt, Rinehart & Winston.
- Sweller, J. (1988). Cognitive load during problem solving: Effects on learning. *Cognitive Science, 12*(2), 257–285.
- Vygotsky, L. S. (1978). *Mind in society*. Harvard University Press.
- Wood, D., Bruner, J. S., & Ross, G. (1976). The role of tutoring in problem solving. *Journal of Child Psychology and Psychiatry, 17*(2), 89–100.
