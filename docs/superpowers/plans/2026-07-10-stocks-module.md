# Stocks Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a resilient Alpha Vantage stocks module with 15-minute caching, partial-success quote loading, Chinese-market colors, and non-blocking application integration.

**Architecture:** `StocksService` performs sequential, failure-isolated `GLOBAL_QUOTE` requests; `StocksProvider` validates configuration and owns cache/state transitions; `StocksCard` renders state only. `main.dart` injects the provider and starts its initial load after `runApp`, using the same exactly-once enablement lifecycle as news.

**Tech Stack:** Flutter 3.44+, Dart 3.12+, Provider, `http`/`MockClient`, shared `ApiClient`, shared `CacheManager`, `flutter_test`.

---

## File Structure

- Create `lib/modules/stocks/stocks_service.dart`: Alpha Vantage request orchestration, response classification, and `StockItem` parsing.
- Create `lib/modules/stocks/stocks_provider.dart`: repository abstraction, API-key/symbol validation, 15-minute cache, and module state transitions.
- Create `lib/modules/stocks/stocks_card.dart`: loading/error/empty/offline/data rendering and Chinese-market quote colors.
- Create `test/modules/stocks/stocks_service_test.dart`: deterministic HTTP parsing, sequencing, and partial/all-failure semantics.
- Create `test/modules/stocks/stocks_provider_test.dart`: validation, caching, offline fallback, and cache-failure isolation.
- Create `test/modules/stocks/stocks_card_test.dart`: visible card states, retry, bounded text, and price colors.
- Modify `lib/main.dart`: injectable repository, provider wiring, non-blocking exactly-once initial load.
- Modify `lib/shared/screens/home_screen.dart`: route stocks to `StocksCard`.
- Modify `test/main_test.dart`: inject fake stocks repositories and verify lifecycle behavior.
- Modify `test/shared/home_screen_test.dart`: provide a stocks provider and verify the real card.
- Modify `test/widget_test.dart`: provide a stocks provider so the app harness stays network-free.
- Create `.superpowers/sdd/task-8-report.md` and update `.superpowers/sdd/progress.md`: record implementation and verification evidence; these files are intentionally Git-ignored.

### Task 1: Implement the Alpha Vantage service contract

**Files:**
- Create: `test/modules/stocks/stocks_service_test.dart`
- Create: `lib/modules/stocks/stocks_service.dart`

- [ ] **Step 1: Write failing tests for parsing, request parameters, and empty input**

Create `test/modules/stocks/stocks_service_test.dart` with the required imports and these exact initial `MockClient` tests:

```dart
test('StocksService parses a GLOBAL_QUOTE response', () async {
  late Uri requested;
  final service = StocksService(
    ApiClient(MockClient((request) async {
      requested = request.url;
      return http.Response(jsonEncode({
        'Global Quote': {
          '01. symbol': '600036.SHH',
          '05. price': '35.2000',
          '09. change': '0.3000',
          '10. change percent': '0.8600%',
        },
      }), 200);
    })),
    now: () => DateTime.utc(2026, 7, 10, 2),
  );

  final quotes = await service.fetchQuotes(['600036.SHH'], 'test-key');

  expect(requested.host, 'www.alphavantage.co');
  expect(requested.path, '/query');
  expect(requested.queryParameters['function'], 'GLOBAL_QUOTE');
  expect(requested.queryParameters['symbol'], '600036.SHH');
  expect(requested.queryParameters['apikey'], 'test-key');
  expect(quotes.single.symbol, '600036.SHH');
  expect(quotes.single.name, '600036.SHH');
  expect(quotes.single.price, 35.2);
  expect(quotes.single.change, 0.3);
  expect(quotes.single.changePercent, 0.86);
  expect(quotes.single.updatedAt, DateTime.utc(2026, 7, 10, 2));
});

test('StocksService returns empty without requesting for empty symbols', () async {
  var requests = 0;
  final service = StocksService(ApiClient(MockClient((_) async {
    requests++;
    return http.Response('{}', 200);
  })));

  expect(await service.fetchQuotes([], 'test-key'), isEmpty);
  expect(requests, 0);
});
```

