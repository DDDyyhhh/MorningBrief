import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/app.dart';

void main() {
  testWidgets('MorningBrief app shows Chinese dashboard title', (tester) async {
    await tester.pumpWidget(const MorningBriefApp());

    expect(find.text('MorningBrief'), findsOneWidget);
    expect(find.text('早安！'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
