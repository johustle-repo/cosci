import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_activity_log.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_logs_provider.dart';

class AdminActivityLogsScreen extends StatefulWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  State<AdminActivityLogsScreen> createState() =>
      _AdminActivityLogsScreenState();
}

class _AdminActivityLogsScreenState extends State<AdminActivityLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminLogsProvider>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Activity Logs',
      currentRoute: AppRoutes.adminActivityLogs,
      child: Consumer<AdminLogsProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LogsHeader(provider: provider),
              const SizedBox(height: 20),
              if (provider.isLoading)
                const SizedBox(
                  height: 300,
                  child: AdminLoadingState(message: 'Loading activity logs...'),
                )
              else if (provider.error != null && provider.logs.isEmpty)
                SizedBox(
                  height: 300,
                  child: AdminErrorState(
                    message: provider.error!,
                    onRetry: provider.loadLogs,
                  ),
                )
              else if (provider.logs.isEmpty)
                const AdminEmptyState(
                  message: 'No activity logs found.',
                  icon: Icons.history_rounded,
                )
              else
                _LogsTable(logs: provider.logs),
            ],
          );
        },
      ),
    );
  }
}

class _LogsHeader extends StatelessWidget {
  const _LogsHeader({required this.provider});
  final AdminLogsProvider provider;

  static const _moduleOptions = [
    'all',
    'lessons',
    'simulations',
    'quizzes',
    'puzzles',
    'badges',
    'gamification_rules',
    'daily_challenges',
    'announcements',
    'settings',
    'students',
  ];

  static const _actionOptions = [
    'all',
    'create',
    'update',
    'delete',
    'publish',
    'unpublish',
    'login',
    'logout',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Admin Activity Logs',
          actionLabel: 'Refresh',
          actionIcon: Icons.refresh_rounded,
          onAction: provider.loadLogs,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  labelText: 'Search activity',
                  hintText: 'Admin, action, module, or description',
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: provider.filterModule,
                decoration: InputDecoration(
                  labelText: 'Module',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                items: _moduleOptions
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(_label(m))),
                    )
                    .toList(),
                onChanged: (v) => provider.setModuleFilter(v!),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: provider.filterAction,
                decoration: InputDecoration(
                  labelText: 'Action',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                items: _actionOptions
                    .map(
                      (a) => DropdownMenuItem(value: a, child: Text(_label(a))),
                    )
                    .toList(),
                onChanged: (v) => provider.setActionFilter(v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _label(String value) => value
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _LogsTable extends StatelessWidget {
  const _LogsTable({required this.logs});
  final List<AdminActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1120,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FBFF)),
        columns: const [
          DataColumn(label: Text('Timestamp')),
          DataColumn(label: Text('Admin')),
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('Module')),
          DataColumn(label: Text('Description')),
        ],
        rows: logs.map((log) {
          final ts = log.timestamp;
          final formatted = ts != null
              ? DateFormat('MMM d, yyyy HH:mm').format(ts)
              : '—';
          return DataRow(
            cells: [
              DataCell(
                Text(
                  formatted,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      log.adminEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(_ActionBadge(action: log.actionType)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.targetModule,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    log.description,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});
  final String action;

  static const _colors = {
    'create': (Color(0xFFDCFCE7), Color(0xFF166534)),
    'update': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    'delete': (Color(0xFFFEE2E2), Color(0xFFDC2626)),
    'publish': (Color(0xFFDCFCE7), Color(0xFF059669)),
    'unpublish': (Color(0xFFFEF3C7), Color(0xFF92400E)),
    'login': (Color(0xFFF3E8FF), Color(0xFF7C3AED)),
    'logout': (Color(0xFFF1F5F9), Color(0xFF475569)),
  };

  @override
  Widget build(BuildContext context) {
    final colors =
        _colors[action] ?? (const Color(0xFFF1F5F9), const Color(0xFF475569));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        action,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }
}
