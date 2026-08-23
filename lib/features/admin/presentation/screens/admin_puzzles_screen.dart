import 'package:flutter/material.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_audience_selector.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_puzzle.dart';
import 'package:pseudocode_apk/features/admin/models/admin_lesson.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/student_content_preview_dialog.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_puzzles_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_lessons_provider.dart';

// ─── Tokens ───────────────────────────────────────────────────────────────────
const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _cyan = Color(0xFF0891B2);
const _border = Color(0xFFE2E8F0);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

class AdminPuzzlesScreen extends StatefulWidget {
  const AdminPuzzlesScreen({super.key});

  @override
  State<AdminPuzzlesScreen> createState() => _AdminPuzzlesScreenState();
}

class _AdminPuzzlesScreenState extends State<AdminPuzzlesScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminPuzzlesProvider>().loadPuzzles();
      context.read<AdminLessonsProvider>().loadLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Puzzles',
      currentRoute: AppRoutes.adminPuzzles,
      child: Consumer<AdminPuzzlesProvider>(
        builder: (context, provider, _) {
          final puzzles = provider.puzzles
              .where(
                (p) =>
                    _search.isEmpty ||
                    p.title.toLowerCase().contains(_search.toLowerCase()) ||
                    p.topic.toLowerCase().contains(_search.toLowerCase()),
              )
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                count: provider.puzzles.length,
                publishedCount: provider.puzzles
                    .where((p) => p.isPublished)
                    .length,
                onNew: () => _showForm(context, provider),
              ),
              const SizedBox(height: 20),
              _SearchBar(
                value: _search,
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 16),
              if (provider.isLoading)
                const _LoadingState()
              else if (provider.error != null && provider.puzzles.isEmpty)
                _ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadPuzzles,
                )
              else if (puzzles.isEmpty)
                _EmptyState(
                  hasQuery: _search.isNotEmpty,
                  onNew: () => _showForm(context, provider),
                )
              else
                _PuzzlesTable(
                  puzzles: puzzles,
                  provider: provider,
                  onEdit: (p) => _showForm(context, provider, p),
                  onView: (p) => _previewPuzzle(context, p),
                ),
            ],
          );
        },
      ),
    );
  }

  void _previewPuzzle(BuildContext context, AdminPuzzle puzzle) {
    showStudentPuzzlePreview(context, puzzle);
  }

  void _showForm(
    BuildContext context,
    AdminPuzzlesProvider provider, [
    AdminPuzzle? existing,
  ]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _PuzzleFormDialog(existing: existing),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.count,
    required this.publishedCount,
    required this.onNew,
  });
  final int count;
  final int publishedCount;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_cyan, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.extension_rounded,
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
                'Puzzle Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '$count puzzle${count == 1 ? '' : 's'}  ·  $publishedCount published',
                style: const TextStyle(fontSize: 13, color: _textSub),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onNew,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Puzzle'),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
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

// ─────────────────────────────────────────────────────────────────────────────
// PREMIUM TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _PuzzlesTable extends StatelessWidget {
  const _PuzzlesTable({
    required this.puzzles,
    required this.provider,
    required this.onEdit,
    required this.onView,
  });
  final List<AdminPuzzle> puzzles;
  final AdminPuzzlesProvider provider;
  final void Function(AdminPuzzle) onEdit;
  final void Function(AdminPuzzle) onView;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 1180,
      child: Column(
        children: [
          // Header row
          Container(
            color: const Color(0xFFF8FAFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                SizedBox(width: 8),
                SizedBox(width: 12),
                Expanded(flex: 5, child: _H('Title')),
                Expanded(flex: 3, child: _H('Topic')),
                SizedBox(width: 120, child: _H('Type')),
                SizedBox(width: 90, child: _H('Difficulty')),
                SizedBox(width: 70, child: _H('XP', center: true)),
                SizedBox(width: 90, child: _H('Status')),
                SizedBox(width: 110, child: _H('Actions', center: true)),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),

          // Rows
          ...puzzles.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return _PuzzleRow(
              puzzle: p,
              isLast: i == puzzles.length - 1,
              onEdit: () => onEdit(p),
              onView: () => onView(p),
              onToggle: () => provider.togglePublished(p.id, !p.isPublished),
              onDelete: () async {
                final confirmed = await showAdminConfirmDialog(
                  context,
                  title: 'Delete Puzzle',
                  message: 'Delete "${p.title}"? This cannot be undone.',
                );
                if (confirmed && context.mounted) {
                  await provider.deletePuzzle(p.id, p.title);
                }
              },
            );
          }),
        ],
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

