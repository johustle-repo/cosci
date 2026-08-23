import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFFEAF2FF),
    this.foregroundColor = const Color(0xFF123D9B),
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: backgroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
