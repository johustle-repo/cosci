import 'package:flutter/material.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_sidebar.dart';
import 'package:pseudocode_apk/features/admin/presentation/layout/admin_topbar.dart';

/// Responsive root layout shared by every administration screen.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.pageTitle,
    required this.currentRoute,
    required this.child,
  });

  final String pageTitle;
  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: Colors.white,
          drawer: showSidebar
              ? null
              : Drawer(
                  width: 280,
                  child: AdminSidebar(currentRoute: currentRoute, width: 280),
                ),
          body: Row(
            children: [
              if (showSidebar) AdminSidebar(currentRoute: currentRoute),
              Expanded(
                child: Column(
                  children: [
                    Builder(
                      builder: (context) => AdminTopbar(
                        pageTitle: pageTitle,
                        onMenuPressed: showSidebar
                            ? null
                            : () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF8FAFF), Color(0xFFF1F6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Positioned(
                              right: -90,
                              top: -110,
                              child: _AmbientOrb(
                                size: 300,
                                color: Color(0x141D4ED8),
                              ),
                            ),
                            const Positioned(
                              left: -80,
                              bottom: -100,
                              child: _AmbientOrb(
                                size: 260,
                                color: Color(0x120EA5A4),
                              ),
                            ),
                            SafeArea(
                              top: false,
                              child: SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.fromLTRB(
                                  constraints.maxWidth < 600 ? 12 : 24,
                                  constraints.maxWidth < 600 ? 14 : 22,
                                  constraints.maxWidth < 600 ? 12 : 24,
                                  constraints.maxWidth < 600 ? 18 : 30,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1680,
                                    ),
                                    child: Theme(
                                      data: _adminTheme(context),
                                      child: TweenAnimationBuilder<double>(
                                        key: ValueKey(currentRoute),
                                        tween: Tween(begin: 0, end: 1),
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, content) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                8 * (1 - value),
                                              ),
                                              child: content,
                                            ),
                                          );
                                        },
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: child,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ThemeData _adminTheme(BuildContext context) {
    final base = Theme.of(context);
    const border = Color(0xFFD8E3F2);
    return base.copyWith(
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14173A67),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F8FD)),
        headingTextStyle: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: const TextStyle(color: Color(0xFF334155), fontSize: 13),
        dividerThickness: .8,
        horizontalMargin: 20,
        columnSpacing: 26,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: Colors.white.withValues(alpha: .92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0E3A8A),
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
