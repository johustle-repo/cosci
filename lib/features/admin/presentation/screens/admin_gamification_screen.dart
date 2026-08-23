import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/admin/models/admin_badge.dart';
import 'package:pseudocode_apk/features/admin/models/admin_gamification_rule.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_shell.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_confirm_dialog.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_error_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_loading_state.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_notice_banner.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:pseudocode_apk/features/admin/providers/admin_gamification_provider.dart';

class AdminGamificationScreen extends StatefulWidget {
  const AdminGamificationScreen({super.key});

  @override
  State<AdminGamificationScreen> createState() =>
      _AdminGamificationScreenState();
}

class _AdminGamificationScreenState extends State<AdminGamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminGamificationProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: 'Gamification',
      currentRoute: AppRoutes.adminGamification,
      child: Consumer<AdminGamificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const SizedBox(
              height: 300,
              child: AdminLoadingState(message: 'Loading gamification data...'),
            );
          }
          if (provider.error != null &&
              provider.badges.isEmpty &&
              provider.rules.isEmpty) {
            return SizedBox(
              height: 300,
              child: AdminErrorState(
                message: provider.error!,
                onRetry: provider.loadAll,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.error != null) ...[
                AdminNoticeBanner(
                  message: provider.error!,
                  onRetry: provider.loadAll,
                  onDismiss: provider.clearError,
                ),
                const SizedBox(height: 14),
              ],
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Badges'),
                  Tab(text: 'XP Rules'),
                  Tab(text: 'Level Thresholds'),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  child: switch (_tabController.index) {
                    1 => _XpRulesTab(
                      key: const ValueKey('xp-rules'),
                      provider: provider,
                    ),
                    2 => _LevelThresholdsTab(
                      key: const ValueKey('level-thresholds'),
                      provider: provider,
                    ),
                    _ => _BadgesTab(
                      key: const ValueKey('badges'),
                      provider: provider,
                    ),
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Badges Tab ────────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({super.key, required this.provider});
  final AdminGamificationProvider provider;

  @override
  Widget build(BuildContext context) {
    final installedIds = provider.badges.map((badge) => badge.id).toSet();
    final missing = _starterBadges
        .where((badge) => !installedIds.contains(badge.id))
        .toList();
    final activityBadges =
        provider.badges.where((badge) => !badge.id.startsWith('rank_')).toList()
          ..sort((a, b) {
            final aIndex = _starterBadges.indexWhere((item) => item.id == a.id);
            final bIndex = _starterBadges.indexWhere((item) => item.id == b.id);
            if (aIndex < 0 && bIndex < 0) return a.title.compareTo(b.title);
            if (aIndex < 0) return 1;
            if (bIndex < 0) return -1;
            return aIndex.compareTo(bIndex);
          });
    final rankBadges =
        provider.badges.where((badge) => badge.id.startsWith('rank_')).toList()
          ..sort((a, b) {
            final aIndex = _starterBadges.indexWhere((item) => item.id == a.id);
            final bIndex = _starterBadges.indexWhere((item) => item.id == b.id);
            return aIndex.compareTo(bIndex);
          });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Learner Badge Collection',
          actionLabel: 'New Badge',
          actionIcon: Icons.add_rounded,
          onAction: () => _showBadgeForm(context, provider),
        ),
        const SizedBox(height: 14),
        _BadgeWelcomePanel(
          installedCount: provider.badges.length,
          missingCount: missing.length,
          isSaving: provider.isSaving,
          onInstall: missing.isEmpty
              ? null
              : () => _installStarterSet(context, missing),
        ),
        const SizedBox(height: 18),
        provider.badges.isEmpty
            ? _StarterBadgePreview(
                isSaving: provider.isSaving,
                onInstall: () => _installStarterSet(context, missing),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activityBadges.isNotEmpty)
                    _BadgeGridSection(
                      title: 'Achievement badges',
                      subtitle: 'Earned by completing meaningful activities',
                      icon: Icons.emoji_events_rounded,
                      badges: activityBadges,
                      onEdit: (badge) =>
                          _showBadgeForm(context, provider, badge),
                      onDelete: (badge) => _deleteBadge(context, badge),
                    ),
                  if (activityBadges.isNotEmpty && rankBadges.isNotEmpty)
                    const SizedBox(height: 24),
                  if (rankBadges.isNotEmpty)
                    _BadgeGridSection(
                      title: 'Coding rank journey',
                      subtitle: 'A clear path from beginner to professional',
                      icon: Icons.military_tech_rounded,
                      badges: rankBadges,
                      showRankNumber: true,
                      onEdit: (badge) =>
                          _showBadgeForm(context, provider, badge),
                      onDelete: (badge) => _deleteBadge(context, badge),
                    ),
                ],
              ),
      ],
    );
  }

  Future<void> _installStarterSet(
    BuildContext context,
    List<AdminBadge> badges,
  ) async {
    final ok = await provider.installStarterBadges(badges);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${badges.length} learner badges are ready to earn.'
              : provider.error ?? 'Could not install starter badges.',
        ),
      ),
    );
  }

  Future<void> _deleteBadge(BuildContext context, AdminBadge badge) async {
    final ok = await showAdminConfirmDialog(
      context,
      title: 'Delete Badge',
      message: 'Delete "${badge.title}"? Learners can no longer earn it.',
    );
    if (ok && context.mounted) {
      await provider.deleteBadge(badge.id, badge.title);
    }
  }

  static const _starterBadges = <AdminBadge>[
    AdminBadge(
      id: 'first_simulation',
      title: 'Code Explorer',
      description: 'Take the first step from reading code to running it.',
      iconName: 'terminal',
      accentHex: '#2563EB',
      criteria: 'Complete 1 lesson or simulation',
      milestoneLabel: 'Your first successful run',
    ),
    AdminBadge(
      id: 'quiz_master',
      title: 'Sharp Thinker',
      description: 'Show strong understanding in a graded knowledge check.',
      iconName: 'spark',
      accentHex: '#7C3AED',
      criteria: 'Score at least 80% on a quiz',
      milestoneLabel: 'Earn an 80%+ quiz score',
    ),
    AdminBadge(
      id: 'first_puzzle',
      title: 'Syntax Builder',
      description: 'Put code tiles in the correct order and solve a puzzle.',
      iconName: 'puzzle',
      accentHex: '#0891B2',
      criteria: 'Complete 1 syntax puzzle',
      milestoneLabel: 'Solve your first code stack',
    ),
    AdminBadge(
      id: 'challenge_committed',
      title: 'Daily Challenger',
      description: 'Turn practice into progress by finishing a daily task.',
      iconName: 'target',
      accentHex: '#EA580C',
      criteria: 'Complete 1 daily challenge',
      milestoneLabel: 'Finish today\'s challenge',
    ),
    AdminBadge(
      id: 'streak_week',
      title: 'Consistency Champion',
      description: 'Build a learning habit and keep the momentum alive.',
      iconName: 'flame',
      accentHex: '#DB2777',
      criteria: 'Reach a 7-day learning streak',
      milestoneLabel: 'Practice for 7 days in a row',
    ),
    AdminBadge(
      id: 'rank_beginner',
      title: 'Coding Beginner',
      description: 'Your coding journey has officially begun.',
      iconName: 'seedling',
      accentHex: '#16A34A',
      criteria: 'Earn 10 total XP',
      milestoneLabel: 'Beginner rank · 10 XP',
    ),
    AdminBadge(
      id: 'rank_apprentice',
      title: 'Coding Apprentice',
      description: 'You are building reliable programming foundations.',
      iconName: 'bolt',
      accentHex: '#0284C7',
      criteria: 'Earn 60 total XP',
      milestoneLabel: 'Apprentice rank · 60 XP',
    ),
    AdminBadge(
      id: 'rank_intermediate',
      title: 'Intermediate Coder',
      description: 'You can apply core concepts across coding activities.',
      iconName: 'code',
      accentHex: '#7C3AED',
      criteria: 'Earn 150 total XP',
      milestoneLabel: 'Intermediate rank · 150 XP',
    ),
    AdminBadge(
      id: 'rank_advanced',
      title: 'Advanced Developer',
      description: 'Complex problems are becoming opportunities to grow.',
      iconName: 'rocket',
      accentHex: '#EA580C',
      criteria: 'Earn 280 total XP',
      milestoneLabel: 'Advanced rank · 280 XP',
    ),
    AdminBadge(
      id: 'rank_professional',
      title: 'Professional Programmer',
      description: 'You have demonstrated consistent, well-rounded mastery.',
      iconName: 'crown',
      accentHex: '#CA8A04',
      criteria: 'Earn 450 total XP',
      milestoneLabel: 'Professional rank · 450 XP',
    ),
  ];

  void _showBadgeForm(
    BuildContext ctx,
    AdminGamificationProvider provider, [
    AdminBadge? existing,
  ]) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _BadgeFormDialog(existing: existing),
      ),
    );
  }
}

