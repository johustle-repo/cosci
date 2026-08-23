import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_audience_selector.dart';
import 'package:pseudocode_apk/features/admin/presentation/widgets/admin_section_header.dart';

void main() {
  testWidgets(
    'audience selector remains usable on a narrow high-text-scale screen',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminAudienceSelector(
                programs: const {},
                years: const {},
                onProgramsChanged: (_) {},
                onYearsChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel(RegExp('Learner audience selection')),
        findsOneWidget,
      );
      expect(find.text('BS Computer Science'), findsOneWidget);
      expect(find.text('2nd Year'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('admin section actions stack safely on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSectionHeader(
            title: 'Daily Challenge Management',
            actionLabel: 'New Challenge',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Daily Challenge Management'), findsOneWidget);
  });
}
