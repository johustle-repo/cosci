import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_audience_selector.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_lesson.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_content_preview_dialog.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_lessons_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_settings_provider.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/services/compiler_service.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _border = Color(0xFFE2E8F0);
const _surface = Color(0xFFF8FAFF);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  String _search = '';
  String _languageFilter = 'All';
  String _statusFilter = 'All';
  String _focusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminLessonsProvider>().loadLessons(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Lessons',
      currentRoute: AppRoutes.adminLessons,
      child: Consumer<AdminLessonsProvider>(
        builder: (context, provider, _) {
          final lessons = provider.lessons.where((l) {
            final matchesSearch =
                _search.isEmpty ||
                l.title.toLowerCase().contains(_search.toLowerCase()) ||
                l.topic.toLowerCase().contains(_search.toLowerCase());
            final matchesLanguage =
                _languageFilter == 'All' || l.language == _languageFilter;
            final matchesFocus =
                _focusFilter == 'All' || l.errorFocus == _focusFilter;
            final matchesStatus = switch (_statusFilter) {
              'Published' => l.isPublished,
              'Draft' => !l.isPublished,
              'Needs review' => !l.isReadyToPublish,
              'Ready' => l.isReadyToPublish,
              _ => true,
            };
            return matchesSearch &&
                matchesLanguage &&
                matchesFocus &&
                matchesStatus;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              _PageHeader(
                count: provider.lessons.length,
                publishedCount: provider.lessons
                    .where((l) => l.isPublished)
                    .length,
                onNew: () => _showForm(context, provider),
                onSyllabus: () => Navigator.pushNamed(
                  context,
                  AppRoutes.adminLessonGenerator,
                ),
              ),
              const SizedBox(height: 20),

              // ── Search ─────────────────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 900;
                  final fieldWidth = narrow
                      ? ((constraints.maxWidth - 10) / 2).clamp(150.0, 320.0)
                      : 170.0;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SearchBar(
                        value: _search,
                        width: narrow ? constraints.maxWidth : 340,
                        onChanged: (v) => setState(() => _search = v),
                      ),
                      _FilterDropdown(
                        label: 'Language',
                        value: _languageFilter,
                        width: fieldWidth,
                        values: const ['All', 'C++', 'Java', 'JavaScript'],
                        onChanged: (v) => setState(() => _languageFilter = v),
                      ),
                      _FilterDropdown(
                        label: 'Status',
                        value: _statusFilter,
                        width: fieldWidth,
                        values: const [
                          'All',
                          'Published',
                          'Draft',
                          'Ready',
                          'Needs review',
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v),
                      ),
                      _FilterDropdown(
                        label: 'Focus',
                        value: _focusFilter,
                        width: fieldWidth,
                        values: const [
                          'All',
                          'Concept',
                          'Syntax',
                          'Logic',
                          'Syntax and Logic',
                        ],
                        onChanged: (v) => setState(() => _focusFilter = v),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── States ─────────────────────────────────────────────────
              if (provider.isLoading)
                const _LoadingState()
              else if (provider.error != null && provider.lessons.isEmpty)
                _ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadLessons,
                )
              else if (lessons.isEmpty)
                _EmptyState(
                  hasQuery: _search.isNotEmpty,
                  onNew: () => Navigator.pushNamed(
                    context,
                    AppRoutes.adminLessonGenerator,
                  ),
                )
              else
                _LanguageLessonGroups(
                  lessons: lessons,
                  provider: provider,
                  completionCounts: provider.completionCounts,
                  onEdit: (l) => _showForm(context, provider, l),
                  onView: (l) => _previewLesson(context, l),
                  onHistory: (l) => _showHistory(context, provider, l),
                ),
            ],
          );
        },
      ),
    );
  }

  void _previewLesson(BuildContext context, AdminLesson lesson) {
    showAdminContentPreview(
      context,
      title: lesson.title,
      icon: Icons.menu_book_rounded,
      metadata: {
        'Topic': lesson.topic,
        'Language': lesson.language,
        'Difficulty': lesson.difficulty,
        'Status': lesson.isPublished ? 'Published' : 'Draft',
        'Audience': [
          ...lesson.audiencePrograms,
          ...lesson.yearLevels,
        ].join(', '),
      },
      sections: [
        AdminPreviewSection('Description', lesson.description),
        AdminPreviewSection('Learning objective', lesson.learningObjective),
        AdminPreviewSection('Introduction', lesson.introduction),
        AdminPreviewSection('Key concepts', lesson.keyConcepts.join('\n')),
        AdminPreviewSection(
          'Algorithm steps',
          lesson.algorithmSteps.join('\n'),
        ),
        AdminPreviewSection('Worked example', lesson.workedExample),
        AdminPreviewSection('Source code', lesson.sourceCode, isCode: true),
        AdminPreviewSection(
          'Expected output',
          lesson.expectedOutput,
          isCode: true,
        ),
        AdminPreviewSection('Common mistakes', lesson.commonMistakes),
        AdminPreviewSection('Summary', lesson.summary),
      ],
    );
  }

  Future<void> _showHistory(
    BuildContext context,
    AdminLessonsProvider provider,
    AdminLesson lesson,
  ) async {
    showDialog<void>(
      context: context,
      builder: (_) => _RevisionHistoryDialog(
        lesson: lesson,
        revisions: provider.loadRevisions(lesson.id),
      ),
    );
  }

  void _showForm(
    BuildContext context,
    AdminLessonsProvider provider, [
    AdminLesson? existing,
  ]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _LessonFormDialog(existing: existing),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────

// Retained as an internal card template for future draft-history views.
// ignore: unused_element
class _RecentDraftsPanel extends StatelessWidget {
  const _RecentDraftsPanel({
    required this.lessons,
    required this.onView,
    required this.onEdit,
  });

  final List<AdminLesson> lessons;
  final ValueChanged<AdminLesson> onView;
  final ValueChanged<AdminLesson> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: _blue, size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Recently created lesson drafts',
                  style: TextStyle(
                    color: _textMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Review and validate these lessons before publishing.',
            style: TextStyle(color: _textSub, fontSize: 13),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050
                  ? 4
                  : constraints.maxWidth >= 720
                  ? 2
                  : 1;
              final cardWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12 * (columns - 1)) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: lessons
                    .map(
                      (lesson) => SizedBox(
                        width: cardWidth,
                        child: _RecentDraftCard(
                          lesson: lesson,
                          onView: () => onView(lesson),
                          onEdit: () => onEdit(lesson),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentDraftCard extends StatelessWidget {
  const _RecentDraftCard({
    required this.lesson,
    required this.onView,
    required this.onEdit,
  });

  final AdminLesson lesson;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final created = lesson.createdAt ?? lesson.updatedAt;
    final dateLabel = created == null
        ? 'Recently created'
        : 'Created ${MaterialLocalizations.of(context).formatShortDate(created)}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD8E3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _DraftBadge(),
              const Spacer(),
              Text(
                '${lesson.readinessPercent}% ready',
                style: const TextStyle(
                  color: _blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lesson.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${lesson.language} • ${lesson.topic}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _textSub, fontSize: 12),
          ),
          const SizedBox(height: 7),
          Text(
            dateLabel,
            style: const TextStyle(color: _textSub, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftBadge extends StatelessWidget {
  const _DraftBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E6),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Text(
      'DRAFT',
      style: TextStyle(
        color: Color(0xFFB45309),
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.count,
    required this.publishedCount,
    required this.onNew,
    required this.onSyllabus,
  });
  final int count;
  final int publishedCount;
  final VoidCallback onNew;
  final VoidCallback onSyllabus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final details = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + title
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
                Icons.menu_book_rounded,
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
                    'Lesson Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '$count lesson${count == 1 ? '' : 's'}  ·  $publishedCount published',
                    style: const TextStyle(fontSize: 13, color: _textSub),
                  ),
                ],
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onSyllabus,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload syllabus'),
            ),
            OutlinedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Manual lesson'),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [details, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: details),
            actions,
          ],
        );
      },
    );
  }
}