- [ ] **Step 2: Run the service test and verify RED**

Run:

```powershell
flutter test test/modules/stocks/stocks_service_test.dart
```

Expected: compilation fails because `stocks_service.dart` and `StocksService` do not exist.

- [ ] **Step 3: Add the minimal service parser**

Create `lib/modules/stocks/stocks_service.dart` with:

```dart
import '../../core/api_client.dart';
import '../../models/stock_item.dart';

class StocksService {
  StocksService(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _client;
  final DateTime Function() _now;

  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    final quotes = <StockItem>[];
    for (final symbol in symbols) {
      final uri = Uri.https('www.alphavantage.co', '/query', {
        'function': 'GLOBAL_QUOTE',
        'symbol': symbol,
        'apikey': apiKey,
      });
      final json = await _client.getJson(uri);
      final rawQuote = json['Global Quote'];
      if (rawQuote is! Map || rawQuote.isEmpty) continue;
      final quote = Map<String, dynamic>.from(rawQuote);
      final responseSymbol = quote['01. symbol'] as String;
      quotes.add(
        StockItem(
          symbol: responseSymbol,
          name: symbol,
          price: double.parse(quote['05. price'] as String),
          change: double.parse(quote['09. change'] as String),
          changePercent: double.parse(
            (quote['10. change percent'] as String).replaceAll('%', ''),
          ),
          updatedAt: _now(),
        ),
      );
    }
    return quotes;
  }
}
```

- [ ] **Step 4: Run the focused test and verify GREEN**

Run `flutter test test/modules/stocks/stocks_service_test.dart`.

Expected: the two initial tests pass.

- [ ] **Step 5: Add failing tests for sequential isolation and response classification**

Extend the service test with cases that assert:

```dart
test('StocksService keeps successes when another symbol fails', () async {
  final service = StocksService(ApiClient(MockClient((request) async {
    if (request.url.queryParameters['symbol'] == 'BROKEN') {
      return http.Response('unavailable', 503);
    }
    return http.Response(jsonEncode({
      'Global Quote': {
        '01. symbol': 'HEALTHY',
        '05. price': '12.5',
        '09. change': '-0.5',
        '10. change percent': '-3.8462%',
      },
    }), 200);
  })));

  final quotes = await service.fetchQuotes(['BROKEN', 'HEALTHY'], 'key');

  expect(quotes.map((quote) => quote.symbol), ['HEALTHY']);
});

test('StocksService throws when every symbol fails', () async {
  final service = StocksService(
    ApiClient(MockClient((_) async => http.Response('unavailable', 503))),
  );

  await expectLater(
    service.fetchQuotes(['ONE', 'TWO'], 'key'),
    throwsA(isA<StocksServiceException>()),
  );
});

test('StocksService returns empty when all GLOBAL_QUOTE objects are empty', () async {
  final service = StocksService(ApiClient(MockClient((_) async {
    return http.Response(jsonEncode({'Global Quote': <String, dynamic>{}}), 200);
  })));

  expect(await service.fetchQuotes(['ONE', 'TWO'], 'key'), isEmpty);
});

test('StocksService skips malformed numeric data when another quote is valid', () async {
  final service = StocksService(ApiClient(MockClient((request) async {
    final symbol = request.url.queryParameters['symbol']!;
    return http.Response(jsonEncode({
      'Global Quote': {
        '01. symbol': symbol,
        '05. price': symbol == 'BAD' ? 'not-a-number' : '10',
        '09. change': '1',
        '10. change percent': '10%',
      },
    }), 200);
  })));

  final quotes = await service.fetchQuotes(['BAD', 'GOOD'], 'key');

  expect(quotes.map((quote) => quote.symbol), ['GOOD']);
});
```

Add these sequencing and terminal-response tests:

