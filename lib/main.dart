import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/database/app_database.dart';
import 'core/storage.dart';
import 'modules/calendar/calendar_provider.dart';
import 'modules/calendar/calendar_service.dart';
import 'shared/module_config_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final storage = await AppStorage.create();
  final database = await AppDatabase.open();
  final moduleConfigProvider = ModuleConfigProvider(storage);
  await moduleConfigProvider.load();
  final calendarProvider = CalendarProvider(SqliteCalendarService(database.database));
  await calendarProvider.loadToday();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: moduleConfigProvider),
        ChangeNotifierProvider.value(value: calendarProvider),
      ],
      child: const MorningBriefApp(),
    ),
  );
}
