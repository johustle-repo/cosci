import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_syllabus.dart';
import 'package:pseudocode_apk/features/admin/models/admin_syllabus_analysis.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_table_surface.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_generation_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_settings_provider.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_syllabus_provider.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _navy = Color(0xFF0E3A8A);
const _blue = Color(0xFF1D4ED8);
const _blueLight = Color(0xFFEFF6FF);
const _border = Color(0xFFE2E8F0);
const _surface = Color(0xFFF8FAFF);
const _textMain = Color(0xFF0F172A);
const _textSub = Color(0xFF64748B);

class AdminSyllabusDetailScreen extends StatefulWidget {
  const AdminSyllabusDetailScreen({super.key, required this.syllabusId});
  final String syllabusId;

  @override
  State<AdminSyllabusDetailScreen> createState() =>
      _AdminSyllabusDetailScreenState();
}

class _AdminSyllabusDetailScreenState extends State<AdminSyllabusDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<AdminSyllabusProvider>();
      final gp = context.read<AdminGenerationProvider>();
      final apiKey = context.read<AdminSettingsProvider>().settings.groqApiKey;
      sp.configureApiKey(apiKey);
      gp.configureApiKey(apiKey);

      sp.loadSyllabusDetail(widget.syllabusId).then((_) {
        if (sp.currentSyllabus != null) {
          gp.loadJobs(syllabusId: widget.syllabusId);
          gp.loadGeneratedCounts(widget.syllabusId);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Syllabus Detail',
      currentRoute: AppRoutes.adminSyllabus,
      child: Consumer<AdminSyllabusProvider>(
        builder: (context, sp, _) {
          if (sp.isLoading) {
            return const _CenteredLoader(message: 'Loading syllabus…');
          }
          if (sp.error != null) {
            return _FullError(
              message: sp.error!,
              onRetry: () => sp.loadSyllabusDetail(widget.syllabusId),
            );
          }
          final syllabus = sp.currentSyllabus;
          if (syllabus == null) {
            return const _FullError(message: 'Syllabus not found.');
          }
          return _DetailBody(syllabus: syllabus, analysis: sp.currentAnalysis);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN BODY
// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.syllabus, required this.analysis});
  final AdminSyllabus syllabus;
  final AdminSyllabusAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Breadcrumb + title bar ───────────────────────────────────────
        _TitleBar(syllabus: syllabus),
        const SizedBox(height: 24),

        // ── Overview cards row ───────────────────────────────────────────
        _OverviewRow(syllabus: syllabus, analysis: analysis),
        const SizedBox(height: 24),

        // ── Analysis section ─────────────────────────────────────────────
        _AnalysisPanel(syllabus: syllabus, analysis: analysis),
        const SizedBox(height: 24),

        // ── Generation section ───────────────────────────────────────────
        if (analysis != null) _GenerationPanel(analysis: analysis!),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TITLE BAR
// ─────────────────────────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.syllabus});
  final AdminSyllabus syllabus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _blue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.adminSyllabus,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.description_rounded,
            color: Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syllabus.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    if (syllabus.courseCode.isNotEmpty) syllabus.courseCode,
                    if (syllabus.courseName.isNotEmpty) syllabus.courseName,
                  ].join('  ·  '),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(status: syllabus.analysisStatus),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'analyzed' => (
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
        'Analyzed',
      ),
      'analyzing' => (const Color(0xFFDBEAFE), _blue, 'Analyzing…'),
      'failed' => (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'Failed'),
      _ => (Colors.white.withValues(alpha: 0.2), Colors.white70, 'Pending'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW ROW (info cards)
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.syllabus, required this.analysis});
  final AdminSyllabus syllabus;
  final AdminSyllabusAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _InfoCard(
          icon: Icons.code_rounded,
          label: 'Language',
          value: syllabus.programmingLanguage.isNotEmpty
              ? syllabus.programmingLanguage
              : '—',
          color: _blue,
        ),
        _InfoCard(
          icon: Icons.school_rounded,
          label: 'Year Level',
          value: syllabus.yearLevel.isNotEmpty ? syllabus.yearLevel : '—',
          color: const Color(0xFF7C3AED),
        ),
        _InfoCard(
          icon: Icons.calendar_month_rounded,
          label: 'Term',
          value: syllabus.term.isNotEmpty ? syllabus.term : '—',
          color: const Color(0xFF0891B2),
        ),
        _InfoCard(
          icon: Icons.attach_file_rounded,
          label: 'File',
          value:
              '${syllabus.fileType.toUpperCase()}  ${syllabus.displayFileSize}',
          color: const Color(0xFFD97706),
        ),
        if (analysis != null) ...[
          _InfoCard(
            icon: Icons.segment_rounded,
            label: 'Units',
            value: '${analysis!.units.length}',
            color: const Color(0xFF059669),
          ),
          _InfoCard(
            icon: Icons.topic_rounded,
            label: 'Topics',
            value: '${analysis!.allTopics.length}',
            color: const Color(0xFF059669),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: _textSub),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYSIS PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisPanel extends StatelessWidget {
  const _AnalysisPanel({required this.syllabus, required this.analysis});
  final AdminSyllabus syllabus;
  final AdminSyllabusAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<AdminSyllabusProvider>();

    return _PanelCard(
      header: _PanelHeader(
        icon: Icons.auto_awesome_rounded,
        iconColor: _blue,
        title: 'AI Syllabus Analysis',
        subtitle: 'Extract topics, units and learning outcomes using Groq AI',
        trailing: FilledButton.icon(
          onPressed: sp.isAnalyzing ? null : () => _runAnalysis(context, sp),
          icon: sp.isAnalyzing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  syllabus.isAnalyzed
                      ? Icons.refresh_rounded
                      : Icons.play_arrow_rounded,
                  size: 16,
                ),
          label: Text(
            sp.isAnalyzing
                ? 'Analysing…'
                : syllabus.isAnalyzed
                ? 'Re-Analyse'
                : 'Analyse Syllabus',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sp.analysisError != null) ...[
            _AlertBar(message: sp.analysisError!, type: _AlertType.error),
            const SizedBox(height: 16),
          ],
          if (sp.isAnalyzing)
            const _AnalyzingPlaceholder()
          else if (analysis == null)
            _AnalysisEmptyState(syllabus: syllabus)
          else
            _AnalysisResult(analysis: analysis!),
        ],
      ),
    );
  }

  Future<void> _runAnalysis(
    BuildContext context,
    AdminSyllabusProvider sp,
  ) async {
    final apiKey = context.read<AdminSettingsProvider>().settings.groqApiKey;
    if (apiKey.isEmpty) {
      _showApiKeyDialog(context, sp);
      return;
    }
    sp.configureApiKey(apiKey);

    // Groq chat completions do not accept binary files.
    // For every file type (including PDF) we ask the admin to paste the
    // extracted text so we can send it as a plain-text prompt.
    _showTextInputDialog(context, sp);
  }

  void _showApiKeyDialog(BuildContext context, AdminSyllabusProvider sp) {
    showDialog<void>(
      context: context,
      builder: (_) => _ApiKeyDialog(
        onSave: (key) async {
          final settingsProvider = context.read<AdminSettingsProvider>();
          sp.configureApiKey(key);
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            await settingsProvider.saveSettings(
              settingsProvider.settings.copyWith(groqApiKey: key),
            );
            if (!context.mounted) return;
            _runAnalysis(context, sp);
          });
        },
      ),
    );
  }

  void _showTextInputDialog(BuildContext context, AdminSyllabusProvider sp) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: sp,
        child: _PasteTextDialog(syllabus: syllabus),
      ),
    );
  }
}

