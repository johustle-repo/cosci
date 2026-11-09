import 'package:flutter/material.dart';

/// Explains to students why lessons, quizzes, and puzzles unlock one at a
/// time. The rationale mirrors the expert validation instrument in
/// `expert_validation_form.md`.
class SequentialRationaleButton extends StatelessWidget {
  const SequentialRationaleButton({super.key, required this.contentLabel});

  /// Plural name of the content on this screen, e.g. "quizzes".
  final String contentLabel;

  static Future<void> show(BuildContext context, String contentLabel) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.stairs_rounded, color: Color(0xFF123D9B)),
        title: const Text('Why step by step?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Each programming language has its own path. Inside a path, '
                '$contentLabel open one at a time, in the order of the course '
                'syllabus.',
              ),
              const SizedBox(height: 14),
              const _Reason(
                icon: Icons.account_tree_rounded,
                title: 'Concepts build on each other',
                text:
                    'Loops need variables and conditions; arrays need loops. '
                    'Following the syllabus order makes sure the prerequisite '
                    'is learned first.',
              ),
              const _Reason(
                icon: Icons.verified_rounded,
                title: 'Mastery before moving on',
                text:
                    'You move ahead after passing (or using every attempt), so '
                    'gaps are found and reviewed early instead of piling up.',
              ),
              const _Reason(
                icon: Icons.psychology_rounded,
                title: 'One focus at a time',
                text:
                    'Working on one topic per language keeps the mental load '
                    'manageable and makes your progress easier to track.',
              ),
              const _Reason(
                icon: Icons.lock_open_rounded,
                title: 'You are never stuck',
                text:
                    'A quiz counts as finished once you pass it or use all its '
                    'attempts, and finished items stay open for review. You '
                    'can also study other languages at the same time.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => show(context, contentLabel),
      icon: const Icon(Icons.help_outline_rounded, size: 18),
      label: const Text('Why do these unlock step by step?'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF123D9B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
