import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:morningbrief/core/app_error.dart';
import 'package:morningbrief/core/cache_manager.dart';
import 'package:morningbrief/core/constants.dart';
import 'package:morningbrief/models/stock_item.dart';
import 'package:morningbrief/modules/stocks/stocks_provider.dart';
import 'package:morningbrief/shared/module_state.dart';

class _FixedStocksRepository implements StocksRepository {
  _FixedStocksRepository([this.result = const <StockItem>[]]);

  final List<StockItem> result;
  int calls = 0;
  List<String>? receivedSymbols;
  String? receivedApiKey;

  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    calls++;
    receivedSymbols = List<String>.of(symbols);
    receivedApiKey = apiKey;
    return result;
  }
}

class _ThrowingStocksRepository implements StocksRepository {
  int calls = 0;

  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    calls++;
    throw StateError('network should not be called');
  }
}

class _ControllableCacheManager implements CacheManager {
  _ControllableCacheManager({
    this.freshValue,
    this.freshError,
    this.anyValue,
    this.anyError,
    this.saveError,
  });

  CachedValue? freshValue;
  Object? freshError;
  CachedValue? anyValue;
  Object? anyError;
  Object? saveError;
  int freshReads = 0;
  int anyReads = 0;
  int saveCalls = 0;
  String? freshKey;
  Duration? freshTtl;
  String? anyKey;
  String? savedKey;
  String? savedJson;

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    freshReads++;
    freshKey = key;
    freshTtl = ttl;
    if (freshError != null) throw freshError!;
    return freshValue;
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    anyReads++;
    anyKey = key;
    if (anyError != null) throw anyError!;
    return anyValue;
  }

  @override
  Future<void> save(String key, String jsonValue) async {
    saveCalls++;
    savedKey = key;
    savedJson = jsonValue;
    if (saveError != null) throw saveError!;
  }
}

StockItem _stock({String symbol = 'MSFT'}) {
  return StockItem(
    symbol: symbol,
    name: symbol,
    price: 451.23,
    change: 2.5,
    changePercent: 0.56,
    updatedAt: DateTime(2026, 7, 10, 8, 30),
  );
}

CachedValue _freshCache(String jsonValue) {
  return CachedValue(
    key: AppConstants.cacheStocks,
    jsonValue: jsonValue,
    savedAt: DateTime(2026, 7, 10, 8),
    isFresh: true,
  );
}

CachedValue _staleCache(String jsonValue) {
  return CachedValue(
    key: AppConstants.cacheStocks,
    jsonValue: jsonValue,
    savedAt: DateTime(2026, 7, 9, 8),
    isFresh: false,
  );
}

StocksProvider _provider({
  required StocksRepository repository,
  required CacheManager cache,
  List<String> Function()? symbolsReader,
  String Function()? apiKeyReader,
}) {
  return StocksProvider(
    repository: repository,
    cache: cache,
    symbolsReader: symbolsReader ?? () => ['MSFT'],
    apiKeyReader: apiKeyReader ?? () => 'key',
  );
}

