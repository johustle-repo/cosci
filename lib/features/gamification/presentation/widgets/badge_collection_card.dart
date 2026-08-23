import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/gamification/services/certificate_service.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/gamification_style.dart';
import 'package:pseudocode_apk/models/achievement.dart';
import 'package:pseudocode_apk/models/gamification_profile.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';

class BadgeCollectionCard extends StatelessWidget {
  const BadgeCollectionCard({super.key, required this.profile});

  final GamificationProfile profile;

  List<Achievement> get badges => profile.badges;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Badge Quest',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _CollectionProgress(badges: badges),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Complete real learning activities, grow your collection, and celebrate every coding win.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 920
                    ? 3
                    : constraints.maxWidth > 580
                    ? 2
                    : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: badges.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: columns == 1 ? 238 : 260,
                  ),
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    final progress = _progressFor(badge.id);
                    final accent = badge.isUnlocked
                        ? GamificationStyle.badgeColor(badge.accentHex)
                        : const Color(0xFFB8C5D8);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showBadgePreview(
                          context,
                          badge: badge,
                          progress: progress,
                          accent: accent,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: badge.isUnlocked
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      accent.withValues(alpha: 0.16),
                                      accent.withValues(alpha: 0.06),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFF8FAFC),
                                      Color(0xFFF1F5F9),
                                    ],
                                  ),
                            border: Border.all(
                              color: badge.isUnlocked
                                  ? accent.withValues(alpha: 0.32)
                                  : const Color(0xFFD7E1EC),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: badge.isUnlocked
                                          ? accent.withValues(alpha: 0.16)
                                          : Colors.white,
                                    ),
                                    child: Icon(
                                      GamificationStyle.badgeIcon(
                                        badge.iconName,
                                      ),
                                      color: accent,
                                    ),
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          color: badge.isUnlocked
                                              ? accent.withValues(alpha: 0.12)
                                              : const Color(0xFFEFF4FA),
                                        ),
                                        child: Text(
                                          badge.isUnlocked
                                              ? 'Unlocked'
                                              : 'Locked',
                                          style: TextStyle(
                                            color: badge.isUnlocked
                                                ? accent
                                                : const Color(0xFF64748B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                        color: accent,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                badge.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                badge.description,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                badge.milestoneLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: badge.isUnlocked
                                          ? accent
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 7,
                                  value: badge.isUnlocked ? 1 : progress.value,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                badge.isUnlocked
                                    ? 'Quest complete!'
                                    : progress.label,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  _BadgeProgress _progressFor(String id) {
    return switch (id) {
      'first_simulation' => _BadgeProgress.single(profile.completedLessons),
      'quiz_master' => _BadgeProgress.single(profile.highScoreQuizCount),
      'first_puzzle' => _BadgeProgress.single(profile.completedPuzzles),
      'challenge_committed' => _BadgeProgress.single(
        profile.completedChallenges,
      ),
      'streak_week' => _BadgeProgress(
        value: (profile.dailyStreak / 7).clamp(0, 1),
        label: '${profile.dailyStreak.clamp(0, 7)} of 7 days',
      ),
      'rank_beginner' => _xpProgress(10),
      'rank_apprentice' => _xpProgress(60),
      'rank_intermediate' => _xpProgress(150),
      'rank_advanced' => _xpProgress(280),
      'rank_professional' => _xpProgress(450),
      _ => const _BadgeProgress(value: 0, label: 'Keep learning to unlock'),
    };
  }

  _BadgeProgress _xpProgress(int target) => _BadgeProgress(
    value: (profile.totalXp / target).clamp(0, 1),
    label: '${profile.totalXp.clamp(0, target)} of $target XP',
  );

  Future<void> _showBadgePreview(
    BuildContext context, {
    required Achievement badge,
    required _BadgeProgress progress,
    required Color accent,
  }) async {
    final user = context.read<AuthProvider>().currentUser;
    final learnerName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email.split('@').first ?? 'CoSci Learner');
    var downloading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.22),
                        accent.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badge.isUnlocked
                              ? accent
                              : const Color(0xFFCBD5E1),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.22),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          GamificationStyle.badgeIcon(badge.iconName),
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        badge.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(dialogContext).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge.isUnlocked
                            ? 'Achievement unlocked'
                            : 'Keep learning to unlock this badge',
                        style: TextStyle(
                          color: badge.isUnlocked
                              ? accent
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        badge.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      _PreviewDetail(
                        icon: Icons.flag_rounded,
                        label: 'Milestone',
                        value: badge.milestoneLabel,
                        accent: accent,
                      ),
                      const SizedBox(height: 10),
                      _PreviewDetail(
                        icon: badge.isUnlocked
                            ? Icons.verified_rounded
                            : Icons.insights_rounded,
                        label: badge.isUnlocked ? 'Certificate' : 'Progress',
                        value: badge.isUnlocked
                            ? 'Certificate ready for $learnerName'
                            : progress.label,
                        accent: accent,
                      ),
                      const SizedBox(height: 22),
                      if (badge.isUnlocked)
                        FilledButton.icon(
                          onPressed: downloading
                              ? null
                              : () async {
                                  setDialogState(() => downloading = true);
                                  // Render feedback before PDF encoding begins.
                                  await WidgetsBinding.instance.endOfFrame;
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 120),
                                  );
                                  try {
                                    await const CertificateService()
                                        .downloadBadgeCertificate(
                                          badge: badge,
                                          learnerName: learnerName,
                                          learnerId: user?.uid ?? 'learner',
                                        );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Certificate generated successfully.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (error, stackTrace) {
                                    debugPrint(
                                      'Certificate generation failed: $error\n$stackTrace',
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Certificate could not be generated. Please try again.',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (dialogContext.mounted) {
                                      setDialogState(() => downloading = false);
                                    }
                                  }
                                },
                          icon: downloading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            downloading
                                ? 'Preparing your certificate...'
                                : 'Download certificate',
                          ),
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: downloading
                            ? Container(
                                key: const ValueKey('certificate-progress'),
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF4FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFBFD6FF),
                                  ),
                                ),
                                child: const Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LinearProgressIndicator(
                                      minHeight: 4,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Building the PDF, signature, and verification code. Keep this window open.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF334E78),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('certificate-progress-idle'),
                              ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: downloading
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: const Text('Close preview'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewDetail extends StatelessWidget {
  const _PreviewDetail({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CollectionProgress extends StatelessWidget {
  const _CollectionProgress({required this.badges});
  final List<Achievement> badges;

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((badge) => badge.isUnlocked).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$unlocked / ${badges.length} unlocked',
        style: const TextStyle(
          color: Color(0xFF123D9B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BadgeProgress {
  const _BadgeProgress({required this.value, required this.label});
  final double value;
  final String label;

  factory _BadgeProgress.single(int completed) => _BadgeProgress(
    value: completed > 0 ? 1 : 0,
    label: completed > 0 ? 'Ready to unlock' : '0 of 1 completed',
  );
}
