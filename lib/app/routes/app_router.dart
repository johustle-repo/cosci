import 'package:flutter/material.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_activity_logs_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_announcements_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_generation_jobs_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_syllabus_detail_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_syllabus_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_challenges_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_gamification_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_lessons_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_lesson_generator_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_puzzles_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_quizzes_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_simulations_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_student_detail_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_students_screen.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_guard.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/get_started_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/login_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/register_screen.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/account_verification_screen.dart';
import 'package:pseudocode_apk/features/code_simulation/presentation/screens/code_simulation_screen.dart';
import 'package:pseudocode_apk/features/account/presentation/screens/account_screen.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pseudocode_apk/features/gamification/presentation/screens/gamification_screen.dart';
import 'package:pseudocode_apk/features/lessons/presentation/screens/lesson_detail_screen.dart';
import 'package:pseudocode_apk/features/lessons/presentation/screens/lessons_screen.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/features/professor/presentation/screens/professor_home_screen.dart';
import 'package:pseudocode_apk/features/professor/presentation/screens/instructor_content_screen.dart';
import 'package:pseudocode_apk/features/professor/presentation/screens/instructor_students_screen.dart';
import 'package:pseudocode_apk/features/progress_tracking/presentation/screens/progress_tracking_screen.dart';
import 'package:pseudocode_apk/features/puzzles/presentation/screens/puzzles_screen.dart';
import 'package:pseudocode_apk/features/quizzes/presentation/screens/quizzes_screen.dart';
import 'package:pseudocode_apk/shared/widgets/auth_guard.dart';
import 'package:pseudocode_apk/shared/widgets/app_startup_screen.dart';

class AppRouter {
  const AppRouter({this.startupError});

  final String? startupError;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Startup & Auth ─────────────────────────────────────────────────────
      case AppRoutes.startup:
        return _build(AppStartupScreen(startupError: startupError), settings);
      case AppRoutes.login:
        return _build(const GuestGuard(child: LoginScreen()), settings);
      case AppRoutes.getStarted:
        return _build(const GuestGuard(child: GetStartedScreen()), settings);
      case AppRoutes.register:
        return _build(const GuestGuard(child: RegisterScreen()), settings);
      case AppRoutes.verifyEmail:
        return _build(
          AccountVerificationScreen(email: settings.arguments as String? ?? ''),
          settings,
        );
      case AppRoutes.forgotPassword:
        return _build(
          const GuestGuard(child: ForgotPasswordScreen()),
          settings,
        );

      // ── Student routes ─────────────────────────────────────────────────────
      case AppRoutes.dashboard:
        return _build(const AuthGuard(child: DashboardScreen()), settings);
      case AppRoutes.professorHome:
        return _build(
          const AuthGuard(
            allowedRole: 'instructor',
            child: ProfessorHomeScreen(),
          ),
          settings,
        );
      case AppRoutes.instructorLessons:
        return _build(
          const AuthGuard(
            allowedRole: 'instructor',
            child: InstructorLessonLibraryScreen(),
          ),
          settings,
        );
      case AppRoutes.instructorSimulations:
        return _build(
          const AuthGuard(
            allowedRole: 'instructor',
            child: InstructorSimulationPreviewScreen(),
          ),
          settings,
        );
      case AppRoutes.instructorQuizzes:
        return _build(
          const AuthGuard(
            allowedRole: 'instructor',
            child: InstructorQuizPreviewScreen(),
          ),
          settings,
        );
      case AppRoutes.instructorPuzzles:
        return _build(
          const AuthGuard(
            allowedRole: 'instructor',
            child: InstructorPuzzlePreviewScreen(),
          ),
          settings,
        );
      case AppRoutes.instructorStudents:
        return _build(
          const AuthGuard(
            allowedRole: 'instructor',
            child: InstructorStudentsScreen(),
          ),
          settings,
        );
      case AppRoutes.instructorAnalytics:
        return _build(
          const AuthGuard(
            allowedRole: 'instructor',
            child: InstructorClassAnalyticsScreen(),
          ),
          settings,
        );
      case AppRoutes.lessons:
        return _build(const AuthGuard(child: LessonsScreen()), settings);
      case AppRoutes.lessonDetail:
        final lesson = settings.arguments as Lesson?;
        if (lesson == null) {
          return _build(const AuthGuard(child: LessonsScreen()), settings);
        }
        return _build(
          AuthGuard(child: LessonDetailScreen(lesson: lesson)),
          settings,
        );
      case AppRoutes.codeSimulation:
        return _build(const AuthGuard(child: CodeSimulationScreen()), settings);
      case AppRoutes.quizzes:
        return _build(const AuthGuard(child: QuizzesScreen()), settings);
      case AppRoutes.puzzles:
        return _build(const AuthGuard(child: PuzzlesScreen()), settings);
      case AppRoutes.gamification:
        return _build(const AuthGuard(child: GamificationScreen()), settings);
      case AppRoutes.progress:
        return _build(
          const AuthGuard(child: ProgressTrackingScreen()),
          settings,
        );
      case AppRoutes.account:
        return _build(const SignedInGuard(child: AccountScreen()), settings);

