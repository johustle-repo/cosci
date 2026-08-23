import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudocode_apk/providers/auth_provider.dart';
import 'package:pseudocode_apk/shared/widgets/app_drawer.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.actions,
    this.maxContentWidth = 1280,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final double maxContentWidth;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return const EdgeInsets.all(12);
    if (width < 1024) return const EdgeInsets.all(18);
    return const EdgeInsets.all(24);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentUser?.normalizedRole;
    final workspaceLabel = switch (role) {
      'instructor' => 'CoSci teaching workspace',
      'admin' => 'CoSci administration workspace',
      _ => 'CoSci learner workspace',
    };
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useDesktopNavigation = screenWidth >= 1100;
    final isPhone = screenWidth < 600;
    final page = Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7FAFF), Color(0xFFF1F6FF)],
            ),
          ),
        ),
        Positioned(
          top: -110,
          right: -38,
          child: _AmbientCircle(
            size: 220,
            color: const Color(0xFF123D9B).withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          left: -90,
          bottom: -120,
          child: _AmbientCircle(
            size: 240,
            color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
          ),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: body,
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: useDesktopNavigation
          ? null
          : AppBar(
              toolbarHeight: isPhone ? 60 : 72,
              backgroundColor: Colors.white.withValues(alpha: 0.96),
              surfaceTintColor: Colors.transparent,
              shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              title: Row(
                children: [
                  if (!isPhone) ...[
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD6E2F2)),
                      ),
                      child: Image.asset('assets/images/cosci.png'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!isPhone)
                          Text(
                            workspaceLabel,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: actions,
              scrolledUnderElevation: 0,
              leadingWidth: isPhone ? 58 : 66,
              leading: Builder(
                builder: (context) => Padding(
                  padding: EdgeInsets.only(left: isPhone ? 8 : 14),
                  child: IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF0F2857),
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
              ),
              automaticallyImplyLeading: false,
            ),
      drawer: useDesktopNavigation ? null : const AppDrawer(),
      body: useDesktopNavigation
          ? Row(
              children: [
                const SizedBox(width: 264, child: AppDrawer(embedded: true)),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopPageHeader(
                        title: title,
                        subtitle: workspaceLabel,
                        actions: actions,
                      ),
                      Expanded(child: page),
                    ],
                  ),
                ),
              ],
            )
          : page,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _DesktopPageHeader extends StatelessWidget {
  const _DesktopPageHeader({
    required this.title,
    required this.subtitle,
    this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD6E2F2)),
            ),
            child: Image.asset('assets/images/cosci.png'),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle({required this.size, required this.color});

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
