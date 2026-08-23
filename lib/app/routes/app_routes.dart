class AppRoutes {
  // ── Student / shared routes ─────────────────────────────────────────────────
  static const String startup = '/';
  static const String getStarted = '/get-started';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String professorHome = '/professor-home';
  static const String instructorLessons = '/instructor/lessons';
  static const String instructorSimulations = '/instructor/simulations';
  static const String instructorQuizzes = '/instructor/quizzes';
  static const String instructorPuzzles = '/instructor/puzzles';
  static const String instructorStudents = '/instructor/students';
  static const String instructorAnalytics = '/instructor/analytics';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lessons/detail';
  static const String codeSimulation = '/code-simulation';
  static const String quizzes = '/quizzes';
  static const String puzzles = '/puzzles';
  static const String gamification = '/gamification';
  static const String progress = '/progress';
  static const String account = '/account';

  // ── Admin routes ─────────────────────────────────────────────────────────────
  static const String adminHome = '/admin-home';
  static const String adminStudents = '/admin/students';
  static const String adminStudentDetail = '/admin/students/detail';
  static const String adminLessons = '/admin/lessons';
  static const String adminLessonGenerator = '/admin/lessons/generate';
  static const String adminSimulations = '/admin/simulations';
  static const String adminQuizzes = '/admin/quizzes';
  static const String adminPuzzles = '/admin/puzzles';
  static const String adminGamification = '/admin/gamification';
  static const String adminChallenges = '/admin/challenges';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';
  static const String adminActivityLogs = '/admin/activity-logs';

  // ── Syllabus & AI generation routes ─────────────────────────────────────────
  static const String adminSyllabus = '/admin/syllabus';
  static const String adminSyllabusDetail = '/admin/syllabus/detail';
  static const String adminGenerationJobs = '/admin/generation-jobs';
}
