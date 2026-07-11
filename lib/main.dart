import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/api_client.dart';
import 'core/cache_manager.dart';
import 'core/constants.dart';
import 'core/database/app_database.dart';
import 'core/storage.dart';
import 'models/module_config.dart';
import 'modules/calendar/calendar_provider.dart';
import 'modules/calendar/calendar_service.dart';
import 'modules/news/news_provider.dart';
import 'modules/news/news_service.dart';
import 'modules/stocks/stocks_provider.dart';
import 'modules/stocks/stocks_service.dart';
import 'modules/tech_news/tech_news_provider.dart';
import 'modules/tech_news/tech_news_service.dart';
import 'modules/weather/weather_provider.dart';
import 'modules/weather/weather_service.dart';
import 'shared/module_config_provider.dart';

Future<void> main() async {
  await startApp();
}

Future<void> startApp({
  Future<AppDatabase> Function()? openCalendarDatabase,
  NewsRepository? newsRepository,
  StocksRepository? stocksRepository,
  TechNewsRepository? techNewsRepository,
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
  final newsProvider = NewsProvider(
    repository: newsRepository ?? NewsServiceRepository(NewsService(apiClient)),
    cache: cacheManager,
    feedsReader: () => AppConstants.generalNewsFeeds,
  );
  final stocksProvider = StocksProvider(
    repository:
        stocksRepository ?? StocksServiceRepository(StocksService(apiClient)),
    cache: cacheManager,
    symbolsReader: () => moduleConfigProvider.stockSymbols,
    apiKeyReader: () => moduleConfigProvider.stockApiKey,
  );
  final techNewsProvider = TechNewsProvider(
    repository:
        techNewsRepository ??
        TechNewsServiceRepository(
          TechNewsService(NewsServiceTechNewsSource(NewsService(apiClient))),
        ),
    cache: cacheManager,
  );
  var newsLoadStarted = false;
  void loadNewsIfEnabled() {
    if (newsLoadStarted ||
        !moduleConfigProvider.isEnabled(MorningModuleId.news)) {
      return;
    }
    newsLoadStarted = true;
    unawaited(_loadNewsSafely(newsProvider));
  }

  moduleConfigProvider.addListener(loadNewsIfEnabled);

  var techNewsLoadStarted = false;
  void loadTechNewsIfEnabled() {
    if (techNewsLoadStarted ||
        !moduleConfigProvider.isEnabled(MorningModuleId.techNews)) {
      return;
    }
    techNewsLoadStarted = true;
    unawaited(_loadTechNewsSafely(techNewsProvider));
  }

  moduleConfigProvider.addListener(loadTechNewsIfEnabled);

  String? lastScheduledStockConfiguration;
  void loadStocksIfEnabled() {
    if (!moduleConfigProvider.isEnabled(MorningModuleId.stocks)) {
      return;
    }
    final configurationFingerprint = _stocksConfigurationFingerprint(
      moduleConfigProvider,
    );
    if (configurationFingerprint == lastScheduledStockConfiguration) return;
    lastScheduledStockConfiguration = configurationFingerprint;
    unawaited(_loadStocksSafely(stocksProvider));
  }

  moduleConfigProvider.addListener(loadStocksIfEnabled);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: moduleConfigProvider),
        ChangeNotifierProvider.value(value: calendarProvider),
        ChangeNotifierProvider.value(value: weatherProvider),
        ChangeNotifierProvider.value(value: newsProvider),
        ChangeNotifierProvider.value(value: stocksProvider),
        ChangeNotifierProvider.value(value: techNewsProvider),
      ],
      child: const MorningBriefApp(),
    ),
  );
  loadNewsIfEnabled();
  loadTechNewsIfEnabled();
  loadStocksIfEnabled();
}

Future<void> _loadNewsSafely(NewsProvider provider) async {
  try {
    await provider.loadFromCacheOrRefresh();
  } catch (_) {
    // News loading must never block or fail application startup.
  }
}

Future<void> _loadStocksSafely(StocksProvider provider) async {
  try {
    await provider.loadFromCacheOrRefresh();
  } catch (_) {
    // Stock loading must never block or fail application startup.
  }
}

Future<void> _loadTechNewsSafely(TechNewsProvider provider) async {
  try {
    await provider.loadFromCacheOrRefresh();
  } catch (_) {
    // Tech/AI news loading must never block or fail application startup.
  }
}

String _stocksConfigurationFingerprint(ModuleConfigProvider provider) {
  final symbols = provider.stockSymbols
      .map((symbol) => symbol.trim())
      .where((symbol) => symbol.isNotEmpty);
  return '${provider.stockApiKey.trim()}\u0000${symbols.join('\u0000')}';
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
