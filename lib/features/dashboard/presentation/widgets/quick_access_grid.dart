import 'package:flutter/material.dart';

class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key, required this.items});

  final List<QuickAccessItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 980
            ? 3
            : constraints.maxWidth > 560
            ? 2
            : 1;
        final childAspectRatio = constraints.maxWidth > 980
            ? 2.15
            : constraints.maxWidth > 560
            ? 2.0
            : 2.7;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF6FAFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFCBD8EE)),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: EdgeInsets.all(constraints.maxWidth < 560 ? 14 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: item.color.withValues(alpha: 0.12),
                            ),
                            child: Icon(item.icon, color: item.color),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFF2F7FF),
                            ),
                            child: Text(
                              'Open',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: item.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: 18,
                            color: item.color,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class QuickAccessItem {
  const QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
