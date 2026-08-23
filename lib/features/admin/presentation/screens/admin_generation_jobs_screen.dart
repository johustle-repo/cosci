import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/admin/models/admin_content_generation_job.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_generation_provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';

/// Read-only view of all content generation jobs across all syllabi.
/// Can optionally be scoped to a specific syllabus when [syllabusId] is given.
class AdminGenerationJobsScreen extends StatefulWidget {
  const AdminGenerationJobsScreen({super.key, this.syllabusId});

  /// When non-null, only shows jobs for this syllabus.
  final String? syllabusId;

  @override
  State<AdminGenerationJobsScreen> createState() =>
      _AdminGenerationJobsScreenState();
}

class _AdminGenerationJobsScreenState extends State<AdminGenerationJobsScreen> {
  String _filterType = 'all'; // all | lesson | quiz | puzzle | simulation
  String _filterStatus = 'all'; // all | running | completed | partial | failed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminGenerationProvider>().loadJobs(
        syllabusId: widget.syllabusId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Generation Jobs',
      currentRoute: AppRoutes.adminGenerationJobs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (widget.syllabusId != null) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
              ],
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generation Jobs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0E3A8A),
                      ),
                    ),
                    Text(
                      'Track AI content generation runs and their results.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () => context
                    .read<AdminGenerationProvider>()
                    .loadJobs(syllabusId: widget.syllabusId),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters
          _FilterRow(
            filterType: _filterType,
            filterStatus: _filterStatus,
            onTypeChanged: (v) => setState(() => _filterType = v),
            onStatusChanged: (v) => setState(() => _filterStatus = v),
          ),
          const SizedBox(height: 16),

          // Table — no Expanded; AdminShell already scrolls the content area
          Consumer<AdminGenerationProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingJobs) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (provider.error != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Error: ${provider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final jobs = _applyFilters(provider.jobs);
              if (jobs.isEmpty) {
                return const _EmptyJobs();
              }

              return _JobsTable(jobs: jobs);
            },
          ),
        ],
      ),
    );
  }

  List<AdminContentGenerationJob> _applyFilters(
    List<AdminContentGenerationJob> jobs,
  ) {
    return jobs.where((j) {
      final typeMatch = _filterType == 'all' || j.contentType == _filterType;
      final statusMatch = _filterStatus == 'all' || j.status == _filterStatus;
      return typeMatch && statusMatch;
    }).toList()..sort((a, b) {
      final ta = a.startedAt ?? a.createdAt ?? DateTime(0);
      final tb = b.startedAt ?? b.createdAt ?? DateTime(0);
      return tb.compareTo(ta); // newest first
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Row
// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filterType,
    required this.filterStatus,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  final String filterType;
  final String filterStatus;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipGroup(
          label: 'Type:',
          value: filterType,
          options: const {
            'all': 'All',
            'lesson': 'Lessons',
            'quiz': 'Quizzes',
            'puzzle': 'Puzzles',
            'simulation': 'Simulations',
          },
          onChanged: onTypeChanged,
        ),
        const SizedBox(width: 24),
        _FilterChipGroup(
          label: 'Status:',
          value: filterStatus,
          options: const {
            'all': 'All',
            'running': 'Running',
            'completed': 'Completed',
            'partial': 'Partial',
            'failed': 'Failed',
          },
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}

class _FilterChipGroup extends StatelessWidget {
  const _FilterChipGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 8),
        Wrap(
          spacing: 6,
          children: options.entries
              .map(
                (e) => ChoiceChip(
                  label: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 12,
                      color: value == e.key ? Colors.white : Colors.black87,
                      fontWeight: value == e.key
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  selected: value == e.key,
                  selectedColor: const Color(0xFF1D4ED8),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  onSelected: (_) => onChanged(e.key),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Jobs Table
// ─────────────────────────────────────────────────────────────────────────────

class _JobsTable extends StatelessWidget {
  const _JobsTable({required this.jobs});

  final List<AdminContentGenerationJob> jobs;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1160,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Syllabus', style: _headerStyle)),
          DataColumn(label: Text('Type', style: _headerStyle)),
          DataColumn(label: Text('Status', style: _headerStyle)),
          DataColumn(
            label: Text('Generated', style: _headerStyle),
            numeric: true,
          ),
          DataColumn(label: Text('Failed', style: _headerStyle), numeric: true),
          DataColumn(label: Text('Started', style: _headerStyle)),
          DataColumn(label: Text('Completed', style: _headerStyle)),
          DataColumn(label: Text('Details', style: _headerStyle)),
        ],
        rows: jobs
            .map(
              (job) => DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        job.syllabusTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(_TypeBadge(type: job.contentType)),
                  DataCell(_StatusBadge(status: job.status)),
                  DataCell(
                    Text(
                      '${job.generatedCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: job.generatedCount > 0
                            ? const Color(0xFF059669)
                            : Colors.black45,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${job.failedCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: job.failedCount > 0
                            ? const Color(0xFFDC2626)
                            : Colors.black45,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDate(job.startedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDate(job.completedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  DataCell(
                    job.errorMessage != null
                        ? Tooltip(
                            message: job.errorMessage!,
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFFD97706),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$month-$day $hour:$min';
  }

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF374151),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Badges
// ─────────────────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'lesson' => ('Lesson', const Color(0xFF1D4ED8)),
      'quiz' => ('Quiz', const Color(0xFF7C3AED)),
      'puzzle' => ('Puzzle', const Color(0xFF0891B2)),
      'simulation' => ('Simulation', const Color(0xFF059669)),
      _ => (type, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'running' => ('Running', const Color(0xFF1D4ED8), Icons.sync_rounded),
      'completed' => (
        'Completed',
        const Color(0xFF059669),
        Icons.check_circle_rounded,
      ),
      'partial' => (
        'Partial',
        const Color(0xFFD97706),
        Icons.warning_amber_rounded,
      ),
      'failed' => ('Failed', const Color(0xFFDC2626), Icons.cancel_rounded),
      'queued' => ('Queued', const Color(0xFF6B7280), Icons.schedule_rounded),
      _ => (status, Colors.grey, Icons.help_outline_rounded),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 36,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No generation jobs yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jobs will appear here once you generate\ncontent from a syllabus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