      // ── Admin routes ───────────────────────────────────────────────────────
      case AppRoutes.adminHome:
        return _build(
          const AdminGuard(child: AdminDashboardScreen()),
          settings,
        );
      case AppRoutes.adminStudents:
        return _build(const AdminGuard(child: AdminStudentsScreen()), settings);
      case AppRoutes.adminStudentDetail:
        final studentId = settings.arguments as String?;
        return _build(
          AdminGuard(
            child: AdminStudentDetailScreen(studentId: studentId ?? ''),
          ),
          settings,
        );
      case AppRoutes.adminLessons:
        return _build(const AdminGuard(child: AdminLessonsScreen()), settings);
      case AppRoutes.adminLessonGenerator:
        return _build(
          const AdminGuard(child: AdminLessonGeneratorScreen()),
          settings,
        );
      case AppRoutes.adminSimulations:
        return _build(
          const AdminGuard(child: AdminSimulationsScreen()),
          settings,
        );
      case AppRoutes.adminQuizzes:
        return _build(const AdminGuard(child: AdminQuizzesScreen()), settings);
      case AppRoutes.adminPuzzles:
        return _build(const AdminGuard(child: AdminPuzzlesScreen()), settings);
      case AppRoutes.adminGamification:
        return _build(
          const AdminGuard(child: AdminGamificationScreen()),
          settings,
        );
      case AppRoutes.adminChallenges:
        return _build(
          const AdminGuard(child: AdminChallengesScreen()),
          settings,
        );
      case AppRoutes.adminAnnouncements:
        return _build(
          const AdminGuard(child: AdminAnnouncementsScreen()),
          settings,
        );
      case AppRoutes.adminReports:
        return _build(const AdminGuard(child: AdminReportsScreen()), settings);
      case AppRoutes.adminSettings:
        return _build(const AdminGuard(child: AdminSettingsScreen()), settings);
      case AppRoutes.adminActivityLogs:
        return _build(
          const AdminGuard(child: AdminActivityLogsScreen()),
          settings,
        );

      // ── Syllabus & AI generation routes ─────────────────────────────────
      case AppRoutes.adminSyllabus:
        return _build(const AdminGuard(child: AdminSyllabusScreen()), settings);
      case AppRoutes.adminSyllabusDetail:
        final syllabusId = settings.arguments as String?;
        return _build(
          AdminGuard(
            child: AdminSyllabusDetailScreen(syllabusId: syllabusId ?? ''),
          ),
          settings,
        );
      case AppRoutes.adminGenerationJobs:
        final syllabusId = settings.arguments as String?;
        return _build(
          AdminGuard(child: AdminGenerationJobsScreen(syllabusId: syllabusId)),
          settings,
        );

      default:
        return _build(const AuthGuard(child: DashboardScreen()), settings);
    }
  }

  MaterialPageRoute<dynamic> _build(Widget page, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}
