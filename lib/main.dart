import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/api_client.dart';
import 'core/cache_manager.dart';
import 'core/database/app_database.dart';
import 'core/storage.dart';
import 'modules/calendar/calendar_provider.dart';
import 'modules/calendar/calendar_service.dart';
import 'modules/weather/weather_provider.dart';
import 'modules/weather/weather_service.dart';
import 'shared/module_config_provider.dart';

Future<void> main() async {
  await startApp();
}

Future<void> startApp({
  Future<AppDatabase> Function()? openCalendarDatabase,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final storage = await AppStorage.create();
  final moduleConfigProvider = ModuleConfigProvider(storage);
  await moduleConfigProvider.load();
  final database = await _openDatabaseOrNull(
    openCalendarDatabase ?? AppDatabase.open,
  );
  final calendarProvider = await _createCalendarProvider(database);
  final apiClient = ApiClient();
  final cacheManager = database == null
      ? MemoryCacheManager()
      : SqliteCacheManager(database.database);
  final weatherProvider = WeatherProvider(
    repository: WeatherServiceRepository(WeatherService(apiClient)),
    cache: cacheManager,
    cityReader: () => moduleConfigProvider.city,
    apiKeyReader: () => moduleConfigProvider.weatherApiKey,
  );
  await weatherProvider.loadFromCacheOrRefresh();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: moduleConfigProvider),
        ChangeNotifierProvider.value(value: calendarProvider),
        ChangeNotifierProvider.value(value: weatherProvider),
      ],
      child: const MorningBriefApp(),
    ),
  );
}

Future<AppDatabase?> _openDatabaseOrNull(
  Future<AppDatabase> Function() openDatabase,
) async {
  try {
    return await openDatabase();
  } catch (_) {
    return null;
  }
}

Future<CalendarProvider> _createCalendarProvider(AppDatabase? database) async {
  if (database == null) {
    final provider = CalendarProvider(MemoryCalendarService());
    await provider.loadToday();
    provider.setStorageError();
    return provider;
  }
  try {
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
