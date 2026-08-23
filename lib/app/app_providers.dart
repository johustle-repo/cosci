import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_announcements_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_challenges_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_dashboard_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_gamification_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_generation_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_lessons_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_logs_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_puzzles_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_quizzes_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_reports_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_settings_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_simulations_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_students_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_syllabus_provider.dart';
import 'package:pseudocode_apk/features/admin/services/admin_ai_generation_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_firestore_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_log_service.dart';
import 'package:pseudocode_apk/features/admin/services/admin_syllabus_service.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/providers/dashboard_provider.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';
import 'package:pseudocode_apk/providers/lessons_provider.dart';
import 'package:pseudocode_apk/providers/progress_provider.dart';
import 'package:pseudocode_apk/providers/puzzles_provider.dart';
import 'package:pseudocode_apk/providers/quizzes_provider.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/services/auth_service.dart';
import 'package:pseudocode_apk/services/code_simulation_service.dart';
import 'package:pseudocode_apk/services/dashboard_service.dart';
import 'package:pseudocode_apk/services/firestore_service.dart';
import 'package:pseudocode_apk/services/gamification_service.dart';
import 'package:pseudocode_apk/services/lesson_service.dart';
import 'package:pseudocode_apk/services/puzzle_service.dart';
import 'package:pseudocode_apk/services/progress_service.dart';
import 'package:pseudocode_apk/services/quiz_service.dart';
import 'package:pseudocode_apk/features/professor/services/instructor_analytics_service.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    // ── Core services ──────────────────────────────────────────────────────
    Provider<FirestoreService>(create: (_) => FirestoreService()),
    ProxyProvider<FirestoreService, AuthService>(
      update: (context, firestoreService, previous) =>
          AuthService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, LessonService>(
      update: (context, firestoreService, previous) =>
          LessonService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, ProgressService>(
      update: (context, firestoreService, previous) =>
          ProgressService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, DashboardService>(
      update: (context, firestoreService, previous) =>
          DashboardService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, GamificationService>(
      update: (context, firestoreService, previous) =>
          GamificationService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, PuzzleService>(
      update: (context, firestoreService, previous) =>
          PuzzleService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, QuizService>(
      update: (context, firestoreService, previous) =>
          QuizService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, CodeSimulationService>(
      update: (context, firestoreService, previous) =>
          CodeSimulationService(firestoreService: firestoreService),
    ),
    ProxyProvider<FirestoreService, InstructorAnalyticsService>(
      update: (_, firestoreService, previous) =>
          previous ??
          InstructorAnalyticsService(firestoreService: firestoreService),
    ),

    // ── Student-side providers ─────────────────────────────────────────────
    ChangeNotifierProxyProvider<AuthService, AuthProvider>(
      create: (_) => AuthProvider(),
      update: (_, authService, authProvider) =>
          authProvider!..attach(authService),
    ),
    ChangeNotifierProxyProvider<DashboardService, DashboardProvider>(
      create: (_) => DashboardProvider(),
      update: (_, dashboardService, dashboardProvider) =>
          dashboardProvider!..attach(dashboardService),
    ),
    ChangeNotifierProxyProvider<LessonService, LessonsProvider>(
      create: (_) => LessonsProvider(),
      update: (_, lessonService, lessonsProvider) =>
          lessonsProvider!..attach(lessonService),
    ),
    ChangeNotifierProxyProvider2<
      CodeSimulationService,
      AuthProvider,
      SimulationProvider
    >(
      create: (_) => SimulationProvider(),
      update: (_, simulationService, authProvider, simulationProvider) =>
          simulationProvider!..attach(simulationService, authProvider),
    ),
    ChangeNotifierProxyProvider<QuizService, QuizzesProvider>(
      create: (_) => QuizzesProvider(),
      update: (_, quizService, quizzesProvider) =>
          quizzesProvider!..attach(quizService),
    ),
    ChangeNotifierProxyProvider2<
      AuthProvider,
      GamificationService,
      GamificationProvider
    >(
      create: (_) => GamificationProvider(),
      update: (_, authProvider, gamificationService, gamificationProvider) =>
          gamificationProvider!..attach(
            gamificationService: gamificationService,
            authProvider: authProvider,
          ),
    ),
    ChangeNotifierProxyProvider3<
      PuzzleService,
      AuthProvider,
      GamificationProvider,
      PuzzlesProvider
    >(
      create: (_) => PuzzlesProvider(),
      update:
          (
            _,
            puzzleService,
            authProvider,
            gamificationProvider,
            puzzlesProvider,
          ) => puzzlesProvider!
            ..attach(
              puzzleService: puzzleService,
              authProvider: authProvider,
              gamificationProvider: gamificationProvider,
            ),
    ),
    ChangeNotifierProxyProvider<ProgressService, ProgressProvider>(
      create: (_) => ProgressProvider(),
      update: (_, progressService, progressProvider) =>
          progressProvider!..attach(progressService),
    ),

    // ── Admin services ─────────────────────────────────────────────────────
    ProxyProvider<FirestoreService, AdminFirestoreService>(
      update: (_, firestoreService, _) =>
          AdminFirestoreService(firestoreService: firestoreService),
    ),
    // AdminLogService depends on AdminFirestoreService (constructor) and
    // AuthProvider (to set the current admin user via setAdmin).
    ProxyProvider2<AdminFirestoreService, AuthProvider, AdminLogService>(
      update: (_, adminFirestoreService, authProvider, previous) {
        final svc =
            previous ??
            AdminLogService(adminFirestoreService: adminFirestoreService);
        svc.setAdmin(authProvider.currentUser);
        return svc;
      },
    ),

    // ── Admin providers ────────────────────────────────────────────────────
    // Dashboard + Reports + Logs only need AdminFirestoreService (no logger).
    ChangeNotifierProxyProvider<AdminFirestoreService, AdminDashboardProvider>(
      create: (_) => AdminDashboardProvider(),
      update: (_, adminService, provider) => provider!..attach(adminService),
    ),
    ChangeNotifierProxyProvider<AdminFirestoreService, AdminReportsProvider>(
      create: (_) => AdminReportsProvider(),
      update: (_, adminService, provider) => provider!..attach(adminService),
    ),
    ChangeNotifierProxyProvider<AdminFirestoreService, AdminLogsProvider>(
      create: (_) => AdminLogsProvider(),
      update: (_, adminService, provider) => provider!..attach(adminService),
    ),
    // All other admin providers need both AdminFirestoreService and AdminLogService.
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminStudentsProvider
    >(
      create: (_) => AdminStudentsProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminLessonsProvider
    >(
      create: (_) => AdminLessonsProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminSimulationsProvider
    >(
      create: (_) => AdminSimulationsProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminQuizzesProvider
    >(
      create: (_) => AdminQuizzesProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminPuzzlesProvider
    >(
      create: (_) => AdminPuzzlesProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminGamificationProvider
    >(
      create: (_) => AdminGamificationProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminChallengesProvider
    >(
      create: (_) => AdminChallengesProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminAnnouncementsProvider
    >(
      create: (_) => AdminAnnouncementsProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),
    ChangeNotifierProxyProvider2<
      AdminFirestoreService,
      AdminLogService,
      AdminSettingsProvider
    >(
      create: (_) => AdminSettingsProvider(),
      update: (_, adminService, logger, provider) =>
          provider!..attach(adminService, logger),
    ),

    // ── Syllabus & AI generation services ─────────────────────────────────
    // AdminAiGenerationService is a singleton that holds the API key in memory.
    Provider<AdminAiGenerationService>(
      create: (_) => AdminAiGenerationService(),
    ),
    ProxyProvider<FirestoreService, AdminSyllabusService>(
      update: (_, firestoreService, previous) =>
          previous ?? AdminSyllabusService(firestoreService: firestoreService),
    ),

    // ── Syllabus & AI generation providers ────────────────────────────────
    // Both providers need: AdminSyllabusService + AdminAiGenerationService + AdminLogService.
    ChangeNotifierProxyProvider3<
      AdminSyllabusService,
      AdminAiGenerationService,
      AdminLogService,
      AdminSyllabusProvider
    >(
      create: (_) => AdminSyllabusProvider(),
      update: (_, syllabusService, aiService, logger, provider) =>
          provider!..attach(syllabusService, aiService, logger),
    ),
    ChangeNotifierProxyProvider3<
      AdminSyllabusService,
      AdminAiGenerationService,
      AdminLogService,
      AdminGenerationProvider
    >(
      create: (_) => AdminGenerationProvider(),
      update: (_, syllabusService, aiService, logger, provider) =>
          provider!..attach(syllabusService, aiService, logger),
    ),
  ];
}
