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
    var hadFailure = false;

    for (final configuredSymbol in symbols) {
      final uri = Uri.https('www.alphavantage.co', '/query', {
        'function': 'GLOBAL_QUOTE',
        'symbol': configuredSymbol,
        'apikey': apiKey,
      });

      try {
        final json = await _client.getJson(uri);
        if (json.containsKey('Note') || json.containsKey('Information')) {
          hadFailure = true;
          break;
        }

        final value = json['Global Quote'];
        if (value is! Map<String, dynamic>) {
          hadFailure = true;
          continue;
        }
        if (value.isEmpty) continue;

        final quote = _parseQuote(value, configuredSymbol);
        if (quote == null) {
          hadFailure = true;
          continue;
        }
        quotes.add(quote);
      } catch (_) {
        hadFailure = true;
      }
    }

    if (quotes.isNotEmpty) return quotes;
    if (hadFailure) {
      throw StocksServiceException('股票行情全部加载失败');
    }
    return quotes;
  }

  StockItem? _parseQuote(Map<String, dynamic> json, String configuredSymbol) {
    final symbol = json['01. symbol'];
    final price = _parseFiniteDouble(json['05. price']);
    final change = _parseFiniteDouble(json['09. change']);
    final changePercent = _parseChangePercent(json['10. change percent']);
    if (symbol is! String ||
        symbol.trim().isEmpty ||
        price == null ||
        change == null ||
        changePercent == null) {
      return null;
    }

    return StockItem(
      symbol: symbol,
      name: configuredSymbol,
      price: price,
      change: change,
      changePercent: changePercent,
      updatedAt: _now(),
    );
  }

  double? _parseFiniteDouble(Object? value) {
    if (value is! String) return null;
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  double? _parseChangePercent(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    final numeric = trimmed.endsWith('%')
        ? trimmed.substring(0, trimmed.length - 1).trim()
        : trimmed;
    return _parseFiniteDouble(numeric);
  }
}

class StocksServiceException implements Exception {
  StocksServiceException(this.message);

  final String message;

  @override
  String toString() => 'StocksServiceException: $message';
}
