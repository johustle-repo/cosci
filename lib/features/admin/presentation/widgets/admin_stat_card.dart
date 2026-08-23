import 'package:flutter/material.dart';

/// An expressive, accessible dashboard metric card.
class AdminStatCard extends StatefulWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<AdminStatCard> createState() => _AdminStatCardState();
}

class _AdminStatCardState extends State<AdminStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: '${widget.label}: ${widget.value}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.015 : 1,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, widget.color.withValues(alpha: .055)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovered
                    ? widget.color.withValues(alpha: .42)
                    : const Color(0xFFD9E4F2),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _hovered ? .15 : .07),
                  blurRadius: _hovered ? 28 : 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.color,
                              widget.color.withValues(alpha: .72),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(alpha: .24),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 25),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.value,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF102449),
                                    letterSpacing: -.6,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onTap != null)
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
