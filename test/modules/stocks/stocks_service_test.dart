import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:morningbrief/core/api_client.dart';
import 'package:morningbrief/modules/stocks/stocks_service.dart';

http.Response _jsonResponse(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object> _quote({
  required String symbol,
  String price = '123.45',
  String change = '1.25',
  String changePercent = '1.02%',
}) => {
  'Global Quote': {
    '01. symbol': symbol,
    '02. open': '122.20',
    '03. high': '124.00',
    '04. low': '121.80',
    '05. price': price,
    '06. volume': '1000000',
    '07. latest trading day': '2026-07-09',
    '08. previous close': '122.20',
    '09. change': change,
    '10. change percent': changePercent,
  },
};

void main() {
  test(
    'StocksService parses a quote and sends Alpha Vantage parameters',
    () async {
      late Uri requestedUri;
      final updatedAt = DateTime(2026, 7, 10, 8, 30);
      final client = ApiClient(
        MockClient((request) async {
          requestedUri = request.url;
          return _jsonResponse(
            _quote(
              symbol: 'MSFT',
              price: '451.23',
              change: '-2.50',
              changePercent: '-0.5510%',
            ),
          );
        }),
      );

      final quotes = await StocksService(
        client,
        now: () => updatedAt,
      ).fetchQuotes(['msft'], 'secret-key');

      expect(requestedUri.scheme, 'https');
      expect(requestedUri.host, 'www.alphavantage.co');
      expect(requestedUri.path, '/query');
      expect(requestedUri.queryParameters, {
        'function': 'GLOBAL_QUOTE',
        'symbol': 'msft',
        'apikey': 'secret-key',
      });
      expect(quotes, hasLength(1));
      expect(quotes.single.symbol, 'MSFT');
      expect(quotes.single.name, 'msft');
      expect(quotes.single.price, 451.23);
      expect(quotes.single.change, -2.5);
      expect(quotes.single.changePercent, -0.551);
      expect(quotes.single.updatedAt, updatedAt);
    },
  );

  test('StocksService returns empty input without making a request', () async {
    var requestCount = 0;
    final client = ApiClient(
      MockClient((_) async {
        requestCount++;
        return _jsonResponse(_quote(symbol: 'UNEXPECTED'));
      }),
    );

    final quotes = await StocksService(client).fetchQuotes([], 'secret-key');

    expect(quotes, isEmpty);
    expect(requestCount, 0);
  });

  test(
    'StocksService waits for each request before starting the next',
    () async {
      final firstResponse = Completer<http.Response>();
      final requestedSymbols = <String>[];
      addTearDown(() {
        if (!firstResponse.isCompleted) {
          firstResponse.complete(_jsonResponse({'Global Quote': {}}));
        }
      });
      final client = ApiClient(
        MockClient((request) {
          final symbol = request.url.queryParameters['symbol']!;
          requestedSymbols.add(symbol);
          if (symbol == 'FIRST') return firstResponse.future;
          return Future.value(_jsonResponse({'Global Quote': {}}));
        }),
      );

      final fetch = StocksService(
        client,
      ).fetchQuotes(['FIRST', 'SECOND'], 'secret-key');
      await Future<void>.delayed(Duration.zero);

      expect(requestedSymbols, ['FIRST']);

      firstResponse.complete(_jsonResponse({'Global Quote': {}}));
      expect(await fetch, isEmpty);
      expect(requestedSymbols, ['FIRST', 'SECOND']);
    },
  );

  test('StocksService keeps later success after an ordinary failure', () async {
    final requestedSymbols = <String>[];
    final client = ApiClient(
      MockClient((request) async {
        final symbol = request.url.queryParameters['symbol']!;
        requestedSymbols.add(symbol);
        if (symbol == 'BROKEN') return http.Response('unavailable', 503);
        return _jsonResponse(_quote(symbol: symbol));
      }),
    );

    final quotes = await StocksService(
      client,
    ).fetchQuotes(['BROKEN', 'HEALTHY'], 'secret-key');

    expect(requestedSymbols, ['BROKEN', 'HEALTHY']);
    expect(quotes.map((quote) => quote.symbol), ['HEALTHY']);
  });

  test('StocksService throws when all symbols fail ordinarily', () async {
    final requestedSymbols = <String>[];
    final client = ApiClient(
      MockClient((request) async {
        requestedSymbols.add(request.url.queryParameters['symbol']!);
        return http.Response('unavailable', 500);
      }),
    );

    await expectLater(
      StocksService(client).fetchQuotes(['FIRST', 'SECOND'], 'secret-key'),
      throwsA(
        isA<StocksServiceException>().having(
          (error) => error.message,
          'message',
          '股票行情全部加载失败',
        ),
      ),
    );
    expect(requestedSymbols, ['FIRST', 'SECOND']);
  });

  test(
    'StocksService returns empty when every quote is valid but empty',
    () async {
      final client = ApiClient(
        MockClient((_) async => _jsonResponse({'Global Quote': {}})),
      );

      final quotes = await StocksService(
        client,
      ).fetchQuotes(['FIRST', 'SECOND'], 'secret-key');

      expect(quotes, isEmpty);
    },
  );

  test(
    'StocksService isolates malformed numeric data from a valid quote',
    () async {
      final client = ApiClient(
        MockClient((request) async {
          final symbol = request.url.queryParameters['symbol']!;
          if (symbol == 'BROKEN') {
            return _jsonResponse(_quote(symbol: symbol, price: 'NaN'));
          }
          return _jsonResponse(_quote(symbol: symbol, price: '98.75'));
        }),
      );

      final quotes = await StocksService(
        client,
      ).fetchQuotes(['BROKEN', 'HEALTHY'], 'secret-key');

      expect(quotes, hasLength(1));
      expect(quotes.single.symbol, 'HEALTHY');
      expect(quotes.single.price, 98.75);
    },
  );

  test(
    'StocksService treats a non-empty quote missing a required field as failure',
    () async {
      final client = ApiClient(
        MockClient(
          (_) async => _jsonResponse({
            'Global Quote': {
              '01. symbol': 'BROKEN',
              '05. price': '100.00',
              '10. change percent': '1.00%',
            },
          }),
        ),
      );

      await expectLater(
        StocksService(client).fetchQuotes(['BROKEN'], 'secret-key'),
        throwsA(isA<StocksServiceException>()),
      );
    },
  );

  test(
    'StocksService stops on Note and throws without prior success',
    () async {
      final requestedSymbols = <String>[];
      final client = ApiClient(
        MockClient((request) async {
          final symbol = request.url.queryParameters['symbol']!;
          requestedSymbols.add(symbol);
          return _jsonResponse({'Note': 'API call frequency exceeded'});
        }),
      );

      await expectLater(
        StocksService(
          client,
        ).fetchQuotes(['LIMITED', 'NOT_REQUESTED'], 'secret-key'),
        throwsA(isA<StocksServiceException>()),
      );
      expect(requestedSymbols, ['LIMITED']);
    },
  );

  test(
    'StocksService stops on Information and returns prior success',
    () async {
      final requestedSymbols = <String>[];
      final client = ApiClient(
        MockClient((request) async {
          final symbol = request.url.queryParameters['symbol']!;
          requestedSymbols.add(symbol);
          if (symbol == 'HEALTHY') {
            return _jsonResponse(_quote(symbol: symbol));
          }
          return _jsonResponse({'Information': 'API rate limit reached'});
        }),
      );

      final quotes = await StocksService(
        client,
      ).fetchQuotes(['HEALTHY', 'LIMITED', 'NOT_REQUESTED'], 'secret-key');

      expect(quotes.map((quote) => quote.symbol), ['HEALTHY']);
      expect(requestedSymbols, ['HEALTHY', 'LIMITED']);
    },
  );
}
