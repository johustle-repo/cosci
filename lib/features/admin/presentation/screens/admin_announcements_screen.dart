import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_announcement.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_announcements_provider.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminAnnouncementsProvider>().loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Announcements',
      currentRoute: AppRoutes.adminAnnouncements,
      child: Consumer<AdminAnnouncementsProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                title: 'Announcement Management',
                actionLabel: 'New Announcement',
                actionIcon: Icons.add_rounded,
                onAction: () => _showForm(context, provider),
              ),
              const SizedBox(height: 16),
              _AnnouncementOverview(provider: provider),
              const SizedBox(height: 20),
              if (provider.isLoading)
                const SizedBox(
                  height: 300,
                  child: AdminLoadingState(message: 'Loading announcements...'),
                )
              else if (provider.error != null && provider.announcements.isEmpty)
                SizedBox(
                  height: 300,
                  child: AdminErrorState(
                    message: provider.error!,
                    onRetry: provider.loadAnnouncements,
                  ),
                )
              else if (provider.announcements.isEmpty)
                AdminEmptyState(
                  message: 'No announcements yet.',
                  icon: Icons.campaign_rounded,
                  actionLabel: 'New Announcement',
                  onAction: () => _showForm(context, provider),
                )
              else
                _AnnouncementsTable(provider: provider),
            ],
          );
        },
      ),
    );
  }

  void _showForm(
    BuildContext ctx,
    AdminAnnouncementsProvider provider, [
    AdminAnnouncement? existing,
  ]) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _AnnouncementFormDialog(existing: existing),
      ),
    );
  }
}

class _AnnouncementOverview extends StatelessWidget {
  const _AnnouncementOverview({required this.provider});
  final AdminAnnouncementsProvider provider;

  @override
  Widget build(BuildContext context) {
    final published = provider.announcements
        .where((item) => item.isPublished)
        .length;
    final drafts = provider.announcements.length - published;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF102E67),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final message = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep your learning community informed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Create targeted updates for learners, instructors, or everyone.',
                style: TextStyle(color: Color(0xFFD7E5FF)),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _OverviewCount(value: '$published', label: 'Published'),
              _OverviewCount(value: '$drafts', label: 'Drafts'),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF123E91),
                ),
                onPressed: provider.isSaving
                    ? null
                    : provider.installCommonAnnouncements,
                icon: const Icon(Icons.library_add_rounded, size: 18),
                label: const Text('Add common templates'),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [message, const SizedBox(height: 18), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: message),
              const SizedBox(width: 24),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _OverviewCount extends StatelessWidget {
  const _OverviewCount({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFD7E5FF), fontSize: 10),
        ),
      ],
    ),
  );
}

class _AnnouncementsTable extends StatelessWidget {
  const _AnnouncementsTable({required this.provider});
  final AdminAnnouncementsProvider provider;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1280
          ? 3
          : constraints.maxWidth >= 760
          ? 2
          : 1;
      const gap = 16.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: provider.announcements
            .map(
              (announcement) => SizedBox(
                width: width,
                child: _AnnouncementCard(
                  announcement: announcement,
                  provider: provider,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.provider});
  final AdminAnnouncement announcement;
  final AdminAnnouncementsProvider provider;

  @override
  Widget build(BuildContext context) {
    final published = announcement.isPublished;
    final audience = switch (announcement.targetAudience) {
      'students' => 'Learners',
      'professors' => 'Instructors',
      _ => 'Everyone',
    };
    final audienceIcon = switch (announcement.targetAudience) {
      'students' => Icons.school_rounded,
      'professors' => Icons.co_present_rounded,
      _ => Icons.groups_rounded,
    };
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFF1D5CC6),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: published
                      ? const Color(0xFFE6F8EF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  published ? 'Published' : 'Draft',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: published
                        ? const Color(0xFF087A55)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Announcement actions',
                onSelected: (value) => _handleAction(context, value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'publish',
                    child: Text(published ? 'Move to drafts' : 'Publish'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            announcement.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF13213A),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              announcement.message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.45),
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(audienceIcon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 7),
              Text(
                audience,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(announcement.updatedAt ?? announcement.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    if (action == 'publish') {
      await provider.togglePublished(
        announcement.id,
        !announcement.isPublished,
      );
      return;
    }
    if (action == 'edit') {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: _AnnouncementFormDialog(existing: announcement),
        ),
      );
      return;
    }
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Delete Announcement',
      message: 'Delete "${announcement.title}"?',
    );
    if (confirmed && context.mounted) {
      await provider.deleteAnnouncement(announcement.id, announcement.title);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently added';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _AnnouncementFormDialog extends StatefulWidget {
  const _AnnouncementFormDialog({this.existing});
  final AdminAnnouncement? existing;

  @override
  State<_AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<_AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _msgCtrl;
  String _audience = 'all';
  bool _isPublished = false;
  static const _audiences = ['all', 'students', 'professors'];
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _msgCtrl = TextEditingController(text: e?.message ?? '');
    _audience = e?.targetAudience ?? 'all';
    _isPublished = e?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminAnnouncementsProvider>();
    final a = AdminAnnouncement(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      message: _msgCtrl.text.trim(),
      targetAudience: _audience,
      isPublished: _isPublished,
    );
    final ok = _isEdit
        ? await provider.updateAnnouncement(a)
        : await provider.createAnnouncement(a);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAnnouncementsProvider>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEdit ? 'Edit Announcement' : 'New Announcement'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
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
                controller: _msgCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(labelText: 'Target Audience'),
                borderRadius: BorderRadius.circular(12),
                items: _audiences
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _audience = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish Immediately'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
              ),
            ],
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
              : Text(_isEdit ? 'Save Changes' : 'Publish'),
        ),
      ],
    );
  }
}
