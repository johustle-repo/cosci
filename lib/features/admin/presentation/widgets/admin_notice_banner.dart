import 'package:flutter/material.dart';

class AdminNoticeBanner extends StatelessWidget {
  const AdminNoticeBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.isWarning = true,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? const Color(0xFFD97706) : const Color(0xFF2563EB);
    final background = isWarning
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFEFF6FF);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.info_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Retry'),
              ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