```dart
test('StocksService waits for one symbol before requesting the next', () async {
  final firstResponse = Completer<http.Response>();
  final requested = <String>[];
  final service = StocksService(ApiClient(MockClient((request) {
    final symbol = request.url.queryParameters['symbol']!;
    requested.add(symbol);
    if (symbol == 'ONE') return firstResponse.future;
    return Future.value(
      http.Response(jsonEncode({'Global Quote': <String, dynamic>{}}), 200),
    );
  })));

  final fetch = service.fetchQuotes(['ONE', 'TWO'], 'key');
  await Future<void>.delayed(Duration.zero);
  expect(requested, ['ONE']);

  firstResponse.complete(
    http.Response(jsonEncode({'Global Quote': <String, dynamic>{}}), 200),
  );
  await fetch;
  expect(requested, ['ONE', 'TWO']);
});

test('StocksService stops on Note and throws without prior success', () async {
  final requested = <String>[];
  final service = StocksService(ApiClient(MockClient((request) async {
    requested.add(request.url.queryParameters['symbol']!);
    return http.Response(jsonEncode({'Note': 'rate limited'}), 200);
  })));

  await expectLater(
    service.fetchQuotes(['ONE', 'TWO'], 'key'),
    throwsA(isA<StocksServiceException>()),
  );
  expect(requested, ['ONE']);
});

test('StocksService returns prior success and stops on Information', () async {
  final requested = <String>[];
  final service = StocksService(ApiClient(MockClient((request) async {
    final symbol = request.url.queryParameters['symbol']!;
    requested.add(symbol);
    if (symbol == 'ONE') {
      return http.Response(jsonEncode({
        'Global Quote': {
          '01. symbol': 'ONE',
          '05. price': '10',
          '09. change': '1',
          '10. change percent': '10%',
        },
      }), 200);
    }
    return http.Response(jsonEncode({'Information': 'quota exceeded'}), 200);
  })));

  final quotes = await service.fetchQuotes(['ONE', 'TWO', 'THREE'], 'key');

  expect(quotes.map((quote) => quote.symbol), ['ONE']);
  expect(requested, ['ONE', 'TWO']);
});
```

- [ ] **Step 6: Run the expanded test and verify RED**

Run `flutter test test/modules/stocks/stocks_service_test.dart`.

Expected: tests fail because the minimal loop is all-or-nothing, does not classify failures, and does not define `StocksServiceException`.

- [ ] **Step 7: Implement failure-isolated sequential outcomes**

Refactor the service so each symbol returns a private result with `quote`, `empty`, `failure`, or `terminalFailure`. Use `double.tryParse`, reject missing/non-string/non-finite required values, count ordinary failures, and stop on `Note`/`Information`. After the loop, throw `StocksServiceException('股票行情全部加载失败')` only when there are no valid quotes and at least one failed result.

The public contract remains:

```dart
Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey)
```

The exception is:

```dart
class StocksServiceException implements Exception {
  StocksServiceException(this.message);

  final String message;

  @override
  String toString() => 'StocksServiceException: $message';
}
```

- [ ] **Step 8: Run service tests and format only touched files**

Run:

```powershell
dart format lib/modules/stocks/stocks_service.dart test/modules/stocks/stocks_service_test.dart
flutter test test/modules/stocks/stocks_service_test.dart
```

Expected: all service tests pass and no live endpoint is contacted.

- [ ] **Step 9: Commit the service slice**

```powershell
git add -- lib/modules/stocks/stocks_service.dart test/modules/stocks/stocks_service_test.dart
git commit -m "feat: add stocks quote service"
```

### Task 2: Implement provider validation and successful caching

**Files:**
- Create: `test/modules/stocks/stocks_provider_test.dart`
- Create: `lib/modules/stocks/stocks_provider.dart`

- [ ] **Step 1: Write failing provider tests for idle, API key, symbols, and success**

Create these deterministic helpers at the top of `stocks_provider_test.dart`:

