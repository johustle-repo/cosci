import 'package:flutter/material.dart';

/// Small chip displaying published / unpublished status.
class AdminPublishChip extends StatelessWidget {
  const AdminPublishChip({super.key, required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isPublished
              ? const Color(0xFF166534)
              : const Color(0xFF92400E),
        ),
      ),
    );
  }
}

/// Status chip for daily challenges.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'active':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
      case 'scheduled':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1E40AF);
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
