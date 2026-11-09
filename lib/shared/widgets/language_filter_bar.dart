import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/providers/language_selection_provider.dart';

/// Multi-select programming-language picker shown above Lessons, Quizzes,
/// and Puzzles. Several languages can be active at once; "All" clears the
/// selection.
class LanguageFilterBar extends StatelessWidget {
  const LanguageFilterBar({super.key, required this.languages, this.countFor});

  /// Language tracks that have content on this screen.
  final List<String> languages;

  /// Optional item count shown on each chip.
  final int Function(String language)? countFor;

  @override
  Widget build(BuildContext context) {
    if (languages.length < 2) return const SizedBox.shrink();
    final selection = context.watch<LanguageSelectionProvider>();
    // Ignore saved selections for languages this screen does not offer.
    final active = selection.selected.where(languages.contains).toSet();
    final showAll = active.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 18,
              color: Color(0xFF123D9B),
            ),
            const SizedBox(width: 6),
            Text(
              'Programming language',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Select one or more to study side by side',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: showAll,
              onSelected: (_) => selection.selectAll(),
            ),
            for (final language in languages)
              FilterChip(
                label: Text(
                  countFor == null
                      ? language
                      : '$language (${countFor!(language)})',
                ),
                selected: active.contains(language),
                onSelected: (_) => selection.toggle(language),
              ),
          ],
        ),
      ],
    );
  }
}

/// Section header separating each language track in a filtered list.
class LanguageTrackHeader extends StatelessWidget {
  const LanguageTrackHeader({
    super.key,
    required this.language,
    required this.completed,
    required this.total,
    this.unitLabel = 'completed',
  });

  final String language;
  final int completed;
  final int total;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (completed / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF123D9B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  language,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$completed of $total $unitLabel · $percent%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: total == 0 ? 0 : completed / total,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }
}
