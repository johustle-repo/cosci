import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/activity_gamification_card.dart';
import 'package:pseudocode_apk/features/gamification/presentation/widgets/reward_popup_dialog.dart';
import 'package:pseudocode_apk/providers/gamification_provider.dart';
import 'package:pseudocode_apk/providers/simulation_provider.dart';
import 'package:pseudocode_apk/services/compiler_service.dart';
import 'package:pseudocode_apk/services/code_simulation_service.dart';
import 'package:pseudocode_apk/models/code_simulation_activity.dart';
import 'package:pseudocode_apk/shared/widgets/app_scaffold.dart';

class CodeSimulationScreen extends StatefulWidget {
  const CodeSimulationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CodeSimulationScreen> createState() => _CodeSimulationScreenState();
}

class _CodeSimulationScreenState extends State<CodeSimulationScreen> {
  late final TextEditingController _controller;
  String _taskLanguage = 'All';
  String _taskDifficulty = 'All';

  String _languageGroup(CodeSimulationActivity activity) {
    final language = activity.language.trim().toLowerCase();
    if (language == 'java') return 'Java';
    if (language == 'javascript' || language == 'js') return 'JavaScript';
    return 'C++';
  }

  Future<void> _selectLanguageGroup(String language) async {
    final provider = context.read<SimulationProvider>();
    var effectiveLanguage = language;
    var matches = provider.activities.where((activity) {
      return (language == 'All' || _languageGroup(activity) == language) &&
          (_taskDifficulty == 'All' || activity.difficulty == _taskDifficulty);
    }).toList();

    if (matches.isEmpty && language != 'All') {
      effectiveLanguage = 'All';
      matches = provider.activities.where((activity) {
        return _taskDifficulty == 'All' ||
            activity.difficulty == _taskDifficulty;
      }).toList();
    }

    setState(() => _taskLanguage = effectiveLanguage);
    if (matches.isEmpty ||
        matches.any((item) => item.id == provider.selectedActivity?.id)) {
      return;
    }

    provider.selectActivity(matches.first);
    await provider.restoreDraft();
    if (!mounted) return;
    _controller.text = provider.sampleCode;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<SimulationProvider>();
    _controller = TextEditingController(text: provider.sampleCode);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SimulationProvider>().loadActivities();
      if (mounted) {
        _controller.text = context.read<SimulationProvider>().sampleCode;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markSimulationComplete() async {
    final activity = context.read<SimulationProvider>().selectedActivity;
    final reward = await context
        .read<GamificationProvider>()
        .completeSimulationLesson(
          lessonId: activity?.id ?? 'simulation-intro',
          title: activity?.title ?? 'Introduction to Co-Sci simulation',
        );

    if (!mounted) {
      return;
    }

    if (reward != null) {
      await RewardPopupDialog.show(context, reward);
      if (!mounted) {
        return;
      }
      context.read<GamificationProvider>().clearLatestReward();
      return;
    }

    final gamification = context.read<GamificationProvider>();
    final message = gamification.errorMessage ?? gamification.statusMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _runSimulation() async {
    await context.read<SimulationProvider>().runCode();
    if (!mounted) {
      return;
    }

    final provider = context.read<SimulationProvider>();
    final message = provider.lastRunSuccessful
        ? '${provider.selectedLanguage.label} compiled and ran. Submit to verify the solution logic.'
        : '${provider.selectedLanguage.label} simulation found an issue.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitActivity() async {
    final provider = context.read<SimulationProvider>();
    final isCorrect = await provider.submitSelectedActivity();
    if (!mounted) {
      return;
    }

    _controller.text = provider.sampleCode;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isCorrect
            ? const Color(0xFF166534)
            : const Color(0xFFB45309),
        content: Text(provider.activityFeedback ?? 'Task submitted.'),
      ),
    );

    if (isCorrect) {
      await _markSimulationComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final simulationProvider = context.watch<SimulationProvider>();
    final gamificationProvider = context.watch<GamificationProvider>();
    final selectedActivity = simulationProvider.selectedActivity;
    final visibleActivities = simulationProvider.activities.where((activity) {
      return (_taskLanguage == 'All' ||
              _languageGroup(activity) == _taskLanguage) &&
          (_taskDifficulty == 'All' || activity.difficulty == _taskDifficulty);
    }).toList();
    final languageCounts = <String, int>{
      for (final language in const ['C++', 'Java', 'JavaScript'])
        language: simulationProvider.activities
            .where(
              (activity) =>
                  _languageGroup(activity) == language &&
                  (_taskDifficulty == 'All' ||
                      activity.difficulty == _taskDifficulty),
            )
            .length,
    };
    final lineCount = _controller.text.split('\n').length.clamp(1, 999);

    final content = Padding(
      padding: AppScaffold.pagePadding(context),
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 18 : 22,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF071A3B),
                  Color(0xFF0D285A),
                  Color(0xFF123C81),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF123D9B).withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  child: const Text(
                    'Simulation IDE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Co-Sci Studio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.sizeOf(context).width < 600 ? 25 : 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Practice algorithm thinking in an IDE-style workspace. Run your Co-Sci, inspect the console output, and mark the lesson complete after meaningful progress.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroPill(
                      icon: Icons.flash_on_rounded,
                      label: 'Rewarded learning task',
                    ),
                    _HeroPill(
                      icon: Icons.play_circle_fill_rounded,
                      label: simulationProvider.isRunning ? 'Running' : 'Ready',
                    ),
                    _HeroPill(
                      icon: Icons.rule_rounded,
                      label: '$lineCount lines',
                    ),
                    _HeroPill(
                      icon: Icons.memory_rounded,
                      label: simulationProvider.selectedLanguage.statusLabel,
                    ),
                    _HeroPill(
                      icon:
                          simulationProvider.compilerHealth ==
                              CompilerHealth.online
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      label: switch (simulationProvider.compilerHealth) {
                        CompilerHealth.online => 'Compiler online',
                        CompilerHealth.offline => 'Compiler unavailable',
                        CompilerHealth.notConfigured =>
                          'Compiler setup required',
                        CompilerHealth.checking => 'Checking compiler',
                      },
                    ),
                    if (simulationProvider.feedbackNotificationCount > 0)
                      _HeroPill(
                        icon: Icons.notifications_active_rounded,
                        label:
                            '${simulationProvider.feedbackNotificationCount} instructor feedback update${simulationProvider.feedbackNotificationCount == 1 ? '' : 's'}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (simulationProvider.fromLesson) ...[
            Card(
              color: const Color(0xFFEFF6FF),
              child: ListTile(
                leading: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF1D4ED8),
                ),
                title: Text(
                  'Practicing from ${simulationProvider.lessonPracticeTitle ?? 'lesson'}',
                ),
                subtitle: const Text(
                  'Your lesson example is loaded in the editor.',
                ),
                trailing: TextButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to lesson'),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (simulationProvider.compilerHealth != CompilerHealth.online) ...[
            Card(
              color: const Color(0xFFFFF7ED),
              child: ListTile(
                leading: const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFB45309),
                ),
                title: Text(switch (simulationProvider.compilerHealth) {
                  CompilerHealth.notConfigured => 'Compiler setup required',
                  CompilerHealth.offline => 'Compiler service unavailable',
                  CompilerHealth.checking => 'Checking compiler service',
                  CompilerHealth.online => 'Compiler online',
                }),
                subtitle: const Text(
                  'You can still press Run Code to test the connection and see a specific recovery message. Submission becomes available after a successful compiler connection.',
                ),
                trailing: TextButton.icon(
                  onPressed:
                      simulationProvider.compilerHealth ==
                          CompilerHealth.checking
                      ? null
                      : () => context
                            .read<SimulationProvider>()
                            .refreshCompilerHealth(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: Color(0xFF123D9B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Simulation Activity',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (simulationProvider.isLoadingActivities)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (simulationProvider.activities.isEmpty)
                    Text(
                      simulationProvider.isLoadingActivities
                          ? 'Loading published simulation tasks...'
                          : 'No published simulation tasks with expected output are available yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final languages = _LanguageGroupSelector(
                          selected: _taskLanguage,
                          counts: languageCounts,
                          onSelected: _selectLanguageGroup,
                        );
                        final difficulty = _CompactFilter(
                          label: 'Difficulty',
                          value: _taskDifficulty,
                          values: const ['All', 'Easy', 'Medium', 'Hard'],
                          onChanged: (value) async {
                            setState(() => _taskDifficulty = value);
                            await _selectLanguageGroup(_taskLanguage);
                          },
                        );

                        if (constraints.maxWidth >= 760) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: languages),
                              const SizedBox(width: 20),
                              difficulty,
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            languages,
                            const SizedBox(height: 14),
                            difficulty,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue:
                          visibleActivities.any(
                            (activity) => activity.id == selectedActivity?.id,
                          )
                          ? selectedActivity?.id
                          : null,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      menuMaxHeight: 280,
                      itemHeight: null,
                      borderRadius: BorderRadius.circular(16),
                      selectedItemBuilder: (context) {
                        return visibleActivities.map((activity) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              activity.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Choose a task',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      items: visibleActivities.map((activity) {
                        return DropdownMenuItem<String>(
                          value: activity.id,
                          child: Container(
                            color: Colors.white,
                            constraints: const BoxConstraints(minHeight: 54),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              activity.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (id) async {
                        final provider = context.read<SimulationProvider>();
                        final matches = simulationProvider.activities.where(
                          (item) => item.id == id,
                        );
                        final activity = matches.isEmpty ? null : matches.first;
                        if (activity == null) {
                          return;
                        }
                        provider.selectActivity(activity);
                        await provider.restoreDraft();
                        if (!mounted) return;
                        _controller.text = provider.sampleCode;
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (selectedActivity != null) ...[
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: Color(0xFF123D9B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Selected simulation content',
                          style: TextStyle(
                            color: Color(0xFF123D9B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      selectedActivity.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedActivity.instructions,
                      style: Theme.of(context).textTheme.bodyMedium,
                      softWrap: true,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TaskPill(selectedActivity.language),
                        _TaskPill(selectedActivity.difficulty),
                        if (selectedActivity.topic.isNotEmpty)
                          _TaskPill(selectedActivity.topic),
                        _TaskPill('+${selectedActivity.xpReward} XP'),
                        _TaskPill(
                          '${selectedActivity.effectiveTestCases.length + selectedActivity.hiddenTestCount} test case${selectedActivity.effectiveTestCases.length + selectedActivity.hiddenTestCount == 1 ? '' : 's'}',
                          wide: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ActivityGamificationCard(
                      rewardXp: selectedActivity.xpReward,
                      requirement:
                          'Pass every test case and submit the task to earn the reward.',
                      completed: simulationProvider.lastSubmissionCorrect,
                    ),
                    if (simulationProvider.activityFeedback != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: simulationProvider.lastSubmissionCorrect
                              ? const Color(0xFFE8F7EE)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: simulationProvider.lastSubmissionCorrect
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFED7AA),
                          ),
                        ),
                        child: Text(
                          simulationProvider.activityFeedback!,
                          style: TextStyle(
                            color: simulationProvider.lastSubmissionCorrect
                                ? const Color(0xFF166534)
                                : const Color(0xFF9A3412),
                            fontWeight: FontWeight.w700,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                    if (selectedActivity.problemGoal.isNotEmpty ||
                        selectedActivity.algorithmSteps.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _AlgorithmPanel(activity: selectedActivity),
                    ],
                    if (selectedActivity.hints.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _HintsPanel(provider: simulationProvider),
                    ],
                    if (selectedActivity.executionSteps.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ExecutionTracePanel(
                        steps: selectedActivity.executionSteps,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF9FBFF), Color(0xFFF2F7FF)],
                      ),
                      border: Border.all(color: const Color(0xFFD9E6F6)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 720;

                        final languagePicker = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Programming Language',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Switch the editor template and runtime behavior.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFD5E4F8),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ProgrammingLanguage>(
                                  value: simulationProvider.selectedLanguage,
                                  isExpanded: true,
                                  borderRadius: BorderRadius.circular(18),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                  dropdownColor: Colors.white,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  items: ProgrammingLanguage.values.map((
                                    language,
                                  ) {
                                    return DropdownMenuItem<
                                      ProgrammingLanguage
                                    >(
                                      value: language,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: const Color(0xFFEAF2FF),
                                            ),
                                            child: Center(
                                              child: Text(
                                                language.label.substring(0, 1),
                                                style: const TextStyle(
                                                  color: Color(0xFF123D9B),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              language.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (language) {
                                    if (language == null) {
                                      return;
                                    }

                                    context
                                        .read<SimulationProvider>()
                                        .selectLanguage(language);
                                    _controller.text = context
                                        .read<SimulationProvider>()
                                        .sampleCode;
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        );

                        final actions = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              simulationProvider.draftSaved
                                  ? 'Draft saved securely to your account.'
                                  : 'Run, reset, or submit your solution.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  onPressed: simulationProvider.isRunning
                                      ? null
                                      : _runSimulation,
                                  icon: simulationProvider.isRunning
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.play_arrow_rounded),
                                  label: Text(
                                    simulationProvider.isRunning
                                        ? 'Running...'
                                        : 'Run Code',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Reset workspace?'),
                                        content: const Text(
                                          'Your current editor changes will be replaced by the starter code.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Reset'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true || !context.mounted) {
                                      return;
                                    }
                                    context
                                        .read<SimulationProvider>()
                                        .resetWorkspace();
                                    _controller.text = context
                                        .read<SimulationProvider>()
                                        .sampleCode;
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.restart_alt_rounded),
                                  label: const Text('Reset'),
                                ),
                                OutlinedButton.icon(
                                  onPressed:
                                      simulationProvider.consoleOutput.isEmpty
                                      ? null
                                      : () async {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text: simulationProvider
                                                  .consoleOutput,
                                            ),
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Console output copied.',
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text('Copy output'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed:
                                      gamificationProvider.isSubmitting ||
                                          simulationProvider.isRunning ||
                                          selectedActivity == null
                                      ? null
                                      : _submitActivity,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFEAF2FF),
                                    foregroundColor: const Color(0xFF123D9B),
                                  ),
                                  icon: const Icon(Icons.fact_check_rounded),
                                  label: const Text('Submit Task'),
                                ),
                              ],
                            ),
                          ],
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: languagePicker),
                              const SizedBox(width: 18),
                              Expanded(flex: 2, child: actions),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            languagePicker,
                            const SizedBox(height: 18),
                            actions,
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _EditorPanel(
                        controller: _controller,
                        selectedLanguage: simulationProvider.selectedLanguage,
                        onChanged: (value) {
                          context.read<SimulationProvider>().updateSampleCode(
                            value,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: _ConsolePanel(
                        output: simulationProvider.consoleOutput,
                        success: simulationProvider.lastRunSuccessful,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _EditorPanel(
                    controller: _controller,
                    selectedLanguage: simulationProvider.selectedLanguage,
                    onChanged: (value) {
                      context.read<SimulationProvider>().updateSampleCode(
                        value,
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  _ConsolePanel(
                    output: simulationProvider.consoleOutput,
                    success: simulationProvider.lastRunSuccessful,
                  ),
                ],
              );
            },
          ),
          if (simulationProvider.lastExecutionResult != null &&
              !simulationProvider.lastExecutionResult!.succeeded) ...[
            const SizedBox(height: 14),
            _DiagnosticCard(result: simulationProvider.lastExecutionResult!),
          ],
          if (simulationProvider.caseResults.isNotEmpty) ...[
            const SizedBox(height: 14),
            _TestResultsCard(results: simulationProvider.caseResults),
          ],
          if (simulationProvider.attemptHistory.isNotEmpty) ...[
            const SizedBox(height: 14),
            _MasteryPanel(mastery: simulationProvider.mastery),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Color(0xFF123D9B),
                ),
                title: const Text('Recommended next step'),
                subtitle: Text(
                  [
                    simulationProvider.masteryRecommendation,
                    if (simulationProvider.recommendedActivity != null)
                      'Recommended activity: ${simulationProvider.recommendedActivity!.title}',
                  ].join('\n'),
                ),
                trailing: simulationProvider.recommendedActivity == null
                    ? null
                    : TextButton(
                        onPressed: () {
                          final activity =
                              simulationProvider.recommendedActivity!;
                          context.read<SimulationProvider>().selectActivity(
                            activity,
                          );
                          _controller.text = activity.starterCode;
                          setState(() {});
                        },
                        child: const Text('Open'),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            _AttemptHistoryCard(attempts: simulationProvider.attemptHistory),
          ],
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return AppScaffold(
      title: 'Code Simulation',
      body: content,
      maxContentWidth: 1440,
    );
  }
}

class _MasteryPanel extends StatelessWidget {
  const _MasteryPanel({required this.mastery});
  final SimulationMastery mastery;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Simulation mastery summary',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your simulation mastery',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final metricWidth = constraints.maxWidth >= 260
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MasteryMetric(
                      width: metricWidth,
                      label: 'Syntax and runtime',
                      value: '${mastery.compilerRate}%',
                    ),
                    _MasteryMetric(
                      width: metricWidth,
                      label: 'Logic accuracy',
                      value: '${mastery.logicRate}%',
                    ),
                    _MasteryMetric(
                      width: metricWidth,
                      label: 'First-attempt success',
                      value: '${mastery.firstAttemptRate}%',
                    ),
                    _MasteryMetric(
                      width: metricWidth,
                      label: 'Attempts to pass',
                      value: mastery.averageAttemptsToPass.toStringAsFixed(1),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _MasteryMetric extends StatelessWidget {
  const _MasteryMetric({
    required this.label,
    required this.value,
    required this.width,
  });
  final String label;
  final String value;
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF123D9B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
        ),
      ],
    ),
  );
}

class _AttemptHistoryCard extends StatelessWidget {
  const _AttemptHistoryCard({required this.attempts});
  final List<SimulationAttemptSummary> attempts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your recent attempts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...attempts
                .take(5)
                .map(
                  (attempt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      attempt.passed
                          ? Icons.check_circle_rounded
                          : Icons.lightbulb_outline_rounded,
                      color: attempt.passed
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                    ),
                    title: Text(attempt.title),
                    subtitle: Text(
                      attempt.feedback.isEmpty
                          ? '${attempt.language} • ${attempt.passed ? 'Passed' : 'Keep improving'}'
                          : 'Instructor feedback: ${attempt.feedback}',
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CompactFilter extends StatelessWidget {
  const _CompactFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (item) {
        if (item != null) onChanged(item);
      },
    ),
  );
}

class _LanguageGroupSelector extends StatelessWidget {
  const _LanguageGroupSelector({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final String selected;
  final Map<String, int> counts;
  final Future<void> Function(String language) onSelected;

  @override
  Widget build(BuildContext context) {
    final groups = ['All', ...counts.keys];
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Browse by programming language',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groups.map((language) {
            final count = language == 'All' ? total : counts[language] ?? 0;
            return ChoiceChip(
              selected: selected == language,
              onSelected: count == 0 ? null : (_) => onSelected(language),
              avatar: Icon(
                language == 'All' ? Icons.apps_rounded : Icons.code_rounded,
                size: 17,
              ),
              label: Text('$language  $count'),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AlgorithmPanel extends StatelessWidget {
  const _AlgorithmPanel({required this.activity});
  final CodeSimulationActivity activity;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Understand the algorithm first',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        if (activity.problemGoal.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(activity.problemGoal),
        ],
        if (activity.inputsDescription.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Input: ${activity.inputsDescription}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        if (activity.algorithmSteps.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...activity.algorithmSteps.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${entry.key + 1}. ${entry.value}'),
            ),
          ),
        ],
        if (activity.keyConcepts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: activity.keyConcepts
                .map(
                  (concept) => Chip(
                    label: Text(concept),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
        if (activity.commonMistakes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Watch out: ${activity.commonMistakes}',
            style: const TextStyle(color: Color(0xFFB45309)),
          ),
        ],
      ],
    ),
  );
}

class _HintsPanel extends StatelessWidget {
  const _HintsPanel({required this.provider});
  final SimulationProvider provider;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Progressive hints',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Need a hint?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: provider.canRevealHint
                    ? provider.revealNextHint
                    : null,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: Text(
                  provider.revealedHintCount == 0 ? 'Reveal hint' : 'Next hint',
                ),
              ),
            ],
          ),
          ...provider.revealedHints.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Hint ${entry.key + 1}: ${entry.value}'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExecutionTracePanel extends StatefulWidget {
  const _ExecutionTracePanel({required this.steps});
  final List<ActivityExecutionStep> steps;
  @override
  State<_ExecutionTracePanel> createState() => _ExecutionTracePanelState();
}

class _ExecutionTracePanelState extends State<_ExecutionTracePanel> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final step = widget.steps[index.clamp(0, widget.steps.length - 1)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Execution trace • Step ${index + 1}/${widget.steps.length}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(step.description),
          if (step.variableStates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: step.variableStates.entries
                  .map(
                    (entry) =>
                        Chip(label: Text('${entry.key} = ${entry.value}')),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: index == 0 ? null : () => setState(() => index--),
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: index >= widget.steps.length - 1
                    ? null
                    : () => setState(() => index++),
                child: const Text('Next step'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard({required this.result});

  final ExecutionResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7ED),
      child: ListTile(
        leading: const Icon(
          Icons.my_location_rounded,
          color: Color(0xFFB45309),
        ),
        title: Text(result.categoryLabel),
        subtitle: Text(
          [
            if (result.line != null)
              'Location: line ${result.line}${result.column == null ? '' : ', column ${result.column}'}',
            result.learnerExplanation,
            'Next step: ${result.nextStep}',
          ].join('\n'),
        ),
      ),
    );
  }
}

class _TestResultsCard extends StatelessWidget {
  const _TestResultsCard({required this.results});

  final List<SimulationCaseResult> results;

  @override
  Widget build(BuildContext context) {
    final passed = results.where((result) => result.passed).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test results: $passed/${results.length} passed',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...results.asMap().entries.map((entry) {
              final result = entry.value;
              final hidden = result.testCase.isHidden;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  result.passed
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: result.passed
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB91C1C),
                ),
                title: Text(
                  hidden
                      ? 'Hidden test ${entry.key + 1}'
                      : result.testCase.name,
                ),
                subtitle: hidden
                    ? Text(
                        result.passed
                            ? 'Passed'
                            : 'Failed — review your algorithm for other inputs.',
                      )
                    : Text(
                        'Expected: ${result.testCase.expectedOutput}\nActual: ${result.execution.output.isEmpty ? '(no output)' : result.execution.output}',
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.controller,
    required this.selectedLanguage,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ProgrammingLanguage selectedLanguage;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final lines = controller.text.split('\n');
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1833),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF16386C)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF081324),
              borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
            ),
            child: Row(
              children: [
                const _WindowDot(color: Color(0xFFF87171)),
                const SizedBox(width: 8),
                const _WindowDot(color: Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                const _WindowDot(color: Color(0xFF34D399)),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: const Color(0xFF11284E),
                  ),
                  child: Text(
                    selectedLanguage.fileName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.code_rounded,
                  color: Color(0xFF78A8FF),
                  size: 18,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: SizedBox(
              height: compact ? 330 : 440,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 42,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lines.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.8),
                          child: Text(
                            '${index + 1}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF5E7BAE),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: Color(0xFFEAF2FF),
                        fontSize: 14,
                        height: 1.6,
                        fontFamily: 'monospace',
                      ),
                      cursorColor: const Color(0xFF56C4FF),
                      decoration: const InputDecoration(
                        hintText: 'Write code here...',
                        hintStyle: TextStyle(
                          color: Color(0xFF6F8BB8),
                          fontFamily: 'monospace',
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: false,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsolePanel extends StatelessWidget {
  const _ConsolePanel({required this.output, required this.success});

  final String output;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1730), Color(0xFF102245)],
        ),
        border: Border.all(color: const Color(0xFF193A74)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(27),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  success ? Icons.verified_rounded : Icons.terminal_rounded,
                  color: success
                      ? const Color(0xFF34D399)
                      : const Color(0xFF78A8FF),
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Console Output',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: compact ? 260 : 440),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF07101F),
                border: Border.all(color: const Color(0xFF17305A)),
              ),
              child: SelectableText(
                output,
                style: TextStyle(
                  color: success
                      ? const Color(0xFFDDFDEA)
                      : const Color(0xFFD9E6FF),
                  fontSize: 13.5,
                  height: 1.55,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPill extends StatelessWidget {
  const _TaskPill(this.label, {this.wide = false});

  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = wide
        ? (screenWidth < 520 ? screenWidth - 92 : 420.0)
        : (screenWidth < 360 ? screenWidth - 92 : 220.0);

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth < 120 ? 120 : maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD5E4FF)),
      ),
      child: Text(
        label,
        maxLines: wide ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF123D9B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WindowDot extends StatelessWidget {
  const _WindowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
