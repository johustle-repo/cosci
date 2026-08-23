import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/badge_collection_card.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/gamification_hero_card.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/streak_overview_card.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/xp_level_card.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GamificationProvider>();
    final profile = provider.profile;

    final content = RefreshIndicator(
      onRefresh: () =>
          context.read<GamificationProvider>().loadProfile(forceRefresh: true),
      child: ListView(
        padding: AppScaffold.pagePadding(context),
        children: [
          GamificationHeroCard(profile: profile),
          const SizedBox(height: 18),
          if (provider.errorMessage != null) ...[
            _InfoBanner(message: provider.errorMessage!, isError: true),
            const SizedBox(height: 12),
          ] else if (provider.statusMessage != null) ...[
            _InfoBanner(message: provider.statusMessage!),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 820) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: XpLevelCard(profile: profile)),
                    const SizedBox(width: 14),
                    Expanded(child: StreakOverviewCard(profile: profile)),
                  ],
                );
              }

              return Column(
                children: [
                  XpLevelCard(profile: profile),
                  const SizedBox(height: 14),
                  StreakOverviewCard(profile: profile),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          BadgeCollectionCard(profile: profile),
          if (provider.isLoading) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return AppScaffold(
      title: 'Gamification',
      body: content,
      maxContentWidth: 1180,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isError ? const Color(0xFFFFF1F1) : const Color(0xFFEAF3FF),
        border: Border.all(
          color: isError ? const Color(0xFFF5C2C2) : const Color(0xFFD5E5FF),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError ? const Color(0xFFB42318) : const Color(0xFF123D9B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError
                    ? const Color(0xFF8E1C1C)
                    : const Color(0xFF123D9B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