class _BadgeWelcomePanel extends StatelessWidget {
  const _BadgeWelcomePanel({
    required this.installedCount,
    required this.missingCount,
    required this.isSaving,
    required this.onInstall,
  });
  final int installedCount;
  final int missingCount;
  final bool isSaving;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A63), Color(0xFF1747AA), Color(0xFF0F9F9A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24123D9B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD65A),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installedCount == 0
                      ? 'Launch your learner badge journey'
                      : '$installedCount badges active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  missingCount == 0
                      ? 'The complete starter collection is ready for learners to unlock.'
                      : 'Install $missingCount tested milestones connected to lessons, quizzes, puzzles, challenges, and streaks.',
                  style: const TextStyle(
                    color: Color(0xFFDCE8FF),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onInstall != null) ...[
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: isSaving ? null : onInstall,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD65A),
                foregroundColor: const Color(0xFF102A63),
              ),
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text('Install starter set'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarterBadgePreview extends StatelessWidget {
  const _StarterBadgePreview({required this.isSaving, required this.onInstall});
  final bool isSaving;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E2F2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _BadgesTab._starterBadges
                .map((badge) => _BadgeMedallion(badge: badge))
                .toList(),
          ),
          const SizedBox(height: 22),
          Text(
            '${_BadgesTab._starterBadges.length} badges, ready from day one',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Each badge is already connected to a real learning milestone. No manual criteria setup is required.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: isSaving ? null : onInstall,
            icon: const Icon(Icons.rocket_launch_rounded),
            label: const Text('Activate starter badges'),
          ),
        ],
      ),
    );
  }
}

