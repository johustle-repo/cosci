import 'package:flutter/material.dart';

class ContentStateCard extends StatelessWidget {
  const ContentStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
    this.tint = const Color(0xFF123D9B),
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: tint.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, size: 28, color: tint),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (actionLabel != null && onPressed != null) ...[
                  const SizedBox(height: 18),
                  FilledButton(onPressed: onPressed, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
