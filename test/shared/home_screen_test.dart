import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/models/module_config.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/models/weather_model.dart';
import 'package:morningbrief/modules/news/news_provider.dart';
import 'package:morningbrief/modules/stocks/stocks_provider.dart';
import 'package:morningbrief/modules/weather/weather_provider.dart';
import 'package:morningbrief/shared/module_config_provider.dart';
import 'package:morningbrief/shared/screens/home_screen.dart';

class _HomeScreenWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) {
    return Future.value(
      WeatherModel(
        city: city,
        temperature: 0,
        feelsLike: 0,
        humidity: 0,
        windSpeed: 0,
        description: 'test',
        iconCode: '01d',
        forecast: const <WeatherForecast>[],
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
    );
  }
}

class _HomeScreenNewsRepository implements NewsRepository {
  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async {
    return [
      NewsArticle(
        title: '首页新闻',
        summary: '首页新闻摘要',
        source: '首页新闻来源',
        url: Uri.parse('https://example.com/home-news'),
        publishedAt: DateTime.utc(2026, 7, 10),
      ),
    ];
  }
}

class _HomeScreenStocksRepository implements StocksRepository {
  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    return [
      StockItem(
        symbol: 'AAPL',
        name: 'Apple',
        price: 123.45,
        change: 1.25,
        changePercent: 1.02,
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'HomeScreen shows greeting, enabled module placeholders, and updated time',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppStorage.create();
      final provider = ModuleConfigProvider(storage);
      await provider.load();
      await provider.toggle(MorningModuleId.techNews, false);
      final calendarProvider = CalendarProvider(MemoryCalendarService());
      await calendarProvider.loadToday();
      final weatherProvider = WeatherProvider(
        repository: _HomeScreenWeatherRepository(),
        cache: MemoryCacheManager(),
        cityReader: () => 'Shanghai',
        apiKeyReader: () => 'test-key',
      );
      addTearDown(weatherProvider.dispose);
      final newsProvider = NewsProvider(
        repository: _HomeScreenNewsRepository(),
        cache: MemoryCacheManager(),
        feedsReader: () => [Uri.parse('https://example.com/news.xml')],
      );
      addTearDown(newsProvider.dispose);
      await newsProvider.refresh();
      final stocksProvider = StocksProvider(
        repository: _HomeScreenStocksRepository(),
        cache: MemoryCacheManager(),
        symbolsReader: () => ['AAPL'],
        apiKeyReader: () => 'test-key',
      );
      addTearDown(stocksProvider.dispose);
      await stocksProvider.refresh();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: calendarProvider),
            ChangeNotifierProvider.value(value: weatherProvider),
            ChangeNotifierProvider.value(value: newsProvider),
            ChangeNotifierProvider.value(value: stocksProvider),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('\u80a1\u7968\u8d22\u7ecf'), findsOneWidget);
      expect(find.text('AAPL'), findsOneWidget);
      expect(find.text('123.45'), findsOneWidget);
      expect(find.text('\u6a21\u5757\u6b63\u5728\u52a0\u8f7d'), findsNothing);

      expect(find.text('早安！'), findsOneWidget);
      expect(find.text('天气'), findsOneWidget);
      expect(find.text('新闻头条'), findsOneWidget);
      expect(find.text('首页新闻'), findsOneWidget);
      expect(find.text('首页新闻来源'), findsOneWidget);
      expect(find.text('首页新闻摘要'), findsOneWidget);
      expect(find.text('日历与日程'), findsOneWidget);
      expect(find.textContaining('上次更新'), findsOneWidget);
    },
  );
}
