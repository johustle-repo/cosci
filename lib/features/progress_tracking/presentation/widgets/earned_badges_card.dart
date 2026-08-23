import 'package:flutter/material.dart';
import 'package:pseudocode_apk/models/dashboard_badge.dart';

class EarnedBadgesCard extends StatelessWidget {
  const EarnedBadgesCard({super.key, required this.badges});

  final List<DashboardBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earned Badges',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              badges.isEmpty
                  ? 'No badges earned yet.'
                  : 'Recognition from milestones stored in Firestore.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (badges.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFF7FAFF),
                  border: Border.all(color: const Color(0xFFD8E4F4)),
                ),
                child: const Text(
                  'Complete learning tasks to unlock badges and see them here.',
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 280 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: badges.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 64,
                    ),
                    itemBuilder: (context, index) {
                      final badge = badges[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF7FAFF), Color(0xFFEAF2FF)],
                          ),
                          border: Border.all(color: const Color(0xFFD5E4FF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(
                                  0xFF123D9B,
                                ).withValues(alpha: 0.12),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                size: 18,
                                color: Color(0xFF123D9B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                badge.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF123D9B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
