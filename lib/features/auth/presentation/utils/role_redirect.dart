import 'package:flutter/widgets.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:pseudocode_apk/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pseudocode_apk/features/professor/presentation/screens/professor_home_screen.dart';
import 'package:pseudocode_apk/models/app_user.dart';
import 'package:pseudocode_apk/features/auth/presentation/screens/student_id_verification_screen.dart';

/// Central role-based routing helper.
///
/// [buildHome] returns the home widget for the given user role (used by
/// [AppStartupScreen] and [GuestGuard] which render widgets inline).
///
/// [homeRoute] returns the named route string for post-login navigation
/// (used by screens that call [Navigator.pushNamedAndRemoveUntil]).
class RoleRedirect {
  /// Returns the home widget for inline rendering based on role.
  static Widget buildHome(AppUser? user) {
    final role = user?.normalizedRole ?? '';
    if (role == 'admin') {
      return const AdminDashboardScreen();
    }
    switch (role) {
      case 'instructor':
        return const ProfessorHomeScreen();
      case 'student':
        if (user?.requiresIdVerification ?? false) {
          return const StudentIdVerificationScreen();
        }
        return const DashboardScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  /// Returns the named route for [Navigator.pushNamedAndRemoveUntil] after login.
  static String homeRoute(AppUser? user) {
    final role = user?.normalizedRole ?? '';
    if (role == 'admin') return AppRoutes.adminHome;
    if (role == 'instructor') return AppRoutes.professorHome;
    if (user?.requiresIdVerification ?? false) {
      return AppRoutes.verifyStudentId;
    }
    return AppRoutes.dashboard;
  }
}