void main() {
  test('StocksProvider starts idle', () {
    final provider = _provider(
      repository: _FixedStocksRepository(),
      cache: _ControllableCacheManager(),
    );
    addTearDown(provider.dispose);

    expect(provider.state.status, ModuleStatus.idle);
  });

  for (final useCacheLoader in [true, false]) {
    final methodName = useCacheLoader ? 'loadFromCacheOrRefresh' : 'refresh';

    test(
      '$methodName rejects a blank API key before cache or network',
      () async {
        final repository = _FixedStocksRepository([_stock()]);
        final cache = _ControllableCacheManager();
        final provider = _provider(
          repository: repository,
          cache: cache,
          apiKeyReader: () => '  \t ',
        );
        addTearDown(provider.dispose);

        if (useCacheLoader) {
          await provider.loadFromCacheOrRefresh();
        } else {
          await provider.refresh();
        }

        expect(provider.state.status, ModuleStatus.error);
        expect(provider.state.error?.type, AppErrorType.apiKeyMissing);
        expect(provider.state.error?.message, '请先在设置中填写 Alpha Vantage API Key');
        expect(repository.calls, 0);
        expect(cache.freshReads, 0);
        expect(cache.anyReads, 0);
      },
    );

    test(
      '$methodName rejects empty normalized symbols before cache or network',
      () async {
        final repository = _FixedStocksRepository([_stock()]);
        final cache = _ControllableCacheManager();
        final provider = _provider(
          repository: repository,
          cache: cache,
          symbolsReader: () => ['', '  ', '\t'],
        );
        addTearDown(provider.dispose);

        if (useCacheLoader) {
          await provider.loadFromCacheOrRefresh();
        } else {
          await provider.refresh();
        }

        expect(provider.state.status, ModuleStatus.empty);
        expect(repository.calls, 0);
        expect(cache.freshReads, 0);
        expect(cache.anyReads, 0);
      },
    );
  }

  test('StocksProvider passes trimmed configuration to repository', () async {
    final repository = _FixedStocksRepository([_stock()]);
    final provider = _provider(
      repository: repository,
      cache: _ControllableCacheManager(),
      symbolsReader: () => [' MSFT ', '', '  ', '\tAAPL\t'],
      apiKeyReader: () => '  secret-key  ',
    );
    addTearDown(provider.dispose);

    await provider.refresh();

    expect(repository.receivedSymbols, ['MSFT', 'AAPL']);
    expect(repository.receivedApiKey, 'secret-key');
  });

  test(
    'StocksProvider exposes successful data and serializes its cache',
    () async {
      final quotes = [_stock(), _stock(symbol: 'AAPL')];
      final repository = _FixedStocksRepository(quotes);
      final cache = _ControllableCacheManager();
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(provider.state.data, same(quotes));
      expect(cache.saveCalls, 1);
      expect(cache.savedKey, AppConstants.cacheStocks);
      final decoded = jsonDecode(cache.savedJson!) as List<dynamic>;
      final cachedQuotes = decoded
          .map((value) => StockItem.fromJson(value as Map<String, dynamic>))
          .toList();
      expect(cachedQuotes.map((quote) => quote.symbol), ['MSFT', 'AAPL']);
      expect(cachedQuotes.first.updatedAt, quotes.first.updatedAt);
    },
  );

  test(
    'StocksProvider exposes empty network result without saving cache',
    () async {
      final repository = _FixedStocksRepository();
      final cache = _ControllableCacheManager();
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.state.status, ModuleStatus.empty);
      expect(repository.calls, 1);
      expect(cache.saveCalls, 0);
    },
  );

  test(
    'StocksProvider uses a 15-minute fresh cache without fetching',
    () async {
      final cachedQuote = _stock();
      final repository = _ThrowingStocksRepository();
      final cache = _ControllableCacheManager(
        freshValue: _freshCache(jsonEncode([cachedQuote.toJson()])),
      );
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.loadFromCacheOrRefresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(provider.state.data?.single.symbol, cachedQuote.symbol);
      expect(repository.calls, 0);
      expect(cache.freshReads, 1);
      expect(cache.freshKey, AppConstants.cacheStocks);
      expect(cache.freshTtl, const Duration(minutes: 15));
      expect(cache.anyReads, 0);
    },
  );

  final invalidFreshCaches = <String, String>{
    'missing cache': '',
    'malformed JSON': 'not valid JSON',
    'wrong JSON shape': '{}',
    'invalid stock item': '[{"symbol": 1}]',
    'decoded empty list': '[]',
  };

  for (final invalidCache in invalidFreshCaches.entries) {
    test('StocksProvider treats ${invalidCache.key} as a cache miss', () async {
      final repository = _FixedStocksRepository([_stock()]);
      final cache = _ControllableCacheManager(
        freshValue: invalidCache.key == 'missing cache'
            ? null
            : _freshCache(invalidCache.value),
      );
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);

      await provider.loadFromCacheOrRefresh();

      expect(provider.state.status, ModuleStatus.data);
      expect(repository.calls, 1);
      expect(cache.freshReads, 1);
    });
  }

  test('StocksProvider treats an unreadable fresh cache as a miss', () async {
    final repository = _FixedStocksRepository([_stock()]);
    final cache = _ControllableCacheManager(
      freshError: StateError('cache unavailable'),
    );
    final provider = _provider(repository: repository, cache: cache);
    addTearDown(provider.dispose);

    await provider.loadFromCacheOrRefresh();

    expect(provider.state.status, ModuleStatus.data);
    expect(repository.calls, 1);
    expect(cache.freshReads, 1);
  });

  test(
    'StocksProvider notifies loading and successful data transitions',
    () async {
      final repository = _FixedStocksRepository([_stock()]);
      final provider = _provider(
        repository: repository,
        cache: _ControllableCacheManager(),
      );
      addTearDown(provider.dispose);
      final statuses = <ModuleStatus>[];
      provider.addListener(() => statuses.add(provider.state.status));

      await provider.refresh();

      expect(statuses, [ModuleStatus.loading, ModuleStatus.data]);
    },
  );

  test(
    'StocksProvider uses readable stale cache when repository fails',
    () async {
      final cachedQuote = _stock(symbol: 'AAPL');
      final repository = _ThrowingStocksRepository();
      final cache = _ControllableCacheManager(
        anyValue: _staleCache(jsonEncode([cachedQuote.toJson()])),
      );
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);
      final statuses = <ModuleStatus>[];
      provider.addListener(() => statuses.add(provider.state.status));

      await expectLater(provider.refresh(), completes);

      expect(provider.state.status, ModuleStatus.offline);
      expect(provider.state.data?.single.symbol, 'AAPL');
      expect(repository.calls, 1);
      expect(cache.anyReads, 1);
      expect(cache.anyKey, AppConstants.cacheStocks);
      expect(statuses, [ModuleStatus.loading, ModuleStatus.offline]);
    },
  );

  test(
    'StocksProvider shows standard error when repository fails without cache',
    () async {
      final repository = _ThrowingStocksRepository();
      final cache = _ControllableCacheManager();
      final provider = _provider(repository: repository, cache: cache);
      addTearDown(provider.dispose);
      final statuses = <ModuleStatus>[];
      provider.addListener(() => statuses.add(provider.state.status));

      await expectLater(provider.refresh(), completes);

      expect(provider.state.status, ModuleStatus.error);
      expect(provider.state.error?.type, AppErrorType.network);
      expect(provider.state.error?.message, '股票行情加载失败');
      expect(cache.anyReads, 1);
      expect(statuses, [ModuleStatus.loading, ModuleStatus.error]);
    },
  );

  final unusableStaleCaches = <String, String?>{
    'missing stale cache': null,
    'malformed stale JSON': 'not valid JSON',
    'wrong stale JSON shape': '{}',
    'invalid stale stock item': '[{"symbol": 1}]',
    'empty stale list': '[]',
  };

  for (final invalidCache in unusableStaleCaches.entries) {
    test(
      'StocksProvider treats ${invalidCache.key} as unavailable after failure',
      () async {
        final cache = _ControllableCacheManager(
          anyValue: invalidCache.value == null
              ? null
              : _staleCache(invalidCache.value!),
        );
        final provider = _provider(
          repository: _ThrowingStocksRepository(),
          cache: cache,
        );
        addTearDown(provider.dispose);

        await expectLater(provider.refresh(), completes);

        expect(provider.state.status, ModuleStatus.error);
        expect(provider.state.error?.type, AppErrorType.network);
        expect(provider.state.error?.message, '股票行情加载失败');
        expect(cache.anyReads, 1);
      },
    );
  }

  test(
    'StocksProvider treats stale cache read exceptions as unavailable',
    () async {
      final cache = _ControllableCacheManager(
        anyError: StateError('cache unavailable'),
      );
      final provider = _provider(
        repository: _ThrowingStocksRepository(),
        cache: cache,
      );
      addTearDown(provider.dispose);

      await expectLater(provider.refresh(), completes);

      expect(provider.state.status, ModuleStatus.error);
      expect(provider.state.error?.type, AppErrorType.network);
      expect(provider.state.error?.message, '股票行情加载失败');
      expect(cache.anyReads, 1);
    },
  );

  test('StocksProvider keeps fetched quotes when cache save fails', () async {
    final quotes = [_stock(), _stock(symbol: 'AAPL')];
    final cache = _ControllableCacheManager(saveError: StateError('disk full'));
    final provider = _provider(
      repository: _FixedStocksRepository(quotes),
      cache: cache,
    );
    addTearDown(provider.dispose);

    await expectLater(provider.refresh(), completes);

    expect(provider.state.status, ModuleStatus.data);
    expect(provider.state.data, same(quotes));
    expect(cache.saveCalls, 1);
    expect(cache.anyReads, 0);
  });

  test('StocksProvider uses stale cache when api key reader throws', () async {
    final cachedQuote = _stock(symbol: 'AAPL');
    final repository = _FixedStocksRepository([_stock()]);
    final cache = _ControllableCacheManager(
      anyValue: _staleCache(jsonEncode([cachedQuote.toJson()])),
    );
    final provider = _provider(
      repository: repository,
      cache: cache,
      apiKeyReader: () => throw StateError('settings unavailable'),
    );
    addTearDown(provider.dispose);

    await expectLater(provider.loadFromCacheOrRefresh(), completes);

    expect(provider.state.status, ModuleStatus.offline);
    expect(provider.state.data?.single.symbol, 'AAPL');
    expect(repository.calls, 0);
    expect(cache.freshReads, 0);
    expect(cache.anyReads, 1);
  });

  test(
    'StocksProvider shows standard error when symbols reader throws',
    () async {
      final repository = _FixedStocksRepository([_stock()]);
      final cache = _ControllableCacheManager();
      final provider = _provider(
        repository: repository,
        cache: cache,
        symbolsReader: () => throw StateError('settings unavailable'),
      );
      addTearDown(provider.dispose);

      await expectLater(provider.refresh(), completes);

      expect(provider.state.status, ModuleStatus.error);
      expect(provider.state.error?.type, AppErrorType.network);
      expect(provider.state.error?.message, '股票行情加载失败');
      expect(repository.calls, 0);
      expect(cache.anyReads, 1);
    },
  );
}