class _BadgeMedallion extends StatelessWidget {
  const _BadgeMedallion({required this.badge});
  final AdminBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(badge.accentHex);
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .82),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .2),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: .76), color],
          ),
        ),
        child: Icon(_badgeIcon(badge.iconName), color: Colors.white, size: 27),
      ),
    );
  }
}

class _BadgeGridSection extends StatelessWidget {
  const _BadgeGridSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badges,
    required this.onEdit,
    required this.onDelete,
    this.showRankNumber = false,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<AdminBadge> badges;
  final ValueChanged<AdminBadge> onEdit;
  final ValueChanged<AdminBadge> onDelete;
  final bool showRankNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1747AA), size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF10213D),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${badges.length} badges',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1450
                ? 5
                : constraints.maxWidth >= 1120
                ? 4
                : constraints.maxWidth >= 820
                ? 3
                : constraints.maxWidth >= 520
                ? 2
                : 1;
            final cardWidth =
                (constraints.maxWidth - ((columns - 1) * 14)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: badges.asMap().entries.map((entry) {
                return SizedBox(
                  width: cardWidth,
                  child: _BadgeCard(
                    badge: entry.value,
                    rankNumber: showRankNumber ? entry.key + 1 : null,
                    onEdit: () => onEdit(entry.value),
                    onDelete: () => onDelete(entry.value),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.onEdit,
    required this.onDelete,
    this.rankNumber,
  });
  final AdminBadge badge;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? rankNumber;

  @override
  Widget build(BuildContext context) {
    final accent = _badgeColor(badge.accentHex);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 258,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: .16), Colors.white],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -52,
                top: -58,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: .07),
                  ),
                ),
              ),
              Positioned(
                left: -18,
                right: -18,
                top: -22,
                child: Container(height: 4, color: accent),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _BadgeMedallion(badge: badge),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          rankNumber == null ? 'MILESTONE' : 'RANK $rankNumber',
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Badge actions',
                        color: Colors.white,
                        onSelected: (value) =>
                            value == 'edit' ? onEdit() : onDelete(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit badge'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete badge'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    badge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF10213D),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'HOW TO EARN',
                    style: TextStyle(
                      color: accent.withValues(alpha: .82),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: .15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, size: 16, color: accent),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            badge.criteria,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _badgeColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  return value == null ? const Color(0xFF2563EB) : Color(0xFF000000 | value);
}