```dart
class _FixedStocksRepository implements StocksRepository {
  _FixedStocksRepository(this.quotes);

  final List<StockItem> quotes;
  int calls = 0;
  List<String>? receivedSymbols;
  String? receivedApiKey;

  @override
  Future<List<StockItem>> fetchQuotes(
    List<String> symbols,
    String apiKey,
  ) async {
    calls++;
    receivedSymbols = symbols;
    receivedApiKey = apiKey;
    return quotes;
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
    throw StateError('network unavailable');
  }
}

class _ControllableCacheManager implements CacheManager {
  _ControllableCacheManager({
    this.freshValue,
    this.anyValue,
    this.freshError,
    this.anyError,
    this.saveError,
  });

  CachedValue? freshValue;
  CachedValue? anyValue;
  Object? freshError;
  Object? anyError;
  Object? saveError;
  int saveCalls = 0;
  String? readFreshKey;
  Duration? readFreshTtl;
  String? savedKey;
  String? savedJson;

  @override
  Future<void> save(String key, String jsonValue) async {
    saveCalls++;
    savedKey = key;
    savedJson = jsonValue;
    if (saveError != null) throw saveError!;
  }

  @override
  Future<CachedValue?> readFresh(String key, Duration ttl) async {
    readFreshKey = key;
    readFreshTtl = ttl;
    if (freshError != null) throw freshError!;
    return freshValue;
  }

  @override
  Future<CachedValue?> readAny(String key) async {
    if (anyError != null) throw anyError!;
    return anyValue;
  }
}

StockItem _quote(String symbol) => StockItem(
  symbol: symbol,
  name: symbol,
  price: 35.2,
  change: 0.3,
  changePercent: 0.86,
  updatedAt: DateTime.utc(2026, 7, 10, 2),
);

CachedValue _cachedRaw(String raw) => CachedValue(
  key: AppConstants.cacheStocks,
  jsonValue: raw,
  savedAt: DateTime.utc(2026, 7, 10),
  isFresh: true,
);

CachedValue _cachedQuotes(List<StockItem> quotes) => _cachedRaw(
  jsonEncode(quotes.map((quote) => quote.toJson()).toList()),
);

StocksProvider _provider({
  required StocksRepository repository,
  CacheManager? cache,
  List<String> Function()? symbolsReader,
  String Function()? apiKeyReader,
}) => StocksProvider(
  repository: repository,
  cache: cache ?? MemoryCacheManager(),
  symbolsReader: symbolsReader ?? () => ['600036.SHH'],
  apiKeyReader: apiKeyReader ?? () => 'test-key',
);
```

Then add these exact tests:

```dart
test('StocksProvider starts idle', () {
  final provider = _provider(repository: _FixedStocksRepository([]));
  addTearDown(provider.dispose);
  expect(provider.state.status, ModuleStatus.idle);
});

test('StocksProvider requires an API key without fetching', () async {
  final repository = _FixedStocksRepository([]);
  final provider = _provider(repository: repository, apiKeyReader: () => '  ');
  addTearDown(provider.dispose);

  await provider.loadFromCacheOrRefresh();

  expect(provider.state.status, ModuleStatus.error);
  expect(provider.state.error!.type, AppErrorType.apiKeyMissing);
  expect(provider.state.error!.message, '请先在设置中填写 Alpha Vantage API Key');
  expect(repository.calls, 0);
});

test('StocksProvider returns empty for no configured symbols', () async {
  final repository = _FixedStocksRepository([]);
  final provider = _provider(
    repository: repository,
    symbolsReader: () => const <String>[],
  );
  addTearDown(provider.dispose);

  await provider.refresh();

  expect(provider.state.status, ModuleStatus.empty);
  expect(repository.calls, 0);
});

test('StocksProvider fetches configured symbols and caches quotes', () async {
  final quote = _quote('600036.SHH');
  final repository = _FixedStocksRepository([quote]);
  final cache = _ControllableCacheManager();
  final provider = _provider(repository: repository, cache: cache);
  addTearDown(provider.dispose);

  await provider.refresh();

  expect(provider.state.status, ModuleStatus.data);
  expect(provider.state.data, [quote]);
  expect(repository.receivedSymbols, ['600036.SHH']);
  expect(repository.receivedApiKey, 'test-key');
  expect(cache.savedKey, AppConstants.cacheStocks);
  expect(
    StockItem.fromJson(
      (jsonDecode(cache.savedJson!) as List<dynamic>).single
          as Map<String, dynamic>,
    ).symbol,
    '600036.SHH',
  );
});
```