class _LanguageLessonGroups extends StatelessWidget {
  const _LanguageLessonGroups({
    required this.lessons,
    required this.provider,
    required this.completionCounts,
    required this.onEdit,
    required this.onView,
    required this.onHistory,
  });

  final List<AdminLesson> lessons;
  final AdminLessonsProvider provider;
  final Map<String, int> completionCounts;
  final void Function(AdminLesson) onEdit;
  final void Function(AdminLesson) onView;
  final void Function(AdminLesson) onHistory;

  @override
  Widget build(BuildContext context) {
    const languages = ['C++', 'Java', 'JavaScript'];
    final groups = [
      for (final language in languages)
        if (lessons.any((lesson) => lesson.language == language))
          MapEntry(
            language,
            lessons.where((lesson) => lesson.language == language).toList(),
          ),
    ];
    final other = lessons
        .where((lesson) => !languages.contains(lesson.language))
        .toList();
    if (other.isNotEmpty) groups.add(MapEntry('Other', other));

    return Column(
      children: [
        for (final group in groups) ...[
          _LanguageGroupHeader(language: group.key, lessons: group.value),
          const SizedBox(height: 10),
          _LessonsTable(
            lessons: group.value,
            provider: provider,
            completionCounts: completionCounts,
            onEdit: onEdit,
            onView: onView,
            onHistory: onHistory,
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _LanguageGroupHeader extends StatelessWidget {
  const _LanguageGroupHeader({required this.language, required this.lessons});

  final String language;
  final List<AdminLesson> lessons;

  @override
  Widget build(BuildContext context) {
    final color = switch (language) {
      'Java' => const Color(0xFFDC2626),
      'JavaScript' => const Color(0xFFD97706),
      _ => const Color(0xFF2563EB),
    };
    final published = lessons.where((lesson) => lesson.isPublished).length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.code_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textMain,
                  ),
                ),
                Text(
                  '${lessons.length} lesson${lessons.length == 1 ? '' : 's'} · $published published',
                  style: const TextStyle(fontSize: 12, color: _textSub),
                ),
              ],
            ),
          ),
          Text(
            '${lessons.where((lesson) => lesson.isReadyToPublish).length} ready',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.value,
    required this.onChanged,
    this.width = 340,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by title or topic…',
          hintStyle: const TextStyle(fontSize: 13, color: _textSub),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: _textSub,
          ),
          suffixIcon: value.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _textSub,
                  ),
                  onPressed: () => onChanged(''),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _blue, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.width = 170,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _LessonsTable extends StatelessWidget {
  const _LessonsTable({
    required this.lessons,
    required this.provider,
    required this.completionCounts,
    required this.onEdit,
    required this.onView,
    required this.onHistory,
  });
  final List<AdminLesson> lessons;
  final AdminLessonsProvider provider;
  final Map<String, int> completionCounts;
  final void Function(AdminLesson) onEdit;
  final void Function(AdminLesson) onView;
  final void Function(AdminLesson) onHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
      child: AdminTableSurface(
        minWidth: 1410,
        child: Column(
          children: [
            // Table header row
            Container(
              color: const Color(0xFFF8FAFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: const Row(
                children: [
                  SizedBox(width: 32), // status dot column
                  SizedBox(width: 12),
                  Expanded(flex: 5, child: _H('Title')),
                  Expanded(flex: 3, child: _H('Topic')),
                  SizedBox(width: 80, child: _H('Language')),
                  SizedBox(width: 90, child: _H('Difficulty')),
                  SizedBox(width: 120, child: _H('Focus')),
                  SizedBox(width: 100, child: _H('Readiness')),
                  SizedBox(width: 90, child: _H('Completed')),
                  SizedBox(width: 60, child: _H('Order', center: true)),
                  SizedBox(width: 104, child: _H('Status', center: true)),
                  SizedBox(width: 176, child: _H('Actions', center: true)),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),

            // Rows
            ...lessons.asMap().entries.map((entry) {
              final i = entry.key;
              final l = entry.value;
              final isLast = i == lessons.length - 1;
              return _LessonRow(
                lesson: l,
                isLast: isLast,
                onEdit: () => onEdit(l),
                onView: () => onView(l),
                onHistory: () => onHistory(l),
                completionCount: completionCounts[l.id] ?? 0,
                onToggle: () => provider.togglePublished(l.id, !l.isPublished),
                onDelete: () async {
                  final confirmed = await showAdminConfirmDialog(
                    context,
                    title: 'Delete Lesson',
                    message: 'Delete "${l.title}"? This cannot be undone.',
                  );
                  if (confirmed && context.mounted) {
                    await provider.deleteLesson(l.id, l.title);
                  }
                },
              );
            }),
          ],
        ),
      ),
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.isLast,
    required this.onEdit,
    required this.onView,
    required this.onHistory,
    required this.completionCount,
    required this.onToggle,
    required this.onDelete,
  });
  final AdminLesson lesson;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onHistory;
  final int completionCount;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Published dot indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lesson.isPublished
                      ? const Color(0xFF059669)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.description.isNotEmpty)
                      Text(
                        lesson.description,
                        style: const TextStyle(fontSize: 11, color: _textSub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Topic
              Expanded(
                flex: 3,
                child: Text(
                  lesson.topic,
                  style: const TextStyle(fontSize: 12, color: _textSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Language
              SizedBox(width: 80, child: _LangBadge(label: lesson.language)),

              // Difficulty
              SizedBox(width: 90, child: _DiffBadge(level: lesson.difficulty)),

              SizedBox(
                width: 120,
                child: Text(
                  lesson.errorFocus,
                  style: const TextStyle(fontSize: 11, color: _textSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(
                width: 100,
                child: Tooltip(
                  message: lesson.isReadyToPublish
                      ? 'All required lesson content is ready'
                      : 'Open the lesson to complete missing P0 requirements',
                  child: Row(
                    children: [
                      Icon(
                        lesson.isReadyToPublish
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
                        size: 15,
                        color: lesson.isReadyToPublish
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${lesson.readinessPercent}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: lesson.isReadyToPublish
                              ? const Color(0xFF047857)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, size: 14, color: _blue),
                    const SizedBox(width: 5),
                    Text(
                      '$completionCount learner${completionCount == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 11, color: _textSub),
                    ),
                  ],
                ),
              ),

              // Order
              SizedBox(
                width: 60,
                child: Text(
                  '${lesson.sortOrder}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _textSub),
                ),
              ),

              // Status
              SizedBox(
                width: 104,
                child: Center(
                  child: _StatusBadge(isPublished: lesson.isPublished),
                ),
              ),

              // Actions
              SizedBox(
                width: 176,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionBtn(
                      icon: Icons.visibility_rounded,
                      color: const Color(0xFF0F766E),
                      tooltip: 'Preview lesson',
                      onTap: onView,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: lesson.isPublished
                          ? Icons.unpublished_rounded
                          : Icons.publish_rounded,
                      color: lesson.isPublished
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                      tooltip: lesson.isPublished ? 'Unpublish' : 'Publish',
                      onTap: !lesson.isPublished && !lesson.isReadyToPublish
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Complete the lesson requirements before publishing.',
                                ),
                              ),
                            )
                          : onToggle,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.edit_rounded,
                      color: _blue,
                      tooltip: 'Edit',
                      onTap: onEdit,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.history_rounded,
                      color: const Color(0xFF7C3AED),
                      tooltip: 'Revision history',
                      onTap: onHistory,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFDC2626),
                      tooltip: 'Delete',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: _border),
      ],
    );
  }
}

class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _blue,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (level.toLowerCase()) {
      'hard' => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
      'medium' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      _ => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 11,
            color: isPublished ? const Color(0xFF059669) : _textSub,
          ),
          const SizedBox(width: 4),
          Text(
            isPublished ? 'Published' : 'Draft',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPublished ? const Color(0xFF166534) : _textSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
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
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              'Loading lessons…',
              style: TextStyle(fontSize: 13, color: _textSub),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.onNew});
  final bool hasQuery;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 32,
                color: _blue,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery ? 'No results found' : 'No lessons yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Try a different search term.'
                  : 'Upload a syllabus to generate an organized set of lesson drafts.',
              style: const TextStyle(fontSize: 13, color: _textSub),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _RevisionHistoryDialog extends StatelessWidget {
  const _RevisionHistoryDialog({required this.lesson, required this.revisions});
  final AdminLesson lesson;
  final Future<List<Map<String, dynamic>>> revisions;

  String _date(Object? value) {
    final date = value is DateTime
        ? value
        : value is Timestamp
        ? value.toDate()
        : null;
    if (date == null) return 'Date unavailable';
    return '${date.month}/${date.day}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        const Icon(Icons.history_rounded),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${lesson.title} history',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: 560,
      height: 420,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: revisions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Revision history could not be loaded.'),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No previous revisions yet. A snapshot is created before every update.',
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const Divider(),
            itemBuilder: (_, index) {
              final item = items[index];
              final title = (item['title'] ?? 'Untitled lesson').toString();
              final editor = (item['snapshotBy'] ?? 'admin').toString();
              final focus = (item['errorFocus'] ?? 'Concept').toString();
              return ListTile(
                leading: CircleAvatar(child: Text('${items.length - index}')),
                title: Text(title),
                subtitle: Text(
                  '${_date(item['snapshotAt'])} • $editor\n$focus focus',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

class _LessonFormDialog extends StatefulWidget {
  const _LessonFormDialog({this.existing});
  final AdminLesson? existing;

  @override
  State<_LessonFormDialog> createState() => _LessonFormDialogState();
}

class _AuthoringGuide extends StatelessWidget {
  const _AuthoringGuide();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: const Row(
      children: [
        Icon(Icons.route_rounded, color: _blue),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Authoring path: Foundation  →  Explanation  →  Compiler practice  →  Publish',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FormSectionTitle extends StatelessWidget {
  const _FormSectionTitle({
    required this.number,
    required this.title,
    required this.subtitle,
  });
  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: _navy, shape: BoxShape.circle),
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _textMain,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: _textSub),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LessonFormDialogState extends State<_LessonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _objectiveCtrl;
  late final TextEditingController _conceptsCtrl;
  late final TextEditingController _prerequisitesCtrl;
  late final TextEditingController _introductionCtrl;
  late final TextEditingController _workedExampleCtrl;
  late final TextEditingController _mistakesCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _sourceCtrl;
  late final TextEditingController _stdinCtrl;
  late final TextEditingController _outputCtrl;
  late final TextEditingController _algorithmCtrl;
  late final TextEditingController _pseudocodeCtrl;
  String _language = 'C++';
  String _difficulty = 'Easy';
  bool _isPublished = false;
  bool _compilerValidated = false;
  DateTime? _compilerValidatedAt;
  bool _isValidatingCode = false;
  String? _compilerMessage;
  String _errorFocus = 'Concept';
  late Set<String> _audiencePrograms;
  late Set<String> _yearLevels;

  static const _languages = ['C++', 'Java', 'JavaScript'];
  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _errorFocuses = [
    'Concept',
    'Syntax',
    'Logic',
    'Syntax and Logic',
  ];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _topicCtrl = TextEditingController(text: e?.topic ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _orderCtrl = TextEditingController(
      text: e != null ? '${e.sortOrder}' : '0',
    );
    _minutesCtrl = TextEditingController(text: '${e?.estimatedMinutes ?? 15}');
    _objectiveCtrl = TextEditingController(text: e?.learningObjective ?? '');
    _conceptsCtrl = TextEditingController(
      text: e?.keyConcepts.join(', ') ?? '',
    );
    _prerequisitesCtrl = TextEditingController(
      text: e?.prerequisites.join(', ') ?? '',
    );
    _introductionCtrl = TextEditingController(text: e?.introduction ?? '');
    _workedExampleCtrl = TextEditingController(text: e?.workedExample ?? '');
    _mistakesCtrl = TextEditingController(text: e?.commonMistakes ?? '');
    _summaryCtrl = TextEditingController(text: e?.summary ?? '');
    _sourceCtrl = TextEditingController(text: e?.sourceCode ?? '')
      ..addListener(_invalidateCompilerCheck);
    _stdinCtrl = TextEditingController(text: e?.standardInput ?? '')
      ..addListener(_invalidateCompilerCheck);
    _outputCtrl = TextEditingController(text: e?.expectedOutput ?? '')
      ..addListener(_invalidateCompilerCheck);
    _algorithmCtrl = TextEditingController(
      text: e?.algorithmSteps.join('\n') ?? '',
    );
    _pseudocodeCtrl = TextEditingController(text: e?.pseudocode ?? '');
    _language = _languages.contains(e?.language) ? e!.language : 'C++';
    _difficulty = e?.difficulty ?? 'Easy';
    _isPublished = e?.isPublished ?? false;
    _errorFocus = _errorFocuses.contains(e?.errorFocus)
        ? e!.errorFocus
        : 'Concept';
    _compilerValidated = e?.compilerValidated ?? false;
    _compilerValidatedAt = e?.compilerValidatedAt;
    _audiencePrograms = {...?e?.audiencePrograms};
    _yearLevels = {...?e?.yearLevels};
    if (e != null) _fillMissingGeneratedFields();
  }

  void _fillMissingGeneratedFields() {
    final topic = _topicCtrl.text.trim().isEmpty
        ? _titleCtrl.text.trim().replaceFirst(RegExp(r'^Introduction to '), '')
        : _topicCtrl.text.trim();
    final subject = topic.isEmpty ? 'the lesson topic' : topic;
    final description = _descCtrl.text.trim();
    void fill(TextEditingController controller, String text) {
      if (controller.text.trim().isEmpty) controller.text = text;
    }

    if (_audiencePrograms.isEmpty) {
      _audiencePrograms = {
        'BS Computer Science',
        'BS Information Technology',
        'BS Mathematics-CIT',
      };
    }
    if (_yearLevels.isEmpty) _yearLevels = {'1st Year', '2nd Year'};
    fill(
      _objectiveCtrl,
      'By the end of this lesson, learners can explain $subject and apply it in a simple $_language program.',
    );
    fill(_conceptsCtrl, '$subject, algorithm, $_language fundamentals');
    fill(
      _prerequisitesCtrl,
      'Basic programming concepts, Reading simple program statements',
    );
    fill(
      _introductionCtrl,
      description.isEmpty
          ? 'This lesson introduces $subject using a guided explanation, a step-by-step algorithm, and runnable practice.'
          : description,
    );
    fill(
      _algorithmCtrl,
      'Identify the input and expected result.\nBreak the solution into ordered operations.\nImplement the operations in $_language.\nRun the program and verify its output.',
    );
    fill(
      _workedExampleCtrl,
      'Trace the runnable example line by line. Identify its data, follow each operation, and verify why it produces the expected output.',
    );
    fill(
      _mistakesCtrl,
      'Avoid skipping algorithm steps, using invalid $_language syntax, or assuming the result without tracing the code. Test each step and read compiler feedback carefully.',
    );
    fill(
      _summaryCtrl,
      'This lesson explains how $subject is planned as an algorithm, implemented in $_language, and checked using the program output.',
    );
    final message = 'Lesson example: $subject';
    fill(_sourceCtrl, _lessonStarterCode(_language, message));
    fill(_outputCtrl, message);
  }

  String _lessonStarterCode(String language, String message) {
    if (language == 'Java') {
      return 'public class Main {\n  public static void main(String[] args) {\n    System.out.println("$message");\n  }\n}';
    }
    if (language == 'JavaScript') return 'console.log("$message");';
    return '#include <iostream>\nusing namespace std;\n\nint main() {\n  cout << "$message" << endl;\n  return 0;\n}';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _topicCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _minutesCtrl.dispose();
    _objectiveCtrl.dispose();
    _conceptsCtrl.dispose();
    _prerequisitesCtrl.dispose();
    _introductionCtrl.dispose();
    _workedExampleCtrl.dispose();
    _mistakesCtrl.dispose();
    _summaryCtrl.dispose();
    _sourceCtrl.dispose();
    _stdinCtrl.dispose();
    _outputCtrl.dispose();
    _algorithmCtrl.dispose();
    _pseudocodeCtrl.dispose();
    super.dispose();
  }

  List<String> _lines(TextEditingController controller) => controller.text
      .split(RegExp(r'\r?\n|,'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  void _invalidateCompilerCheck() {
    if (!_compilerValidated || !mounted) return;
    setState(() {
      _compilerValidated = false;
      _compilerValidatedAt = null;
      _compilerMessage = 'Code changed. Validate it again before publishing.';
    });
  }

  Future<void> _validateCode() async {
    if (_sourceCtrl.text.trim().isEmpty) {
      setState(() => _compilerMessage = 'Add a runnable code example first.');
      return;
    }
    setState(() {
      _isValidatingCode = true;
      _compilerMessage = null;
    });
    final result = await const CompilerService().execute(
      language: ProgrammingLanguageX.fromLabel(_language),
      sourceCode: _sourceCtrl.text,
      stdin: _stdinCtrl.text,
    );
    if (!mounted) return;
    final expected = _outputCtrl.text.trimRight();
    final outputMatches =
        expected.isEmpty || result.output.trimRight() == expected;
    setState(() {
      _isValidatingCode = false;
      _compilerValidated = result.succeeded && outputMatches;
      _compilerValidatedAt = _compilerValidated ? DateTime.now() : null;
      _compilerMessage = !result.succeeded
          ? '${result.message}${result.output.isEmpty ? '' : '\n${result.output}'}'
          : outputMatches
          ? 'Compiler check passed. The example is ready for learners.'
          : 'Logic check failed: actual output does not match expected output.\nActual: ${result.output}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audiencePrograms.isEmpty || _yearLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one eligible program and year level.'),
        ),
      );
      return;
    }
    if (_isPublished &&
        _sourceCtrl.text.trim().isNotEmpty &&
        !_compilerValidated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validate the code example before publishing this lesson.',
          ),
        ),
      );
      return;
    }
    final provider = context.read<AdminLessonsProvider>();
    final topics = context.read<AdminSettingsProvider>().settings.topics;
    final lesson = AdminLesson(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      topic: _topicCtrl.text.trim().isEmpty
          ? (topics.isNotEmpty ? topics.first : 'General')
          : _topicCtrl.text.trim(),
      language: _language,
      difficulty: _difficulty,
      description: _descCtrl.text.trim(),
      sortOrder: int.tryParse(_orderCtrl.text) ?? 0,
      isPublished: _isPublished,
      audiencePrograms: _audiencePrograms.toList(),
      yearLevels: _yearLevels.toList(),
      estimatedMinutes: int.tryParse(_minutesCtrl.text) ?? 15,
      learningObjective: _objectiveCtrl.text.trim(),
      keyConcepts: _lines(_conceptsCtrl),
      prerequisites: _lines(_prerequisitesCtrl),
      introduction: _introductionCtrl.text.trim(),
      workedExample: _workedExampleCtrl.text.trim(),
      commonMistakes: _mistakesCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      errorFocus: _errorFocus,
      sourceCode: _sourceCtrl.text.trim(),
      standardInput: _stdinCtrl.text,
      expectedOutput: _outputCtrl.text.trimRight(),
      algorithmSteps: _lines(_algorithmCtrl),
      pseudocode: _pseudocodeCtrl.text.trim(),
      compilerValidated: _compilerValidated,
      compilerValidatedAt: _compilerValidatedAt,
    );
    final ok = _isEdit
        ? await provider.updateLesson(lesson)
        : await provider.createLesson(lesson);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminLessonsProvider>();
    final isBusy = provider.isSaving;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _DialogHeader(
              icon: _isEdit ? Icons.edit_rounded : Icons.add_rounded,
              title: _isEdit ? 'Edit Lesson' : 'New Lesson',
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _AuthoringGuide(),
                      const SizedBox(height: 18),
                      const _FormSectionTitle(
                        number: '1',
                        title: 'Lesson foundation',
                        subtitle:
                            'Define the topic, audience, language, and learning goal.',
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _titleCtrl,
                          decoration: _dec('Title *', Icons.title_rounded),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _topicCtrl,
                          decoration: _dec(
                            'Topic',
                            Icons.topic_rounded,
                            hint: 'e.g. Variables, Loops',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AdminAudienceSelector(
                        programs: _audiencePrograms,
                        years: _yearLevels,
                        onProgramsChanged: (value) =>
                            setState(() => _audiencePrograms = value),
                        onYearsChanged: (value) =>
                            setState(() => _yearLevels = value),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              child: DropdownButtonFormField<String>(
                                initialValue: _language,
                                decoration: _dec(
                                  'Language',
                                  Icons.code_rounded,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                items: _languages
                                    .map(
                                      (l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(l),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _language = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              child: DropdownButtonFormField<String>(
                                initialValue: _difficulty,
                                decoration: _dec(
                                  'Difficulty',
                                  Icons.bar_chart_rounded,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                items: _difficulties
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(d),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _difficulty = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: _dec(
                            'Description / Explanation',
                            Icons.notes_rounded,
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _FormSectionTitle(
                        number: '2',
                        title: 'Guided explanation',
                        subtitle:
                            'Explain the algorithm in small, learner-friendly steps.',
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _objectiveCtrl,
                          decoration: _dec(
                            'Learning objective *',
                            Icons.flag_rounded,
                            hint: 'What should the learner be able to do?',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'A measurable learning objective is required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              child: TextFormField(
                                controller: _conceptsCtrl,
                                decoration: _dec(
                                  'Key concepts *',
                                  Icons.lightbulb_rounded,
                                  hint: 'variables, loops, conditions',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              child: TextFormField(
                                controller: _prerequisitesCtrl,
                                decoration: _dec(
                                  'Prerequisites',
                                  Icons.account_tree_rounded,
                                  hint: 'one per line or comma-separated',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              child: DropdownButtonFormField<String>(
                                initialValue: _errorFocus,
                                decoration: _dec(
                                  'Learning focus',
                                  Icons.bug_report_rounded,
                                ),
                                items: _errorFocuses
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _errorFocus = value!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              child: TextFormField(
                                controller: _minutesCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec(
                                  'Estimated minutes',
                                  Icons.timer_outlined,
                                ),
                                validator: (v) {
                                  final value = int.tryParse(v ?? '');
                                  return value == null ||
                                          value < 1 ||
                                          value > 180
                                      ? 'Enter 1–180 minutes'
                                      : null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _introductionCtrl,
                          maxLines: 3,
                          decoration: _dec(
                            'Introduction',
                            Icons.waving_hand_rounded,
                            hint:
                                'Connect the topic to a beginner-friendly situation.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _algorithmCtrl,
                          maxLines: 4,
                          decoration: _dec(
                            'Algorithm steps *',
                            Icons.format_list_numbered_rounded,
                            hint: 'One clear step per line',
                          ),
                          validator: (v) => _lines(_algorithmCtrl).isEmpty
                              ? 'Add at least one algorithm step'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _workedExampleCtrl,
                          maxLines: 3,
                          decoration: _dec(
                            'Worked example',
                            Icons.school_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              child: TextFormField(
                                controller: _mistakesCtrl,
                                maxLines: 3,
                                decoration: _dec(
                                  'Common mistakes',
                                  Icons.warning_amber_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              child: TextFormField(
                                controller: _summaryCtrl,
                                maxLines: 3,
                                decoration: _dec(
                                  'Lesson summary',
                                  Icons.summarize_rounded,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _FormSectionTitle(
                        number: '3',
                        title: 'Compiler practice',
                        subtitle:
                            'Provide runnable code and verify syntax and expected behavior.',
                      ),
                      const SizedBox(height: 12),
                      _field(
                        child: TextFormField(
                          controller: _sourceCtrl,
                          maxLines: 9,
                          autocorrect: false,
                          enableSuggestions: false,
                          enableIMEPersonalizedLearning: false,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          decoration: _dec(
                            'Runnable $_language example',
                            Icons.code_rounded,
                            hint:
                                'Use a complete program that can be compiled and run.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              child: TextFormField(
                                controller: _stdinCtrl,
                                maxLines: 3,
                                autocorrect: false,
                                enableSuggestions: false,
                                enableIMEPersonalizedLearning: false,
                                style: const TextStyle(fontFamily: 'monospace'),
                                decoration: _dec(
                                  'Standard input',
                                  Icons.keyboard_rounded,
                                  hint: 'No input required for this example',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              child: TextFormField(
                                controller: _outputCtrl,
                                maxLines: 3,
                                autocorrect: false,
                                enableSuggestions: false,
                                enableIMEPersonalizedLearning: false,
                                style: const TextStyle(fontFamily: 'monospace'),
                                decoration: _dec(
                                  'Expected output',
                                  Icons.terminal_rounded,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _isValidatingCode ? null : _validateCode,
                            icon: _isValidatingCode
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow_rounded),
                            label: const Text('Compile and validate'),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _compilerValidated
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            color: _compilerValidated
                                ? const Color(0xFF059669)
                                : _textSub,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _compilerMessage ??
                                  (_compilerValidated
                                      ? 'Validated compiler example'
                                      : 'Publishing requires validation when code is included.'),
                              style: TextStyle(
                                fontSize: 12,
                                color: _compilerValidated
                                    ? const Color(0xFF047857)
                                    : _textSub,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Optional pseudocode',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Use only when it helps explain the algorithm.',
                        ),
                        children: [
                          TextFormField(
                            controller: _pseudocodeCtrl,
                            maxLines: 6,
                            style: const TextStyle(fontFamily: 'monospace'),
                            decoration: _dec(
                              'Pseudocode',
                              Icons.schema_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _FormSectionTitle(
                        number: '4',
                        title: 'Review and publish',
                        subtitle:
                            'Set the order and publish only when all requirements pass.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: _field(
                              child: TextFormField(
                                controller: _orderCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dec(
                                  'Sort Order',
                                  Icons.sort_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              children: [
                                Switch(
                                  value: _isPublished,
                                  onChanged: (v) =>
                                      setState(() => _isPublished = v),
                                  activeThumbColor: const Color(0xFF059669),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isPublished ? 'Published' : 'Draft',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: _isPublished
                                            ? const Color(0xFF059669)
                                            : _textSub,
                                      ),
                                    ),
                                    const Text(
                                      'Visible to students',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _textSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isBusy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: isBusy ? null : _submit,
                    icon: isBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 15),
                    label: Text(_isEdit ? 'Save Changes' : 'Create'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({required Widget child}) => child;

  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: _textSub),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: _blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
