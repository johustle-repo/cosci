import 'package:flutter/material.dart';

class AdminAudienceSelector extends StatelessWidget {
  const AdminAudienceSelector({
    super.key,
    required this.programs,
    required this.years,
    required this.onProgramsChanged,
    required this.onYearsChanged,
  });

  static const supportedPrograms = [
    'BS Computer Science',
    'BS Information Technology',
    'BS Mathematics-CIT',
  ];
  static const supportedYears = ['1st Year', '2nd Year'];

  final Set<String> programs;
  final Set<String> years;
  final ValueChanged<Set<String>> onProgramsChanged;
  final ValueChanged<Set<String>> onYearsChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Learner audience selection',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learner audience',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text('No selection means all supported learners.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: supportedPrograms
                .map(
                  (value) => FilterChip(
                    label: Text(value),
                    selected: programs.contains(value),
                    onSelected: (selected) {
                      final next = {...programs};
                      selected ? next.add(value) : next.remove(value);
                      onProgramsChanged(next);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: supportedYears
                .map(
                  (value) => FilterChip(
                    label: Text(value),
                    selected: years.contains(value),
                    onSelected: (selected) {
                      final next = {...years};
                      selected ? next.add(value) : next.remove(value);
                      onYearsChanged(next);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