- [ ] **Step 2: Run provider tests and verify RED**

Run `flutter test test/modules/stocks/stocks_provider_test.dart`.

Expected: compilation fails because `stocks_provider.dart`, `StocksRepository`, and `StocksProvider` do not exist.

- [ ] **Step 3: Implement repository abstraction and minimum provider**

Create `lib/modules/stocks/stocks_provider.dart` with:

```dart
abstract class StocksRepository {
  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey);
}

class StocksServiceRepository implements StocksRepository {
  StocksServiceRepository(this._service);
  final StocksService _service;

  @override
  Future<List<StockItem>> fetchQuotes(List<String> symbols, String apiKey) {
    return _service.fetchQuotes(symbols, apiKey);
  }
}
```

Add `StocksProvider` with injected repository/cache/readers, an idle `ModuleState<List<StockItem>>`, trimmed key validation, trimmed non-empty symbols, loading/data/empty transitions, best-effort JSON cache save, and `notifyListeners()` after each terminal transition. Use `AppConstants.cacheStocks`.

- [ ] **Step 4: Run provider tests and verify GREEN**

Run `flutter test test/modules/stocks/stocks_provider_test.dart`.

Expected: initial provider tests pass.

- [ ] **Step 5: Add failing tests for fresh cache and empty network results**

Add these fresh-cache and empty-result tests:

```dart
test('StocksProvider uses 15-minute fresh cache without fetching', () async {
  final repository = _ThrowingStocksRepository();
  final cache = _ControllableCacheManager(
    freshValue: _cachedQuotes([_quote('CACHED')]),
  );
  final provider = _provider(repository: repository, cache: cache);
  addTearDown(provider.dispose);

  await provider.loadFromCacheOrRefresh();

  expect(provider.state.status, ModuleStatus.data);
  expect(provider.state.data!.single.symbol, 'CACHED');
  expect(cache.readFreshKey, AppConstants.cacheStocks);
  expect(cache.readFreshTtl, const Duration(minutes: 15));
  expect(repository.calls, 0);
});

test('StocksProvider does not cache an empty network result', () async {
  final cache = _ControllableCacheManager();
  final provider = _provider(
    repository: _FixedStocksRepository([]),
    cache: cache,
  );
  addTearDown(provider.dispose);

  await provider.refresh();

  expect(provider.state.status, ModuleStatus.empty);
  expect(cache.saveCalls, 0);
});

test('StocksProvider treats invalid fresh caches as misses', () async {
  for (final cache in [
    _ControllableCacheManager(freshValue: _cachedRaw('not-json')),
    _ControllableCacheManager(freshValue: _cachedRaw('[]')),
    _ControllableCacheManager(freshError: StateError('cache unavailable')),
  ]) {
    final repository = _FixedStocksRepository([_quote('NETWORK')]);
    final provider = _provider(repository: repository, cache: cache);

    await provider.loadFromCacheOrRefresh();

    expect(provider.state.data!.single.symbol, 'NETWORK');
    expect(repository.calls, 1);
    provider.dispose();
  }
});
```

- [ ] **Step 6: Run provider tests and verify RED**

Run `flutter test test/modules/stocks/stocks_provider_test.dart`.

Expected: failures show missing 15-minute fresh-cache behavior and cache decoding isolation.

- [ ] **Step 7: Implement safe fresh-cache loading**

Add `_readFreshCachedQuotes`, `_readAnyCachedQuotes`, and one shared safe decoder. The decoder catches cache read, JSON decoding, cast, and `StockItem.fromJson` failures and returns `null`. Treat decoded empty lists as unusable cache entries.

- [ ] **Step 8: Run and format provider files**

```powershell
dart format lib/modules/stocks/stocks_provider.dart test/modules/stocks/stocks_provider_test.dart
flutter test test/modules/stocks/stocks_provider_test.dart
```

Expected: provider validation, success, empty, and fresh-cache tests pass.

- [ ] **Step 9: Commit the provider base slice**

```powershell
git add -- lib/modules/stocks/stocks_provider.dart test/modules/stocks/stocks_provider_test.dart
git commit -m "feat: add stocks provider caching"
```

