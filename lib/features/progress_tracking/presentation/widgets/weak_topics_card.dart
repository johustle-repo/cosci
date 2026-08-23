import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/progress_summary.dart';

class WeakTopicsCard extends StatelessWidget {
  const WeakTopicsCard({super.key, required this.weakTopics});

  final List<WeakTopic> weakTopics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weak Topics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              weakTopics.isEmpty
                  ? 'No weak topics detected from current quiz scores.'
                  : 'Topics with lower recorded quiz scores that may need review.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (weakTopics.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF7FAFF),
                  border: Border.all(color: const Color(0xFFD8E4F4)),
                ),
                child: const Text(
                  'Keep solving quizzes to generate topic-level mastery feedback.',
                ),
              )
            else
              ...weakTopics.map(
                (topic) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD8E4F4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                topic.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${topic.averageScore}%',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: topic.averageScore < 50
                                        ? const Color(0xFFB91C1C)
                                        : const Color(0xFFB45309),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${topic.attempts} attempts | ${topic.recommendation}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
