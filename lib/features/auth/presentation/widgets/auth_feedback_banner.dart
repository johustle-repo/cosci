import 'package:flutter/material.dart';

class AuthFeedbackBanner extends StatelessWidget {
  const AuthFeedbackBanner({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