### Task 3: Harden provider offline and cache-failure behavior

**Files:**
- Modify: `test/modules/stocks/stocks_provider_test.dart`
- Modify: `lib/modules/stocks/stocks_provider.dart`

- [ ] **Step 1: Write failing offline and failure-isolation tests**

Add these offline and failure-isolation tests:

```dart
test('StocksProvider exposes stale quotes offline on repository failure', () async {
  final provider = _provider(
    repository: _ThrowingStocksRepository(),
    cache: _ControllableCacheManager(anyValue: _cachedQuotes([_quote('OLD')])),
  );
  addTearDown(provider.dispose);

  await provider.refresh();

  expect(provider.state.status, ModuleStatus.offline);
  expect(provider.state.data!.single.symbol, 'OLD');
});

test('StocksProvider reports the standard error without usable stale cache', () async {
  final provider = _provider(repository: _ThrowingStocksRepository());
  addTearDown(provider.dispose);

  await provider.refresh();

  expect(provider.state.status, ModuleStatus.error);
  expect(provider.state.error!.type, AppErrorType.network);
  expect(provider.state.error!.message, '股票行情加载失败');
});

test('StocksProvider rejects malformed unreadable and empty stale caches', () async {
  for (final cache in [
    _ControllableCacheManager(anyValue: _cachedRaw('not-json')),
    _ControllableCacheManager(anyValue: _cachedRaw('[]')),
    _ControllableCacheManager(anyError: StateError('cache unavailable')),
  ]) {
    final provider = _provider(
      repository: _ThrowingStocksRepository(),
      cache: cache,
    );

    await expectLater(provider.refresh(), completes);
    expect(provider.state.error!.message, '股票行情加载失败');
    provider.dispose();
  }
});

test('StocksProvider keeps fetched quotes when cache save fails', () async {
  final provider = _provider(
    repository: _FixedStocksRepository([_quote('NEW')]),
    cache: _ControllableCacheManager(
      saveError: StateError('cache unavailable'),
    ),
  );
  addTearDown(provider.dispose);

  await provider.refresh();

  expect(provider.state.status, ModuleStatus.data);
  expect(provider.state.data!.single.symbol, 'NEW');
});

test('StocksProvider isolates configuration reader failures', () async {
  final provider = _provider(
    repository: _FixedStocksRepository([]),
    symbolsReader: () => throw StateError('settings unavailable'),
  );
  addTearDown(provider.dispose);

  await expectLater(provider.refresh(), completes);

  expect(provider.state.error!.message, '股票行情加载失败');
});
```

- [ ] **Step 2: Run provider tests and verify RED**

Run `flutter test test/modules/stocks/stocks_provider_test.dart`.

Expected: new tests fail because repository/configuration failures do not yet share safe stale-cache fallback.

- [ ] **Step 3: Implement one failure fallback path**

Add a private method that reads a usable stale cache and sets offline state, or sets:

```dart
ModuleState.error(
  const AppError(
    type: AppErrorType.network,
    message: '股票行情加载失败',
  ),
)
```

Call it for repository failures and reader exceptions. Keep missing-key and empty-symbol outcomes distinct. Wrap cache save separately so its failure cannot enter the network-failure path.

- [ ] **Step 4: Run provider tests and verify GREEN**

Run `flutter test test/modules/stocks/stocks_provider_test.dart`.

Expected: all provider tests pass.

- [ ] **Step 5: Commit provider hardening**

```powershell
git add -- lib/modules/stocks/stocks_provider.dart test/modules/stocks/stocks_provider_test.dart
git commit -m "fix: harden stocks cache fallback"
```

### Task 4: Build the stocks card through widget tests

**Files:**
- Create: `test/modules/stocks/stocks_card_test.dart`
- Create: `lib/modules/stocks/stocks_card.dart`

- [ ] **Step 1: Write failing card-state tests**

Create a `MaterialApp` harness with `ChangeNotifierProvider.value` and fake repositories. Add tests for:

