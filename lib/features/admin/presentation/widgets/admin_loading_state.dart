import 'package:flutter/material.dart';

class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(minWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8E3F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D173A67),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0E3A8A),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
