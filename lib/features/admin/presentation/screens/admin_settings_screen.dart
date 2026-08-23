import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_settings_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Settings',
      currentRoute: AppRoutes.adminSettings,
      child: Consumer<AdminSettingsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const SizedBox(
              height: 400,
              child: AdminLoadingState(message: 'Loading settings...'),
            );
          }
          if (provider.error != null) {
            return SizedBox(
              height: 400,
              child: AdminErrorState(
                message: provider.error!,
                onRetry: provider.loadSettings,
              ),
            );
          }
          return _SettingsContent(provider: provider);
        },
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({required this.provider});
  final AdminSettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Settings & Configuration',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.loadSettings(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SettingsOverview(provider: provider),
        const SizedBox(height: 28),

        // Topics Management
        AdminSectionHeader(title: 'Course Topics'),
        const SizedBox(height: 16),
        _TopicsCard(provider: provider),
        const SizedBox(height: 32),

        // Module Visibility
        AdminSectionHeader(title: 'Module Visibility'),
        const SizedBox(height: 16),
        _ModuleVisibilityCard(provider: provider),
        const SizedBox(height: 32),

        // Admin Roles
        AdminSectionHeader(title: 'Admin Roles'),
        const SizedBox(height: 16),
        _AdminRolesCard(provider: provider),
        const SizedBox(height: 32),

        const AdminSectionHeader(title: 'Backup & Restore'),
        const SizedBox(height: 16),
        _BackupRestoreCard(provider: provider),
        const SizedBox(height: 32),

        const AdminSectionHeader(title: 'System Maintenance'),
        const SizedBox(height: 16),
        _MaintenanceCard(provider: provider),
      ],
    );
  }
}

class _SettingsOverview extends StatelessWidget {
  const _SettingsOverview({required this.provider});
  final AdminSettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final visibility = provider.settings.moduleVisibility;
    final visible = visibility.values.where((value) => value).length;
    final total = visibility.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF102E67),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final heading = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform configuration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Manage learning categories, learner access, and administrative permissions.',
                style: TextStyle(color: Color(0xFFD7E5FF), height: 1.4),
              ),
            ],
          );
          final metrics = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SettingsMetric(
                value: '${provider.settings.topics.length}',
                label: 'Course topics',
                icon: Icons.topic_rounded,
              ),
              _SettingsMetric(
                value: '$visible/$total',
                label: 'Modules visible',
                icon: Icons.visibility_rounded,
              ),
              _SettingsMetric(
                value: '${provider.settings.adminRoles.length}',
                label: 'Admin roles',
                icon: Icons.admin_panel_settings_rounded,
              ),
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [heading, const SizedBox(height: 18), metrics],
                )
              : Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 24),
                    metrics,
                  ],
                );
        },
      ),
    );
  }
}

class _SettingsMetric extends StatelessWidget {
  const _SettingsMetric({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 132,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: .15)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD45A), size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFFD7E5FF), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TopicsCard extends StatefulWidget {
  const _TopicsCard({required this.provider});
  final AdminSettingsProvider provider;

  @override
  State<_TopicsCard> createState() => _TopicsCardState();
}

class _TopicsCardState extends State<_TopicsCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.provider.settings.topics;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Manage the reusable topics used to organize lessons, simulations, quizzes, and puzzles.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: widget.provider.isSaving ? null : _restoreTopics,
                  icon: const Icon(Icons.restore_rounded, size: 17),
                  label: const Text('Restore defaults'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final field = TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Add a topic, for example Recursion',
                    prefixIcon: const Icon(Icons.topic_outlined),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _addTopic(),
                );
                final button = FilledButton.icon(
                  onPressed: widget.provider.isSaving ? null : _addTopic,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add topic'),
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [field, const SizedBox(height: 10), button],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 12),
                    button,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (topics.isEmpty)
              const Text(
                'No topics defined.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topics.map((topic) {
                  return Chip(
                    label: Text(topic, style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: widget.provider.isSaving
                        ? null
                        : () => _removeTopic(topic),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    labelStyle: const TextStyle(color: Color(0xFF1D4ED8)),
                    deleteIconColor: const Color(0xFF1D4ED8),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTopic() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final added = await widget.provider.addTopic(text);
    if (!mounted) return;
    if (added) {
      _ctrl.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Topic "$text" added.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$text" is already in the topic list.')),
      );
    }
  }

  void _removeTopic(String topic) {
    widget.provider.removeTopic(topic);
  }

  Future<void> _restoreTopics() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore default topics?'),
        content: const Text(
          'This will replace the current topic list with the recommended programming topics. Existing learning content will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore defaults'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.provider.restoreDefaultTopics();
    }
  }
}

