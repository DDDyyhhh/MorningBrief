import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/app.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/models/weather_model.dart';
import 'package:morningbrief/modules/news/news_provider.dart';
import 'package:morningbrief/modules/stocks/stocks_provider.dart';
import 'package:morningbrief/modules/tech_news/tech_news_provider.dart';
import 'package:morningbrief/modules/weather/weather_provider.dart';
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
    final weatherProvider = WeatherProvider(
      repository: _UnusedWeatherRepository(),
      cache: MemoryCacheManager(),
      cityReader: () => provider.city,
      apiKeyReader: () => provider.weatherApiKey,
    );
    addTearDown(weatherProvider.dispose);
    await weatherProvider.refresh();
    final newsProvider = NewsProvider(
      repository: _UnusedNewsRepository(),
      cache: MemoryCacheManager(),
      feedsReader: () => const <Uri>[],
    );
    addTearDown(newsProvider.dispose);
    final stocksProvider = StocksProvider(
      repository: _UnusedStocksRepository(),
      cache: MemoryCacheManager(),
      symbolsReader: () => const <String>[],
      apiKeyReader: () => '',
    );
    addTearDown(stocksProvider.dispose);
    final techNewsProvider = TechNewsProvider(
      repository: _UnusedTechNewsRepository(),
      cache: MemoryCacheManager(),
    );
    addTearDown(techNewsProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: calendarProvider),
          ChangeNotifierProvider.value(value: weatherProvider),
          ChangeNotifierProvider.value(value: newsProvider),
          ChangeNotifierProvider.value(value: stocksProvider),
          ChangeNotifierProvider.value(value: techNewsProvider),
        ],
        child: const MorningBriefApp(),
      ),
    );

    expect(find.text('MorningBrief'), findsOneWidget);
    expect(find.text('早安！'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('科技 AI 新闻'), findsOneWidget);
  });
}

class _UnusedWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) {
    throw UnimplementedError('Weather fetch should not run without API key');
  }
}

class _UnusedNewsRepository implements NewsRepository {
  @override
  Future<List<NewsArticle>> fetchArticles(List<Uri> feeds, {int limit = 10}) {
    throw UnimplementedError('News fetch should not run in this widget test');
  }
}

class _UnusedStocksRepository implements StocksRepository {
  @override
  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey) {
    throw UnimplementedError('Stock fetch should not run in this widget test');
  }
}

class _UnusedTechNewsRepository implements TechNewsRepository {
  @override
  Future<List<NewsArticle>> fetchArticles({int limit = 8}) {
    throw UnimplementedError(
      'Tech/AI news fetch should not run in this widget test',
    );
  }
}
