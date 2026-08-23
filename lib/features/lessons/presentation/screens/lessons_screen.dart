import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/models/lesson.dart';
import 'package:pseudocode_apk/providers/lessons_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonsProvider>().loadLessons(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LessonsProvider>();

    final content = Padding(
      padding: AppScaffold.pagePadding(context),
      child: provider.isLoading && provider.lessons.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && provider.lessons.isEmpty
          ? _LessonsStateCard(
              icon: Icons.cloud_off_rounded,
              message: provider.errorMessage!,
              actionLabel: 'Try again',
              onPressed: () => context.read<LessonsProvider>().loadLessons(
                forceRefresh: true,
              ),
            )
          : provider.isEmpty
          ? _LessonsStateCard(
              icon: Icons.menu_book_rounded,
              message:
                  'No lesson content is available yet. Add lesson documents in Firestore to populate this section.',
              actionLabel: 'Refresh',
              onPressed: () => context.read<LessonsProvider>().loadLessons(
                forceRefresh: true,
              ),
            )
          : ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF081B3D), Color(0xFF123C81)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading and Lessons',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build algorithm understanding through guided reading and structured lesson content delivered from Firestore.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (provider.recommendedLessons.isNotEmpty) ...[
                  _RecommendationPanel(
                    lessons: provider.recommendedLessons,
                    completedCount: provider.completedLessonIds.length,
                    totalCount: provider.lessons.length,
                  ),
                  const SizedBox(height: 18),
                ],
                ...provider.lessons.map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LessonCard(
                      lesson: lesson,
                      completed: provider.isCompleted(lesson.id),
                    ),
                  ),
                ),
              ],
            ),
    );

    if (widget.embedded) {
      return content;
    }

    return AppScaffold(title: 'Lessons', body: content, maxContentWidth: 1280);
  }
}

class _LessonsStateCard extends StatelessWidget {
  const _LessonsStateCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onPressed, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.completed});

  final Lesson lesson;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 600;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.lessonDetail,
          arguments: lesson,
        ),
        child: Padding(
          padding: EdgeInsets.all(isPhone ? 14 : 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isPhone ? 44 : 54,
                height: isPhone ? 44 : 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isPhone ? 14 : 18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF123D9B), Color(0xFF56C4FF)],
                  ),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (completed) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: Color(0xFF059669),
                            semanticLabel: 'Completed lesson',
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            lesson.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (!isPhone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFEAF3FF),
                            ),
                            child: Text(
                              '${lesson.language} • ${lesson.estimatedMinutes} min',
                              style: const TextStyle(
                                color: Color(0xFF123D9B),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isPhone) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFFEAF3FF),
                          ),
                          child: Text(
                            '${lesson.language} • ${lesson.estimatedMinutes} min',
                            style: const TextStyle(
                              color: Color(0xFF123D9B),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      lesson.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'Open lesson',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: const Color(0xFF123D9B)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Color(0xFF123D9B),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationPanel extends StatelessWidget {
  const _RecommendationPanel({
    required this.lessons,
    required this.completedCount,
    required this.totalCount,
  });
  final List<Lesson> lessons;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Recommended next lessons',
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF047857)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Recommended next',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF064E3B),
                  ),
                ),
              ),
              Text(
                '$completedCount/$totalCount completed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Start with the least difficult unfinished lesson, then build upward.',
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          ...lessons.map(
            (lesson) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  '${lesson.sortOrder}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
              title: Text(
                lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${lesson.difficulty} • ${lesson.errorFocus} focus',
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.lessonDetail,
                arguments: lesson,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
