import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_daily_challenge.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_publish_chip.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_challenges_provider.dart';

class AdminChallengesScreen extends StatefulWidget {
  const AdminChallengesScreen({super.key});

  @override
  State<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends State<AdminChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminChallengesProvider>().loadChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Daily Challenges',
      currentRoute: AppRoutes.adminChallenges,
      child: Consumer<AdminChallengesProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                title: 'Daily Challenge Management',
                actionLabel: 'New Challenge',
                actionIcon: Icons.add_rounded,
                onAction: () => _showForm(context, provider),
              ),
              const SizedBox(height: 14),
              _ChallengeStarterBanner(
                challengeCount: provider.challenges.length,
                activeCount: provider.challenges
                    .where((challenge) => challenge.isActive)
                    .length,
                scheduledCount: provider.challenges
                    .where((challenge) => challenge.status == 'scheduled')
                    .length,
                isSaving: provider.isSaving,
                onInstall: () => _installStarterPack(context, provider),
              ),
              const SizedBox(height: 18),
              if (provider.isLoading)
                const SizedBox(
                  height: 300,
                  child: AdminLoadingState(message: 'Loading challenges...'),
                )
              else if (provider.error != null && provider.challenges.isEmpty)
                SizedBox(
                  height: 300,
                  child: AdminErrorState(
                    message: provider.error!,
                    onRetry: provider.loadChallenges,
                  ),
                )
              else if (provider.challenges.isEmpty)
                AdminEmptyState(
                  message: 'No daily challenges yet.',
                  icon: Icons.today_rounded,
                  actionLabel: 'New Challenge',
                  onAction: () => _showForm(context, provider),
                )
              else
                _ChallengeBoard(
                  provider: provider,
                  onEdit: (challenge) =>
                      _showForm(context, provider, challenge),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _installStarterPack(
    BuildContext context,
    AdminChallengesProvider provider,
  ) async {
    final count = await provider.installStarterChallenges();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? '$count ready-to-use daily challenges installed.'
              : provider.error ?? 'Could not install the starter plan.',
        ),
      ),
    );
  }

  void _showForm(
    BuildContext ctx,
    AdminChallengesProvider provider, [
    AdminDailyChallenge? existing,
  ]) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _ChallengeFormDialog(existing: existing),
      ),
    );
  }
}

class _ChallengeStarterBanner extends StatelessWidget {
  const _ChallengeStarterBanner({
    required this.challengeCount,
    required this.activeCount,
    required this.scheduledCount,
    required this.isSaving,
    required this.onInstall,
  });
  final int challengeCount;
  final int activeCount;
  final int scheduledCount;
  final bool isSaving;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF102A63), Color(0xFF1747AA), Color(0xFF0F9F9A)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24123D9B),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Wrap(
      spacing: 18,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFFFFD65A),
            size: 31,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 680),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep learners moving every day',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Create a balanced challenge calendar from published lessons, simulations, quizzes, and puzzles.',
                style: TextStyle(color: Color(0xFFDCE8FF), height: 1.4),
              ),
            ],
          ),
        ),
        _ChallengeMetric(value: '$challengeCount', label: 'Total'),
        _ChallengeMetric(value: '$activeCount', label: 'Active'),
        _ChallengeMetric(value: '$scheduledCount', label: 'Scheduled'),
        FilledButton.icon(
          onPressed: isSaving ? null : onInstall,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFD65A),
            foregroundColor: const Color(0xFF102A63),
          ),
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(
            challengeCount == 0
                ? 'Install 7-day starter plan'
                : 'Refresh starter plan',
          ),
        ),
      ],
    ),
  );
}

class _ChallengeMetric extends StatelessWidget {
  const _ChallengeMetric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFDCE8FF), fontSize: 10),
        ),
      ],
    ),
  );
}

class _ChallengeBoard extends StatelessWidget {
  const _ChallengeBoard({required this.provider, required this.onEdit});
  final AdminChallengesProvider provider;
  final ValueChanged<AdminDailyChallenge> onEdit;

