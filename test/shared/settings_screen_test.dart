import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/shared/module_config_provider.dart';
import 'package:morningbrief/shared/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SettingsScreen shows module toggles and preference fields', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final provider = ModuleConfigProvider(storage);
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('模块管理'), findsOneWidget);
    expect(find.text('天气'), findsOneWidget);
    expect(find.text('城市'), findsOneWidget);
    expect(find.text('OpenWeatherMap API Key'), findsOneWidget);
    expect(find.text('Alpha Vantage API Key'), findsOneWidget);
  });

  testWidgets('SettingsScreen saves each preference on editing completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final provider = ModuleConfigProvider(storage);
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    final fields = tester.widgetList<TextField>(find.byType(TextField));

    expect(fields, hasLength(3));
    expect(fields.every((field) => field.onEditingComplete != null), isTrue);
    expect(fields.every((field) => field.onSubmitted != null), isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();

    final symbolsField = tester.widget<TextField>(find.byType(TextField).last);
    expect(symbolsField.onEditingComplete, isNotNull);
    expect(symbolsField.onSubmitted, isNotNull);
  });
}