```dart
expect(find.text('股票财经'), findsOneWidget);
expect(find.byIcon(Icons.show_chart), findsOneWidget);
expect(find.text('暂无行情'), findsOneWidget); // idle and empty
expect(find.byType(CircularProgressIndicator), findsOneWidget); // pending
expect(find.text('股票行情加载失败'), findsOneWidget); // failure
expect(find.text('重试'), findsOneWidget);
expect(find.text('离线'), findsOneWidget); // stale fallback
```

The retry test must fail once, tap `重试`, pump twice, and assert the second repository call renders a quote.

- [ ] **Step 2: Run card tests and verify RED**

Run `flutter test test/modules/stocks/stocks_card_test.dart`.

Expected: compilation fails because `stocks_card.dart` and `StocksCard` do not exist.

- [ ] **Step 3: Implement shared-state rendering**

Create `StocksCard` using `ModuleCard`, `ModuleLoadingWidget`, `ModuleErrorWidget`, and `ModuleEmptyWidget`. Use title `股票财经`, icon `Icons.show_chart`, offline badge from `state.isOffline`, empty copy `暂无行情`, and `provider.refresh` for retry.

- [ ] **Step 4: Add failing quote-row color and overflow tests**

Render positive, negative, and zero-change quotes. Locate their change texts and assert:

```dart
expect(positive.style!.color, AppColors.profitRed);
expect(negative.style!.color, AppColors.lossGreen);
expect(zero.style?.color, isNull);
```

Assert symbol/name/price/change percentage texts use finite `maxLines` and `TextOverflow.ellipsis`. Use exact signed change copy such as `+0.30 (+0.86%)`, `-0.10 (-0.28%)`, and `0.00 (0.00%)`.

- [ ] **Step 5: Run card tests and verify RED**

Run `flutter test test/modules/stocks/stocks_card_test.dart`.

Expected: state tests may pass, while row formatting/color/overflow tests fail until data rows are implemented.

- [ ] **Step 6: Implement bounded quote rows and Chinese-market colors**

Use a row with `Expanded` text columns. Price and change text must remain bounded. Select red only when `change > 0`, green only when `change < 0`, and no explicit color when `change == 0`.

- [ ] **Step 7: Format and run card tests**

```powershell
dart format lib/modules/stocks/stocks_card.dart test/modules/stocks/stocks_card_test.dart
flutter test test/modules/stocks/stocks_card_test.dart
```

Expected: all card tests pass.

- [ ] **Step 8: Commit the card slice**

```powershell
git add -- lib/modules/stocks/stocks_card.dart test/modules/stocks/stocks_card_test.dart
git commit -m "feat: add stocks dashboard card"
```

### Task 5: Integrate stocks without blocking startup

**Files:**
- Modify: `test/main_test.dart`
- Modify: `test/shared/home_screen_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/shared/screens/home_screen.dart`

- [ ] **Step 1: Update existing harnesses with fake stocks providers/repositories**

In `home_screen_test.dart` and `widget_test.dart`, create a `StocksProvider` using `MemoryCacheManager`, a fake repository, `symbolsReader: () => ['600036.SHH']`, and `apiKeyReader: () => 'test-key'`. Add it to each `MultiProvider` and dispose it in teardown.

In every existing `startApp` test, pass a fake `StocksRepository` through a new expected `stocksRepository` parameter. This first edit intentionally fails to compile until production wiring exists.

- [ ] **Step 2: Add failing startup lifecycle tests**

Add a pending stocks repository and verify `startApp` returns and renders `MorningBrief` before its completer resolves. Seed `AppConstants.stockApiKey: 'test-key'` so the repository is reached.

Add disabled-stock preferences and tests proving:

```dart
expect(repository.calls, 0); // disabled at startup
```

Then toggle `MorningModuleId.stocks` to true twice and assert:

```dart
expect(repository.calls, 1);
```

- [ ] **Step 3: Add a failing home-screen card assertion**

Refresh the fake stocks provider with a quote and assert the home screen shows `股票财经`, the symbol, and its formatted price instead of `模块正在加载`.

- [ ] **Step 4: Run integration tests and verify RED**

```powershell
flutter test test/main_test.dart test/shared/home_screen_test.dart test/widget_test.dart
```

