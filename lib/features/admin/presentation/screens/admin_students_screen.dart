import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_student_profile.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_students_provider.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _green = Color(0xFF059669);
const _border = Color(0xFFE2E8F0);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminStudentsProvider>().loadStudents();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Users',
      currentRoute: AppRoutes.adminStudents,
      child: Consumer<AdminStudentsProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                total: provider.students.length,
                activeCount: provider.students.where((s) => s.isActive).length,
                onRefresh: () => provider.loadStudents(forceRefresh: true),
              ),
              const SizedBox(height: 16),
              _UserInsights(students: provider.students),
              const SizedBox(height: 16),

              // Search + filter row
              LayoutBuilder(
                builder: (context, constraints) {
                  final search = TextField(
                    controller: _searchCtrl,
                    onChanged: provider.setSearch,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: const TextStyle(fontSize: 13, color: _textSub),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: _textSub,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: _textSub,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                provider.setSearch('');
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _blue, width: 1.5),
                      ),
                    ),
                  );
                  final filters = _FilterChips(
                    value: provider.filterStatus,
                    onChanged: provider.setFilter,
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        search,
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: filters,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      filters,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              if (provider.isLoading && provider.students.isEmpty)
                const _LoadingState()
              else if (provider.error != null && provider.students.isEmpty)
                _ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadStudents,
                )
              else if (provider.students.isEmpty)
                const _EmptyState()
              else ...[
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: _blue,
                      backgroundColor: Color(0xFFE8EEF8),
                    ),
                  ),
                _StudentsTable(students: provider.students, provider: provider),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UserInsights extends StatelessWidget {
  const _UserInsights({required this.students});
  final List<AdminStudentProfile> students;

  @override
  Widget build(BuildContext context) {
    final active = students.where((s) => s.isActive).length;
    final learners = students
        .where((s) => s.normalizedRole == 'student')
        .length;
    final staff = students.where((s) => s.normalizedRole != 'student').length;
    final incomplete = students.where((s) => s.profileWarning != null).length;
    final items = [
      ('Active accounts', '$active', Icons.verified_user_rounded, _green),
      ('Learners', '$learners', Icons.school_rounded, _blue),
      (
        'Admin & faculty',
        '$staff',
        Icons.badge_rounded,
        const Color(0xFF7C3AED),
      ),
      (
        'Needs attention',
        '$incomplete',
        Icons.warning_amber_rounded,
        const Color(0xFFD97706),
      ),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF3F7FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173A67),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 12,
        children: items.map((item) {
          return SizedBox(
            width: 180,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.$4.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(item.$3, color: item.$4, size: 19),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _textMain,
                      ),
                    ),
                    Text(
                      item.$1,
                      style: const TextStyle(fontSize: 11, color: _textSub),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.total,
    required this.activeCount,
    required this.onRefresh,
  });
  final int total;
  final int activeCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_navy, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.people_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User and Role Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '$total account${total == 1 ? '' : 's'}  ·  $activeCount active',
                style: const TextStyle(fontSize: 13, color: _textSub),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER CHIPS
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});
  final String value;
  final void Function(String) onChanged;

  static const _opts = {
    'all': 'All',
    'active': 'Active',
    'inactive': 'Inactive',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _opts.entries.map((e) {
        final selected = value == e.key;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(
              e.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _textSub,
              ),
            ),
            selected: selected,
            selectedColor: _navy,
            backgroundColor: Colors.white,
            side: BorderSide(color: selected ? _navy : _border, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            onSelected: (_) => onChanged(e.key),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _StudentsTable extends StatelessWidget {
  const _StudentsTable({required this.students, required this.provider});
  final List<AdminStudentProfile> students;
  final AdminStudentsProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1240
            ? 1240.0
            : constraints.maxWidth;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D173A67),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF8FAFF), Color(0xFFEFF5FF)],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 36),
                        SizedBox(width: 12),
                        Expanded(flex: 3, child: _H('Name')),
                        Expanded(flex: 4, child: _H('Email')),
                        SizedBox(width: 125, child: _H('Date Added')),
                        SizedBox(width: 120, child: _H('Role')),
                        SizedBox(width: 70, child: _H('Level', center: true)),
                        SizedBox(width: 80, child: _H('XP', center: true)),
                        SizedBox(width: 70, child: _H('Streak', center: true)),
                        SizedBox(width: 70, child: _H('Badges', center: true)),
                        SizedBox(width: 100, child: _H('Status')),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 112,
                          child: _H('Actions', center: true),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: _border),
                  ...students.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    return _StudentRow(
                      student: s,
                      isEven: i.isEven,
                      isLast: i == students.length - 1,
                      onView: () => Navigator.pushNamed(
                        context,
                        AppRoutes.adminStudentDetail,
                        arguments: s.uid,
                      ),
                      onToggle: () async {
                        final action = s.isActive ? 'suspend' : 'activate';
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              '${action[0].toUpperCase()}${action.substring(1)} account?',
                            ),
                            content: Text(
                              'Are you sure you want to $action ${s.displayName}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(action),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await provider.toggleStudentStatus(
                            s.uid,
                            !s.isActive,
                          );
                        }
                      },
                      onRoleChanged: (role) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm role change'),
                            content: Text('Change ${s.displayName} to $role?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Change role'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await provider.changeUserRole(s.uid, role);
                        }
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              color: Color(0xFFDC2626),
                              size: 34,
                            ),
                            title: const Text('Permanently delete account?'),
                            content: Text(
                              'Delete ${s.displayName} (${s.email})?\n\n'
                              'This removes the sign-in account, profile, progress, '
                              'badges, and attempts. This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                icon: const Icon(Icons.delete_forever_rounded),
                                label: const Text('Delete permanently'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        final error = await provider.deleteUser(s.uid);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: error == null
                                ? _green
                                : const Color(0xFFB91C1C),
                            content: Text(
                              error ??
                                  '${s.displayName} was permanently deleted.',
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.text, {this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFF52627A),
        letterSpacing: 0.7,
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.isEven,
    required this.isLast,
    required this.onView,
    required this.onToggle,
    required this.onRoleChanged,
    required this.onDelete,
  });
  final AdminStudentProfile student;
  final bool isEven;
  final bool isLast;
  final VoidCallback onView;
  final VoidCallback onToggle;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initials = student.displayName.isNotEmpty
        ? student.displayName.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return Column(
      children: [
        Container(
          color: isEven ? Colors.white : const Color(0xFFFBFDFF),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onView,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            student.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF17376B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (student.profileWarning case final warning?)
                      Tooltip(
                        message: warning,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 17,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Email
              Expanded(
                flex: 4,
                child: Text(
                  student.email,
                  style: const TextStyle(fontSize: 12, color: _textSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(
                width: 125,
                child: _DateAdded(createdAt: student.createdAt),
              ),

              SizedBox(
                width: 120,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: _roleColor(
                      student.normalizedRole,
                    ).withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: student.normalizedRole,
                    isDense: true,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _roleColor(student.normalizedRole),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'instructor',
                        child: Text('Instructor'),
                      ),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null && value != student.normalizedRole) {
                        onRoleChanged(value);
                      }
                    },
                  ),
                ),
              ),

              // Level
              SizedBox(
                width: 70,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Lv.${student.currentLevel}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                  ),
                ),
              ),

              // XP
              SizedBox(
                width: 80,
                child: Text(
                  '${student.totalXp} XP',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ),

              // Streak
              SizedBox(
                width: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${student.streakDays}d',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),

              // Badges
              SizedBox(
                width: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 13,
                      color: Color(0xFFCA8A04),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${student.badgesEarned}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCA8A04),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge
              SizedBox(
                width: 100,
                child: _ActiveBadge(isActive: student.isActive),
              ),
              const SizedBox(width: 12),

              // Actions
              SizedBox(
                width: 112,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PopupMenuButton<String>(
                    tooltip: 'Account actions',
                    onSelected: (value) {
                      if (value == 'view') onView();
                      if (value == 'toggle') onToggle();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.person_search_rounded),
                          title: Text('View profile'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            student.isActive
                                ? Icons.person_off_rounded
                                : Icons.person_add_alt_1_rounded,
                          ),
                          title: Text(
                            student.isActive ? 'Suspend' : 'Activate',
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.delete_forever_rounded,
                            color: Color(0xFFDC2626),
                          ),
                          title: Text(
                            'Delete account',
                            style: TextStyle(color: Color(0xFFB91C1C)),
                          ),
                          subtitle: Text('Permanent and cannot be undone'),
                        ),
                      ),
                    ],
                    child: Container(
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5FB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD8E3F2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Manage',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF17376B),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.more_horiz_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: _border),
      ],
    );
  }

  Color _roleColor(String role) => switch (role) {
    'admin' => const Color(0xFF7C3AED),
    'instructor' => const Color(0xFF0369A1),
    _ => const Color(0xFF166534),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DateAdded extends StatelessWidget {
  const _DateAdded({required this.createdAt});
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final date = createdAt?.toLocal();
    if (date == null) {
      return const Tooltip(
        message: 'Creation date was not recorded for this legacy account.',
        child: Text(
          'Not recorded',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }
    return Tooltip(
      message: DateFormat('MMMM d, yyyy - h:mm a').format(date),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 13,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('MMM d, yyyy').format(date),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF52627A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _navy, strokeWidth: 2.5),
          SizedBox(height: 12),
          Text(
            'Loading students…',
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 30,
              color: _navy,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No students found.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Students who register on the app will appear here.',
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
        ],
      ),
    );
  }
}
