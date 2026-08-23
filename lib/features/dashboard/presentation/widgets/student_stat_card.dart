import 'package:flutter/material.dart';

class StudentStatCard extends StatelessWidget {
  const StudentStatCard({
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
    final compact = MediaQuery.sizeOf(context).width < 480;
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 82 : 132),
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FBFF)],
            ),
          ),
          child: Flex(
            direction: compact ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              SizedBox(width: compact ? 12 : 0, height: compact ? 0 : 14),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF0C2350),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5E718C),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
