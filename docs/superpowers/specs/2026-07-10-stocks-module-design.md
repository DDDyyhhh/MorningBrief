# Task 8 Stocks Module Design

## Goal

Add a production-ready stocks module to MorningBrief that reads configured Alpha Vantage symbols, displays cached or freshly fetched quotes, degrades safely when the API or cache fails, and never blocks application startup.

## Scope

Task 8 adds:

- `StocksService.fetchQuotes(List<String> symbols, String apiKey)`.
- `StocksProvider.loadFromCacheOrRefresh()` and `refresh()`.
- A `StocksCard` routed from `MorningModuleId.stocks`.
- Startup lifecycle integration matching the existing non-blocking news-module pattern.
- Deterministic service, provider, widget, home-screen, and startup tests with no live Alpha Vantage requests.

Task 8 does not change the default symbols, upgrade dependencies, implement global refresh orchestration, validate Alpha Vantage with real credentials, or add Android runtime verification.

## Architecture

The module follows the existing feature boundary used by weather and news:

- `StocksService` owns request construction, sequential multi-symbol orchestration, Alpha Vantage response interpretation, and quote parsing.
- `StocksProvider` owns configuration validation, cache policy, state transitions, and offline fallback.
- `StocksCard` renders provider state without performing network or cache work.
- `main.dart` creates and injects the provider, then starts its first load after `runApp` without awaiting external network work.
- `home_screen.dart` routes `MorningModuleId.stocks` to the real card.

## Service Behavior

`StocksService` sends one Alpha Vantage `GLOBAL_QUOTE` request at a time. Sequential requests avoid a burst of concurrent calls against a rate-limited API.

Each configured symbol produces one of three outcomes:

1. A valid `Global Quote` becomes a `StockItem`.
2. An empty `Global Quote` is treated as a successful request with no available quote.
3. A transport error, malformed required field, invalid numeric field, `Note`, or `Information` response is treated as a failed symbol.

The service isolates ordinary per-symbol failures and continues with later symbols. `Note` and `Information` indicate a likely global quota or API problem, so the service stops issuing further requests. Quotes already parsed before that response remain usable.

The final result follows these rules:

- At least one valid quote: return all valid quotes, even if other symbols failed.
- No valid quotes and at least one failed symbol: throw a stocks service exception.
- All requests completed normally but every quote was empty: return an empty list.
- An empty symbol list: return an empty list without issuing a request.

The service preserves configured order and does not place API keys in logs, errors, fixtures, or committed source.

## Provider and Cache Behavior

`StocksProvider` starts idle and uses `AppConstants.cacheStocks` with a 15-minute TTL.

Before any cache or network load, the provider reads and trims the configured API key. A missing key produces an `apiKeyMissing` error with the exact message `请先在设置中填写 Alpha Vantage API Key` and performs no network request. An empty configured symbol list produces the empty state and performs no network request.

For a valid configuration:

- A readable, non-empty fresh cache becomes the data state without a repository call.
- A missing, unreadable, malformed, or empty fresh cache is treated as a cache miss.
- A successful non-empty network result is saved on a best-effort basis and becomes the data state.
- A successful empty network result becomes the empty state and is not cached.
- A repository failure falls back to a readable, non-empty stale cache and becomes the offline state.
- If no usable stale cache exists, the provider produces a network error with the exact message `股票行情加载失败`.
- Cache read, decode, and save exceptions never escape from provider load methods.
- Cache-save failure never discards successfully fetched quotes.

Configuration-reader failures are handled like load failures: use a usable stale cache when possible, otherwise expose the standard stock-loading error.

## Card Design

`StocksCard` uses the existing shared module widgets and has:

- Title: `股票财经`.
- Icon: `Icons.show_chart`.
- Loading, retryable error, empty, offline, and data states.
- Empty copy: `暂无行情`.
- One bounded row per quote showing symbol, display name, price, absolute change, and percentage change.
- Positive values in `AppColors.profitRed` and negative values in `AppColors.lossGreen`, following Chinese market convention.
- Zero change in the normal theme text color rather than implying a gain or loss.

Alpha Vantage `GLOBAL_QUOTE` does not supply a company name, so the initial implementation uses the configured symbol as both `symbol` and `name`.

## Application Lifecycle

Stocks loading follows the hardened news lifecycle:

- The provider is constructed before `runApp` and injected through `MultiProvider`.
- The external load is scheduled after `runApp` and is not awaited by startup.
- If the stocks module is disabled at startup, no repository request occurs.
- Enabling it later in the same app session triggers exactly one initial load.
- Repeated enabled notifications do not trigger duplicate initial loads.
- `startApp` accepts an injectable `StocksRepository` so startup tests never reach the real Alpha Vantage endpoint.
- Unexpected initial-load exceptions are isolated and cannot fail application startup.

## Testing Strategy

Implementation uses strict red-green-refactor cycles.

Service tests cover:

- Valid quote parsing and request parameters.
- Sequential request behavior and configured ordering.
- Partial success when another symbol fails or is malformed.
- All-symbol failure.
- All-symbol empty responses.
- Empty symbol input.
- Invalid numeric fields.
- `Note` and `Information` responses, including stopping later requests.

Provider tests cover:

- Initial idle state.
- Missing API key and empty symbol short-circuits.
- 15-minute fresh-cache reuse without a repository call.
- Successful fetch and cache serialization.
- Empty results without cache writes.
- Stale-cache offline fallback.
- No-cache error behavior.
- Cache read, decode, and save failures.
- Settings-reader failures.

Widget and integration tests cover:

- Card title, icon, loading, empty, error/retry, offline, and data states.
- Chinese-market gain/loss colors and neutral zero-change color.
- Bounded quote text that cannot overflow the card.
- Home-screen routing to a real `StocksCard`.
- Fake repository injection for every startup or home-screen harness.
- Non-blocking startup, disabled-module suppression, and exactly-once loading after enablement.

Focused stock tests, the complete Flutter test suite, `flutter analyze`, and `git diff --check` must pass before Task 8 is reported complete. Android runtime and live Alpha Vantage smoke testing remain explicitly unverified until suitable credentials and a device or emulator are available.

## Files

Create:

- `lib/modules/stocks/stocks_service.dart`
- `lib/modules/stocks/stocks_provider.dart`
- `lib/modules/stocks/stocks_card.dart`
- `test/modules/stocks/stocks_service_test.dart`
- `test/modules/stocks/stocks_provider_test.dart`
- `test/modules/stocks/stocks_card_test.dart`

Modify as required:

- `lib/main.dart`
- `lib/shared/screens/home_screen.dart`
- `test/main_test.dart`
- `test/widget_test.dart`
- `test/shared/home_screen_test.dart`

No unrelated calendar, weather, news, dependency, or default-symbol changes belong in Task 8.
