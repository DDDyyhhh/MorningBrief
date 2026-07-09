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
  await startApp();
}

Future<void> startApp({Future<AppDatabase> Function()? openCalendarDatabase}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final storage = await AppStorage.create();
  final moduleConfigProvider = ModuleConfigProvider(storage);
  await moduleConfigProvider.load();
  final calendarProvider = await _createCalendarProvider(openCalendarDatabase ?? AppDatabase.open);

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

Future<CalendarProvider> _createCalendarProvider(Future<AppDatabase> Function() openDatabase) async {
  try {
    final database = await openDatabase();
    final provider = CalendarProvider(SqliteCalendarService(database.database));
    await provider.loadToday();
    return provider;
  } catch (_) {
    final provider = CalendarProvider(MemoryCalendarService());
    await provider.loadToday();
    provider.setStorageError();
    return provider;
  }
}
