import 'package:flutter/material.dart';

class LoadingView extends StatefulWidget {
  const LoadingView({super.key, this.message = 'Preparing your workspace...'});

  final String message;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fade = Tween<double>(
      begin: .72,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scale = Tween<double>(begin: .97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06152E), Color(0xFF123D82), Color(0xFF0B6B71)],
            stops: [0, .66, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _SplashGridPainter()),
              ),
            ),
            Positioned(
              top: -120,
              right: -70,
              child: _GlowOrb(
                size: 330,
                color: const Color(0xFF60A5FA).withValues(alpha: .13),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -90,
              child: _GlowOrb(
                size: 370,
                color: const Color(0xFF2DD4BF).withValues(alpha: .12),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Semantics(
                      liveRegion: true,
                      label: widget.message,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: _fade,
                            child: ScaleTransition(
                              scale: _scale,
                              child: Container(
                                width: 132,
                                height: 132,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFDCEBFF)],
                                  ),
                                  borderRadius: BorderRadius.circular(36),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .8),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF60A5FA,
                                      ).withValues(alpha: .3),
                                      blurRadius: 42,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .24,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(29),
                                  child: Image.asset(
                                    'assets/images/cosci.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Learn • Code • Understand',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .7),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .13),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  widget.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 5,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: .12,
                                    ),
                                    color: const Color(0xFF67E8F9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 9,
                            runSpacing: 9,
                            alignment: WrapAlignment.center,
                            children: const [
                              _StatusPill(
                                icon: Icons.cloud_done_outlined,
                                text: 'Secure sync',
                              ),
                              _StatusPill(
                                icon: Icons.terminal_rounded,
                                text: 'Coding workspace',
                              ),
                              _StatusPill(
                                icon: Icons.school_outlined,
                                text: 'Learner focused',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF7DD3FC)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: 80)],
    ),
  );
}

class _SplashGridPainter extends CustomPainter {
  const _SplashGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .028)
      ..strokeWidth = 1;
    const gap = 48.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
