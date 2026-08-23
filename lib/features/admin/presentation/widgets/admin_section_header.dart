import 'package:flutter/material.dart';

/// Section title row with an optional primary action button.
class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final heading = Row(
          children: [
            Container(
              width: 5,
              height: 26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF102449),
                  letterSpacing: -.2,
                ),
              ),
            ),
          ],
        );
        final action = actionLabel != null && onAction != null
            ? FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null;
        if (!compact) {
          return Row(
            children: [
              Expanded(child: heading),
              ?action,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        );
      },
    );
  }
}
