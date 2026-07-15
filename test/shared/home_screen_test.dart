import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/storage.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/models/calendar_event.dart';
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
  int calls = 0;

  @override
  Future<WeatherModel> fetchWeather({
    required String city,
    required String apiKey,
  }) {
    calls++;
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
  int calls = 0;

  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async {
    calls++;
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
  int calls = 0;

  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    calls++;
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

class _HomeScreenCalendarService implements CalendarService {
  int todayCalls = 0;

  @override
  Future<CalendarEvent> createEvent(String title, DateTime startsAt) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(int id) {
    throw UnimplementedError();
  }

  @override
  Future<List<CalendarEvent>> todayEvents() async {
    todayCalls++;
    return [];
  }

  @override
  Future<void> toggleCompleted(int id, bool completed) {
    throw UnimplementedError();
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
      final calendarService = _HomeScreenCalendarService();
      final calendarProvider = CalendarProvider(calendarService);
      await calendarProvider.loadToday();
      final weatherRepository = _HomeScreenWeatherRepository();
      final weatherProvider = WeatherProvider(
        repository: weatherRepository,
        cache: MemoryCacheManager(),
        cityReader: () => 'Shanghai',
        apiKeyReader: () => 'test-key',
      );
      addTearDown(weatherProvider.dispose);
      final newsRepository = _HomeScreenNewsRepository();
      final newsProvider = NewsProvider(
        repository: newsRepository,
        cache: MemoryCacheManager(),
        feedsReader: () => [Uri.parse('https://example.com/news.xml')],
      );
      addTearDown(newsProvider.dispose);
      await newsProvider.refresh();
      final stocksRepository = _HomeScreenStocksRepository();
      final stocksProvider = StocksProvider(
        repository: stocksRepository,
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

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(weatherRepository.calls, 1);
      expect(newsRepository.calls, 2);
      expect(stocksRepository.calls, 2);
      expect(calendarService.todayCalls, 2);
      expect(
        find.text('\u5df2\u5237\u65b0\u6668\u95f4\u7b80\u62a5'),
        findsOneWidget,
      );

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

  testWidgets('HomeScreen has refresh and settings actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final provider = ModuleConfigProvider(storage);
    await provider.load();
    for (final config in provider.configs) {
      await provider.toggle(config.id, false);
    }

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
