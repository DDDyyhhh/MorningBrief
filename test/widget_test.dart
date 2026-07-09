import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/app.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/shared/module_config_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MorningBrief app shows Chinese dashboard title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final provider = ModuleConfigProvider(storage);
    await provider.load();
    final calendarProvider = CalendarProvider(MemoryCalendarService());
    await calendarProvider.loadToday();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: calendarProvider),
        ],
        child: const MorningBriefApp(),
      ),
    );

    expect(find.text('MorningBrief'), findsOneWidget);
    expect(find.text('早安！'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
