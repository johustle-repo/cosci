import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pseudocode_apk/shared/widgets/feature_card.dart';

void main() {
  testWidgets('FeatureCard renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeatureCard(
            title: 'Lessons',
            subtitle: 'Starter module',
            icon: Icons.menu_book_outlined,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Lessons'), findsOneWidget);
    expect(find.text('Starter module'), findsOneWidget);
  });
}