class _PuzzleRow extends StatelessWidget {
  const _PuzzleRow({
    required this.puzzle,
    required this.isLast,
    required this.onEdit,
    required this.onView,
    required this.onToggle,
    required this.onDelete,
  });
  final AdminPuzzle puzzle;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: puzzle.isPublished
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
                      puzzle.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (puzzle.hint != null && puzzle.hint!.isNotEmpty)
                      Text(
                        'Hint: ${puzzle.hint}',
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
                  puzzle.topic,
                  style: const TextStyle(fontSize: 12, color: _textSub),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Type badge
              SizedBox(
                width: 120,
                child: _PuzzleTypeBadge(type: puzzle.puzzleType),
              ),

              // Difficulty
              SizedBox(width: 90, child: _DiffBadge(level: puzzle.difficulty)),

              // XP
              SizedBox(
                width: 70,
                child: Text(
                  '${puzzle.xpReward} XP',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
              ),

              // Status
              SizedBox(
                width: 90,
                child: _StatusBadge(isPublished: puzzle.isPublished),
              ),

              // Actions
              SizedBox(
                width: 118,
                child: PopupMenuButton<String>(
                  tooltip: 'Manage puzzle',
                  onSelected: (value) {
                    if (value == 'view') onView();
                    if (value == 'toggle') onToggle();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.visibility_rounded),
                        title: Text('Preview puzzle'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      enabled: puzzle.isPublished || puzzle.isReadyToPublish,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          puzzle.isPublished
                              ? Icons.visibility_off_rounded
                              : Icons.publish_rounded,
                        ),
                        title: Text(
                          puzzle.isPublished ? 'Unpublish' : 'Publish',
                        ),
                        subtitle:
                            !puzzle.isPublished && !puzzle.isReadyToPublish
                            ? Text(
                                'Complete ${puzzle.readinessIssues.join(', ')}',
                              )
                            : null,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Edit puzzle'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                        ),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manage',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.more_horiz_rounded, size: 17),
                      ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED BADGES & ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PuzzleTypeBadge extends StatelessWidget {
  const _PuzzleTypeBadge({required this.type});
  final String type;

  static const _map = {
    'code_flow': (Color(0xFF7C3AED), 'Code Flow'),
    'output_prediction': (Color(0xFF0891B2), 'Output'),
    'debug_bug': (Color(0xFFDC2626), 'Debug Bug'),
  };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _map[type] ?? (const Color(0xFF64748B), type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
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
    final (color, bg) = switch (level) {
      'Easy' => (const Color(0xFF059669), const Color(0xFFDCFCE7)),
      'Medium' => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      'Hard' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
      _ => (_textSub, const Color(0xFFF1F5F9)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
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
  const _StatusBadge({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPublished
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: isPublished
              ? const Color(0xFF059669)
              : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 4),
        Text(
          isPublished ? 'Published' : 'Draft',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isPublished
                ? const Color(0xFF059669)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
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
          SizedBox(height: 16),
          Text(
            'Loading puzzles…',
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
  const _EmptyState({required this.hasQuery, required this.onNew});
  final bool hasQuery;
  final VoidCallback onNew;

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
              color: _cyan.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.extension_rounded, size: 30, color: _cyan),
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No puzzles match your search.' : 'No puzzles yet.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 8),
          if (!hasQuery)
            const Text(
              'Create your first puzzle to get started.',
              style: TextStyle(fontSize: 13, color: _textSub),
            ),
          const SizedBox(height: 20),
          if (!hasQuery)
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New Puzzle'),
              style: FilledButton.styleFrom(backgroundColor: _navy),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PUZZLE FORM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _PuzzleFormDialog extends StatefulWidget {
  const _PuzzleFormDialog({this.existing});
  final AdminPuzzle? existing;

  @override
  State<_PuzzleFormDialog> createState() => _PuzzleFormDialogState();
}

class _PuzzleFormDialogState extends State<_PuzzleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _topicCtrl;
  late final TextEditingController _snippetCtrl;
  late final TextEditingController _hintCtrl;
  late final TextEditingController _explanationCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _scrambledCtrl;
  late final TextEditingController _correctOrderCtrl;
  late final TextEditingController _outputChoicesCtrl;
  late final TextEditingController _correctOutputCtrl;
  late final TextEditingController _bugDescCtrl;
  late final TextEditingController _bugAnswerCtrl;

  String _puzzleType = 'code_flow';
  String _difficulty = 'Easy';
  bool _isPublished = false;
  late Set<String> _audiencePrograms;
  late Set<String> _yearLevels;
  String? _lessonId;

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _topicCtrl = TextEditingController(text: e?.topic ?? '');
    _snippetCtrl = TextEditingController(text: e?.codeSnippet ?? '');
    _hintCtrl = TextEditingController(text: e?.hint ?? '');
    _explanationCtrl = TextEditingController(text: e?.explanation ?? '');
    _xpCtrl = TextEditingController(text: '${e?.xpReward ?? 25}');
    _scrambledCtrl = TextEditingController(
      text: e?.scrambledLines.join('\n') ?? '',
    );
    _correctOrderCtrl = TextEditingController(
      text: e?.correctOrder.join('\n') ?? '',
    );
    _outputChoicesCtrl = TextEditingController(
      text: e?.outputChoices.join('\n') ?? '',
    );
    _correctOutputCtrl = TextEditingController(text: e?.correctOutputId ?? '');
    _bugDescCtrl = TextEditingController(text: e?.bugDescription ?? '');
    _bugAnswerCtrl = TextEditingController(text: e?.bugAnswer ?? '');
    _puzzleType = e?.puzzleType ?? 'code_flow';
    _difficulty = e?.difficulty ?? 'Easy';
    _isPublished = e?.isPublished ?? false;
    _audiencePrograms = {...?e?.audiencePrograms};
    _yearLevels = {...?e?.yearLevels};
    _lessonId = e?.lessonId;
  }

  void _applyLesson(AdminLesson lesson) {
    final correct = _lessonCode(lesson);
    final scrambled = List<String>.from(correct);
    if (scrambled.length > 2) {
      final first = scrambled.removeAt(0);
      scrambled.add(first);
      if (scrambled.length > 3) {
        final item = scrambled.removeAt(1);
        scrambled.insert(scrambled.length - 1, item);
      }
    } else {
      scrambled
        ..clear()
        ..addAll(correct.reversed);
    }
    setState(() {
      _lessonId = lesson.id;
      _titleCtrl.text = '${lesson.title} – Syntax Stack';
      _topicCtrl.text = lesson.topic;
      _difficulty = lesson.difficulty;
      _snippetCtrl.text = correct.join('\n');
      _correctOrderCtrl.text = correct.join('\n');
      _scrambledCtrl.text = scrambled.join('\n');
      _hintCtrl.text =
          'Start with the program entry point, then follow the execution order.';
      _explanationCtrl.text =
          'Drag each code tile and stack the lines from top to bottom to form valid ${lesson.language} syntax.';
      _audiencePrograms = {...lesson.audiencePrograms};
      _yearLevels = {...lesson.yearLevels};
    });
  }

  List<String> _lessonCode(AdminLesson lesson) {
    final source = lesson.sourceCode.trim();
    if (source.isNotEmpty) {
      return source
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
    }
    final language = lesson.language.toLowerCase();
    if (language.contains('java') && !language.contains('script')) {
      return [
        'public class Main {',
        '  public static void main(String[] args) {',
        '    System.out.println("${lesson.topic}");',
        '  }',
        '}',
      ];
    }
    if (language.contains('javascript')) {
      return [
        'function main() {',
        '  console.log("${lesson.topic}");',
        '}',
        'main();',
      ];
    }
    return [
      '#include <iostream>',
      'using namespace std;',
      'int main() {',
      '  cout << "${lesson.topic}" << endl;',
      '  return 0;',
      '}',
    ];
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _topicCtrl,
      _snippetCtrl,
      _hintCtrl,
      _explanationCtrl,
      _xpCtrl,
      _scrambledCtrl,
      _correctOrderCtrl,
      _outputChoicesCtrl,
      _correctOutputCtrl,
      _bugDescCtrl,
      _bugAnswerCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminPuzzlesProvider>();
    final puzzle = AdminPuzzle(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      difficulty: _difficulty,
      puzzleType: _puzzleType,
      xpReward: int.tryParse(_xpCtrl.text) ?? 25,
      isPublished: _isPublished,
      codeSnippet: _snippetCtrl.text.trim().isEmpty
          ? null
          : _snippetCtrl.text.trim(),
      hint: _hintCtrl.text.trim().isEmpty ? null : _hintCtrl.text.trim(),
      explanation: _explanationCtrl.text.trim().isEmpty
          ? null
          : _explanationCtrl.text.trim(),
      scrambledLines: _puzzleType == 'code_flow'
          ? _toLines(_scrambledCtrl.text)
          : [],
      correctOrder: _puzzleType == 'code_flow'
          ? _toLines(_correctOrderCtrl.text)
          : [],
      outputChoices: _puzzleType == 'output_prediction'
          ? _toLines(_outputChoicesCtrl.text)
          : [],
      correctOutputId: _puzzleType == 'output_prediction'
          ? _correctOutputCtrl.text.trim()
          : null,
      bugDescription: _puzzleType == 'debug_bug'
          ? _bugDescCtrl.text.trim()
          : null,
      bugAnswer: _puzzleType == 'debug_bug' ? _bugAnswerCtrl.text.trim() : null,
      audiencePrograms: _audiencePrograms.toList(),
      yearLevels: _yearLevels.toList(),
      lessonId: _lessonId,
      language:
          context
              .read<AdminLessonsProvider>()
              .lessons
              .where((lesson) => lesson.id == _lessonId)
              .map((lesson) => lesson.language)
              .firstOrNull ??
          widget.existing?.language ??
          'C++',
    );
    final ok = _isEdit
        ? await provider.updatePuzzle(puzzle)
        : await provider.createPuzzle(puzzle);
    if (ok && mounted) Navigator.pop(context);
  }

  List<String> _toLines(String text) =>
      text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminPuzzlesProvider>();
    final lessons = context.watch<AdminLessonsProvider>().lessons;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_cyan, _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.extension_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Syntax Puzzle' : 'Create Syntax Puzzle',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: lessons.any((l) => l.id == _lessonId)
                            ? _lessonId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Lesson to turn into a syntax puzzle *',
                          prefixIcon: Icon(Icons.menu_book_rounded),
                        ),
                        items: lessons
                            .map(
                              (lesson) => DropdownMenuItem(
                                value: lesson.id,
                                child: Text(
                                  '${lesson.language} • ${lesson.title}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        validator: (value) =>
                            value == null ? 'Select a lesson' : null,
                        onChanged: (id) {
                          final lesson = lessons
                              .where((l) => l.id == id)
                              .firstOrNull;
                          if (lesson != null) _applyLesson(lesson);
                        },
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Title',
                        _titleCtrl,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _field('Topic', _topicCtrl),
                      const SizedBox(height: 14),
                      AdminAudienceSelector(
                        programs: _audiencePrograms,
                        years: _yearLevels,
                        onProgramsChanged: (value) =>
                            setState(() => _audiencePrograms = value),
                        onYearsChanged: (value) =>
                            setState(() => _yearLevels = value),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Activity type',
                              ),
                              child: Text('Syntax Stack • Drag and reorder'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _difficulty,
                              decoration: const InputDecoration(
                                labelText: 'Difficulty',
                              ),
                              borderRadius: BorderRadius.circular(10),
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field('Code Snippet', _snippetCtrl, maxLines: 4),
                      const SizedBox(height: 14),

                      // Type-specific fields
                      if (_puzzleType == 'code_flow') ...[
                        _field(
                          'Scrambled Lines (one per line)',
                          _scrambledCtrl,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          'Correct Order (one per line)',
                          _correctOrderCtrl,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_puzzleType == 'output_prediction') ...[
                        _field(
                          'Output Choices (one per line)',
                          _outputChoicesCtrl,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 14),
                        _field('Correct Output Choice', _correctOutputCtrl),
                        const SizedBox(height: 14),
                      ],
                      if (_puzzleType == 'debug_bug') ...[
                        _field('Bug Description', _bugDescCtrl, maxLines: 2),
                        const SizedBox(height: 14),
                        _field('Bug Answer / Fix', _bugAnswerCtrl),
                        const SizedBox(height: 14),
                      ],
                      _field('Hint (optional)', _hintCtrl),
                      const SizedBox(height: 14),
                      _field('Explanation', _explanationCtrl, maxLines: 2),
                      const SizedBox(height: 14),
                      _field(
                        'XP Reward',
                        _xpCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Switch(
                            value: _isPublished,
                            onChanged: (v) => setState(() => _isPublished = v),
                            activeThumbColor: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isPublished
                                  ? const Color(0xFF059669)
                                  : _textSub,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  OutlinedButton(
                    onPressed: provider.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: provider.isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: provider.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Save Changes' : 'Create Syntax Puzzle',
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }
}
