import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/reward_popup_dialog.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/providers/lessons_provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.lesson});

  final Lesson lesson;

  Future<void> _completeLesson(BuildContext context) async {
    final reward = await context.read<GamificationProvider>().completeLesson(
      lessonId: lesson.id,
      title: lesson.title,
    );

    if (!context.mounted) {
      return;
    }

    if (reward != null) {
      await context.read<LessonsProvider>().loadLessons(forceRefresh: true);
      if (!context.mounted) return;
      await RewardPopupDialog.show(context, reward);
      if (!context.mounted) {
        return;
      }
      context.read<GamificationProvider>().clearLatestReward();
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lesson completed • +${reward.xpAwarded} XP • ${reward.newTotalXp} total XP',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW PROGRESS',
            textColor: const Color(0xFFFDE68A),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.gamification),
          ),
        ),
      );
      return;
    }

    final provider = context.read<GamificationProvider>();
    final message = provider.statusMessage ?? provider.errorMessage;
    if (message != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: provider.errorMessage == null
              ? const Color(0xFF123D9B)
              : const Color(0xFFB91C1C),
          content: Row(
            children: [
              Icon(
                provider.errorMessage == null
                    ? Icons.info_outline_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1000;
    return AppScaffold(
      title: 'Lesson',
      maxContentWidth: double.infinity,
      body: CustomScrollView(
        slivers: [
          // ── Hero app bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: isDesktop ? 286 : (width < 600 ? 240 : 220),
            pinned: false,
            toolbarHeight: 0,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF081B3D),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF081B3D), Color(0xFF123C81)],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        width < 600 ? 16 : 28,
                        width < 600 ? 66 : 82,
                        width < 600 ? 16 : 28,
                        width < 600 ? 22 : 34,
                      ),
                      child: _LessonHeroContent(
                        lesson: lesson,
                        isDesktop: isDesktop,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Padding(
                  padding: AppScaffold.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(
                              icon: Icons.description_rounded,
                              title: 'Overview',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              lesson.description,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.65,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Learning objective
                      if (lesson.learningObjective.isNotEmpty) ...[
                        _Card(
                          accent: const Color(0xFF1D4ED8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                icon: Icons.flag_rounded,
                                title: 'Learning Objective',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D4ED8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      lesson.learningObjective,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: Color(0xFF1E293B),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Key concepts
                      if (lesson.keyConcepts.isNotEmpty) ...[
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(
                                icon: Icons.lightbulb_outline_rounded,
                                title: 'Key Concepts',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: lesson.keyConcepts
                                    .map((c) => _ConceptChip(label: c))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      if (lesson.prerequisites.isNotEmpty) ...[
                        _ListCard(
                          icon: Icons.account_tree_rounded,
                          title: 'Before You Start',
                          items: lesson.prerequisites,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (lesson.introduction.isNotEmpty) ...[
                        _TextCard(
                          icon: Icons.waving_hand_rounded,
                          title: 'Introduction',
                          text: lesson.introduction,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (lesson.algorithmSteps.isNotEmpty) ...[
                        _ListCard(
                          icon: Icons.format_list_numbered_rounded,
                          title: 'How the Algorithm Works',
                          items: lesson.algorithmSteps,
                          numbered: true,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (lesson.workedExample.isNotEmpty) ...[
                        _TextCard(
                          icon: Icons.school_rounded,
                          title: 'Worked Example',
                          text: lesson.workedExample,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (lesson.sourceCode.isNotEmpty) ...[
                        _CodeCard(lesson: lesson),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              context
                                  .read<SimulationProvider>()
                                  .prepareLessonPractice(
                                    language: lesson.language,
                                    sourceCode: lesson.sourceCode,
                                    stdin: lesson.standardInput,
                                    lessonTitle: lesson.title,
                                  );
                              Navigator.pushNamed(
                                context,
                                AppRoutes.codeSimulation,
                              );
                            },
                            icon: const Icon(Icons.terminal_rounded),
                            label: const Text(
                              'Practice this example in the compiler',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (lesson.pseudocode.isNotEmpty) ...[
                        _TextCard(
                          icon: Icons.schema_rounded,
                          title: 'Optional Pseudocode',
                          text: lesson.pseudocode,
                          monospace: true,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (lesson.commonMistakes.isNotEmpty) ...[
                        _TextCard(
                          icon: Icons.warning_amber_rounded,
                          title: '${lesson.errorFocus} Error Focus',
                          text: lesson.commonMistakes,
                          accent: const Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (lesson.summary.isNotEmpty) ...[
                        _TextCard(
                          icon: Icons.summarize_rounded,
                          title: 'Lesson Summary',
                          text: lesson.summary,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Topic & meta
                      if (lesson.topic.isNotEmpty) ...[
                        _Card(
                          child: Row(
                            children: [
                              _MetaTile(
                                icon: Icons.topic_rounded,
                                label: 'Topic',
                                value: lesson.topic,
                              ),
                              const SizedBox(width: 24),
                              _MetaTile(
                                icon: Icons.bar_chart_rounded,
                                label: 'Difficulty',
                                value: lesson.difficulty,
                              ),
                              const SizedBox(width: 24),
                              _MetaTile(
                                icon: Icons.timer_outlined,
                                label: 'Duration',
                                value: '${lesson.estimatedMinutes} min',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Done button
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              context.watch<GamificationProvider>().isSubmitting
                              ? null
                              : () => _completeLesson(context),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Done Reading'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF081B3D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LessonHeroContent extends StatelessWidget {
  const _LessonHeroContent({required this.lesson, required this.isDesktop});

  final Lesson lesson;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lesson.topic.isNotEmpty)
          Text(
            lesson.topic.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          lesson.title,
          maxLines: isDesktop ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            height: 1.12,
            fontSize: isDesktop ? 34 : 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(icon: Icons.code_rounded, label: lesson.language),
            _InfoChip(icon: Icons.bar_chart_rounded, label: lesson.difficulty),
            _InfoChip(
              icon: Icons.timer_outlined,
              label: '${lesson.estimatedMinutes} min',
            ),
            if (lesson.compilerValidated)
              const _InfoChip(
                icon: Icons.verified_rounded,
                label: 'Compiler validated',
              ),
          ],
        ),
      ],
    );

    final icon = Container(
      width: isDesktop ? 72 : 52,
      height: isDesktop ? 72 : 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: isDesktop ? 34 : 26,
      ),
    );

    if (!isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 14),
          Expanded(child: details),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        icon,
        const SizedBox(width: 22),
        Expanded(child: details),
        const SizedBox(width: 32),
        Container(
          width: 300,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR LEARNING PATH',
                style: TextStyle(
                  color: Color(0xFFBFDBFE),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              _HeroStep(label: 'Understand', active: true),
              _HeroStep(
                label: lesson.sourceCode.isEmpty ? 'Review' : 'Practice',
                active: lesson.sourceCode.isNotEmpty,
              ),
              const _HeroStep(label: 'Complete', active: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroStep extends StatelessWidget {
  const _HeroStep({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(
          active ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: active ? const Color(0xFF5EEAD4) : Colors.white54,
          size: 17,
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _TextCard extends StatelessWidget {
  const _TextCard({
    required this.icon,
    required this.title,
    required this.text,
    this.monospace = false,
    this.accent,
  });
  final IconData icon;
  final String title;
  final String text;
  final bool monospace;
  final Color? accent;

  @override
  Widget build(BuildContext context) => _Card(
    accent: accent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title),
        const SizedBox(height: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFF1E293B),
            fontFamily: monospace ? 'monospace' : null,
          ),
        ),
      ],
    ),
  );
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.icon,
    required this.title,
    required this.items,
    this.numbered = false,
  });
  final IconData icon;
  final String title;
  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title),
        const SizedBox(height: 10),
        ...items.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    numbered ? '${entry.key + 1}.' : '•',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context) => _Card(
    accent: lesson.compilerValidated ? const Color(0xFF059669) : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(
                icon: Icons.code_rounded,
                title: 'Runnable Code Example',
              ),
            ),
            if (lesson.compilerValidated)
              const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 16,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Compiler validated',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF081B3D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            lesson.sourceCode,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
              color: Color(0xFFE2E8F0),
            ),
          ),
        ),
        if (lesson.standardInput.isNotEmpty ||
            lesson.expectedOutput.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              if (lesson.standardInput.isNotEmpty)
                _CodeMeta(label: 'INPUT', value: lesson.standardInput),
              if (lesson.expectedOutput.isNotEmpty)
                _CodeMeta(
                  label: 'EXPECTED OUTPUT',
                  value: lesson.expectedOutput,
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _CodeMeta extends StatelessWidget {
  const _CodeMeta({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
        ),
      ),
      const SizedBox(height: 4),
      SelectableText(
        value,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    ],
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.accent});
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent?.withValues(alpha: 0.2) ?? const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1D4ED8)),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _ConceptChip extends StatelessWidget {
  const _ConceptChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