class _ModuleVisibilityCard extends StatelessWidget {
  const _ModuleVisibilityCard({required this.provider});
  final AdminSettingsProvider provider;

  static const _moduleLabels = {
    'lessons': 'Lessons',
    'simulations': 'Code Simulations',
    'quizzes': 'Quizzes',
    'puzzles': 'Puzzles',
    'daily_challenges': 'Daily Challenges',
    'announcements': 'Announcements',
  };
  static const _moduleDescriptions = {
    'lessons': 'Structured learning content and examples',
    'simulations': 'Compiler-backed coding practice',
    'quizzes': 'Multiple-choice knowledge checks',
    'puzzles': 'Drag-and-arrange syntax activities',
    'daily_challenges': 'Scheduled daily learning tasks',
    'announcements': 'Updates shown to learners',
  };
  static const _moduleIcons = {
    'lessons': Icons.menu_book_rounded,
    'simulations': Icons.terminal_rounded,
    'quizzes': Icons.quiz_rounded,
    'puzzles': Icons.extension_rounded,
    'daily_challenges': Icons.calendar_today_rounded,
    'announcements': Icons.campaign_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final visibility = provider.settings.moduleVisibility;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Control which modules are visible to students in the app.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _confirmAll(context, true),
                  icon: const Icon(Icons.visibility_rounded, size: 17),
                  label: const Text('Show all modules'),
                ),
                OutlinedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _confirmAll(context, false),
                  icon: const Icon(Icons.visibility_off_rounded, size: 17),
                  label: const Text('Hide all modules'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 650
                    ? 2
                    : 1;
                const gap = 12.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: _moduleLabels.entries.map((entry) {
                    final isVisible = visibility[entry.key] ?? true;
                    return SizedBox(
                      width: width,
                      child: _ModuleVisibilityTile(
                        title: entry.value,
                        description: _moduleDescriptions[entry.key]!,
                        icon: _moduleIcons[entry.key]!,
                        isVisible: isVisible,
                        enabled: !provider.isSaving,
                        onChanged: (value) => _confirmChange(
                          context,
                          entry.key,
                          entry.value,
                          value,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmChange(
    BuildContext context,
    String key,
    String label,
    bool visible,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${visible ? 'Show' : 'Hide'} $label?'),
        content: Text(
          visible
              ? 'This module will become available in the learner workspace.'
              : 'Learners will no longer be able to open this module. Existing progress will remain saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(visible ? 'Show module' : 'Hide module'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.toggleModuleVisibility(key, visible);
    }
  }

  Future<void> _confirmAll(BuildContext context, bool visible) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(visible ? 'Show all modules?' : 'Hide all modules?'),
        content: Text(
          visible
              ? 'Every learning module will become available in the learner workspace.'
              : 'All learning modules will be hidden. Learner progress and content will remain saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(visible ? 'Show all' : 'Hide all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.setAllModuleVisibility(_moduleLabels.keys, visible);
    }
  }
}

class _ModuleVisibilityTile extends StatelessWidget {
  const _ModuleVisibilityTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.isVisible,
    required this.enabled,
    required this.onChanged,
  });
  final String title;
  final String description;
  final IconData icon;
  final bool isVisible;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE1E8F2)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isVisible
                ? const Color(0xFFE7F6F1)
                : const Color(0xFFEDF1F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isVisible
                ? const Color(0xFF078362)
                : const Color(0xFF7A879A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(value: isVisible, onChanged: enabled ? onChanged : null),
      ],
    ),
  );
}

class _AdminRolesCard extends StatelessWidget {
  const _AdminRolesCard({required this.provider});
  final AdminSettingsProvider provider;

