import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/main.dart' as app_main;
import 'package:morningbrief/models/calendar_event.dart';
import 'package:morningbrief/models/news_article.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/modules/calendar/calendar_provider.dart';
import 'package:morningbrief/modules/calendar/calendar_service.dart';
import 'package:morningbrief/modules/news/news_provider.dart';
import 'package:morningbrief/modules/stocks/stocks_provider.dart';
import 'package:morningbrief/shared/module_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app startup renders even when calendar database initialization fails',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.stockApiKey: 'test-key',
      });
      final stocksRepository = _CountingStocksRepository();
      await app_main.startApp(
        openCalendarDatabase: () async => throw StateError('database corrupt'),
        newsRepository: _EmptyNewsRepository(),
        stocksRepository: stocksRepository,
      );
      await tester.pump();

      expect(stocksRepository.calls, 1);

      expect(find.text('MorningBrief'), findsOneWidget);
      expect(find.text('日历与日程'), findsOneWidget);
      expect(find.text('日程读取失败'), findsOneWidget);
    },
  );

  test('CalendarProvider loads today events and toggles completion', () async {
    final service = MemoryCalendarService(now: () => DateTime(2026, 7, 7, 8));
    final provider = CalendarProvider(service);

    await provider.addEvent('写晨报', DateTime(2026, 7, 7, 9));

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data!.single.title, '写晨报');

    await provider.toggleCompleted(provider.state.data!.single.id!, true);

    expect(provider.state.data!.single.isCompleted, true);
  });

  test('addEvent converts service failure to module error state without throwing', () async {
    final provider = CalendarProvider(_ThrowingCalendarService(createThrows: true));

    await expectLater(provider.addEvent('写晨报', DateTime(2026, 7, 7, 9)), completes);

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error?.message, '日程保存失败');
  });

  test('toggleCompleted converts service failure to module error state without throwing', () async {
    final provider = CalendarProvider(_ThrowingCalendarService(toggleThrows: true));

    await expectLater(provider.toggleCompleted(1, true), completes);

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error?.message, '日程保存失败');
  });

  test('deleteEvent converts service failure to module error state without throwing', () async {
    final provider = CalendarProvider(_ThrowingCalendarService(deleteThrows: true));

    await expectLater(provider.deleteEvent(1), completes);

    expect(provider.state.status, ModuleStatus.error);
    expect(provider.state.error?.message, '日程保存失败');
  });
}

class _EmptyNewsRepository implements NewsRepository {
  @override
  Future<List<NewsArticle>> fetchArticles(
    List<Uri> feeds, {
    int limit = 10,
  }) async => [];
}

class _CountingStocksRepository implements StocksRepository {
  int calls = 0;

  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    calls++;
    return [];
  }
}

class _ThrowingCalendarService implements CalendarService {
  _ThrowingCalendarService({
    this.createThrows = false,
    this.toggleThrows = false,
    this.deleteThrows = false,
  });

  final bool createThrows;
  final bool toggleThrows;
  final bool deleteThrows;

  @override
  Future<CalendarEvent> createEvent(String title, DateTime startsAt) async {
    if (createThrows) throw StateError('write failed');
    return CalendarEvent(
      id: 1,
      title: title,
      startsAt: startsAt,
      isCompleted: false,
      createdAt: DateTime(2026, 7, 7, 8),
    );
  }

  @override
  Future<List<CalendarEvent>> todayEvents() async => const [];

  @override
  Future<void> toggleCompleted(int id, bool completed) async {
    if (toggleThrows) throw StateError('update failed');
  }

  @override
  Future<void> deleteEvent(int id) async {
    if (deleteThrows) throw StateError('delete failed');
  }
}
