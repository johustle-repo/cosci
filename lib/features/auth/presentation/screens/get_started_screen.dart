import 'package:flutter/material.dart';
import 'package:pseudocode_apk/app/routes/app_routes.dart';
import 'package:pseudocode_apk/features/auth/services/onboarding_service.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  Future<void> _continue(BuildContext context, String route) async {
    await OnboardingService.markSeen();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(body: _buildDesktopLayout(context));
        }

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF081225),
                      Color(0xFF0B1C3D),
                      Color(0xFF102A5E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -80,
                right: -40,
                child: _HeroCircle(
                  size: 220,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Positioned(
                top: 60,
                right: 60,
                child: _HeroCircle(
                  size: 110,
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                top: 180,
                right: 20,
                child: _HeroCircle(
                  size: 56,
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.22),
                ),
              ),
              Positioned(
                left: 24,
                top: 110,
                child: _HeroCircle(
                  size: 72,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                left: -70,
                bottom: -100,
                child: _HeroCircle(
                  size: 260,
                  color: colorScheme.primary.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: 110,
                left: 40,
                child: _HeroCircle(
                  size: 94,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                bottom: 80,
                right: 36,
                child: _HeroCircle(
                  size: 78,
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Text(
                              'CoSci',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Learn Co-Sci with clarity, structure, and momentum.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'A focused academic workspace for lessons, simulation, quizzes, and progress tracking.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 16,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FeatureLine(
                                  title: 'Structured learning',
                                  subtitle:
                                      'Move through lessons, assessments, and coding tasks in one flow.',
                                ),
                                SizedBox(height: 14),
                                _FeatureLine(
                                  title: 'Focused practice',
                                  subtitle:
                                      'Work through Co-Sci challenges with less visual noise.',
                                ),
                                SizedBox(height: 14),
                                _FeatureLine(
                                  title: 'Visible progress',
                                  subtitle:
                                      'Track completion, streaks, and growth from a single dashboard.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                _continue(context, AppRoutes.register);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0B1C3D),
                              ),
                              child: const Text('Create my learner account'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                _continue(context, AppRoutes.login);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.24),
                                ),
                              ),
                              child: const Text('I already have an account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF081225),
                  Color(0xFF123D9B),
                  Color(0xFF0F766E),
                ],
                stops: [0.0, 0.68, 1.0],
              ),
            ),
            child: SafeArea(
              child: _SoftCircleBackground(
                baseColor: Colors.transparent,
                circles: const [
                  _SoftCircleSpec(
                    alignment: Alignment(-1.08, -0.82),
                    size: 220,
                    color: Color(0xFFBFD7FF),
                    opacity: 0.18,
                    blurRadius: 36,
                  ),
                  _SoftCircleSpec(
                    alignment: Alignment(1.12, -1.02),
                    size: 360,
                    color: Color(0xFFE3E9F8),
                    opacity: 0.16,
                    blurRadius: 24,
                  ),
                  _SoftCircleSpec(
                    alignment: Alignment(0.98, 0.92),
                    size: 120,
                    color: Color(0xFF8ED8F7),
                    opacity: 0.20,
                    blurRadius: 24,
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 76,
                    vertical: 60,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Text(
                          'Academic coding workspace',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/cosci.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'CoSci',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: const Text(
                          'A sharper way to learn, practice, and track code logic.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Text(
                          'Learn Co-Sci with clarity, structure, and momentum.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricPill(value: '3', label: 'learning modes'),
                          _MetricPill(value: '24/7', label: 'progress sync'),
                          // _MetricPill(value: 'AI', label: 'content assist'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: _SoftCircleBackground(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64,
                    vertical: 48,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2C66D6),
                            Color(0xFF14B8A6),
                            Color(0xFFB9D5FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(31),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF102A5E,
                            ).withValues(alpha: 0.10),
                            blurRadius: 36,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(38),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .97),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'YOUR CODING JOURNEY STARTS HERE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF18469B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Build confidence, one concept at a time.',
                              style: TextStyle(
                                color: Color(0xFF17233C),
                                fontSize: 25,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Learn the idea, test it in the compiler, and track your progress.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const _DesktopFeatureBlock(),
                            const SizedBox(height: 22),
                            const _JourneyStrip(),
                            const SizedBox(height: 26),
                            FilledButton.icon(
                              onPressed: () {
                                _continue(context, AppRoutes.register);
                              },
                              icon: const Icon(Icons.login_rounded),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              label: const Text('Create my learner account'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                _continue(context, AppRoutes.login);
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('I already have an account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF6C35B),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircleBackground extends StatelessWidget {
  const _SoftCircleBackground({
    required this.child,
    this.baseColor = const Color(0xFFF7FAFF),
    this.circles = const [
      _SoftCircleSpec(
        alignment: Alignment(-1.14, -0.62),
        size: 130,
        color: Color(0xFFBFD7FF),
        opacity: 0.22,
        blurRadius: 28,
      ),
      _SoftCircleSpec(
        alignment: Alignment(1.06, -1.04),
        size: 240,
        color: Color(0xFFDDE4F5),
        opacity: 0.36,
        blurRadius: 20,
      ),
      _SoftCircleSpec(
        alignment: Alignment(-0.98, 1.06),
        size: 220,
        color: Color(0xFFADC4F3),
        opacity: 0.26,
        blurRadius: 34,
      ),
      _SoftCircleSpec(
        alignment: Alignment(0.82, 0.78),
        size: 70,
        color: Color(0xFF9FDCF5),
        opacity: 0.32,
        blurRadius: 26,
      ),
    ],
  });

  final Widget child;
  final Color baseColor;
  final List<_SoftCircleSpec> circles;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: baseColor,
      child: Stack(
        children: [
          for (final circle in circles)
            Align(
              alignment: circle.alignment,
              child: IgnorePointer(
                child: SizedBox(
                  width: circle.size,
                  height: circle.size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circle.color.withValues(alpha: circle.opacity),
                      boxShadow: [
                        BoxShadow(
                          color: circle.color.withValues(
                            alpha: circle.opacity * 0.42,
                          ),
                          blurRadius: circle.blurRadius,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _SoftCircleSpec {
  const _SoftCircleSpec({
    required this.alignment,
    required this.size,
    required this.color,
    required this.opacity,
    required this.blurRadius,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double opacity;
  final double blurRadius;
}

class _DesktopFeatureBlock extends StatelessWidget {
  const _DesktopFeatureBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6F4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DesktopFeatureLine(
            icon: Icons.menu_book_rounded,
            title: 'Structured learning',
            subtitle:
                'Move through lessons, assessments, and coding tasks in one flow.',
          ),
          SizedBox(height: 18),
          _DesktopFeatureLine(
            icon: Icons.code_rounded,
            title: 'Focused practice',
            subtitle: 'Work through Co-Sci challenges with less visual noise.',
          ),
          SizedBox(height: 18),
          _DesktopFeatureLine(
            icon: Icons.analytics_rounded,
            title: 'Visible progress',
            subtitle:
                'Track completion, streaks, and growth from one dashboard.',
          ),
        ],
      ),
    );
  }
}

class _DesktopFeatureLine extends StatelessWidget {
  const _DesktopFeatureLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF18469B), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D2A44),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5F7088),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2A60), Color(0xFF174EA6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          _JourneyStep(icon: Icons.menu_book_rounded, label: 'Learn'),
          Expanded(child: Divider(color: Color(0xFF5E8FD8))),
          _JourneyStep(icon: Icons.terminal_rounded, label: 'Practice'),
          Expanded(child: Divider(color: Color(0xFF5E8FD8))),
          _JourneyStep(icon: Icons.insights_rounded, label: 'Master'),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF7DD3FC), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