  static const _roleDescriptions = {
    'admin': 'Full access to all admin features',
    'super_admin': 'Full access + user role management',
    'content_manager': 'Manage lessons, quizzes, puzzles, and challenges',
  };

  @override
  Widget build(BuildContext context) {
    final roles = provider.settings.adminRoles;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Review administrative access levels. Assign or update a user\'s role through User Management.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.adminStudents),
                  icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                  label: const Text('Manage users'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...roles.map((role) {
              final desc = _roleDescriptions[role] ?? 'Admin role';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 20,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                title: Text(
                  role,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                subtitle: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BackupRestoreCard extends StatelessWidget {
  const _BackupRestoreCard({required this.provider});
  final AdminSettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final latest = provider.backups.isEmpty ? null : provider.backups.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2EF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final information = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SettingIcon(
                icon: Icons.cloud_done_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration snapshots',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Store course topics, module visibility, roles, and maintenance settings in a recoverable snapshot.',
                      style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latest == null
                          ? 'No configuration backups created yet.'
                          : 'Latest backup: ${_backupDate(latest['createdAt'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: provider.isSaving
                    ? null
                    : () => _createBackup(context),
                icon: const Icon(Icons.backup_rounded, size: 18),
                label: const Text('Store backup'),
              ),
              OutlinedButton.icon(
                onPressed: provider.isSaving || latest == null
                    ? null
                    : () => _restoreBackup(context, latest['id'].toString()),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Restore latest'),
              ),
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [information, const SizedBox(height: 18), actions],
                )
              : Row(
                  children: [
                    Expanded(child: information),
                    const SizedBox(width: 24),
                    actions,
                  ],
                );
        },
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    final ok = await provider.createConfigurationBackup();
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration backup stored.')),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore latest backup?'),
        content: const Text(
          'Current configuration values will be replaced. Learning content, accounts, and learner progress are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore backup'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await provider.restoreConfigurationBackup(id);
    if (ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration restored successfully.')),
      );
    }
  }

  static String _backupDate(dynamic value) {
    final date = value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    if (date == null) return 'Just now';
    return '${date.month}/${date.day}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MaintenanceCard extends StatefulWidget {
  const _MaintenanceCard({required this.provider});
  final AdminSettingsProvider provider;

  @override
  State<_MaintenanceCard> createState() => _MaintenanceCardState();
}

class _MaintenanceCardState extends State<_MaintenanceCard> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.provider.settings.maintenanceMessage,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.provider.settings.maintenanceMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFFF3B8B8) : const Color(0xFFD8E2EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SettingIcon(
                icon: Icons.engineering_rounded,
                color: active
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFD97706),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learner workspace maintenance',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Temporarily pause learner access while administrators perform updates.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: widget.provider.isSaving ? null : _toggleMaintenance,
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _messageController,
            minLines: 2,
            maxLines: 3,
            maxLength: 240,
            decoration: const InputDecoration(
              labelText: 'Learner maintenance message',
              helperText: 'Shown to learners while maintenance mode is active.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.provider.isSaving ? null : _saveMessage,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save maintenance message'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMaintenance(bool enabled) async {
    if (enabled && _messageController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a clear maintenance message first.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          enabled ? 'Enable maintenance mode?' : 'Resume learner access?',
        ),
        content: Text(
          enabled
              ? 'Learners will be prevented from opening their workspace. Administrators will retain access.'
              : 'Learners will immediately regain access to their workspace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(enabled ? 'Enable maintenance' : 'Resume access'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.provider.updateMaintenanceMode(
        enabled: enabled,
        message: _messageController.text,
      );
    }
  }

  Future<void> _saveMessage() async {
    final message = _messageController.text.trim();
    if (message.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The maintenance message is too short.')),
      );
      return;
    }
    final ok = await widget.provider.updateMaintenanceMode(
      enabled: widget.provider.settings.maintenanceMode,
      message: message,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance message saved.')),
      );
    }
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, color: color, size: 22),
  );
}