IconData _badgeIcon(String name) => switch (name) {
  'terminal' => Icons.terminal_rounded,
  'spark' => Icons.auto_awesome_rounded,
  'puzzle' => Icons.extension_rounded,
  'target' => Icons.track_changes_rounded,
  'flame' => Icons.local_fire_department_rounded,
  'seedling' => Icons.eco_rounded,
  'bolt' => Icons.bolt_rounded,
  'code' => Icons.code_rounded,
  'rocket' => Icons.rocket_launch_rounded,
  'crown' => Icons.workspace_premium_rounded,
  _ => Icons.workspace_premium_rounded,
};

// ── XP Rules Tab ──────────────────────────────────────────────────────────────

class _XpRulesTab extends StatelessWidget {
  const _XpRulesTab({super.key, required this.provider});
  final AdminGamificationProvider provider;

  @override
  Widget build(BuildContext context) {
    final existingIds = provider.xpRules.map((rule) => rule.id).toSet();
    final missing = _defaultXpRules
        .where((rule) => !existingIds.contains(rule.id))
        .toList();
    final totalXp = provider.xpRules.fold<int>(
      0,
      (sum, rule) => sum + (rule.xpAmount ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'XP Reward Rules',
          actionLabel: 'New Rule',
          actionIcon: Icons.add_rounded,
          onAction: () => _showRuleForm(context, provider, 'xp_reward'),
        ),
        const SizedBox(height: 14),
        _RuleOverviewPanel(
          icon: Icons.bolt_rounded,
          title: '${provider.xpRules.length} reward rules configured',
          subtitle: totalXp == 0
              ? 'Install the balanced starter rewards to begin.'
              : '$totalXp XP available across one completion of every configured activity.',
          accent: const Color(0xFF2563EB),
          actionLabel: missing.isEmpty ? null : 'Use recommended rewards',
          isSaving: provider.isSaving,
          onAction: missing.isEmpty
              ? null
              : () => _install(context, missing, 'XP reward'),
        ),
        const SizedBox(height: 16),
        provider.xpRules.isEmpty
            ? _GamificationSetupEmpty(
                icon: Icons.bolt_rounded,
                title: 'Reward meaningful learning',
                message:
                    'Start with balanced XP for lessons, simulations, quizzes, puzzles, and daily challenges.',
                buttonLabel: 'Install recommended XP rules',
                isSaving: provider.isSaving,
                onPressed: () => _install(context, missing, 'XP reward'),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 650
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - 14 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: provider.xpRules
                        .map(
                          (rule) => SizedBox(
                            width: width,
                            child: _XpRuleCard(
                              rule: rule,
                              onEdit: () => _showRuleForm(
                                context,
                                provider,
                                'xp_reward',
                                rule,
                              ),
                              onDelete: () => _deleteRule(context, rule),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
      ],
    );
  }

  Future<void> _install(
    BuildContext context,
    List<AdminGamificationRule> rules,
    String label,
  ) async {
    final ok = await provider.installRules(rules);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '$label settings are ready.'
              : provider.error ?? 'Could not save settings.',
        ),
      ),
    );
  }

  Future<void> _deleteRule(
    BuildContext context,
    AdminGamificationRule rule,
  ) async {
    final ok = await showAdminConfirmDialog(
      context,
      title: 'Delete XP Rule',
      message: 'Remove the ${rule.targetModule ?? 'activity'} reward?',
    );
    if (ok && context.mounted) await provider.deleteRule(rule.id);
  }

  static const _defaultXpRules = <AdminGamificationRule>[
    AdminGamificationRule(
      id: 'xp_lesson',
      ruleType: 'xp_reward',
      description: 'Complete a lesson',
      targetModule: 'lesson',
      xpAmount: 10,
    ),
    AdminGamificationRule(
      id: 'xp_simulation',
      ruleType: 'xp_reward',
      description: 'Complete a code simulation',
      targetModule: 'simulation',
      xpAmount: 10,
    ),
    AdminGamificationRule(
      id: 'xp_quiz',
      ruleType: 'xp_reward',
      description: 'Pass a quiz with at least 80%',
      targetModule: 'quiz',
      xpAmount: 20,
    ),
    AdminGamificationRule(
      id: 'xp_puzzle',
      ruleType: 'xp_reward',
      description: 'Solve a syntax puzzle',
      targetModule: 'puzzle',
      xpAmount: 15,
    ),
    AdminGamificationRule(
      id: 'xp_challenge',
      ruleType: 'xp_reward',
      description: 'Complete the daily challenge',
      targetModule: 'challenge',
      xpAmount: 15,
    ),
  ];

