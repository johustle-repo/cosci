import 'package:flutter/material.dart';

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.title,
    this.description,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8E3F2)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFE9FBF8)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 34, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(height: 16),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
              ],
              Text(
                description ?? message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF94A3B8)),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