Expected: compilation or assertion failures show missing repository injection, provider registration, lifecycle loading, and stocks-card routing.

- [ ] **Step 5: Wire the provider and non-blocking lifecycle**

Modify `startApp` to accept `StocksRepository? stocksRepository`, create `StocksProvider` with `StocksServiceRepository(StocksService(apiClient))` as the production default, and register it in `MultiProvider`.

Add an exactly-once `loadStocksIfEnabled` listener matching the hardened news lifecycle. Invoke it after `runApp`; use `unawaited(_loadStocksSafely(stocksProvider))`; catch unexpected exceptions inside `_loadStocksSafely` so startup cannot fail.

Import `stocks_card.dart` in `home_screen.dart` and return `const StocksCard()` for `MorningModuleId.stocks` before placeholder icon selection.

- [ ] **Step 6: Run integration tests and verify GREEN**

Run:

```powershell
dart format lib/main.dart lib/shared/screens/home_screen.dart test/main_test.dart test/shared/home_screen_test.dart test/widget_test.dart
flutter test test/main_test.dart test/shared/home_screen_test.dart test/widget_test.dart
```

Expected: all integration tests pass without live HTTP calls and pending stock loading does not delay the first frame.

- [ ] **Step 7: Run all stock-focused tests**

```powershell
flutter test test/modules/stocks test/main_test.dart test/shared/home_screen_test.dart test/widget_test.dart
```

Expected: all stock and integration tests pass.

- [ ] **Step 8: Commit integrated Task 8 behavior**

```powershell
git add -- lib/main.dart lib/shared/screens/home_screen.dart test/main_test.dart test/shared/home_screen_test.dart test/widget_test.dart
git commit -m "feat: integrate stocks module"
```

### Task 6: Review, verify, and record Task 8

**Files:**
- Review: all Task 8 code and tests since commit `7cd9b26`
- Create: `.superpowers/sdd/task-8-report.md`
- Modify: `.superpowers/sdd/progress.md`

- [ ] **Step 1: Perform a specification review**

Compare the implementation and tests line-by-line with `docs/superpowers/specs/2026-07-10-stocks-module-design.md`. Record any missing behavior before continuing. Required checks include sequential requests, partial success, all-failure versus all-empty distinction, key/symbol short-circuits, 15-minute cache, offline fallback, Chinese-market colors, and exactly-once non-blocking lifecycle.

- [ ] **Step 2: Perform a code-quality review**

Inspect:

```powershell
git diff 7cd9b26..HEAD -- lib test
```

Fix every Critical or Important issue through a new failing regression test before modifying production code. Keep quality fixes in a separate focused commit such as `fix: harden stocks loading lifecycle`.

- [ ] **Step 3: Run fresh focused verification**

```powershell
flutter test test/modules/stocks test/main_test.dart test/shared/home_screen_test.dart test/widget_test.dart
```

Expected: all focused tests pass with exit code 0.

- [ ] **Step 4: Run fresh complete verification**

```powershell
flutter test
flutter analyze
git diff --check
git status --short --branch
```

Expected: all tests pass, analyzer reports `No issues found!`, `git diff --check` emits no errors, and only the intentionally untracked `HANDOFF.md` remains outside commits.

- [ ] **Step 5: Write the ignored Task 8 report and progress update**

Create `.superpowers/sdd/task-8-report.md` containing:

- Commit IDs and summaries.
- RED/GREEN commands and observed failure reasons.
- Specification and quality review results.
- Focused/full test counts and analyzer result.
- Explicit statements that Android runtime and live Alpha Vantage smoke testing were not performed.
- Confirmation that no API key was committed.

Append this exact status form to `.superpowers/sdd/progress.md` with actual commit IDs:

```text
Task 8: complete (commits <first>..<last>, spec and quality review clean after fixes)
```

- [ ] **Step 6: Confirm final repository scope**

Run:

```powershell
git status --short --branch
git log --oneline -8
```

Expected: implementation commits are present on `morningbrief-sdd`, no unrelated tracked edits remain, and `HANDOFF.md` is still untracked and preserved.
