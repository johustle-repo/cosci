import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/progress_tracking/presentation/widgets/earned_badges_card.dart';
import 'package:pseudocode_apk/features/progress_tracking/presentation/widgets/progress_breakdown_card.dart';
import 'package:pseudocode_apk/features/progress_tracking/presentation/widgets/progress_hero_card.dart';
import 'package:pseudocode_apk/features/progress_tracking/presentation/widgets/progress_kpi_grid.dart';
import 'package:pseudocode_apk/features/progress_tracking/presentation/widgets/recent_activity_card.dart';
import 'package:pseudocode_apk/features/progress_tracking/presentation/widgets/weak_topics_card.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/providers/progress_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';
import 'package:pseudocode_apk/shared/widgets/content_state_card.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.uid;
      context.read<ProgressProvider>().loadSummary(userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final summary = provider.summary;

    final content = Padding(
      padding: AppScaffold.pagePadding(context),
      child: provider.isLoading && provider.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null && provider.isEmpty
          ? _ProgressStateCard(
              icon: Icons.cloud_off_rounded,
              message: provider.errorMessage!,
              actionLabel: 'Try again',
              onPressed: () {
                final userId = context.read<AuthProvider>().currentUser?.uid;
                context.read<ProgressProvider>().loadSummary(
                  userId: userId,
                  forceRefresh: true,
                );
              },
            )
          : ListView(
              children: [
                ProgressHeroCard(summary: summary),
                const SizedBox(height: 18),
                ProgressKpiGrid(summary: summary),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ProgressBreakdownCard(summary: summary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: EarnedBadgesCard(
                              badges: summary.earnedBadges,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        ProgressBreakdownCard(summary: summary),
                        const SizedBox(height: 14),
                        EarnedBadgesCard(badges: summary.earnedBadges),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: WeakTopicsCard(
                              weakTopics: summary.weakTopics,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: RecentActivityCard(
                              activities: summary.recentActivities,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        WeakTopicsCard(weakTopics: summary.weakTopics),
                        const SizedBox(height: 14),
                        RecentActivityCard(
                          activities: summary.recentActivities,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );

    if (widget.embedded) {
      return content;
    }

    return AppScaffold(
      title: 'Progress Tracking',
      body: content,
      maxContentWidth: 1180,
    );
  }
}

class _ProgressStateCard extends StatelessWidget {
  const _ProgressStateCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ContentStateCard(
      icon: icon,
      title: 'Progress data unavailable',
      message: message,
      actionLabel: actionLabel,
      onPressed: onPressed,
    );
  }
}