class _AnalyzingPlaceholder extends StatelessWidget {
  const _AnalyzingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Groq AI is analysing your syllabus…',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _navy,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'This may take up to 30 seconds.',
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
        ],
      ),
    );
  }
}

class _AnalysisEmptyState extends StatelessWidget {
  const _AnalysisEmptyState({required this.syllabus});
  final AdminSyllabus syllabus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _blueLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: _blue,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Not yet analysed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Click "Analyse Syllabus" to extract topics, units and\nlearning outcomes with Groq AI.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textSub),
          ),
          if (syllabus.analysisFailed) ...[
            const SizedBox(height: 12),
            const _AlertBar(
              message:
                  'Previous analysis failed. Check your Groq API key in Settings.',
              type: _AlertType.error,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYSIS RESULT
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisResult extends StatelessWidget {
  const _AnalysisResult({required this.analysis});
  final AdminSyllabusAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Analysed banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Analysis complete — ${analysis.units.length} unit(s), '
                  '${analysis.allTopics.length} topic(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
              if (analysis.analyzedAt != null)
                Text(
                  DateFormat('MMM d, yyyy').format(analysis.analyzedAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF166534),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Course description
        if (analysis.courseDescription.isNotEmpty) ...[
          Text(
            analysis.courseDescription,
            style: const TextStyle(fontSize: 13, color: _textSub, height: 1.5),
          ),
          const SizedBox(height: 16),
        ],

        // Topics wrap
        if (analysis.allTopics.isNotEmpty) ...[
          const _SectionLabel('Topics Covered'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: analysis.allTopics
                .map((t) => _TopicChip(label: t))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Units table
        if (analysis.units.isNotEmpty) ...[
          const _SectionLabel('Course Units'),
          const SizedBox(height: 8),
          _UnitsTable(units: analysis.units),
          const SizedBox(height: 20),
        ],

        // ILOs
        if (analysis.intendedLearningOutcomes.isNotEmpty) ...[
          const _SectionLabel('Intended Learning Outcomes'),
          const SizedBox(height: 8),
          ...analysis.intendedLearningOutcomes.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      o,
                      style: const TextStyle(fontSize: 13, color: _textMain),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnitsTable extends StatelessWidget {
  const _UnitsTable({required this.units});
  final List<SyllabusUnit> units;

  @override
  Widget build(BuildContext context) {
    return AdminTableSurface(
      minWidth: 920,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFF)),
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 80,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: _ColH('Unit')),
          DataColumn(label: _ColH('Title')),
          DataColumn(label: _ColH('Week')),
          DataColumn(label: _ColH('Topics')),
          DataColumn(label: _ColH('Difficulty')),
        ],
        rows: units
            .map(
              (u) => DataRow(
                cells: [
                  DataCell(
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _blueLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${u.unitNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        u.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textMain,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      u.weekReference.isNotEmpty ? u.weekReference : '—',
                      style: const TextStyle(fontSize: 12, color: _textSub),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children:
                            u.topics
                                .take(4)
                                .map((t) => _MiniChip(label: t))
                                .toList()
                              ..addAll(
                                u.topics.length > 4
                                    ? [
                                        _MiniChip(
                                          label: '+${u.topics.length - 4}',
                                        ),
                                      ]
                                    : [],
                              ),
                      ),
                    ),
                  ),
                  DataCell(_DiffBadge(level: u.difficulty)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ColH extends StatelessWidget {
  const _ColH(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _blue,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _blue,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GENERATION PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _GenerationPanel extends StatelessWidget {
  const _GenerationPanel({required this.analysis});
  final AdminSyllabusAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminGenerationProvider>(
      builder: (context, gen, _) {
        return _PanelCard(
          header: _PanelHeader(
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Generate Content',
            subtitle:
                'AI-generate lessons, quizzes, puzzles & simulations for all '
                '${analysis.units.length} unit(s)',
            trailing: TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.adminGenerationJobs,
                arguments: analysis.syllabusId,
              ),
              icon: const Icon(Icons.list_alt_rounded, size: 15),
              label: const Text('View Jobs'),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (gen.generationError != null) ...[
                _AlertBar(
                  message: gen.generationError!,
                  type: _AlertType.error,
                ),
                const SizedBox(height: 16),
              ],
              if (gen.isGenerating)
                _GenerationProgress(gen: gen)
              else
                _GenerationGrid(
                  analysis: analysis,
                  gen: gen,
                  onGenerate: (type) => _confirmGenerate(context, gen, type),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmGenerate(
    BuildContext context,
    AdminGenerationProvider gen,
    String type,
  ) async {
    final apiKey = context.read<AdminSettingsProvider>().settings.groqApiKey;
    if (apiKey.isEmpty) {
      _showApiKeyDialog(context, gen);
      return;
    }
    gen.configureApiKey(apiKey);

    final plural = '${type}s';
    final displayName = plural[0].toUpperCase() + plural.substring(1);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmGenerateDialog(
        type: displayName,
        unitCount: analysis.units.length,
      ),
    );

    if (confirmed == true && context.mounted) {
      await gen.generateContent(analysis: analysis, contentType: type);
      if (context.mounted && gen.generationError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$displayName generated. Review in the $displayName screen.',
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showApiKeyDialog(BuildContext context, AdminGenerationProvider gen) {
    showDialog<void>(
      context: context,
      builder: (_) => _ApiKeyDialog(
        onSave: (key) async {
          final settingsProvider = context.read<AdminSettingsProvider>();
          gen.configureApiKey(key);
          Navigator.of(context).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            await settingsProvider.saveSettings(
              settingsProvider.settings.copyWith(groqApiKey: key),
            );
          });
        },
      ),
    );
  }
}

class _GenerationProgress extends StatelessWidget {
  const _GenerationProgress({required this.gen});
  final AdminGenerationProvider gen;

  @override
  Widget build(BuildContext context) {
    final pct = (gen.generationProgress * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Generating ${gen.generatingType}s…',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _navy,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: gen.generationProgress,
            backgroundColor: const Color(0xFFBFDBFE),
            valueColor: const AlwaysStoppedAnimation<Color>(_blue),
            borderRadius: BorderRadius.circular(4),
            minHeight: 7,
          ),
        ],
      ),
    );
  }
}

class _GenerationGrid extends StatelessWidget {
  const _GenerationGrid({
    required this.analysis,
    required this.gen,
    required this.onGenerate,
  });
  final AdminSyllabusAnalysis analysis;
  final AdminGenerationProvider gen;
  final void Function(String type) onGenerate;

  static const _items = [
    (
      type: 'lesson',
      label: 'Lessons',
      icon: Icons.menu_book_rounded,
      color: _blue,
    ),
    (
      type: 'quiz',
      label: 'Quizzes',
      icon: Icons.quiz_rounded,
      color: Color(0xFF7C3AED),
    ),
    (
      type: 'puzzle',
      label: 'Puzzles',
      icon: Icons.extension_rounded,
      color: Color(0xFFD97706),
    ),
    (
      type: 'simulation',
      label: 'Simulations',
      icon: Icons.terminal_rounded,
      color: Color(0xFF059669),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: _items.map((item) {
            final count = gen.countFor(
              item.type == 'lesson'
                  ? 'lessons'
                  : item.type == 'quiz'
                  ? 'quizzes'
                  : item.type == 'puzzle'
                  ? 'puzzles'
                  : 'simulations',
            );
            return _GenCard(
              label: item.label,
              icon: item.icon,
              color: item.color,
              count: count,
              onTap: () => onGenerate(item.type),
            );
          }).toList(),
        );
      },
    );
  }
}

class _GenCard extends StatelessWidget {
  const _GenCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _textMain,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(count > 0 ? 'Regenerate' : 'Generate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED UI COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.header, required this.child});
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textMain,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _textSub),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _textSub,
        letterSpacing: 0.6,
      ),
    );
  }
}

enum _AlertType { error, warning, info }

class _AlertBar extends StatelessWidget {
  const _AlertBar({required this.message, required this.type});
  final String message;
  final _AlertType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (type) {
      _AlertType.error => (
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
        Icons.error_outline_rounded,
      ),
      _AlertType.warning => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.warning_amber_rounded,
      ),
      _AlertType.info => (_blueLight, _navy, Icons.info_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 13, color: fg)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOGS
// ─────────────────────────────────────────────────────────────────────────────

class _PasteTextDialog extends StatefulWidget {
  const _PasteTextDialog({required this.syllabus});
  final AdminSyllabus syllabus;

  @override
  State<_PasteTextDialog> createState() => _PasteTextDialogState();
}

class _PasteTextDialogState extends State<_PasteTextDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<AdminSyllabusProvider>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.content_paste_rounded,
              title: 'Paste Syllabus Content',
              onClose: sp.isAnalyzing ? null : () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Paste the full text of the syllabus. Groq AI will extract topics, '
                    'units and learning outcomes.',
                    style: TextStyle(fontSize: 13, color: _textSub),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    maxLines: 14,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Paste syllabus text here…',
                      filled: true,
                      fillColor: _surface,
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
                    ),
                  ),
                ],
              ),
            ),
            _DialogFooter(
              onCancel: sp.isAnalyzing ? null : () => Navigator.pop(context),
              onConfirm: sp.isAnalyzing || _ctrl.text.trim().isEmpty
                  ? null
                  : () async {
                      final text = _ctrl.text.trim();
                      Navigator.pop(context);
                      await sp.analyzeSyllabus(textContent: text);
                    },
              confirmLabel: sp.isAnalyzing ? 'Analysing…' : 'Analyse',
              isBusy: sp.isAnalyzing,
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.onSave});
  final void Function(String key) onSave;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.key_rounded,
              title: 'Groq API Key Required',
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AlertBar(
                    message:
                        'Your Groq API key is stored in Firestore settings and never committed to source code.',
                    type: _AlertType.info,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    obscureText: _obscure,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'API Key (gsk_…)',
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _blue, width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _DialogFooter(
              onCancel: () => Navigator.pop(context),
              onConfirm: _ctrl.text.trim().isEmpty
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      widget.onSave(_ctrl.text.trim());
                    },
              confirmLabel: 'Save & Continue',
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmGenerateDialog extends StatelessWidget {
  const _ConfirmGenerateDialog({required this.type, required this.unitCount});
  final String type;
  final int unitCount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(
              icon: Icons.bolt_rounded,
              iconColor: const Color(0xFFD97706),
              title: 'Generate $type?',
              onClose: () => Navigator.pop(context, false),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _AlertBar(
                    message:
                        'This will use Groq AI to generate $type for all $unitCount '
                        'unit(s). Content will be saved in draft status for review.',
                    type: _AlertType.info,
                  ),
                ],
              ),
            ),
            _DialogFooter(
              onCancel: () => Navigator.pop(context, false),
              onConfirm: () => Navigator.pop(context, true),
              confirmLabel: 'Generate',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG BUILDING BLOCKS
// ─────────────────────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.icon,
    required this.title,
    this.iconColor = _blue,
    this.onClose,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _textMain,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onClose,
              color: _textSub,
            ),
        ],
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    this.isBusy = false,
  });
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String confirmLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onConfirm,
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
            label: Text(confirmLabel),
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILITY STATES
// ─────────────────────────────────────────────────────────────────────────────

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: _blue, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 13, color: _textSub)),
        ],
      ),
    );
  }
}

class _FullError extends StatelessWidget {
  const _FullError({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _textMain),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: _navy),
            ),
          ],
        ],
      ),
    );
  }
}