  void _showRuleForm(
    BuildContext ctx,
    AdminGamificationProvider provider,
    String ruleType, [
    AdminGamificationRule? existing,
  ]) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _RuleFormDialog(ruleType: ruleType, existing: existing),
      ),
    );
  }
}

// ── Level Thresholds Tab ──────────────────────────────────────────────────────

class _LevelThresholdsTab extends StatelessWidget {
  const _LevelThresholdsTab({super.key, required this.provider});
  final AdminGamificationProvider provider;

  @override
  Widget build(BuildContext context) {
    final levels = [...provider.levelThresholds]
      ..sort((a, b) => (a.level ?? 0).compareTo(b.level ?? 0));
    final existingIds = levels.map((rule) => rule.id).toSet();
    final missing = _defaultLevels
        .where((rule) => !existingIds.contains(rule.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          title: 'Level Thresholds',
          actionLabel: 'Add Level',
          actionIcon: Icons.add_rounded,
          onAction: () => _showLevelForm(context, provider),
        ),
        const SizedBox(height: 14),
        _RuleOverviewPanel(
          icon: Icons.trending_up_rounded,
          title: '${levels.length} learner levels configured',
          subtitle: levels.isEmpty
              ? 'Create a clear progression from newcomer to professional.'
              : 'Highest milestone: ${levels.last.xpRequired ?? 0} XP at Level ${levels.last.level ?? 1}.',
          accent: const Color(0xFF7C3AED),
          actionLabel: missing.isEmpty ? null : 'Use balanced progression',
          isSaving: provider.isSaving,
          onAction: missing.isEmpty ? null : () => _install(context, missing),
        ),
        const SizedBox(height: 16),
        levels.isEmpty
            ? _GamificationSetupEmpty(
                icon: Icons.stairs_rounded,
                title: 'Build the learner journey',
                message:
                    'Install a balanced ten-level path that starts gently and becomes more challenging over time.',
                buttonLabel: 'Install recommended levels',
                isSaving: provider.isSaving,
                onPressed: () => _install(context, missing),
              )
            : _LevelJourney(
                levels: levels,
                onEdit: (rule) => _showLevelForm(context, provider, rule),
                onDelete: (rule) => _deleteLevel(context, rule),
              ),
      ],
    );
  }

  Future<void> _install(
    BuildContext context,
    List<AdminGamificationRule> levels,
  ) async {
    final ok = await provider.installRules(levels);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Balanced level progression installed.'
              : provider.error ?? 'Could not save levels.',
        ),
      ),
    );
  }

  Future<void> _deleteLevel(
    BuildContext context,
    AdminGamificationRule rule,
  ) async {
    final ok = await showAdminConfirmDialog(
      context,
      title: 'Delete Level',
      message:
          'Remove Level ${rule.level}? This may create a gap in progression.',
    );
    if (ok && context.mounted) await provider.deleteRule(rule.id);
  }

  static const _defaultLevels = <AdminGamificationRule>[
    AdminGamificationRule(
      id: 'level_1',
      ruleType: 'level_threshold',
      description: 'Coding Beginner',
      level: 1,
      xpRequired: 0,
    ),
    AdminGamificationRule(
      id: 'level_2',
      ruleType: 'level_threshold',
      description: 'Coding Apprentice',
      level: 2,
      xpRequired: 60,
    ),
    AdminGamificationRule(
      id: 'level_3',
      ruleType: 'level_threshold',
      description: 'Logic Explorer',
      level: 3,
      xpRequired: 150,
    ),
    AdminGamificationRule(
      id: 'level_4',
      ruleType: 'level_threshold',
      description: 'Intermediate Coder',
      level: 4,
      xpRequired: 280,
    ),
    AdminGamificationRule(
      id: 'level_5',
      ruleType: 'level_threshold',
      description: 'Problem Solver',
      level: 5,
      xpRequired: 450,
    ),
    AdminGamificationRule(
      id: 'level_6',
      ruleType: 'level_threshold',
      description: 'Advanced Developer',
      level: 6,
      xpRequired: 680,
    ),
    AdminGamificationRule(
      id: 'level_7',
      ruleType: 'level_threshold',
      description: 'Code Architect',
      level: 7,
      xpRequired: 960,
    ),
    AdminGamificationRule(
      id: 'level_8',
      ruleType: 'level_threshold',
      description: 'Master Builder',
      level: 8,
      xpRequired: 1300,
    ),
    AdminGamificationRule(
      id: 'level_9',
      ruleType: 'level_threshold',
      description: 'Expert Programmer',
      level: 9,
      xpRequired: 1700,
    ),
    AdminGamificationRule(
      id: 'level_10',
      ruleType: 'level_threshold',
      description: 'Professional Programmer',
      level: 10,
      xpRequired: 2150,
    ),
  ];

  void _showLevelForm(
    BuildContext ctx,
    AdminGamificationProvider provider, [
    AdminGamificationRule? existing,
  ]) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _RuleFormDialog(ruleType: 'level_threshold', existing: existing),
      ),
    );
  }
}

