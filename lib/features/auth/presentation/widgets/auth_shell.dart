import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerBadge = 'CoSci',
  });

  final String title;
  final String subtitle;
  final String headerBadge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 1050;
          final isCompact = width < 420;

          if (isMobile) {
            return _SoftCircleBackground(
              baseColor: const Color(0xFFF7FAFF),
              child: SafeArea(
                child: _buildMobileLayout(context, isCompact, colorScheme),
              ),
            );
          }

          return _buildDesktopLayout(context, colorScheme);
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    bool isCompact,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const _MobileBrand(),
              const SizedBox(height: 18),
              _buildAuthCard(
                context,
                colorScheme,
                padding: EdgeInsets.all(isCompact ? 22 : 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          flex: 9,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF07162F), Color(0xFF123D82)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _CodeGridPainter()),
                    ),
                  ),
                  _SoftCircleBackground(
                    baseColor: Colors.transparent,
                    circles: const [],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 40,
                      ),
                      child: _buildBrandPanel(context, isDark: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 11,
          child: _SoftCircleBackground(
            baseColor: const Color(0xFFF7FAFF),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 46,
                    vertical: 30,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 610),
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
                        padding: const EdgeInsets.all(39),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.97),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: _buildAuthPanel(
                          context,
                          colorScheme,
                          padding: EdgeInsets.zero,
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

  Widget _buildBrandPanel(BuildContext context, {bool isDark = false}) {
    final titleColor = isDark ? Colors.white : const Color(0xFF18469B);
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF53657E);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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
        Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
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
            const SizedBox(width: 18),
            Text(
              'CoSci',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: titleColor,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'A sharper way to learn, practice, and track code logic.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Academic coding workspace built for interactive lessons, coding challenges, quizzes, and progress tracking.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: bodyColor,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 34),
        const _MetricRow(),
        const SizedBox(height: 34),
        const _CodePreviewCard(),
      ],
    );
  }

  Widget _buildAuthCard(
    BuildContext context,
    ColorScheme colorScheme, {
    required EdgeInsets padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF9FBFF)],
        ),
        border: Border.all(color: const Color(0xFFD9E5F4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E3A8A).withValues(alpha: 0.12),
            blurRadius: 42,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: _buildAuthPanel(context, colorScheme, padding: EdgeInsets.zero),
      ),
    );
  }

  Widget _buildAuthPanel(
    BuildContext context,
    ColorScheme colorScheme, {
    required EdgeInsets padding,
  }) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFC9DBF8)),
            ),
            child: Text(
              headerBadge.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF18469B),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF18233A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF596B86),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFF0F6FF), Color(0xFFF0FDFA)],
              ),
              border: Border.all(color: const Color(0xFFCFE0F5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: colorScheme.primary.withValues(alpha: 0.10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF123D9B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your account, code drafts, and learning progress stay securely synced.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF53657E),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          child,
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

class _MetricRow extends StatelessWidget {
  const _MetricRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricPill(value: '3', label: 'learning modes'),
        _MetricPill(value: '24/7', label: 'progress sync'),
        _MetricPill(value: 'AI', label: 'content assist'),
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

class _CodePreviewCard extends StatelessWidget {
  const _CodePreviewCard();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF07152D).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ...const [
                    Color(0xFFFF6B6B),
                    Color(0xFFFFC857),
                    Color(0xFF42D392),
                  ].map(
                    (color) => Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 7),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'learning_workspace.cpp',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.10)),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.65,
                  ),
                  children: [
                    TextSpan(
                      text: '01  ',
                      style: TextStyle(color: Color(0xFF60769B)),
                    ),
                    TextSpan(
                      text: 'while ',
                      style: TextStyle(color: Color(0xFF7DD3FC)),
                    ),
                    TextSpan(
                      text: '(learning) {\n',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: '02    practice();\n',
                      style: TextStyle(color: Color(0xFFFDE68A)),
                    ),
                    TextSpan(
                      text: '03    understand();\n',
                      style: TextStyle(color: Color(0xFF86EFAC)),
                    ),
                    TextSpan(
                      text: '04  }',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileBrand extends StatelessWidget {
  const _MobileBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF123D9B).withValues(alpha: .14),
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset('assets/images/cosci.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CoSci',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Color(0xFF102A5E),
              ),
            ),
            Text(
              'Learn • Code • Grow',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CodeGridPainter extends CustomPainter {
  const _CodeGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const gap = 44.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
