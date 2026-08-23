import 'package:flutter/material.dart';

/// Shows a confirmation dialog before a destructive action (e.g. delete).
/// Returns true if the user confirms, false otherwise.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  Color confirmColor = const Color(0xFFDC2626),
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(Icons.warning_amber_rounded, color: confirmColor, size: 34),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(
          ctx,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
