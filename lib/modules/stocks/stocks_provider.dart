import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/app_error.dart';
import '../../core/cache_manager.dart';
import '../../core/constants.dart';
import '../../models/stock_item.dart';
import '../../shared/module_state.dart';
import 'stocks_service.dart';

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

class StocksProvider extends ChangeNotifier {
  StocksProvider({
    required this.repository,
    required this.cache,
    required this.symbolsReader,
    required this.apiKeyReader,
  });

  final StocksRepository repository;
  final CacheManager cache;
  final List<String> Function() symbolsReader;
  final String Function() apiKeyReader;

  ModuleState<List<StockItem>> _state = ModuleState.idle();

  ModuleState<List<StockItem>> get state => _state;

  Future<void> loadFromCacheOrRefresh() async {
    final configuration = _readConfiguration();
    if (configuration == null) return;

    final cachedQuotes = await _readFreshCachedQuotes();
    if (cachedQuotes != null) {
      _setState(ModuleState.data(cachedQuotes));
      return;
    }

    await _refresh(configuration);
  }

  Future<void> refresh() async {
    final configuration = _readConfiguration();
    if (configuration == null) return;

    await _refresh(configuration);
  }

  _StocksConfiguration? _readConfiguration() {
    final apiKey = apiKeyReader().trim();
    if (apiKey.isEmpty) {
      _setState(
        ModuleState.error(
          const AppError(
            type: AppErrorType.apiKeyMissing,
            message: '请先在设置中填写 Alpha Vantage API Key',
          ),
        ),
      );
      return null;
    }

    final symbols = symbolsReader()
        .map((symbol) => symbol.trim())
        .where((symbol) => symbol.isNotEmpty)
        .toList();
    if (symbols.isEmpty) {
      _setState(ModuleState.empty());
      return null;
    }

    return _StocksConfiguration(symbols: symbols, apiKey: apiKey);
  }

  Future<void> _refresh(_StocksConfiguration configuration) async {
    _setState(ModuleState.loading());
    final quotes = await repository.fetchQuotes(
      configuration.symbols,
      configuration.apiKey,
    );
    if (quotes.isEmpty) {
      _setState(ModuleState.empty());
      return;
    }

    try {
      await cache.save(
        AppConstants.cacheStocks,
        jsonEncode(quotes.map((quote) => quote.toJson()).toList()),
      );
    } catch (_) {
      // Cache persistence is best effort after a successful fetch.
    }
    _setState(ModuleState.data(quotes));
  }

  Future<List<StockItem>?> _readFreshCachedQuotes() async {
    try {
      final cached = await cache.readFresh(
        AppConstants.cacheStocks,
        const Duration(minutes: 15),
      );
      if (cached == null) return null;

      final decoded = jsonDecode(cached.jsonValue);
      if (decoded is! List) return null;
      final quotes = decoded.map((value) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Invalid cached stock item');
        }
        return StockItem.fromJson(value);
      }).toList();
      return quotes.isEmpty ? null : quotes;
    } catch (_) {
      return null;
    }
  }

  void _setState(ModuleState<List<StockItem>> state) {
    _state = state;
    notifyListeners();
  }
}

class _StocksConfiguration {
  const _StocksConfiguration({required this.symbols, required this.apiKey});

  final List<String> symbols;
  final String apiKey;
}