// ── Badge Form Dialog ─────────────────────────────────────────────────────────

class _RuleOverviewPanel extends StatelessWidget {
  const _RuleOverviewPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actionLabel,
    required this.isSaving,
    required this.onAction,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? actionLabel;
  final bool isSaving;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: .2)),
    ),
    child: Wrap(
      spacing: 16,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF10213D),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          OutlinedButton.icon(
            onPressed: isSaving ? null : onAction,
            icon: isSaving
                ? const SizedBox.square(
                    dimension: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(actionLabel!),
          ),
      ],
    ),
  );
}

class _GamificationSetupEmpty extends StatelessWidget {
  const _GamificationSetupEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.isSaving,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(34),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD8E3F2)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFEAF2FF),
          child: Icon(icon, color: const Color(0xFF1747AA), size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: isSaving ? null : onPressed,
          icon: const Icon(Icons.rocket_launch_rounded),
          label: Text(buttonLabel),
        ),
      ],
    ),
  );
}

class _XpRuleCard extends StatelessWidget {
  const _XpRuleCard({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });
  final AdminGamificationRule rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final module = rule.targetModule ?? 'activity';
    final style = _moduleStyle(module);
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        height: 166,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [style.$2.withValues(alpha: .12), Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: style.$2.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(style.$1, color: style.$2),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3C7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${rule.xpAmount ?? 0} XP',
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit reward')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete reward'),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              rule.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${module[0].toUpperCase()}${module.substring(1)} activity',
              style: TextStyle(
                color: style.$2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelJourney extends StatelessWidget {
  const _LevelJourney({
    required this.levels,
    required this.onEdit,
    required this.onDelete,
  });
  final List<AdminGamificationRule> levels;
  final ValueChanged<AdminGamificationRule> onEdit;
  final ValueChanged<AdminGamificationRule> onDelete;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1100
          ? 5
          : constraints.maxWidth >= 720
          ? 3
          : constraints.maxWidth >= 460
          ? 2
          : 1;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: levels.asMap().entries.map((entry) {
          final rule = entry.value;
          final next = entry.key + 1 < levels.length
              ? levels[entry.key + 1].xpRequired
              : null;
          final accent = entry.key < 3
              ? const Color(0xFF16A34A)
              : entry.key < 6
              ? const Color(0xFF2563EB)
              : entry.key < 9
              ? const Color(0xFF7C3AED)
              : const Color(0xFFCA8A04);
          return SizedBox(
            width: width,
            child: Container(
              height: 190,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withValues(alpha: .25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        child: Text(
                          '${rule.level ?? 1}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            value == 'edit' ? onEdit(rule) : onDelete(rule),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit level'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete level'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    rule.description.isEmpty
                        ? 'Level ${rule.level ?? 1}'
                        : rule.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${rule.xpRequired ?? 0} XP required',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    next == null
                        ? 'Highest configured rank'
                        : '${next - (rule.xpRequired ?? 0)} XP to next level',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

(IconData, Color) _moduleStyle(String module) => switch (module) {
  'lesson' => (Icons.menu_book_rounded, const Color(0xFF7C3AED)),
  'simulation' => (Icons.terminal_rounded, const Color(0xFF0284C7)),
  'quiz' => (Icons.quiz_rounded, const Color(0xFFEA580C)),
  'puzzle' => (Icons.extension_rounded, const Color(0xFFDB2777)),
  'challenge' => (Icons.track_changes_rounded, const Color(0xFF16A34A)),
  _ => (Icons.auto_awesome_rounded, const Color(0xFF2563EB)),
};

class _BadgeFormDialog extends StatefulWidget {
  const _BadgeFormDialog({this.existing});
  final AdminBadge? existing;

  @override
  State<_BadgeFormDialog> createState() => _BadgeFormDialogState();
}

class _BadgeFormDialogState extends State<_BadgeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _criteriaCtrl;
  late final TextEditingController _milestoneCtrl;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _iconCtrl = TextEditingController(text: e?.iconName ?? 'award');
    _colorCtrl = TextEditingController(text: e?.accentHex ?? '#123D9B');
    _criteriaCtrl = TextEditingController(text: e?.criteria ?? '');
    _milestoneCtrl = TextEditingController(text: e?.milestoneLabel ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _iconCtrl,
      _colorCtrl,
      _criteriaCtrl,
      _milestoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminGamificationProvider>();
    final badge = AdminBadge(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      iconName: _iconCtrl.text.trim(),
      accentHex: _colorCtrl.text.trim(),
      criteria: _criteriaCtrl.text.trim(),
      milestoneLabel: _milestoneCtrl.text.trim(),
    );
    final ok = _isEdit
        ? await provider.updateBadge(badge)
        : await provider.createBadge(badge);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminGamificationProvider>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEdit ? 'Edit Badge' : 'New Badge'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _iconCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Icon Name (e.g. award)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _colorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Accent Hex (e.g. #1D4ED8)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _criteriaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Criteria (e.g. quiz_score_80)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _milestoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Milestone Label',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: provider.isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: provider.isSaving ? null : _submit,
          child: Text(_isEdit ? 'Save Changes' : 'Create Badge'),
        ),
      ],
    );
  }
}

// ── Rule Form Dialog ──────────────────────────────────────────────────────────

class _RuleFormDialog extends StatefulWidget {
  const _RuleFormDialog({required this.ruleType, this.existing});
  final String ruleType;
  final AdminGamificationRule? existing;

  @override
  State<_RuleFormDialog> createState() => _RuleFormDialogState();
}

class _RuleFormDialogState extends State<_RuleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _moduleCtrl;
  late final TextEditingController _xpCtrl;
  late final TextEditingController _levelCtrl;
  late final TextEditingController _xpRequiredCtrl;
  bool get _isEdit => widget.existing != null;
  bool get _isXpRule => widget.ruleType == 'xp_reward';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _moduleCtrl = TextEditingController(text: e?.targetModule ?? '');
    _xpCtrl = TextEditingController(text: '${e?.xpAmount ?? 20}');
    _levelCtrl = TextEditingController(text: '${e?.level ?? 1}');
    _xpRequiredCtrl = TextEditingController(text: '${e?.xpRequired ?? 100}');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _moduleCtrl.dispose();
    _xpCtrl.dispose();
    _levelCtrl.dispose();
    _xpRequiredCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AdminGamificationProvider>();
    final rule = AdminGamificationRule(
      id: widget.existing?.id ?? '',
      ruleType: widget.ruleType,
      description: _descCtrl.text.trim(),
      targetModule: _isXpRule ? _moduleCtrl.text.trim() : null,
      xpAmount: _isXpRule ? int.tryParse(_xpCtrl.text) : null,
      level: !_isXpRule ? int.tryParse(_levelCtrl.text) : null,
      xpRequired: !_isXpRule ? int.tryParse(_xpRequiredCtrl.text) : null,
    );
    final ok = await provider.saveRule(rule);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminGamificationProvider>();
    final title = _isXpRule
        ? (_isEdit ? 'Edit XP Rule' : 'New XP Rule')
        : (_isEdit ? 'Edit Level' : 'New Level Threshold');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_isXpRule) ...[
                TextFormField(
                  controller: _moduleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target Module (lesson/quiz/puzzle/simulation)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _xpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'XP Amount'),
                ),
              ] else ...[
                TextFormField(
                  controller: _levelCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Level Number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _xpRequiredCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'XP Required to Reach',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: provider.isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: provider.isSaving ? null : _submit,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
