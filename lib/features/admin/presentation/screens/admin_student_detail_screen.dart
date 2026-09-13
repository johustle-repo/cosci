import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_profile.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_students_provider.dart';

class AdminStudentDetailScreen extends StatefulWidget {
  const AdminStudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<AdminStudentDetailScreen> createState() =>
      _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStudentsProvider>().loadStudentDetail(widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Student Profile',
      currentRoute: AppRoutes.adminStudents,
      child: Consumer<AdminStudentsProvider>(
        builder: (context, provider, _) {
          if (provider.isDetailLoading) {
            return const SizedBox(
              height: 400,
              child: AdminLoadingState(message: 'Loading student profile...'),
            );
          }
          if (provider.error != null) {
            return SizedBox(
              height: 400,
              child: AdminErrorState(
                message: provider.error!,
                onRetry: () => provider.loadStudentDetail(widget.studentId),
              ),
            );
          }
          final student = provider.selectedStudent;
          if (student == null) {
            return const Center(child: Text('Student not found.'));
          }
          return _StudentDetailContent(student: student, provider: provider);
        },
      ),
    );
  }
}

class _StudentDetailContent extends StatelessWidget {
  const _StudentDetailContent({required this.student, required this.provider});

  final AdminStudentProfile student;
  final AdminStudentsProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        TextButton.icon(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, AppRoutes.adminStudents),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to Students'),
        ),
        const SizedBox(height: 16),

        // Profile header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    student.displayName.isNotEmpty
                        ? student.displayName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E3A8A),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _InfoChip(
                            label: student.course,
                            color: const Color(0xFFEFF6FF),
                          ),
                          const SizedBox(width: 8),
                          if (student.yearLevel != null)
                            _InfoChip(
                              label: 'Year ${student.yearLevel}',
                              color: const Color(0xFFF5F3FF),
                            ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            label: student.isActive ? 'Active' : 'Inactive',
                            color: student.isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            textColor: student.isActive
                                ? const Color(0xFF166534)
                                : const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Toggle active status
                Column(
                  children: [
                    Text(
                      student.isActive ? 'Account Active' : 'Account Inactive',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Switch(
                      value: student.isActive,
                      onChanged: (v) async {
                        final verb = v ? 'activate' : 'suspend';
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(
                              '${v ? 'Activate' : 'Suspend'} account?',
                            ),
                            content: Text(
                              'Are you sure you want to $verb '
                              '${student.displayName}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: Text(v ? 'Activate' : 'Suspend'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await provider.toggleStudentStatus(student.uid, v);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // XP / Level / Streak stats
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 800 ? 4 : 2;
            final stats = [
              (
                'Total XP',
                '${student.totalXp}',
                Icons.bolt_rounded,
                const Color(0xFF1D4ED8),
              ),
              (
                'Level',
                '${student.currentLevel}',
                Icons.trending_up_rounded,
                const Color(0xFF7C3AED),
              ),
              (
                'Streak',
                '${student.streakDays} days',
                Icons.local_fire_department_rounded,
                const Color(0xFFEA580C),
              ),
              (
                'Badges',
                '${student.badgesEarned}',
                Icons.emoji_events_rounded,
                const Color(0xFFD97706),
              ),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3,
              ),
              itemCount: stats.length,
              itemBuilder: (_, i) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(stats[i].$3, color: stats[i].$4, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            stats[i].$2,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            stats[i].$1,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Progress summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _ProgressRow(
                  label: 'Completed Lessons',
                  value: student.completedLessons,
                ),
                _ProgressRow(
                  label: 'Completed Quizzes',
                  value: student.completedQuizzes,
                ),
                _ProgressRow(
                  label: 'Completed Puzzles',
                  value: student.completedPuzzles,
                ),
                _ProgressRow(
                  label: 'Completed Challenges',
                  value: student.completedChallenges,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Account info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Info',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _LabelValue(
                  label: 'Joined',
                  value: student.createdAt != null
                      ? DateFormat('MMMM d, yyyy').format(student.createdAt!)
                      : '—',
                ),
                _LabelValue(
                  label: 'Last Login',
                  value: student.lastLoginAt != null
                      ? DateFormat(
                          'MMM d, yyyy h:mm a',
                        ).format(student.lastLoginAt!)
                      : '—',
                ),
                _LabelValue(
                  label: 'Last Activity',
                  value: student.lastActivityAt != null
                      ? DateFormat(
                          'MMM d, yyyy h:mm a',
                        ).format(student.lastActivityAt!)
                      : '—',
                ),
                _LabelValue(label: 'Role', value: student.role),
                _LabelValue(label: 'UID', value: student.uid),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color, this.textColor});
  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF0E3A8A),
        ),
      ),
    );
  }
}