  @override
  Widget build(BuildContext context) {
    final challenges = [...provider.challenges]
      ..sort((a, b) => a.date.compareTo(b.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.view_week_rounded,
                color: Color(0xFF1747AA),
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Challenge schedule',
                    style: TextStyle(
                      color: Color(0xFF10213D),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'A learner-friendly view of the upcoming challenge journey',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${challenges.length} days',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1400
                ? 4
                : constraints.maxWidth >= 980
                ? 3
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: challenges.asMap().entries.map((entry) {
                return SizedBox(
                  width: width,
                  child: _ChallengeScheduleCard(
                    dayNumber: entry.key + 1,
                    challenge: entry.value,
                    provider: provider,
                    onEdit: () => onEdit(entry.value),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ChallengeScheduleCard extends StatelessWidget {
  const _ChallengeScheduleCard({
    required this.dayNumber,
    required this.challenge,
    required this.provider,
    required this.onEdit,
  });
  final int dayNumber;
  final AdminDailyChallenge challenge;
  final AdminChallengesProvider provider;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final style = _challengeStyle(challenge.challengeType);
    return Container(
      height: 274,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.$2.withValues(alpha: .22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D173A67),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -48,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.$2.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(height: 4, color: style.$2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [style.$2.withValues(alpha: .72), style.$2],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(style.$1, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAY $dayNumber',
                          style: TextStyle(
                            color: style.$2,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        Text(
                          challenge.date.isEmpty
                              ? 'Unscheduled'
                              : challenge.date,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      tooltip: 'Manage challenge',
                      color: Colors.white,
                      onSelected: (value) => _handleAction(context, value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'active',
                          child: Text('Set active'),
                        ),
                        PopupMenuItem(
                          value: 'scheduled',
                          child: Text('Set scheduled'),
                        ),
                        PopupMenuItem(
                          value: 'inactive',
                          child: Text('Set inactive'),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit challenge'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete challenge'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  challenge.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF10213D),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  challenge.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _ChallengeTypeChip(type: challenge.challengeType),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+${challenge.xpReward} XP',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: challenge.isActive
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFEFF4FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    challenge.status.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: challenge.isActive
                          ? const Color(0xFF15803D)
                          : const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    if (value == 'edit') {
      onEdit();
      return;
    }
    if (value == 'delete') {
      final confirmed = await showAdminConfirmDialog(
        context,
        title: 'Delete Challenge',
        message: 'Delete "${challenge.title}"?',
      );
      if (confirmed && context.mounted) {
        await provider.deleteChallenge(challenge.id, challenge.title);
      }
      return;
    }
    await provider.toggleStatus(challenge.id, value);
  }
}

(IconData, Color) _challengeStyle(String type) => switch (type) {
  'lesson' => (Icons.menu_book_rounded, const Color(0xFF7C3AED)),
  'simulation' => (Icons.terminal_rounded, const Color(0xFF0284C7)),
  'quiz' => (Icons.quiz_rounded, const Color(0xFFEA580C)),
  _ => (Icons.extension_rounded, const Color(0xFFDB2777)),
};

// Retained as a compact fallback for future data-export views.
// ignore: unused_element
class _ChallengesTable extends StatelessWidget {
  const _ChallengesTable({required this.provider});
  final AdminChallengesProvider provider;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1040,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FBFF)),
        columns: const [
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('XP')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: provider.challenges.map((c) {
          return DataRow(
            cells: [
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(_ChallengeTypeChip(type: c.challengeType)),
              DataCell(
                Text(
                  c.date.isEmpty ? '—' : c.date,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${c.xpReward} XP',
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              DataCell(AdminStatusChip(status: c.status)),
              DataCell(
                Row(
                  children: [
                    PopupMenuButton<String>(
                      tooltip: 'Set Status',
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onSelected: (v) => provider.toggleStatus(c.id, v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'active',
                          child: Text('Set Active'),
                        ),
                        PopupMenuItem(
                          value: 'inactive',
                          child: Text('Set Inactive'),
                        ),
                        PopupMenuItem(
                          value: 'scheduled',
                          child: Text('Set Scheduled'),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Color(0xFF1D4ED8),
                      ),
                      onPressed: () {
                        final ctx = context;
                        showDialog<void>(
                          context: ctx,
                          barrierDismissible: false,
                          builder: (_) => ChangeNotifierProvider.value(
                            value: provider,
                            child: _ChallengeFormDialog(existing: c),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                      onPressed: () async {
                        final confirmed = await showAdminConfirmDialog(
                          context,
                          title: 'Delete Challenge',
                          message: 'Delete "${c.title}"?',
                        );
                        if (confirmed && context.mounted) {
                          await provider.deleteChallenge(c.id, c.title);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ChallengeTypeChip extends StatelessWidget {
  const _ChallengeTypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final style = switch (type) {
      'lesson' => (Icons.menu_book_rounded, const Color(0xFF7C3AED)),
      'simulation' => (Icons.terminal_rounded, const Color(0xFF0284C7)),
      'quiz' => (Icons.quiz_rounded, const Color(0xFFEA580C)),
      _ => (Icons.extension_rounded, const Color(0xFFDB2777)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.$2.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.$1, color: style.$2, size: 15),
          const SizedBox(width: 6),
          Text(
            '${type[0].toUpperCase()}${type.substring(1)}',
            style: TextStyle(
              color: style.$2,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeFormDialog extends StatefulWidget {
  const _ChallengeFormDialog({this.existing});
  final AdminDailyChallenge? existing;

  @override
  State<_ChallengeFormDialog> createState() => _ChallengeFormDialogState();
}

class _ChallengeFormDialogState extends State<_ChallengeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _linkedCtrl;
  String _type = 'puzzle';
  String _status = 'inactive';
  static const _types = ['puzzle', 'quiz', 'lesson', 'simulation'];
  static const _statuses = ['active', 'inactive', 'scheduled'];
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _xpCtrl = TextEditingController(text: '${e?.xpReward ?? 50}');
    _dateCtrl = TextEditingController(text: e?.date ?? '');
    _linkedCtrl = TextEditingController(text: e?.linkedContentId ?? '');
    _type = e?.challengeType ?? 'puzzle';
    _status = e?.status ?? 'inactive';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _xpCtrl.dispose();
    _dateCtrl.dispose();
    _linkedCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminChallengesProvider>();
    final c = AdminDailyChallenge(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      challengeType: _type,
      xpReward: int.tryParse(_xpCtrl.text) ?? 50,
      status: _status,
      date: _dateCtrl.text.trim(),
      linkedContentId: _linkedCtrl.text.trim().isEmpty
          ? null
          : _linkedCtrl.text.trim(),
    );
    final ok = _isEdit
        ? await provider.updateChallenge(c)
        : await provider.createChallenge(c);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminChallengesProvider>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEdit ? 'Edit Challenge' : 'New Challenge'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Challenge Type',
                        ),
                        borderRadius: BorderRadius.circular(12),
                        items: _types
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        borderRadius: BorderRadius.circular(12),
                        items: _statuses
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _xpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'XP Reward',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Date (YYYY-MM-DD)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Linked Content ID (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: provider.isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: provider.isSaving ? null : _submit,
          child: provider.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
