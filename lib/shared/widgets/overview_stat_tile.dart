import 'package:flutter/material.dart';

class OverviewStatTile extends StatelessWidget {
  const OverviewStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 168),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF0C2350),
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
