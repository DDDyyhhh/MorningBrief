import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/core/theme/colors.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/modules/stocks/stocks_card.dart';
import 'package:morningbrief/modules/stocks/stocks_provider.dart';
import 'package:provider/provider.dart';

class _FixedStocksRepository implements StocksRepository {
  _FixedStocksRepository(this.quotes);

  final List<StockItem> quotes;
  int calls = 0;

  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    calls++;
    return quotes;
  }
}

class _PendingStocksRepository implements StocksRepository {
  final completer = Completer<List<StockItem>>();

  @override
  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey) {
    return completer.future;
  }
}

class _ThrowingStocksRepository implements StocksRepository {
  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    throw StateError('network unavailable');
  }
}

class _RetryStocksRepository implements StocksRepository {
  int calls = 0;

  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    calls++;
    if (calls == 1) throw StateError('first request failed');
    return [_stock(symbol: 'AAPL', name: 'Apple')];
  }
}

StockItem _stock({
  String symbol = 'MSFT',
  String name = 'Microsoft',
  double price = 35.20,
  double change = 0.30,
  double changePercent = 0.86,
}) {
  return StockItem(
    symbol: symbol,
    name: name,
    price: price,
    change: change,
    changePercent: changePercent,
    updatedAt: DateTime(2026, 7, 11, 8),
  );
}

StocksProvider _provider({
  required StocksRepository repository,
  CacheManager? cache,
}) {
  return StocksProvider(
    repository: repository,
    cache: cache ?? MemoryCacheManager(),
    symbolsReader: () => ['MSFT'],
    apiKeyReader: () => 'key',
  );
}

Widget _stocksCard(StocksProvider provider) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider.value(
        value: provider,
        child: const StocksCard(),
      ),
    ),
  );
}

void main() {
  testWidgets('StocksCard renders title, icon, and empty copy while idle', (
    tester,
  ) async {
    final provider = _provider(repository: _FixedStocksRepository([]));
    addTearDown(provider.dispose);

    await tester.pumpWidget(_stocksCard(provider));

    expect(find.text('股票财经'), findsOneWidget);
    expect(find.byIcon(Icons.show_chart), findsOneWidget);
    expect(find.text('暂无行情'), findsOneWidget);
  });

  testWidgets('StocksCard renders loading while a fetch is pending', (
    tester,
  ) async {
    final repository = _PendingStocksRepository();
    final provider = _provider(repository: repository);
    addTearDown(provider.dispose);

    final refresh = provider.refresh();
    await tester.pumpWidget(_stocksCard(provider));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completer.complete([]);
    await refresh;
  });

  testWidgets('StocksCard renders empty copy for an empty response', (
    tester,
  ) async {
    final provider = _provider(repository: _FixedStocksRepository([]));
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_stocksCard(provider));

    expect(find.text('暂无行情'), findsOneWidget);
  });

  testWidgets('StocksCard renders an error and retries through the provider', (
    tester,
  ) async {
    final repository = _RetryStocksRepository();
    final provider = _provider(repository: repository);
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_stocksCard(provider));
    expect(find.text('股票行情加载失败'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pump();

    expect(repository.calls, 2);
    expect(find.text('AAPL'), findsOneWidget);
  });

  testWidgets('StocksCard marks stale cached quotes as offline', (
    tester,
  ) async {
    final cache = MemoryCacheManager();
    await cache.save(
      AppConstants.cacheStocks,
      jsonEncode([_stock(symbol: 'AAPL', name: 'Apple').toJson()]),
    );
    final provider = _provider(
      repository: _ThrowingStocksRepository(),
      cache: cache,
    );
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_stocksCard(provider));

    expect(find.text('离线'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);
  });

  testWidgets('StocksCard formats quote values and colors by direction', (
    tester,
  ) async {
    final provider = _provider(
      repository: _FixedStocksRepository([
        _stock(),
        _stock(
          symbol: 'AAPL',
          name: 'Apple',
          price: 35.2,
          change: -0.10,
          changePercent: -0.28,
        ),
        _stock(
          symbol: '000001',
          name: '平安银行',
          price: 12,
          change: 0,
          changePercent: 0,
        ),
      ]),
    );
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_stocksCard(provider));

    expect(find.text('Microsoft'), findsOneWidget);
    expect(find.text('35.20'), findsNWidgets(2));
    expect(find.text('12.00'), findsOneWidget);

    final positive = tester.widget<Text>(find.text('+0.30 (+0.86%)'));
    final negative = tester.widget<Text>(find.text('-0.10 (-0.28%)'));
    final unchanged = tester.widget<Text>(find.text('0.00 (0.00%)'));
    expect(positive.style?.color, AppColors.profitRed);
    expect(negative.style?.color, AppColors.lossGreen);
    expect(unchanged.style?.color, isNull);
  });

  testWidgets('StocksCard bounds every text field in a narrow quote row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const symbol = 'EXTREMELY-LONG-STOCK-SYMBOL-THAT-MUST-NOT-OVERFLOW';
    const name = 'A very long company name that must remain inside its column';
    final quote = _stock(
      symbol: symbol,
      name: name,
      price: 123456789012345.67,
      change: 123456789012.34,
      changePercent: 987654321.09,
    );
    final provider = _provider(repository: _FixedStocksRepository([quote]));
    addTearDown(provider.dispose);
    await provider.refresh();

    await tester.pumpWidget(_stocksCard(provider));

    final expectedTexts = [
      symbol,
      name,
      quote.price.toStringAsFixed(2),
      '+${quote.change.toStringAsFixed(2)} '
          '(+${quote.changePercent.toStringAsFixed(2)}%)',
    ];
    for (final value in expectedTexts) {
      final text = tester.widget<Text>(find.text(value));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    }
    expect(tester.takeException(), isNull);
  });
}
